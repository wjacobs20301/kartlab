#!/usr/bin/env python3
"""Make the kart's steering wheel turn with the stick, using the native ControlStick animation.

The native LeftRight clip already rotates the host ControlStick bone Handle_J +/-20 degrees with the
stick (verified in game, .work/ryujinx-handle-probe.log). This candidate:

1. Cart model: makes the steering-wheel pieces (ring, hub, four spokes; 182 triangles in the near LOD)
   degenerate. The far LOD has the rim welded into the body and stays unchanged (distance only).
2. Hidden host model: writes those pieces into host shape 0 (Metal_Handle_03, previously fully
   hidden), rigid-bound to matrix 1 (Handle_J), expressed in Handle_J's new neutral frame.
3. Re-poses Handle_J: pivot at the rim centre, local X along the steering column axis (rim-plane
   normal from PCA), so a rotation about X spins the rim in its own plane. Handle_L/Handle_R (hand
   targets, children of Handle_J) are re-expressed so their neutral world transform is unchanged.
4. Steering clips: LeftRight's Handle_J curve retargeted from rotate Z to rotate X (same keys,
   90 +/- 20 degrees); UpDown's pitch curve made constant so throttle no longer tilts the wheel.
   Both clips' base rotation/translation match the new neutral frame.

Euler convention (nn::g3d EULER_XYZ, column vectors): R = Rz(z) * Ry(y) * Rx(x). Verified against the
runtime Handle_J record under UpDown pitch. Inputs are the currently installed assets.
"""
import hashlib, io, json, math, os, struct, subprocess
import numpy as np
import kart_assets_native_cart as n  # adds the project-local dependency paths
import zstandard as zstd
from kartbf.bfrespy.models.skeleton import Bone
from kartbf.bfrespy.skeletal_anim import BoneAnim, BoneAnimData
from kartbf.bfrespy.common import AnimCurve
from kartbf.bfrespy.switch.memory_pool import BufferTextureViewInfo
from inspect_native_rider import sarc
import rim_analysis as ra

ROOT = n.ROOT
OUT = ROOT / 'assets/rim-transfer'
CART = 'SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc'
HOST = 'SpObj_ControlStick_A.SpObj_ControlStick_A_01.bfres.mc'
ANIM = 'SpObj_ControlStick_A.anim.bfres.zs'
CART_SRC = ROOT / 'assets/source-native-assembly-mod'
GRIP_SRC = ROOT / 'assets/kart-grip-targets'
INSTALLED = ROOT.parent.parent / 'Library/Application Support/Ryujinx/mods/contents/0100f2c0115b6000/KartLab_110/romfs/Model'
MC_TEST = ROOT / '.tools/kart-assets/MeshCodec/build/tests/mc_test'
RIM_BOX = (np.array([-0.35, 0.25, 0.25]), np.array([0.35, 0.95, 0.75]))
ALPHA0 = math.pi / 2  # LeftRight curve neutral value (curve spans 70..110 degrees)


def sha(b):
    return hashlib.sha256(b).hexdigest()


