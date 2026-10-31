#!/usr/bin/env python3
"""Inventory karts: one Zonai capsule per kart body (SpObj_ControlStick_Capsule_A_0N -> SpObj_ControlStick_A_0N).

The vanilla Steering Stick capsule (Capsule_A_01) already spawns SpObj_ControlStick_A_01, the Standard Kart. Built here:
  * Pack/Actor/SpObj_ControlStick_Capsule_A_0{2,3,4}.pack.zs: the vanilla capsule pack with every string renamed
    (Capsule_A_01 -> Capsule_A_0N, content actor A_01 -> A_0N; CapsuleParam.Content and the Replace AttachmentParam);
    BYML members are re-written with byml_rw (string tables stay sorted).
  * UI/Tex/Icon/SpObj_ControlStick_Capsule_A_0{1..4}.bntx.zs: the vanilla capsule icon with the kart drawn over it
    (MK8's own tc_KP_* part icon; B Dasher has none, so its built model is rendered by render_kart_icon.py), ASTC 4x4
    sRGB encoded (astc-encoder) into the same BNTX (block-linear, block height 8, data at +0x1000).
  * Mals/<lang>.Product.110.sarc.zs (USen, EUen): ActorMsg/PouchContent.msbt <capsule>_Name/_Caption and
    ActorMsg/Attachment.msbt <device>_Name/_Adjective for every kart (the Steering Stick is renamed Standard Kart).
  * RSTB: sizes for every file above (vanilla overhead of the same kind of file added to the new size).
RSDB rows for the new capsules come from build_kart_rsdb.py. Output: assets/kart-capsules/romfs (+ RSTB on --rstb).
"""
import argparse, io, json, struct, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter
import zstandard as zstd
from inspect_native_rider import sarc
from build_native_mount_submodel import pack_sarc
from build_kart_variant import rstb_set, MOD, TABLE, base_rstb
from kart_assets_colors import tegra_addresses
import byml_rw, msbt_rw

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/astc'))
import astc_encoder as A

ROM = ROOT / 'extracted/totk/romfs'; MK8 = ROOT / 'extracted/mk8dx/romfs'
OUT = ROOT / 'assets/kart-capsules'
CAP = 'SpObj_ControlStick_Capsule_A_0{}'; DEV = 'SpObj_ControlStick_A_0{}'
CONTENT = {1: 1, 2: 6, 3: 5, 4: 4}   # capsule number -> kart actor number (B Dasher is A_05; see build_kart_variant.py)
KARTS = {
    1: dict(name='Standard Kart', icon='tc_KP_K_Std_Mro^l', adjective='Kart',
            caption='A Zonai device that unfolds into a Mario Kart\nStandard Kart. Climb in and press A to drive.'),
    2: dict(name='Pipe Frame', icon='tc_KP_K_Skl_Mro^l', adjective='Pipe-Frame',
            caption='A Zonai device that unfolds into the Pipe Frame,\na light kart with a bare tube chassis.'),
    3: dict(name='B Dasher', icon=None, render='assets/kart-variant-bds', adjective='B-Dasher',
            caption='A Zonai device that unfolds into the B Dasher,\na sleek kart built for speed.'),
    4: dict(name='Standard Bike', icon='tc_KP_B_Std_Mro^l', adjective='Bike',
            caption='A Zonai device that unfolds into the Standard Bike.\nLean into the turns!'),
}
LANGS = ['USen', 'EUen']
ICON_DATA = 0x1000; ICON_SIZE = 256


def zs_dicts():
    pk = sarc(zstd.ZstdDecompressor().decompress((ROM / 'Pack/ZsDic.pack.zs').read_bytes()))
    return {k: zstd.ZstdCompressionDict(v) for k, v in pk.items()}


def rename_tree(v, pairs):
    if isinstance(v, dict): return {k: rename_tree(x, pairs) for k, x in v.items()}
    if isinstance(v, list): return [rename_tree(x, pairs) for x in v]
    if isinstance(v, str) and not isinstance(v, byml_rw.Bin):
        for a, b in pairs: v = v.replace(a, b)
    return v


