#!/usr/bin/env python3
"""Extra MK8DX kart bodies as separate TOTK actors, all new actors cloned from the vanilla A_02 pack: A_06 = Pipe Frame,
A_05 = B Dasher, A_04 = Standard Bike. (Editing the ActorParam of a vanilla actor - A_02, A_03 - to add a component
reference crashed actor creation in the game's BYML reader, main+0x872fa0; new actors take the same edits fine.)

Per body, everything the Standard Kart chain does (kart_assets_source_native_assembly.py + build_kart_texture_hd.py +
build_source_native_contacts.py), with that body's MK8 data:
  * placement: kart_assets_native_placement_probe.py with KART_BODY_INDEX (MK8's own wheel/arm setup code run on that
    body's Parts.bin rows) -> wheel render centres/scales, normal-arm matrices, body translation;
  * cart model: TOTK SpObj_Cart_A_01 host buffers, body LOD0 (all body shapes) + Standard tyres LOD1 + ArmK_Std arms,
    rigid to the native wheel sockets, sockets moved to the body's wheel centres; saved as a NEW model
    SpObj_Cart_A.SpObj_Cart_A_K<slot> (internal model name and albedo texture name renamed in place, same length);
  * texture: generic atlas (body tiles sized from the body's UV range, wrap rows, arm shelf, tyre row) at 2048^2 as
    TexToGo/Etc_ZonauCart_<slot>_Alb.txtg (Nrm/Mtl stay the shared flat ones);
  * actor: Pack/Actor/SpObj_ControlStick_A_0<slot>.pack = the installed kart pack (every member, so all shared kart
    behaviour, seat, sounds via the A_01 SLink user, glider host model) + A_0<slot> ActorParam/ModelInfo/Physics/
    ControllerSet/Physical-shape members whose references point at the variant files; wheel contact hulls moved to the
    body's wheel centres (same method as build_source_native_contacts.py);
  * RSTB: new model / texture entries inserted (CRC-sorted), pack entry raised.
The body keeps its own steering wheel in the mesh (not transferred to the turning host rim).
Output: assets/kart-variant-<name>/romfs (+ RSTB built on top of KART_RSTB_BASE or the installed one). Nothing installed.
Usage: build_kart_variant.py skl|bds|bike [--rstb PATH]
"""
import argparse, copy, hashlib, io, json, math, os, struct, subprocess, sys, zlib
from pathlib import Path
import numpy as np
from PIL import Image
import kart_assets_colors as color
import zstandard as zstd
from inspect_native_rider import sarc, byml
from build_native_mount_submodel import pack_sarc
from build_cart_physics_trial import scalar_offsets
from kart_assets_colors import encode_bc1, swizzle, read_txtg
n = color.native; k = n.k; ROOT = k.ROOT

BODIES = {
    'skl': dict(name='Pipe Frame', file='BodyK_Skl', index=1, slot='6', model_suffix='1', texture=('Kart/BodyTex/BodyK_Skl_Mro_Alb.szs', 'BodyK_Skl_Mro_Alb'), saddle=(0.66, 0.37)),
    'bds': dict(name='B Dasher', file='BodyK_Bds', index=31, slot='5', model_suffix='3', texture=(None, 'BodyK_Bds_Alb')),
    'bike': dict(name='Standard Bike', file='BodyB_Std', index=14, slot='4', model_suffix='5', kind='bike', saddle=(1.1, 0.45),
                 texture=('Kart/BodyTex/BodyB_Std_Mro_Alb.szs', 'BodyB_Std_Mro_Alb')),
}
# Standard Bike assembly (MK8 units; MK8's bike placement code is not probed, so the parts are fitted by geometry):
# fork (ArmB_StdM ArmB_F + Sus, mirrored) hangs from the Jnt_Handle pivot along the steering axis; swingarm (ArmB_B,
# mirrored) from Jnt_ArmB; centred TireB_Std tyres at scale 1.2. Wheel bottoms are put on the Standard Kart's ground
# (front y 0.05 - 1.77, rear 0.30 - 2.30) so the kart physics hulls still carry it.
BIKE_TIRE_SCALE = 1.2
BIKE_TIRE_RADIUS = 1.88 * BIKE_TIRE_SCALE
BIKE_FORK_AXLE = 4.0       # fork top -> axle along the fork (ArmB_F + Sus, M size)
BIKE_SWING_AXLE = 3.75     # swingarm pivot -> axle (ArmB_B, M size)
BIKE_GROUND = -1.86
BIKE_SHIFT_Z = 0.0


# The body's own steering wheel (rim, hub and spoke pieces: mesh islands inside this box, MK8 units) is dropped from
# kart bodies: the turning host rim (Handle_J, where Link's hands are) is the only wheel, as on the Standard Kart.
WHEEL_BOX = (np.array([-1.75, 2.8, 3.7]), np.array([1.75, 5.4, 5.2]))


