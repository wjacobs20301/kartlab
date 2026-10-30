#!/usr/bin/env python3
"""MK8DX Super Glider (Wing_Std, Mario texture) on the kart, hidden until the controller opens it.

Host model (SpObj_ControlStick_A_01; every ControlStick is the kart in this mod):
  * pCylinder11 (material Mt_Rock_ControlStick_A, collapsed/hidden before): LOD0 = glider sail (Wing_Std_2mat m_Wing
    LOD0, 34 verts / 44 tris) + as much of the frame (m_Frame LOD2) as fits; LOD1 = sail LOD1 (+ frame remainder).
    Rigid-bound to matrix 0; positions in that bone's local space at MK8->TOTK scale 0.16 (same as the kart body).
  * Matrix palette entry 0: Skl_Root -> Control (bone 1). Every other shape on matrix 0 is collapsed (checked).
  * The runtime controller writes Control's bone record (host+2192): axes 0 = hidden, axes s*I + attach point = open.
Anim SpObj_ControlStick_A.anim: the clips' "Control" bone track is renamed "Contro_" (same length, string pool) so the
  clips no longer reset Control every frame.
Textures: TexToGo/Rock_ControlStick_A_Alb.txtg = Wing_Std_Mro_Alb (512^2 BC1, 10 mips); Rock_ControlStick_A_Nrm.txtg =
  flat normal (same format/size as vanilla). ControlStick texture is only used by ControlStick (= the kart).
Inputs: assets/rim-transfer (installed host + anim), assets/kart-texture-hd (installed RSTB), extracted MK8DX Wing_Std.
Output: assets/kart-glider/romfs/...
"""
import hashlib, io, json, struct, zlib
from pathlib import Path
import numpy as np
from PIL import Image
import build_rim_transfer as rt
import kart_assets_native_cart as n
from kart_assets_colors import encode_bc1, swizzle, read_txtg
from kartbf.bfrespy.switch.memory_pool import BufferTextureViewInfo
from kartbf.yaz0 import decompress
from inspect_native_rider import sarc
import zstandard as zstd

ROOT = n.ROOT
OUT = ROOT / 'assets/kart-glider-v2'
SRC = ROOT / 'assets/rim-transfer'
HOST = 'SpObj_ControlStick_A.SpObj_ControlStick_A_01.bfres.mc'
ANIM = 'SpObj_ControlStick_A.anim.bfres.zs'
TABLE = 'System/Resource/ResourceSizeTable.Product.110.rsizetable.zs'
TABLE_SRC = ROOT / 'assets/kart-texture-hd/romfs' / TABLE
MK = ROOT / 'extracted/mk8dx/romfs/Kart'
SCALE = 0.16
# Stored shrunk 1000x: a ControlStick the controller has not taken over (placed from a capsule, a world Steering Stick)
# draws Control at identity, not at its rest scale 0, which showed a full-size open glider. The controller opens the
# glider with bone scale 1000 * s (GLIDER_STORE in controller.src.as).
STORE = 0.001
SHAPE = 'pCylinder11__Mt_Rock_ControlStick_A'
BIG_SHAPE = 'Stand_010__Mt_Rock_ZonauPartsGreen_A'


def extract_wing():
    """MK8 parse must run without kart_assets_native_cart's TOTK parser overrides: separate process."""
    import subprocess, sys
    code = r"""
import io,sys,numpy as np
sys.path.insert(0,%r)
import kart_assets_export as k
from kartbf.yaz0 import decompress
o=open(%r,'rb').read();d=decompress(io.BytesIO(o)).getvalue()
ms=k.ResFile(io.BytesIO(d)).models;out={}
for tag,mname,name in (('sail','Wing_Std_2mat','Wing_Std__m_Wing'),('frame','Wing_Std_2mat','Wing_Std__m_Frame'),('whole','Wing_Std','Wing_Std__m_Wing')):
    sh=ms[mname].shapes[name];a=k.attributes(sh.vtx_buffer)
    out[tag+'_p']=a['_p0'][:,:3];out[tag+'_n']=a['_n0'][:,:3];out[tag+'_t']=a['_t0'][:,:4];out[tag+'_u']=a['_u0'][:,:2]
    for i,mesh in enumerate(sh.meshes):
        out[tag+'_i%%d'%%i]=np.frombuffer(mesh.index_buffer.data[0],dtype='<u2').astype(np.int64)+mesh.first_vtx
np.savez(%r,**out)
""" % (str(Path(__file__).parent), str(MK / 'Wing/Wing_Std.szs'), str(OUT / 'wing.npz'))
    OUT.mkdir(parents=True, exist_ok=True)
    subprocess.run([sys.executable, '-c', code], check=True)
    return np.load(OUT / 'wing.npz')