def capsule_pack(dic, n):
    src = CAP.format(1); dst = CAP.format(n)
    pairs = [(src, dst), (DEV.format(1), DEV.format(CONTENT[n]))]
    members = sarc(zstd.ZstdDecompressor(dict_data=dic).decompress((ROM / f'Pack/Actor/{src}.pack.zs').read_bytes(), max_output_size=64 << 20))
    out = {}
    for name, data in members.items():
        new = name.replace(src, dst)
        if data[:2] == b'YB':
            tree, ver = byml_rw.read(data); tree2 = rename_tree(tree, pairs)
            out[new] = data if tree2 == tree else byml_rw.write(tree2, ver)
        else:
            assert src.encode() not in data and DEV.format(1).encode() not in data, name
            out[new] = data
    assert byml_rw.read(out[f'GameParameter/CapsuleParam/{dst}.game__pouchcontent__CapsuleParam.bgyml'])[0]['Content'] == f'Work/Actor/{DEV.format(CONTENT[n])}.engine__actor__ActorParam.gyml'
    return out


def astc_ctx():
    return A.ASTCContext(A.ASTCConfig(A.ASTCProfile.LDR_SRGB, 4, 4, 1, A.ASTCQualityPreset.THOROUGH))


def icon_decode(bntx):
    lin = np.frombuffer(bntx[ICON_DATA:ICON_DATA + ICON_SIZE * ICON_SIZE], np.uint8)[tegra_addresses(ICON_SIZE, ICON_SIZE, 16)].tobytes()
    img = astc_ctx().decompress(lin, A.ASTCImage(A.ASTCType.U8, ICON_SIZE, ICON_SIZE, 1), A.ASTCSwizzle.from_str('RGBA'))
    return Image.fromarray(np.frombuffer(img.data, np.uint8).reshape(ICON_SIZE, ICON_SIZE, 4).copy(), 'RGBA')


def icon_encode(template, img, old, new):
    data = astc_ctx().compress(A.ASTCImage(A.ASTCType.U8, ICON_SIZE, ICON_SIZE, 1, np.asarray(img.convert('RGBA')).tobytes()), A.ASTCSwizzle.from_str('RGBA'))
    assert len(data) == ICON_SIZE * ICON_SIZE
    tiled = np.zeros(len(data), np.uint8); tiled[tegra_addresses(ICON_SIZE, ICON_SIZE, 16)] = np.frombuffer(data, np.uint8)
    out = bytearray(template); out[ICON_DATA:ICON_DATA + len(data)] = tiled.tobytes()
    assert out.count(old.encode()) == 1 and len(old) == len(new)
    return bytes(out).replace(old.encode(), new.encode())


def kart_picture(info):
    if info.get('render'):
        import render_kart_icon
        return render_kart_icon.render(ROOT / info['render'])
    import kart_assets_export as k
    t = k.BNTX(io.BytesIO((MK8 / 'UI/cmn/menu' / (info['icon'] + '.bntx')).read_bytes())).nx.textures[0]
    return Image.fromarray(np.frombuffer(bytes(t.pixels), np.uint8).reshape(t.height, t.width, 4).copy(), 'RGBA')