def rx(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def ry(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def rz(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def euler(x, y, z):
    return rz(z) @ ry(y) @ rx(x)


def to_euler(r):
    y = math.asin(max(-1.0, min(1.0, -r[2, 0])))
    return math.atan2(r[2, 1], r[2, 2]), y, math.atan2(r[1, 0], r[0, 0])


def snorm10(v):
    value = np.rint(np.clip(v, -1, 1) * 511).astype(np.int32)
    return (int(value[0]) & 1023) | ((int(value[1]) & 1023) << 10) | ((int(value[2]) & 1023) << 20)


def capture_bone_offsets():
    old = Bone.load

    def load(self, loader):
        read = loader.read_vector3f
        seen = []

        def vector():
            seen.append(loader.tell())
            return read()
        loader.read_vector3f = vector
        try:
            result = old(self, loader)
        finally:
            loader.read_vector3f = read
        self.position_offset = seen[-1]
        self.rotation_offset = seen[-1] - 16
        return result
    Bone.load = load


def vertex_locations(data, vb):
    gpu = BufferTextureViewInfo.buff_offs
    vpos = vb.record_offset
    sizeptr = struct.unpack_from('<Q', data, vpos + 0x30)[0]
    cursor = gpu + struct.unpack_from('<i', data, vpos + 0x48)[0]
    out = []
    for j, buffer in enumerate(vb.buffers):
        cursor = (cursor + vb.gpu_buff_align - 1) & -vb.gpu_buff_align
        size = struct.unpack_from('<I', data, sizeptr + j * 16)[0]
        assert size == len(buffer.data[0])
        out.append((cursor, size, buffer.stride))
        cursor += size
    return out


def repack(original_compressed, data):
    info = n.parse(original_compressed)
    gpu = BufferTextureViewInfo.buff_offs
    fmsh = n.build_fmsh(bytes(data[gpu:gpu + info['index_out']]),
                        bytes(data[gpu + info['index_out']:gpu + info['index_out'] + info['vertex_out']]),
                        work_mem=info['work_mem'])
    packed, packed_info = n.pack(bytes(data), fmsh)
    assert packed_info['buffer_size'] == len(data) == info['buffer_size']
    return packed


def decode_check(dest, expected, name):
    check = OUT / 'decoded-check'
    check.mkdir(exist_ok=True)
    subprocess.run([str(MC_TEST), str(dest.parent), str(check)], check=True, capture_output=True)
    assert (check / name.removesuffix('.mc')).read_bytes() == expected, f'independent decoder disagrees: {name}'


def main():
    capture_bone_offsets()
    report = {'status': 'Offline candidate; runtime untested', 'inputs': {}}
    # Inputs must be exactly what is installed today.
    for name, src in ((CART, CART_SRC / 'romfs/Model' / CART), (HOST, GRIP_SRC / 'romfs/Model' / HOST),
                      (ANIM, GRIP_SRC / 'romfs/Model' / ANIM)):
        if (INSTALLED / name).exists() and os.environ.get('RIM_CHECK_INSTALLED'):   # dev check against an installed build
            assert src.read_bytes() == (INSTALLED / name).read_bytes(), f'input differs from installed: {name}'
        report['inputs'][name] = {'source': str(src.relative_to(ROOT)), 'sha256': sha(src.read_bytes())}

    # ---- Cart: find and remove the steering-wheel pieces (near LOD) ----
    cart_c = (CART_SRC / 'romfs/Model' / CART).read_bytes()
    cart_d = bytearray((CART_SRC / 'expected-decoded.bfres').read_bytes())
    cart_model = list(n.parse_host(bytes(cart_d)).models.values())[0]
    cshape = list(cart_model.shapes.values())[0]
    at, first, nxt, ind = ra.mesh_arrays(cshape, 0)
    assert first == 0
    tri_all = ind.reshape(-1, 3)
    live = ~((tri_all[:, 0] == tri_all[:, 1]) & (tri_all[:, 1] == tri_all[:, 2]))
    live_ids = np.nonzero(live)[0]
    tri = tri_all[live]
    p, nrm, uv, rig = at['_p0'][:, :3], at['_n0'][:, :3], at['_u0'][:, :2], at['_i0'][:, 0]
    groups = ra.components(p, tri)
    pieces = []
    for tids in groups.values():
        ids = np.unique(tri[tids])
        if np.all(p[ids].min(0) > RIM_BOX[0]) and np.all(p[ids].max(0) < RIM_BOX[1]):
            pieces.append(tids)
    sizes = sorted(len(t) for t in pieces)
    assert sizes == [6, 6, 6, 6, 32, 126], sizes
    rim_tris = np.concatenate([np.array(t) for t in pieces])
    rim_index_rows = live_ids[rim_tris]  # rows in the full index buffer
    rim_vertices = np.unique(tri[rim_tris])
    assert set(int(x) for x in rig[rim_vertices]) == {0}
    ring = max(pieces, key=len)
    ring_pts = p[np.unique(tri[ring])]
    center = (ring_pts.min(0) + ring_pts.max(0)) / 2
    w, v = np.linalg.eigh(np.cov((ring_pts - center).T))
    axis = v[:, 0] * (1 if v[2, 0] > 0 else -1)  # forward-pointing column axis
    assert w[0] < 0.05 * w[1]
    # Handle_J local X = axis: Rz(g)Ry(b)*(1,0,0) = (cos g cos b, sin g cos b, -sin b)
    beta = -math.asin(axis[2])
    gamma = math.atan2(axis[1], axis[0])
    r_new = euler(ALPHA0, beta, gamma)
    assert np.allclose(r_new[:, 0], axis, atol=1e-6)
    gpu = BufferTextureViewInfo.buff_offs
    assert gpu == struct.unpack_from('<I', cart_d, 0x1c)[0] + 0x120
    cmesh = cshape.meshes[0]
    cidx_at = gpu + struct.unpack_from('<I', cart_d, cmesh.record_offset + 0x20)[0]
    for row in rim_index_rows:
        a = struct.unpack_from('<H', cart_d, cidx_at + row * 6)[0]
        struct.pack_into('<3H', cart_d, cidx_at + row * 6, a, a, a)
    cart_out = repack(cart_c, cart_d)
    report['cart'] = {'removed_pieces_triangles': sizes, 'removed_triangles': int(len(rim_tris)),
                      'rim_vertices': int(len(rim_vertices)), 'far_lod': 'unchanged (rim welded into body)',
                      'rim_center_skl_root': center.tolist(), 'column_axis': axis.tolist(),
                      'pca_eigenvalues': w.tolist()}

    # ---- Host: rest pose + rim geometry in shape 0 ----
    host_c = (GRIP_SRC / 'romfs/Model' / HOST).read_bytes()
    host_d = bytearray((GRIP_SRC / 'decoded-check' / HOST.removesuffix('.mc')).read_bytes())
    hmodel = list(n.parse_host(bytes(host_d)).models.values())[0]
    assert list(hmodel.skeleton.mtx_to_bone_list) == [3, 4] and hmodel.skeleton.num_smooth_mtxs == 0
    bones = hmodel.skeleton.bones
    hj = bones['Handle_J']
    assert hj.parent_idx == 3 and np.allclose(hj.rotation[:3], (0, 0, math.pi / 2)) and hj.rotation[3] == 1.0
    old_pos = np.array(hj.position)
    old_rot = euler(*hj.rotation[:3])
    new_pos = center  # Skl_Root frame of host == Skl_Root frame of Cart (both 0.3766 above Root)
    struct.pack_into('<4f', host_d, hj.rotation_offset, ALPHA0, beta, gamma, 1.0)
    struct.pack_into('<3f', host_d, hj.position_offset, *new_pos)
    hands = []
    for name in ('Handle_L', 'Handle_R'):
        b = bones[name]
        assert b.parent_idx == 4 and b.rotation[3] == 1.0
        lp, lr = np.array(b.position), euler(*b.rotation[:3])
        world_p = old_pos + old_rot @ lp
        world_r = old_rot @ lr
        np_ = r_new.T @ (world_p - new_pos)
        nr = r_new.T @ world_r
        e = to_euler(nr)
        assert np.allclose(euler(*e), nr, atol=1e-6)
        struct.pack_into('<4f', host_d, b.rotation_offset, *e, 1.0)
        struct.pack_into('<3f', host_d, b.position_offset, *np_)
        hands.append(dict(bone=name, world_position=world_p.tolist(), old_local=list(b.position),
                          new_local=np_.tolist(), new_euler=list(e)))
    hshape = list(hmodel.shapes.values())[0]
    assert hshape.name == 'Metal_Handle_03__phong27'
    locs = vertex_locations(host_d, hshape.vtx_buffer)
    assert [l[2] for l in locs] == [8, 12]
    hmesh = hshape.meshes[0]
    slots = hshape.meshes[1].first_vtx - hmesh.first_vtx
    capacity = len(hmesh.index_buffer.data[0]) // 2
    assert len(rim_vertices) <= slots and len(rim_tris) * 3 <= capacity
    # Constant UV from the original (hidden) handle so the rim samples the handle's metal texture.
    hat = n.k.attributes(hshape.vtx_buffer)
    handle_uv = np.median(hat['_u0'][hmesh.first_vtx:hmesh.first_vtx + slots, :2], axis=0)
    remap = {int(old): i for i, old in enumerate(rim_vertices)}
    for i, old in enumerate(rim_vertices):
        lp = r_new.T @ (p[old] - new_pos)
        ln = r_new.T @ nrm[old]
        ln /= max(np.linalg.norm(ln), 1e-9)
        idx = hmesh.first_vtx + i
        struct.pack_into('<3eBB', host_d, locs[0][0] + idx * 8, *lp, 1, 0)
        struct.pack_into('<I2e4b', host_d, locs[1][0] + idx * 12, snorm10(ln), *handle_uv, 127, 0, 0, 127)
    hgpu = BufferTextureViewInfo.buff_offs  # parse_host set this for the host file
    assert hgpu == struct.unpack_from('<I', host_d, 0x1c)[0] + 0x120
    hidx_at = hgpu + struct.unpack_from('<I', host_d, hmesh.record_offset + 0x20)[0]
    new_indices = np.array([[remap[int(x)] for x in tri[t]] for t in rim_tris], dtype='<u2').reshape(-1)
    host_d[hidx_at:hidx_at + capacity * 2] = bytes(capacity * 2)
    host_d[hidx_at:hidx_at + len(new_indices) * 2] = new_indices.tobytes()
    boundptr = struct.unpack_from('<Q', host_d, hshape.record_offset + 0x38)[0]
    for j in range(len(hshape.submesh_boundings)):
        struct.pack_into('<6f', host_d, boundptr + j * 24, 0, 0, 0, 2, 2, 2)
    radiusptr = struct.unpack_from('<Q', host_d, hshape.record_offset + 0x40)[0]
    for j in range(len(hshape.bounding_radius_list)):
        struct.pack_into('<4f', host_d, radiusptr + j * 16, 0, 0, 0, 2)
    host_out = repack(host_c, host_d)
    report['host'] = {'shape': hshape.name, 'matrix': 1, 'bone': 'Handle_J', 'vertices': int(len(rim_vertices)),
                      'triangles': int(len(rim_tris)), 'vertex_slots': int(slots), 'triangle_capacity': capacity // 3,
                      'far_lod': 'left hidden', 'uv': handle_uv.tolist(),
                      'handle_j': {'old_position': old_pos.tolist(), 'old_euler': list(hj.rotation[:3]),
                                   'new_position': new_pos.tolist(), 'new_euler': [ALPHA0, beta, gamma]},
                      'hands': hands}

    # ---- Offline neutral-pose check: rim and hands keep their world positions ----
    check_model = list(n.parse_host(bytes(host_d)).models.values())[0]
    cb = check_model.skeleton.bones
    jp, jr = np.array(cb['Handle_J'].position), euler(*cb['Handle_J'].rotation[:3])
    hat2 = n.k.attributes(list(check_model.shapes.values())[0].vtx_buffer)
    rebuilt = jp + hat2['_p0'][hmesh.first_vtx:hmesh.first_vtx + len(rim_vertices), :3] @ jr.T
    err = float(np.abs(rebuilt - p[rim_vertices]).max())
    assert err < 2e-3, err
    hand_err = max(float(np.abs(jp + jr @ np.array(cb[h['bone']].position) - np.array(h['world_position'])).max())
                   for h in hands)
    assert hand_err < 1e-5, hand_err
    report['neutral_pose_check'] = {'rim_max_world_error': err, 'hand_max_world_error': hand_err,
                                    'note': 'half-float vertex quantisation; host and Cart Skl_Root frames coincide'}

    # ---- Steering clips ----
    anim_c = (GRIP_SRC / 'romfs/Model' / ANIM).read_bytes()
    dic = zstd.ZstdCompressionDict(sarc(zstd.ZstdDecompressor().decompress(
        (ROOT / 'extracted/totk/romfs/Pack/ZsDic.pack.zs').read_bytes()))['zs.zsdic'])
    anim_o = zstd.ZstdDecompressor(dict_data=dic).decompress(anim_c)
    anim_d = bytearray(anim_o)
    init = BoneAnimData.__init__

    def base_capture(self, loader, flags):
        self.record_offset = loader.tell()
        return init(self, loader, flags)
    BoneAnimData.__init__ = base_capture
    old_ba = BoneAnim.load

    def ba_capture(self, loader):
        self.anim_record_offset = loader.tell()
        return old_ba(self, loader)
    BoneAnim.load = ba_capture
    old_cv = AnimCurve.load

    def cv_capture(self, loader):
        self.curve_record_offset = loader.tell()
        return old_cv(self, loader)
    AnimCurve.load = cv_capture
    anims = n.k.ResFile(io.BytesIO(anim_o))
    clip_changes = []
    for anim in anims.skeletal_anims.values():
        bone = next(b for b in anim.bone_anims if b.name == 'Handle_J')
        base = bone.base_data
        assert int(bone.flags_base) == 0x38 and len(bone.curves) == 1
        curve = bone.curves[0]
        flags_at = bone.anim_record_offset + 40
        flags = struct.unpack_from('<I', anim_d, flags_at)[0]
        struct.pack_into('<4f', anim_d, base.record_offset + 12, ALPHA0, beta, gamma, base.rotate[3])
        struct.pack_into('<3f', anim_d, base.record_offset + 28, *new_pos)
        c_at = curve.curve_record_offset
        target = struct.unpack_from('<I', anim_d, c_at + 20)[0]
        if anim.name.endswith('LeftRight'):
            assert target == 40 and flags & 0xe00 == 0x800
            struct.pack_into('<I', anim_d, c_at + 20, 32)
            struct.pack_into('<I', anim_d, flags_at, (flags & ~0xe00) | 0x200)
            change = 'steering curve retargeted rotate Z -> rotate X (keys unchanged)'
        else:
            assert anim.name.endswith('UpDown') and target == 36 and flags & 0xe00 == 0x400
            struct.pack_into('<2f', anim_d, c_at + 32, 0.0, beta)  # scale 0, offset beta: constant
            change = 'throttle pitch curve made constant (rotate Y = beta)'
        clip_changes.append(dict(animation=anim.name, change=change, old_target=target, old_flags=hex(flags)))
    assert len(clip_changes) == 2
    # Re-parse to confirm the edits read back as intended.
    re_anims = n.k.ResFile(io.BytesIO(bytes(anim_d)))
    for anim in re_anims.skeletal_anims.values():
        bone = next(b for b in anim.bone_anims if b.name == 'Handle_J')
        c = bone.curves[0]
        assert np.allclose(bone.base_data.translate, new_pos, atol=1e-6)
        if anim.name.endswith('LeftRight'):
            assert c.anim_data_offset == 32
        else:
            assert c.anim_data_offset == 36 and c.scale == 0.0 and abs(c.offs - beta) < 1e-6
    anim_out = zstd.ZstdCompressor(level=19, dict_data=dic).compress(bytes(anim_d))
    assert zstd.ZstdDecompressor(dict_data=dic).decompress(anim_out) == anim_d
    report['clips'] = clip_changes

    # ---- Write and independently decode ----
    model_dir = OUT / 'romfs/Model'
    model_dir.mkdir(parents=True, exist_ok=True)
    for name, packed, expected in ((CART, cart_out, cart_d), (HOST, host_out, host_d)):
        dest = model_dir / name
        dest.write_bytes(packed)
        (OUT / ('expected-' + name.removesuffix('.mc'))).write_bytes(expected)
        decode_check(dest, bytes(expected), name)
        report.setdefault('outputs', {})[name] = {'sha256': sha(packed), 'decoded_sha256': sha(bytes(expected)),
                                                  'independent_decoder_byte_identical': True}
    (model_dir / ANIM).write_bytes(anim_out)
    report['outputs'][ANIM] = {'sha256': sha(anim_out), 'decoded_sha256': sha(bytes(anim_d))}
    report['limits'] = ['Rim uses the hidden host metal-handle material (constant UV), not the Mario atlas colour',
                        'Far LOD keeps a static rim welded into the body',
                        'Native AS clip selection/blending verified only for neutral, left, right, forward, reverse',
                        'Hands follow Handle_L/R; palm orientation unchanged from the previous fit']
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: report[k] for k in ('cart', 'neutral_pose_check', 'clips')}, indent=1))


if __name__ == '__main__':
    main()
