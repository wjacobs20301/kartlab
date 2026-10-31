#!/usr/bin/env python3
"""Derive the intermediate inputs the asset builders read, from your extracted games (scripts/extract_games.py).

All outputs are local and git-ignored:
  .work/native/mk8dx-main.uncompressed.nso + mk8dx-main.elf   MK8DX main executable (placement probe runs its code)
  .work/native/totk-main.uncompressed.nso                       TOTK main executable (fall-release IPS patch)
  assets/totk-cart-reference/{compressed,decoded}/            TOTK's own cart model, the host the karts are built in
  .work/native-mount/model/{compressed,decoded}/              TOTK's Steering Stick model (hosts the rim, hands, glider)
  assets/mk8-glider/textures/Wing_Std_Mro_Alb.png             MK8 Super Glider albedo (Mario colours)
  .work/kart-runtime/cart-pack/                               TOTK's cart actor pack, unpacked (physics templates)
Usage: prepare_inputs.py   (PYTHONPATH must include .tools/kart-assets/python; scripts/build_mod.sh sets it)
"""
import io, subprocess, sys
from pathlib import Path
import numpy as np
from PIL import Image
import zstandard as zstd

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from inspect_native_rider import sarc
MK8 = ROOT / 'extracted/mk8dx'; TOTK = ROOT / 'extracted/totk'
NATIVE = ROOT / '.work/native'
HACTOOL = ROOT / '.tools/hactool/hactool'; MC_TEST = ROOT / '.tools/kart-assets/MeshCodec/build/tests/mc_test'
CART = 'SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc'


def native():
    NATIVE.mkdir(parents=True, exist_ok=True)
    for game, src in (('mk8dx', MK8 / 'exefs/main'), ('totk', TOTK / 'exefs/main')):
        out = NATIVE / f'{game}-main.uncompressed.nso'
        if not out.exists():
            subprocess.run([str(HACTOOL), '-t', 'nso0', '--disablekeywarns', f'--uncompressed={out}', str(src)], check=True, stdout=subprocess.DEVNULL)
        print('ok', out.relative_to(ROOT))
    elf = NATIVE / 'mk8dx-main.elf'
    if not elf.exists():
        subprocess.run([sys.executable, str(ROOT / 'scripts/nso_to_elf.py'), str(MK8 / 'exefs/main'), str(NATIVE / 'mk8dx-main.uncompressed.nso'), str(elf)], check=True, stdout=subprocess.DEVNULL)
    print('ok', elf.relative_to(ROOT))


def decoded_model(name, ref):
    """Copy a vanilla TOTK model to <ref>/compressed and decode it with MeshCodec into <ref>/decoded."""
    comp = ref / 'compressed'; dec = ref / 'decoded'
    comp.mkdir(parents=True, exist_ok=True); dec.mkdir(parents=True, exist_ok=True)
    (comp / name).write_bytes((TOTK / 'romfs/Model' / name).read_bytes())
    subprocess.run([str(MC_TEST), str(comp), str(dec)], check=True, capture_output=True)   # decodes every .mc in comp
    assert (dec / name.removesuffix('.mc')).exists()
    print('ok', ref.relative_to(ROOT))


def cart_reference():
    decoded_model(CART, ROOT / 'assets/totk-cart-reference')
    decoded_model('SpObj_ControlStick_A.SpObj_ControlStick_A_01.bfres.mc', ROOT / '.work/native-mount/model')


def glider_texture():
    import kart_assets_export as k
    out = ROOT / 'assets/mk8-glider/textures/Wing_Std_Mro_Alb.png'; out.parent.mkdir(parents=True, exist_ok=True)
    res = k.ResFile(io.BytesIO(k.decompress(io.BytesIO((MK8 / 'romfs/Kart/WingTex/Wing_Std_Mro_Alb.szs').read_bytes())).getvalue()))
    for name, e in res.external_files.items():
        if not name.endswith('.bntx'): continue
        for t in k.BNTX(io.BytesIO(e.data)).nx.textures:
            if t.name == 'Wing_Std_Mro_Alb':
                px = np.frombuffer(bytes(t.pixels), np.uint8).reshape(t.height, t.width, 4)
                Image.fromarray(px.copy(), 'RGBA').save(out); print('ok', out.relative_to(ROOT)); return
    raise SystemExit('Wing_Std_Mro_Alb texture not found')


def cart_pack():
    pk = sarc(zstd.ZstdDecompressor().decompress((TOTK / 'romfs/Pack/ZsDic.pack.zs').read_bytes()))
    dic = zstd.ZstdCompressionDict(pk['pack.zsdic'])
    members = sarc(zstd.ZstdDecompressor(dict_data=dic).decompress((TOTK / 'romfs/Pack/Actor/SpObj_Cart_A_01.pack.zs').read_bytes(), max_output_size=64 << 20))
    out = ROOT / '.work/kart-runtime/cart-pack'
    for name, data in members.items():
        p = out / name; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(data)
    print('ok', out.relative_to(ROOT), len(members), 'members')


if __name__ == '__main__':
    native(); cart_reference(); glider_texture(); cart_pack()