def compose(capsule, kart):
    W = 214; kk = kart.resize((W, round(W * kart.height / kart.width)), Image.Resampling.LANCZOS)
    shadow = Image.new('RGBA', kk.size, (0, 0, 0, 0))
    shadow.putalpha(Image.fromarray((np.asarray(kk)[..., 3] * 0.5).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6)))
    im = capsule.copy(); x = (ICON_SIZE - W) // 2; y = 78
    im.alpha_composite(shadow, (x, y + 4)); im.alpha_composite(kk, (x, y)); return im


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--rstb', type=Path); args = ap.parse_args()
    dicts = zs_dicts(); rom = OUT / 'romfs'; report = {}
    raw = bytearray(zstd.ZstdDecompressor().decompress(base_rstb(args.rstb).read_bytes(), max_output_size=64 << 20))
    vanilla_rstb = bytearray(zstd.ZstdDecompressor().decompress((ROM / TABLE).read_bytes(), max_output_size=64 << 20))

    def vanilla_entry(path):
        count = struct.unpack_from('<I', vanilla_rstb, 14)[0]; key = __import__('zlib').crc32(path.encode())
        for i in range(count):
            if struct.unpack_from('<I', vanilla_rstb, 22 + 8 * i)[0] == key: return struct.unpack_from('<I', vanilla_rstb, 22 + 8 * i + 4)[0]
        return None

    def overhead(path, size):
        v = vanilla_entry(path); assert v is not None, path; return v - size

    def put(rel, data, compress=None):
        p = rom / rel; p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(compress(data) if compress else data)
    # packs
    src_pack = sarc(zstd.ZstdDecompressor(dict_data=dicts['pack.zsdic']).decompress((ROM / f'Pack/Actor/{CAP.format(1)}.pack.zs').read_bytes(), max_output_size=64 << 20))
    pack_over = overhead(f'Pack/Actor/{CAP.format(1)}.pack', len(pack_sarc(src_pack)))
    comp_pack = zstd.ZstdCompressor(level=19, dict_data=dicts['pack.zsdic'])
    for n in (2, 3, 4):
        members = capsule_pack(dicts['pack.zsdic'], n); data = pack_sarc(members)
        put(f'Pack/Actor/{CAP.format(n)}.pack.zs', data, comp_pack.compress)
        raw, e = rstb_set(raw, f'Pack/Actor/{CAP.format(n)}.pack', ((len(data) + 31) & ~31) + max(pack_over, 0x1000), True)
        report[f'pack{n}'] = dict(members=len(members), bytes=len(data), rstb=e)
    # icons
    icon_rel = f'UI/Tex/Icon/{CAP.format(1)}.bntx'
    template = zstd.ZstdDecompressor().decompress((ROM / (icon_rel + '.zs')).read_bytes(), max_output_size=16 << 20)
    capsule_img = icon_decode(template); icon_over = overhead(icon_rel, len(template))
    previews = []
    for n, info in KARTS.items():
        img = compose(capsule_img, kart_picture(info)); previews.append(img)
        data = icon_encode(template, img, CAP.format(1), CAP.format(n))
        rel = f'UI/Tex/Icon/{CAP.format(n)}.bntx'; put(rel + '.zs', data, zstd.ZstdCompressor(level=19).compress)
        raw, e = rstb_set(raw, rel, len(data) + icon_over, n != 1); report[f'icon{n}'] = e
    sheet = Image.new('RGBA', (ICON_SIZE * len(previews), ICON_SIZE), (40, 40, 40, 255))
    for i, im in enumerate(previews): sheet.alpha_composite(im, (ICON_SIZE * i, 0))
    sheet.save(OUT / 'icons-preview.png')
    # text
    for lang in LANGS:
        rel = f'Mals/{lang}.Product.110.sarc'
        files = dict(sarc(zstd.ZstdDecompressor(dict_data=dicts['zs.zsdic']).decompress((ROM / (rel + '.zs')).read_bytes(), max_output_size=64 << 20)))
        vanilla_len = len(pack_sarc(dict(files)))
        h, pouch = msbt_rw.read(files['ActorMsg/PouchContent.msbt']); ha, att = msbt_rw.read(files['ActorMsg/Attachment.msbt'])
        for n, info in KARTS.items():
            pouch[CAP.format(n) + '_Name'] = msbt_rw.text(info['name'])
            pouch[CAP.format(n) + '_Caption'] = msbt_rw.text(info['caption'])
            att[DEV.format(CONTENT[n]) + '_Name'] = msbt_rw.text(info['name'])
            att[DEV.format(CONTENT[n]) + '_Adjective'] = msbt_rw.text(info['adjective'])
        files['ActorMsg/PouchContent.msbt'] = msbt_rw.write(h, pouch); files['ActorMsg/Attachment.msbt'] = msbt_rw.write(ha, att)
        assert msbt_rw.read(files['ActorMsg/PouchContent.msbt'])[1] == pouch
        data = pack_sarc(files)
        assert sarc(data) == files
        put(rel + '.zs', data, zstd.ZstdCompressor(level=19, dict_data=dicts['zs.zsdic']).compress)
        raw, e = rstb_set(raw, rel, len(data) + overhead(rel, vanilla_len), False); report[lang] = e
    (rom / TABLE).parent.mkdir(parents=True, exist_ok=True)
    (rom / TABLE).write_bytes(zstd.ZstdCompressor(level=19).compress(bytes(raw)))
    (OUT / 'validation.json').write_text(json.dumps(report, indent=1) + '\n'); print(json.dumps(report, indent=1))


if __name__ == '__main__':
    main()