def lod_tris(w, tag, lod):
    verts = dict(p=w[tag + '_p'] * SCALE * STORE, n=w[tag + '_n'], t=w[tag + '_t'], u=w[tag + '_u'])
    return verts, w['%s_i%d' % (tag, lod)].reshape(-1, 3)


def pack_part(verts, tris, max_v, max_i):
    """Greedy: keep whole triangles (deduplicated vertices) until vertex/index budgets run out."""
    key = lambda i: (tuple(np.round(verts['p'][i] / STORE, 5)), tuple(np.round(verts['u'][i], 5)), tuple(np.round(verts['n'][i], 3)))
    remap, order, out = {}, [], []
    for tri in tris:
        new = [key(i) for i in tri if key(i) not in remap]
        if len(set(new)) + len(order) > max_v or (len(out) + 1) * 3 > max_i:
            continue
        local = []
        for i in tri:
            k_ = key(i)
            if k_ not in remap:
                remap[k_] = len(order); order.append(int(i))
            local.append(remap[k_])
        out.append(local)
    return order, np.array(out, dtype=np.int64).reshape(-1, 3)


def write_shape(host_d, shape, groups):
    """groups: per LOD list of (verts, order, tris). Writes vertices/indices into that LOD's slots."""
    locs = rt.vertex_locations(host_d, shape.vtx_buffer)
    assert [l[2] for l in locs] == [8, 12]
    gpu = BufferTextureViewInfo.buff_offs
    summary = []
    for lod, parts in enumerate(groups):
        mesh = shape.meshes[lod]
        slots = (shape.meshes[lod + 1].first_vtx if lod + 1 < len(shape.meshes) else len(next(iter(n.k.attributes(shape.vtx_buffer).values())))) - mesh.first_vtx
        capacity = len(mesh.index_buffer.data[0]) // 2
        base, indices = 0, []
        for verts, order, tris in parts:
            for j, src in enumerate(order):
                idx = mesh.first_vtx + base + j
                nn = verts['n'][src] / max(np.linalg.norm(verts['n'][src]), 1e-9)
                t = verts['t'][src]
                struct.pack_into('<3eBB', host_d, locs[0][0] + idx * 8, *verts['p'][src], 0, 0)
                struct.pack_into('<I2e4b', host_d, locs[1][0] + idx * 12, rt.snorm10(nn), *verts['u'][src],
                                 *[int(np.clip(x * 127, -127, 127)) for x in t])
            indices.extend((tris + base).reshape(-1).tolist())
            base += len(order)
        assert base <= slots and len(indices) <= capacity, (lod, base, slots, len(indices), capacity)
        at = gpu + struct.unpack_from('<I', host_d, mesh.record_offset + 0x20)[0]
        host_d[at:at + capacity * 2] = bytes(capacity * 2)
        host_d[at:at + len(indices) * 2] = np.array(indices, dtype='<u2').tobytes()
        summary.append(dict(lod=lod, vertices=base, vertex_slots=slots, indices=len(indices), index_capacity=capacity))
    boundptr = struct.unpack_from('<Q', host_d, shape.record_offset + 0x38)[0]
    for j in range(len(shape.submesh_boundings)):
        struct.pack_into('<6f', host_d, boundptr + j * 24, 0, 1.5, 0, 3.5, 3, 3.5)
    radiusptr = struct.unpack_from('<Q', host_d, shape.record_offset + 0x40)[0]
    for j in range(len(shape.bounding_radius_list)):
        struct.pack_into('<4f', host_d, radiusptr + j * 16, 0, 1.5, 0, 5)
    return summary


def txtg_from_image(ref_bytes, image, size):
    ref = read_txtg(ref_bytes)
    assert ref['format'] == 0x302
    mips = size.bit_length() - 2 if size >= 4 else 1   # stop at 4x4 like vanilla (128 -> 8 mips)
    mips = min(mips, size.bit_length())
    surfaces = []
    for i in range(mips):
        w = max(1, size >> i)
        lvl = image if i == 0 else image.resize((w, w), Image.Resampling.LANCZOS)
        surfaces.append(swizzle(encode_bc1(lvl), w, w))
    header = bytearray(ref['header'])
    struct.pack_into('<HH', header, 8, size, size)
    header[14] = mips
    c = zstd.ZstdCompressor(level=19)
    frames = [c.compress(x) for x in surfaces]
    data = bytes(header) + b''.join(struct.pack('<HBB', 0, i, 1) for i in range(mips)) \
        + b''.join(struct.pack('<II', len(x), 6) for x in frames) + b''.join(frames)
    chk = read_txtg(data)
    assert (chk['width'], chk['mips']) == (size, mips) and chk['surfaces'] == surfaces
    return data


SKEL_AT = []