def drop_wheel(part):
    """Remove triangles of mesh islands that lie entirely inside WHEEL_BOX (part positions in MK8 units)."""
    tri = part['i'].reshape(-1, 3); nv = len(part['p']); par = np.arange(nv)
    def find(a):
        while par[a] != a: par[a] = par[par[a]]; a = par[a]
        return a
    for a_, b_, c_ in tri:
        for x, y in ((a_, b_), (b_, c_)):
            rx, ry = find(x), find(y)
            if rx != ry: par[rx] = ry
    root = np.array([find(i) for i in range(nv)]); drop = set()
    for r_ in np.unique(root[tri[:, 0]]):
        idx = np.where(root == r_)[0]
        if (part['p'][idx] >= WHEEL_BOX[0]).all() and (part['p'][idx] <= WHEEL_BOX[1]).all(): drop.add(r_)
    keep = ~np.isin(root[tri[:, 0]], list(drop))
    part['i'] = tri[keep].reshape(-1); return int((~keep).sum())


def rot_x(a):
    c, s = math.cos(a), math.sin(a); return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def bike_layout(bm):
    """Fork top, steering rotation, swingarm pivot/rotation and wheel centres in the kart frame (MK8 units)."""
    bones = list(bm.skeleton.bones.values())
    handle = next(b for b in bones if b.name == 'Jnt_Handle'); pivot = next(b for b in bones if b.name == 'Jnt_ArmB')
    steer = rot_x(handle.rotation[0]); fork_top = np.array(handle.position)
    front = fork_top + steer @ np.array([0, -BIKE_FORK_AXLE, 0])
    piv = np.array(pivot.position); swing_a = math.asin((front[1] - piv[1]) / BIKE_SWING_AXLE); swing = rot_x(swing_a)
    rear = piv + swing @ np.array([0, 0, -BIKE_SWING_AXLE])
    shift = np.array([0, BIKE_GROUND + BIKE_TIRE_RADIUS - front[1], BIKE_SHIFT_Z])
    return dict(bones=bones, steer=steer, fork_top=fork_top, pivot=piv, swing=swing, shift=shift,
                front=front + shift, rear=rear + shift)
MOD = Path.home() / 'Library/Application Support/Ryujinx/mods/contents/0100f2c0115b6000/KartLab_110/romfs'   # installed mod (dev tools only)
TABLE = 'System/Resource/ResourceSizeTable.Product.110.rsizetable.zs'


def base_rstb(arg=None):
    """Size table a builder starts from: --rstb, else $KART_RSTB_BASE, else the vanilla game's. Builders only raise or
    insert entries, so scripts/assemble_mod.py merges every builder's table (max per entry) into the final one."""
    if arg: return Path(arg)
    if os.environ.get('KART_RSTB_BASE'): return Path(os.environ['KART_RSTB_BASE'])
    return ROOT / 'extracted/totk/romfs' / TABLE
BASE_ACTOR = 'SpObj_ControlStick_A_01'
S = 8; SIZE = 256 * S


def decode_szs(rel):
    return k.decompress(io.BytesIO((ROOT / 'extracted/mk8dx/romfs' / rel).read_bytes())).getvalue()


def bntx_png(resfile, name):
    for ext_name, e in resfile.external_files.items():
        if not ext_name.endswith('.bntx'): continue
        for t in k.BNTX(io.BytesIO(e.data)).nx.textures:
            if t.name == name:
                px = np.asarray(t.pixels)
                if px.dtype != np.uint8: px = np.rint(np.clip(px, 0, 1) * 255).astype(np.uint8)
                return Image.fromarray(px).convert('RGB')
    raise KeyError(name)


class Atlas:
    """Body tiles in rows 0..189 (grid from the body UV range), wrap rows 190..193, arm shelf 194..199, tyre 200..255."""
    def __init__(self, uv):
        self.u0, self.v0 = math.floor(uv[:, 0].min() + 1e-4), math.floor(uv[:, 1].min() + 1e-4)
        self.nu = max(1, math.ceil(uv[:, 0].max() - 1e-4) - self.u0)
        self.nv = max(1, math.ceil(uv[:, 1].max() - 1e-4) - self.v0)
        self.tw, self.th = 256 / self.nu, 190 / self.nv

    def image(self, body, tire, arm, scale=1):
        s = scale; canvas = Image.new('RGB', (256 * s, 256 * s))
        tile = body.resize((round(self.tw * s), round(self.th * s)), Image.Resampling.LANCZOS)
        for j in range(self.nv):
            for i in range(self.nu): canvas.paste(tile, (round(i * self.tw * s), round(j * self.th * s)))
        canvas.paste(canvas.crop((0, 0, 256 * s, 2 * s)), (0, 190 * s))
        canvas.paste(canvas.crop((0, 188 * s, 256 * s, 190 * s)), (0, 192 * s))
        armtile = arm.resize((64 * s, 2 * s), Image.Resampling.LANCZOS)
        for y in (194, 196):
            for x in range(0, 256, 64): canvas.paste(armtile, (x * s, y * s))
        canvas.paste(canvas.crop((0, 194 * s, 256 * s, 196 * s)), (0, 198 * s))
        tiretile = tire.resize((64 * s, 54 * s), Image.Resampling.LANCZOS)
        for x in range(0, 256, 64): canvas.paste(tiretile, (x * s, 200 * s))
        canvas.paste(canvas.crop((0, 200 * s, 256 * s, 202 * s)), (0, 254 * s))
        return canvas

    def body_uv(self, uv):
        return np.stack([((uv[:, 0] - self.u0) * self.tw + .5) / 256, ((uv[:, 1] - self.v0) * self.th + .5) / 256], 1)