def capture_skeleton():
    from kartbf.bfrespy.models.skeleton import Skeleton
    old = Skeleton.load

    def load(self, loader):
        SKEL_AT.append(loader.tell())
        return old(self, loader)
    Skeleton.load = load


def main():
    rt.capture_bone_offsets()
    capture_skeleton()
    report = {}
    # ---- Host model ----
    host_c = (SRC / 'romfs/Model' / HOST).read_bytes()
    host_d = bytearray((SRC / ('expected-' + HOST.removesuffix('.mc'))).read_bytes())
    model = list(n.parse_host(bytes(host_d)).models.values())[0]
    sk = model.skeleton
    assert list(sk.mtx_to_bone_list) == [3, 4] and sk.num_smooth_mtxs == 0
    assert list(sk.bones.keys())[1] == 'Control'
    for sn, sh in model.shapes.items():   # every other user of matrix 0 must be collapsed
        if sn == SHAPE:
            continue
        at = n.k.attributes(sh.vtx_buffer)
        if 0 in np.unique(at['_i0'][:, 0]):
            ind = np.frombuffer(sh.meshes[0].index_buffer.data[0], dtype='<u2').reshape(-1, 3)
            p = at['_p0'][:, :3]
            area = np.linalg.norm(np.cross(p[ind[:, 1]] - p[ind[:, 0]], p[ind[:, 2]] - p[ind[:, 0]]), axis=1)
            assert (area < 1e-8).all(), sn
    # Skeleton record (v>=9): sig, flags, bone dict ptr, bone array ptr, mtx_to_bone ptr at +24.
    mtx_ptr = struct.unpack_from('<Q', host_d, SKEL_AT[-1] + 24)[0]
    assert struct.unpack_from('<HH', host_d, mtx_ptr) == (3, 4), hex(mtx_ptr)
    near = [mtx_ptr]
    struct.pack_into('<H', host_d, near[0], 1)       # matrix 0 -> Control
    # Folded by default: Control's rest scale 0 (every ControlStick is a kart; only the driven one is opened at runtime).
    ctl = sk.bones['Control']
    scale_at = ctl.rotation_offset - 12
    assert np.allclose(struct.unpack_from('<3f', host_d, scale_at), (1, 1, 1)), struct.unpack_from('<3f', host_d, scale_at)
    struct.pack_into('<3f', host_d, scale_at, 0.0, 0.0, 0.0)
    wing = extract_wing()
    # v2: MK8's in-race glider (model Wing_Std, one shape: sail + frame, LOD0 336 / LOD1 188 tris) in the hidden host
    # shape Stand_010 (1152 + 505 vertex slots, same 8/12-byte vertex layout, rigid), switched to the ControlStick
    # material (shape record +0x52 = material index 1). pCylinder11 (v1's 110-slot host) is collapsed again.
    big = model.shapes[BIG_SHAPE]
    assert struct.unpack_from('<H', host_d, big.record_offset + 0x52)[0] == 3
    struct.pack_into('<H', host_d, big.record_offset + 0x52, model.shapes[SHAPE].material_idx)
    wv, w0 = lod_tris(wing, 'whole', 0); _, w1 = lod_tris(wing, 'whole', 1)
    bslots0 = big.meshes[1].first_vtx - big.meshes[0].first_vtx; bcap0 = len(big.meshes[0].index_buffer.data[0]) // 2
    btotal = len(next(iter(n.k.attributes(big.vtx_buffer).values())))
    bslots1, bcap1 = btotal - big.meshes[1].first_vtx, len(big.meshes[1].index_buffer.data[0]) // 2
    wo0, wt0 = pack_part(wv, w0, bslots0, bcap0); wo1, wt1 = pack_part(wv, w1, bslots1, bcap1)
    assert len(wt0) == len(w0) and len(wt1) == len(w1), (len(wt0), len(w0), len(wt1), len(w1))
    report['glider_shape'] = write_shape(host_d, big, [[(wv, wo0, wt0)], [(wv, wo1, wt1)]])
    report['glider_tris'] = [int(len(wt0)), int(len(wt1))]
    sv, s0 = lod_tris(wing, 'sail', 0); _, s1 = lod_tris(wing, 'sail', 1)
    fv, f2 = lod_tris(wing, 'frame', 2)
    shape = model.shapes[SHAPE]
    slots0 = shape.meshes[1].first_vtx - shape.meshes[0].first_vtx
    cap0 = len(shape.meshes[0].index_buffer.data[0]) // 2
    total = len(next(iter(n.k.attributes(shape.vtx_buffer).values())))
    slots1, cap1 = total - shape.meshes[1].first_vtx, len(shape.meshes[1].index_buffer.data[0]) // 2
    so0, st0 = pack_part(sv, s0, slots0, cap0)
    fo0, ft0 = pack_part(fv, f2, slots0 - len(so0), cap0 - st0.size)
    so1, st1 = pack_part(sv, s1, slots1, cap1)
    fo1, ft1 = pack_part(fv, f2, slots1 - len(so1), cap1 - st1.size)
    empty = (sv, [], np.zeros((0, 3), dtype=np.int64))
    report['host_shape'] = write_shape(host_d, shape, [[empty], [empty]])   # v1 slot no longer used
    report['sail_tris_lod0'] = int(len(st0)); report['frame_tris_lod0'] = int(len(ft0)); report['frame_tris_available'] = int(len(f2))
    chk = list(n.parse_host(bytes(host_d)).models.values())[0]
    assert list(chk.skeleton.mtx_to_bone_list) == [1, 4]
    assert tuple(chk.skeleton.bones['Control'].scale) == (0.0, 0.0, 0.0)
    host_out = rt.repack(host_c, host_d)
    # ---- Anim: stop the clips from driving Control ----
    dic = zstd.ZstdCompressionDict(sarc(zstd.ZstdDecompressor().decompress(
        (ROOT / 'extracted/totk/romfs/Pack/ZsDic.pack.zs').read_bytes()))['zs.zsdic'])
    anim_o = zstd.ZstdDecompressor(dict_data=dic).decompress((SRC / 'romfs/Model' / ANIM).read_bytes())
    anim_d = bytearray(anim_o)
    hits = [i for i in range(len(anim_d) - 9) if anim_d[i:i + 9] == b'\x07\x00Control'[0:9]]
    assert len(hits) == 1, hits                     # string pool entry: u16 length 7 + "Control"
    anim_d[hits[0] + 2:hits[0] + 9] = b'Contro_'
    re_anims = n.k.ResFile(io.BytesIO(bytes(anim_d)))
    for a in re_anims.skeletal_anims.values():
        names = [b.name for b in a.bone_anims]
        assert 'Control' not in names and 'Contro_' in names, names
    anim_out = zstd.ZstdCompressor(level=19, dict_data=dic).compress(bytes(anim_d))
    # ---- Textures ----
    tex = ROOT / 'extracted/totk/romfs/TexToGo'
    wing_img = Image.open(ROOT / 'assets/mk8-glider/textures/Wing_Std_Mro_Alb.png').convert('RGB')
    alb = txtg_from_image((tex / 'Rock_ControlStick_A_Alb.txtg').read_bytes(), wing_img, 512)
    nrm_ref = read_txtg((tex / 'Rock_ControlStick_A_Nrm.txtg').read_bytes())
    report['nrm_format'] = hex(nrm_ref['format'])
    out_tex = {'TexToGo/Rock_ControlStick_A_Alb.txtg': alb}
    if nrm_ref['format'] == 0x302:   # BC1-encoded normal map: flat = (0.5, 0.5, 1)
        out_tex['TexToGo/Rock_ControlStick_A_Nrm.txtg'] = txtg_from_image(
            (tex / 'Rock_ControlStick_A_Nrm.txtg').read_bytes(), Image.new('RGB', (128, 128), (128, 128, 255)), 128)
    raw = bytearray(zstd.ZstdDecompressor().decompress(TABLE_SRC.read_bytes(), max_output_size=64 << 20))
    count = struct.unpack_from('<I', raw, 14)[0]
    for path, data in out_tex.items():
        key = zlib.crc32(path.encode())
        hit = [22 + 8 * i + 4 for i in range(count) if struct.unpack_from('<I', raw, 22 + 8 * i)[0] == key]
        assert len(hit) == 1, path
        before = struct.unpack_from('<I', raw, hit[0])[0]
        struct.pack_into('<I', raw, hit[0], max(before, ((len(data) + 31) & ~31) + 256))
    # ---- Write ----
    rom = OUT / 'romfs'
    (rom / 'Model').mkdir(parents=True, exist_ok=True)
    (rom / 'Model' / HOST).write_bytes(host_out)
    (OUT / ('expected-' + HOST.removesuffix('.mc'))).write_bytes(host_d)
    (rom / 'Model' / ANIM).write_bytes(anim_out)
    for path, data in out_tex.items():
        (rom / path).parent.mkdir(parents=True, exist_ok=True); (rom / path).write_bytes(data)
    (rom / TABLE).parent.mkdir(parents=True, exist_ok=True)
    (rom / TABLE).write_bytes(zstd.ZstdCompressor(level=19).compress(bytes(raw)))
    rt.OUT = OUT
    rt.decode_check(rom / 'Model' / HOST, bytes(host_d), HOST)
    report['outputs'] = {p.relative_to(OUT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                         for p in rom.rglob('*') if p.is_file()}
    report['control_record'] = 'host model bone record 1 (Control) at host+2192: axes zero = hidden'
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