def rename_same_length(data, old, new, expect=None):
    assert len(old) == len(new)
    count = data.count(old)
    if expect is not None: assert count == expect, (old, count)
    return data.replace(old, new), count


def rstb_set(raw, path, size, insert_ok):
    """Set (or insert into the CRC-sorted table) the entry for path. Returns the new raw bytes."""
    count = struct.unpack_from('<I', raw, 14)[0]; key = zlib.crc32(path.encode())
    crcs = [struct.unpack_from('<I', raw, 22 + 8 * i)[0] for i in range(count)]
    import bisect
    i = bisect.bisect_left(crcs, key)
    if i < count and crcs[i] == key:
        before = struct.unpack_from('<I', raw, 22 + 8 * i + 4)[0]
        struct.pack_into('<I', raw, 22 + 8 * i + 4, max(before, size)); return raw, ('raised', before, max(before, size))
    assert insert_ok, path
    raw = raw[:22 + 8 * i] + struct.pack('<II', key, size) + raw[22 + 8 * i:]
    struct.pack_into('<I', raw, 14, count + 1); return bytearray(raw), ('inserted', None, size)


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('body', choices=sorted(BODIES)); ap.add_argument('--rstb', type=Path)
    args = ap.parse_args(); B = BODIES[args.body]; slot = B['slot']
    OUT = ROOT / f"assets/kart-variant-{args.body}"; GEO = OUT / 'geometry'; COL = OUT / 'color'
    OUT.mkdir(parents=True, exist_ok=True)
    report = dict(body=B['name'], mk8_body=B['file'], parts_row=B['index'], slot=slot)
    # ---- sources ----
    body_res = k.ResFile(io.BytesIO(decode_szs(f"Kart/Body/{B['file']}.szs"))); bm = list(body_res.models.values())[0]
    texfile, texname = B['texture']
    body_img = bntx_png(k.ResFile(io.BytesIO(decode_szs(texfile))) if texfile else body_res, texname)
    body_img.save(OUT / f'{texname}.png')
    tire_img = Image.open(ROOT / 'assets/standard-kart/textures/Tire_Std_Alb.png').convert('RGB')
    arm_img = Image.open(ROOT / 'assets/source-native-assembly-mod/ArmK_StdN_Alb.png').convert('RGB')
    arms = list(k.ResFile(io.BytesIO(decode_szs('Kart/Arm/ArmK_Std.szs'))).models.values())[1]; assert arms.name == 'ArmK_StdN'
    probe = json.loads((ROOT / f"assets/source-native-placement-b{B['index']}/native-probe.json").read_text())
    assert probe['indices']['body'] == B['index']
    mapping = [3, 1, 4, 2]   # source tyre order LB LF RB RF -> native rigid matrix ids
    wheel_by_matrix = {i + 1: w for i, w in enumerate(probe['wheels'])}
    body_translation = np.array(probe['body_translation']) * .16
    ranges = {}; arm_uv = {}

    def arm_part(shape_idx, lod):
        w = wheel_by_matrix[mapping[shape_idx]]
        transform = np.array(w['normal_arm_matrix'][:9]).reshape(3, 3).T; translation = np.array(w['normal_arm_matrix'][9:12])
        a = n.source_lod(arms, shape_idx, lod, 1., 0)
        a['p'] = (a['p'] @ transform.T + translation) * .16
        nn = a['n'] @ np.linalg.inv(transform); a['n'] = nn / np.linalg.norm(nn, axis=1)[:, None]
        return a

    nshapes = len(bm.shapes)
    bike = B.get('kind') == 'bike'
    if bike:
        bm = body_res.models['BodyB_Std']; nshapes = len(bm.shapes)
        arm_img = bntx_png(body_res, 'ArmB_Std_Alb'); tire_res = k.ResFile(io.BytesIO(decode_szs('Kart/Tire/TireB_Std.szs')))
        tire_img = bntx_png(tire_res, 'Tire_Std_Alb'); tmb = list(tire_res.models.values())[0]
        lay = bike_layout(bm); armb = body_res.models['ArmB_StdM']
        report['bike_layout'] = {k_: (v_ * .16).round(3).tolist() for k_, v_ in lay.items() if k_ in ('front', 'rear', 'shift')}

        def place(part, rot, pos, mirror=False):
            p, nn = part['p'].copy(), part['n'].copy()
            if mirror:
                p[:, 0] *= -1; nn[:, 0] *= -1; part['i'] = part['i'].reshape(-1, 3)[:, [0, 2, 1]].reshape(-1)
            part['p'] = (p @ rot.T + pos + lay['shift']) * .16; part['n'] = nn @ rot.T; return part

        def body_part(si, lod):
            b = lay['bones'][list(bm.shapes.values())[si].bone_idx]
            return place(n.source_lod(bm, si, lod, 1., 0), rot_x(b.rotation[0]), np.array(b.position))

        def bike_arms(lod, legs=(1, 2)):
            out = []
            for mirror in (False, True):
                for si in legs:   # ArmB_F, Sus: fork leg
                    out.append(place(n.source_lod(armb, si, lod, 1., 0), lay['steer'], lay['fork_top'], mirror))
                out.append(place(n.source_lod(armb, 0, lod, 1., 0), lay['swing'], lay['pivot'], mirror))   # swingarm
            return out

        def bike_geometry(_bm, _tm):
            # Host capacity (LOD0 2652 vertices / 2242 triangles, LOD1 1022 / 538): body LOD0 (rear shock LOD1), tyres
            # LOD1, arms LOD2; far LOD: body LOD2, 6-sided wheels, fork upper legs + swingarm LOD2.
            hi = [body_part(si, 1 if list(bm.shapes.values())[si].name.startswith('Jnt_SusB') else 0) for si in range(nshapes)]
            lo = [body_part(si, min(2, len(list(bm.shapes.values())[si].meshes) - 1)) for si in range(nshapes)]
            body_counts = (sum(len(p['p']) for p in hi), sum(len(p['p']) for p in lo))
            for si, matrix in ((1, 1), (0, 3)):   # TireB_F -> Wheel_00, TireB_B -> Wheel_02 (sockets at x = 0)
                tire = n.source_lod(tmb, si, 1, .16 * BIKE_TIRE_SCALE, matrix); hi.append(tire)
                low = n.low_wheel(matrix, 6); low['p'] *= .16 / .14365 * BIKE_TIRE_SCALE * 1.88 / 1.77; lo.append(low)
            for key, arr, legs in [('high', hi, (1, 2)), ('low', lo, (1,))]:
                start = sum(len(a['p']) for a in arr); new = bike_arms(2, legs)
                arm_uv[key] = np.concatenate([a['u'] for a in new])
                for a in new: a['u'] = np.zeros_like(a['u'])
                arr.extend(new); ranges[key] = (start, sum(len(a['p']) for a in arr))
            ranges['body'] = body_counts
            return n.combine(hi), n.combine(lo)

    def geometry(_bm, tm):
        hi = [n.source_lod(bm, si, 0, 1., 0) for si in range(nshapes)]
        lo = [n.source_lod(bm, si, min(2, len(list(bm.shapes.values())[si].meshes) - 1), 1., 0) for si in range(nshapes)]
        report['steering_wheel_tris_dropped'] = [drop_wheel(p) for p in hi + lo]
        for p in hi + lo: p['p'] = p['p'] * .16 + body_translation
        body_counts = (sum(len(p['p']) for p in hi), sum(len(p['p']) for p in lo))
        for i in range(4):
            matrix = mapping[i]; scale = np.array(wheel_by_matrix[matrix]['render_scale'])
            tire = n.source_lod(tm, i, 1, .16, matrix); tire['p'] *= scale
            tire['n'] /= scale; tire['n'] /= np.linalg.norm(tire['n'], axis=1)[:, None]; hi.append(tire)
            low = n.low_wheel(matrix, 5); low['p'] *= .16 / .14365 * scale; lo.append(low)
        for key, lod, arr in [('high', 1, hi), ('low', 2, lo)]:
            start = sum(len(a['p']) for a in arr); new = [arm_part(i, lod) for i in range(4)]
            arm_uv[key] = np.concatenate([a['u'] for a in new])
            for a in new: a['u'] = np.zeros_like(a['u'])
            arr.extend(new); ranges[key] = (start, sum(len(a['p']) for a in arr))
        ranges['body'] = body_counts
        return n.combine(hi), n.combine(lo)

    n.build(out_override=GEO, geometry_override=bike_geometry if bike else geometry, report_extra={'variant': B['name']})
    body_uv = np.concatenate([n.source_lod(bm, si, 0, .16, 0)['u'] for si in range(nshapes)] +
                             [n.source_lod(bm, si, min(2, len(list(bm.shapes.values())[si].meshes) - 1), .16, 0)['u'] for si in range(nshapes)])
    atlas = Atlas(body_uv); report['atlas_grid'] = dict(u0=atlas.u0, nu=atlas.nu, v0=atlas.v0, nv=atlas.nv)

    def remap_uv(data):   # generic replacement for kart_assets_colors.remap_uv (Std-only UV asserts)
        parsed = n.parse_host(bytes(data)); shape = list(list(parsed.models.values())[0].shapes.values())[0]; vb = shape.vtx_buffer
        gpu = struct.unpack_from('<I', data, 0x1c)[0] + 0x120; vp = vb.record_offset
        sizeptr = struct.unpack_from('<Q', data, vp + 0x30)[0]; cursor = gpu + struct.unpack_from('<i', data, vp + 0x48)[0]; loc = []
        for i, buf in enumerate(vb.buffers):
            cursor = (cursor + vb.gpu_buff_align - 1) & -vb.gpu_buff_align; size = struct.unpack_from('<I', data, sizeptr + i * 16)[0]
            loc.append(cursor); cursor += size
        attrs = k.attributes(vb); rigid = attrs['_i0'][:, 0]; uv = attrs['_u0']; new = uv.copy(); body = rigid == 0
        new[body] = atlas.body_uv(uv[body])
        new[~body, 0] = (uv[~body, 0] * 64 + .5) / 256; new[~body, 1] = (200.5 + uv[~body, 1] * 54) / 256
        for i, x in enumerate(new): struct.pack_into('<2e', data, loc[1] + i * vb.buffers[1].stride + 4, *x)
        # arms (rigid 0 too, so overwrite their range after the body mapping)
        for li, key in enumerate(['high', 'low']):
            first = shape.meshes[li].first_vtx; start, end = ranges[key]
            for j, x in enumerate(arm_uv[key]):
                struct.pack_into('<2e', data, loc[1] + (first + start + j) * vb.buffers[1].stride + 4,
                                 ((x[0] + 1) * 64 + .5) / 256, (194.5 + x[1] * 2) / 256)
        return {'variant_uv': 'generic body grid + arm shelf + tyre row'}

    color.remap_uv = remap_uv; color.OUT = COL
    color.build(GEO, atlas_override=lambda: atlas.image(body_img, tire_img, arm_img))
    # ---- wheel sockets to the body's wheel centres ----
    from kartbf.bfrespy.models.skeleton import Bone
    old_load = Bone.load

    def capture(self, loader):
        read = loader.read_vector3f; seen = []
        def vector():
            at = loader.tell(); v = read(); seen.append(at); return v
        loader.read_vector3f = vector
        try: r = old_load(self, loader)
        finally: loader.read_vector3f = read
        self.position_offset = seen[-1]; return r
    Bone.load = capture
    data = bytearray((COL / 'expected-decoded.bfres').read_bytes())
    model = list(n.parse_host(bytes(data)).models.values())[0]
    sockets = []
    for i in range(4):
        bone = model.skeleton.bones['Wheel_%02d' % i]; target = np.array(wheel_by_matrix[i + 1]['render_center']) * .16
        if bike: target = (lay['front'] if i < 2 else lay['rear']) * .16   # both sockets of an axle on the centre line
        struct.pack_into('<3f', data, bone.position_offset, *target); sockets.append([round(x, 3) for x in target])
    Bone.load = old_load
    report['wheel_sockets'] = sockets; report['vertex_ranges'] = {k_: list(v) for k_, v in ranges.items()}
    # ---- rename model + albedo texture (same length, in place) ----
    # BFRES name dictionaries are bit-tries: a one-entry dict tests bit 0 of the LAST character, which is 1 for
    # "...A_01". A renamed model must keep it (odd last character), or the game cannot find the model (tested: "K2" and
    # "ZZ" never loaded). Pipe Frame -> K1, B Dasher -> K3.
    model_name = f"SpObj_Cart_A_K{B['model_suffix']}"; tex_name = f'Etc_ZonauCart_{slot}_Alb'
    assert ord(model_name[-1]) & 1
    data, c1 = rename_same_length(bytes(data), b'SpObj_Cart_A_01', model_name.encode())
    if os.environ.get('VARIANT_KEEP_TEX'): tex_name = 'Etc_ZonauCart_A_Alb'   # diagnostic: shared albedo name
    data, c2 = rename_same_length(data, b'Etc_ZonauCart_A_Alb', tex_name.encode())
    report['renames'] = {'model_name': c1, 'albedo_texture': c2}
    assert c1 >= 1 and (c2 >= 1 or os.environ.get('VARIANT_KEEP_TEX'))
    data = bytearray(data)
    info = n.parse((COL / 'romfs/Model' / n.HOST).read_bytes())
    gpu = struct.unpack_from('<I', data, 0x1c)[0] + 0x120
    fmsh = n.build_fmsh(bytes(data[gpu:gpu + info['index_out']]), bytes(data[gpu + info['index_out']:gpu + info['index_out'] + info['vertex_out']]), work_mem=info['work_mem'])
    packed, pinfo = n.pack(bytes(data), fmsh)
    rom = OUT / 'romfs'; model_file = f'SpObj_Cart_A.{model_name}.bfres.mc'
    (rom / 'Model').mkdir(parents=True, exist_ok=True); (rom / 'Model' / model_file).write_bytes(packed)
    chk = OUT / 'decoded-check'; chk.mkdir(exist_ok=True)
    subprocess.run([str(ROOT / '.tools/kart-assets/MeshCodec/build/tests/mc_test'), str(rom / 'Model'), str(chk)], check=True, capture_output=True)
    assert (chk / model_file.removesuffix('.mc')).read_bytes() == bytes(data)
    # ---- HD albedo ----
    ref = read_txtg((ROOT / 'assets/kart-texture-hd/romfs/TexToGo/Etc_ZonauCart_A_Alb.txtg').read_bytes())   # header template
    big = atlas.image(body_img, tire_img, arm_img, S); big.save(OUT / 'atlas-preview.png')
    mips = SIZE.bit_length(); surfaces = []
    for i in range(mips):
        w = max(1, SIZE >> i); level = big if i == 0 else big.resize((w, w), Image.Resampling.LANCZOS)
        surfaces.append(swizzle(encode_bc1(level), w, w))
    header = bytearray(ref['header']); struct.pack_into('<HH', header, 8, SIZE, SIZE); header[14] = mips
    comp = zstd.ZstdCompressor(level=19); frames = [comp.compress(x) for x in surfaces]
    txtg = bytes(header) + b''.join(struct.pack('<HBB', 0, i, 1) for i in range(mips)) + b''.join(struct.pack('<II', len(x), 6) for x in frames) + b''.join(frames)
    assert read_txtg(txtg)['surfaces'] == surfaces
    (rom / 'TexToGo').mkdir(parents=True, exist_ok=True); (rom / 'TexToGo' / f'{tex_name}.txtg').write_bytes(txtg)
    # ---- actor pack ----
    pk = sarc(zstd.ZstdDecompressor().decompress((ROOT / 'extracted/totk/romfs/Pack/ZsDic.pack.zs').read_bytes()))
    dic = zstd.ZstdCompressionDict(pk['pack.zsdic'])
    base_pack = Path(os.environ['KART_BASE_PACK']) if os.environ.get('KART_BASE_PACK') else ROOT / f'assets/kart-grip/romfs/Pack/Actor/{BASE_ACTOR}.pack.zs'   # the kart pack the variant copies
    kart = dict(sarc(zstd.ZstdDecompressor(dict_data=dic).decompress(base_pack.read_bytes(), max_output_size=64 << 20)))
    actor = f'SpObj_ControlStick_A_0{slot}'; A01 = BASE_ACTOR.encode(); AX = actor.encode()
    # Start from the vanilla A_0<slot> pack (an actor whose ActorParam has $parent A_01 and its own AI/event members:
    # a pack built only from the kart's A_01 members under the A_0<slot> name never finished creating, state 0) and
    # overlay every kart member, so the parent chain resolves to the modded kart.
    vanilla_pack = ROOT / f'extracted/totk/romfs/Pack/Actor/{actor}.pack.zs'
    report['new_actor'] = not vanilla_pack.exists()
    # B Dasher is the new actor A_05, not the vanilla A_03: A_03 (no ModelInfoRef of its own) had to override the A_01
    # ModelInfo inside its pack, and resources are shared by path, so a Standard Kart created after a B Dasher got the
    # B Dasher model (or failed); every way of giving A_03 its own ModelInfo crashed actor creation (a component
    # allocation returned null at main+0xaf141c), while new actors cloned from A_02 (A_04, A_05) work.
    if report['new_actor']:
        # No vanilla actor of this name (A_04+): clone the vanilla A_02 pack (same shape: $parent A_01, own ModelInfoRef)
        # under the new name (same-length rename of member names and contents). Needs RSDB rows (build_kart_rsdb.py).
        src = 'SpObj_ControlStick_A_02'
        members = {}
        for n_, d_ in sarc(zstd.ZstdDecompressor(dict_data=dic).decompress((ROOT / f'extracted/totk/romfs/Pack/Actor/{src}.pack.zs').read_bytes(), max_output_size=64 << 20)).items():
            members[n_.replace(src, actor)] = d_.replace(src.encode(), AX)
    else:
        members = dict(sarc(zstd.ZstdDecompressor(dict_data=dic).decompress(vanilla_pack.read_bytes(), max_output_size=64 << 20)))
    vanilla_own = sorted(n_ for n_ in members if actor in n_)
    members.update(kart); report['vanilla_members_kept'] = vanilla_own

    def repoint(member, olds):
        # Rewritten with byml_rw: an in-place string rename leaves the string table unsorted (the game looks strings up
        # by binary search).
        import byml_rw
        d = members[member]
        for old in olds: assert d.count(old) == 1, (member, old, d.count(old))
        def ren(v):
            if isinstance(v, dict): return {k_: ren(x) for k_, x in v.items()}
            if isinstance(v, list): return [ren(x) for x in v]
            if isinstance(v, str) and not isinstance(v, byml_rw.Bin):
                for old in olds: v = v.replace(old.decode(), old.replace(A01, AX).decode())
            return v
        tree, ver = byml_rw.read(d); return byml_rw.write(ren(tree), ver)
    mi = members[f'Component/ModelInfo/{BASE_ACTOR}.engine__component__ModelInfo.bgyml']
    assert mi.count(b'SpObj_Cart_A_01') == 1
    members[f'Component/ModelInfo/{actor}.engine__component__ModelInfo.bgyml'] = mi.replace(b'SpObj_Cart_A_01', model_name.encode())
    # The vanilla A_0<slot> ActorParam is kept ($parent A_01). It must point at its own ModelInfo (the variant cart).
    own_ap = members[f'Actor/{actor}.engine__actor__ActorParam.bgyml']
    report['actorparam_has_own_modelinfo'] = f'Component/ModelInfo/{actor}.engine__component__ModelInfo.bgyml'.encode() in own_ap
    report['actorparam_has_own_physics'] = f'Component/Physics/{actor}.engine__component__PhysicsParam.bgyml'.encode() in own_ap
    if not report['actorparam_has_own_modelinfo']:
        # No ModelInfoRef of its own (vanilla A_03 only overrides physics): add one. (Overriding the inherited A_01
        # ModelInfo inside this pack instead broke the Standard Kart: resources are cached by path, so whichever pack
        # loaded first decided the model of both, and a Standard Kart created after a B Dasher failed or looked wrong.)
        import byml_rw
        akey = f'Actor/{actor}.engine__actor__ActorParam.bgyml'; ap, aver = byml_rw.read(members[akey])
        ap['Components']['ModelInfoRef'] = f'?Component/ModelInfo/{actor}.engine__component__ModelInfo.bgyml'
        members[akey] = byml_rw.write(ap, aver)
    # The kart's own physics chain under this actor's name. Repointing it to renamed ControllerSet/Shape members (to move
    # the wheel contact hulls to this body's wheels) crashed the game while creating the actor (null+0x18): Phive params
    # appear to be resolved by their file names. VARIANT_PHYSICS_RENAMED=1 keeps that experiment.
    if not os.environ.get('VARIANT_PHYSICS_RENAMED'):
        members[f'Component/Physics/{actor}.engine__component__PhysicsParam.bgyml'] = members[f'Component/Physics/{BASE_ACTOR}.engine__component__PhysicsParam.bgyml']
    else:
        members[f'Component/Physics/{actor}.engine__component__PhysicsParam.bgyml'] = repoint(
            f'Component/Physics/{BASE_ACTOR}.engine__component__PhysicsParam.bgyml', [f'Phive/ControllerSetParam/{BASE_ACTOR}.phive__ControllerSetParam.gyml'.encode()])
    members[f'Phive/ControllerSetParam/{actor}.phive__ControllerSetParam.bgyml'] = repoint(
        f'Phive/ControllerSetParam/{BASE_ACTOR}.phive__ControllerSetParam.bgyml', [f'Phive/ShapeParam/{BASE_ACTOR}__Physical.phive__ShapeParam.gyml'.encode()])
    # wheel contact hulls at this body's wheel centres (as build_source_native_contacts.py)
    skey = f'Phive/ShapeParam/{BASE_ACTOR}__Physical.phive__ShapeParam.bgyml'; old = members[skey]
    shape = copy.deepcopy(byml(old)); before = copy.deepcopy(shape)
    v = lambda d_: np.array([d_[a] for a in 'XYZ'], dtype=float); dd = lambda a: dict(zip('XYZ', map(float, a)))
    std_probe = json.loads((ROOT / 'assets/source-native-placement/native-probe.json').read_text())
    std_w = {w['name']: w for w in std_probe['wheels']}; var_w = {w['name']: w for w in probe['wheels']}
    hulls = []
    for h in shape['Polytope'][1:]:
        off = v(h['OffsetTranslation']); name = ('L' if off[0] > 0 else 'R') + ('F' if off[2] > 0 else 'B')
        delta = (np.array(var_w[name]['render_center']) - np.array(std_w[name]['render_center'])) * .16
        sc = np.array(var_w[name]['render_scale']) / np.array(std_w[name]['render_scale'])
        h['OffsetTranslation'] = dd(off + delta)
        h['Vertices'] = [dd(v(x) * sc) for x in h['Vertices']]
        a = h['AutoCalc']
        for f_ in ['Center', 'Min', 'Max']: a[f_] = dd(v(a[f_]) * sc)
        a['Volume'] *= float(np.prod(sc))
        hulls.append(dict(wheel=name, moved=delta.round(3).tolist(), scale=sc.round(3).tolist()))
    allh = shape['Polytope']; w_ = np.array([h['AutoCalc']['Volume'] for h in allh]); cs = np.array([v(h['OffsetTranslation']) + v(h['AutoCalc']['Center']) for h in allh])
    agg = shape['AutoCalc']; agg['Center'] = dd((cs * w_[:, None]).sum(0) / w_.sum())
    agg['Min'] = dd(np.min([v(h['OffsetTranslation']) + v(h['AutoCalc']['Min']) for h in allh], axis=0))
    agg['Max'] = dd(np.max([v(h['OffsetTranslation']) + v(h['AutoCalc']['Max']) for h in allh], axis=0)); agg['Volume'] = float(w_.sum())
    payload = bytearray(old)
    for path, (typ, at) in scalar_offsets(old).items():
        a_ = before; b_ = shape
        for c in path: a_ = a_[c]; b_ = b_[c]
        if a_ != b_: assert typ == 0xd2, path; struct.pack_into('<f', payload, at, b_)
    members[f'Phive/ShapeParam/{actor}__Physical.phive__ShapeParam.bgyml'] = bytes(payload)
    report['contact_hulls'] = hulls
    if B.get('saddle'):
        # Own RidableParam (seat height/position) for bodies whose seat is not the kart's: Link's saddle is
        # SaddleOffset from the host bone Root_Stand (kart: Y 0.7, Z 0.45).
        import byml_rw
        rkey = f'Component/RidableParam/{BASE_ACTOR}.game__component__RidableParam.bgyml'
        rid, ver = byml_rw.read(members[rkey]); seat = rid['Seats'][0]['SaddleOffset']
        seat['Y'], seat['Z'] = map(float, B['saddle'])
        own = f'Component/RidableParam/{actor}.game__component__RidableParam.bgyml'; members[own] = byml_rw.write(rid, ver)
        akey = f'Actor/{actor}.engine__actor__ActorParam.bgyml'; ap, aver = byml_rw.read(members[akey])
        ap['Components']['RidableRef'] = '?' + own; members[akey] = byml_rw.write(ap, aver)
        report['saddle'] = dict(Y=seat['Y'], Z=seat['Z'])
    # Every A_01-named member must equal the kart pack's own (resources are shared by path across packs).
    for name_, d_ in members.items():
        if BASE_ACTOR in name_ and name_ in kart: assert d_ == kart[name_], name_
    packed_sarc = pack_sarc(members)
    pack_bytes = zstd.ZstdCompressor(level=19, dict_data=dic).compress(packed_sarc)
    assert sarc(zstd.ZstdDecompressor(dict_data=dic).decompress(pack_bytes, max_output_size=64 << 20)) == members
    (rom / 'Pack/Actor').mkdir(parents=True, exist_ok=True); (rom / f'Pack/Actor/{actor}.pack.zs').write_bytes(pack_bytes)
    # ---- RSTB ----
    src_table = base_rstb(args.rstb)
    raw = bytearray(zstd.ZstdDecompressor().decompress(src_table.read_bytes(), max_output_size=64 << 20))
    cart_alloc = 193464   # decoded allocation of every SpObj_Cart_A model built on the native host (unchanged)
    assert len(data) <= cart_alloc + 4096
    entries = {}
    raw, entries['model'] = rstb_set(raw, f'Model/SpObj_Cart_A.{model_name}.bfres', max(cart_alloc, len(data)), True)
    raw, entries['texture'] = rstb_set(raw, f'TexToGo/{tex_name}.txtg', ((len(txtg) + 31) & ~31) + 256, True)
    raw, entries['pack'] = rstb_set(raw, f'Pack/Actor/{actor}.pack', ((len(packed_sarc) + 31) & ~31) + 0x1000, report['new_actor'])
    (rom / TABLE).parent.mkdir(parents=True, exist_ok=True); (rom / TABLE).write_bytes(zstd.ZstdCompressor(level=19).compress(bytes(raw)))
    report['rstb'] = entries; report['actor'] = actor; report['model'] = model_file; report['texture'] = f'{tex_name}.txtg'
    report['outputs'] = {p.relative_to(OUT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in rom.rglob('*') if p.is_file()}
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n'); print(json.dumps(report, indent=1))


if __name__ == '__main__':
    main()
