#!/usr/bin/env python3
"""Grippy tyres: the kart's four wheel contact hulls used MaterialPreset Material_Cart (the mine cart's rail material,
almost frictionless), so a parked kart slid down any slope. They get Material_Stone_ZonauLight instead (the normal
Zonai-device material; override with KART_TYRE_MATERIAL). Material_StoneNoSlip stopped the karts from driving. The controller sets the driven kart's velocity every frame, so
driving is unchanged; this only matters for a kart nobody drives.

Input: the installed kart pack source (assets/source-native-contacts-raised-chassis-seat-070-cart-dynamics-fwd045).
Output: assets/kart-grip/romfs/Pack/Actor/SpObj_ControlStick_A_01.pack.zs (+ RSTB pack entry raised on --rstb).
The variant packs (build_kart_variant.py) are built from the installed A_01 pack, so rebuild them after installing.
"""
import argparse, json, os
from pathlib import Path
import zstandard as zstd
from inspect_native_rider import sarc
from build_native_mount_submodel import pack_sarc
from build_kart_variant import rstb_set, MOD, TABLE, base_rstb
import byml_rw

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'assets/source-native-contacts-raised-chassis-seat-070-cart-dynamics-fwd045/romfs/Pack/Actor/SpObj_ControlStick_A_01.pack.zs'
OUT = ROOT / 'assets/kart-grip'
SHAPE = 'Phive/ShapeParam/SpObj_ControlStick_A_01__Physical.phive__ShapeParam.bgyml'
MATERIAL = os.environ.get('KART_TYRE_MATERIAL', 'Material_Stone_ZonauLight')


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--rstb', type=Path); args = ap.parse_args()
    pk = sarc(zstd.ZstdDecompressor().decompress((ROOT / 'extracted/totk/romfs/Pack/ZsDic.pack.zs').read_bytes()))
    dic = zstd.ZstdCompressionDict(pk['pack.zsdic'])
    members = dict(sarc(zstd.ZstdDecompressor(dict_data=dic).decompress(SRC.read_bytes(), max_output_size=64 << 20)))
    shape, ver = byml_rw.read(members[SHAPE]); changed = 0
    for h in shape['Polytope']:
        if h['MaterialPresets'] == ['Material_Cart']: h['MaterialPresets'] = [MATERIAL]; changed += 1
    assert changed == 4, changed
    members[SHAPE] = byml_rw.write(shape, ver)
    data = pack_sarc(members)
    out = OUT / 'romfs/Pack/Actor/SpObj_ControlStick_A_01.pack.zs'; out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(zstd.ZstdCompressor(level=19, dict_data=dic).compress(data))
    raw = bytearray(zstd.ZstdDecompressor().decompress(base_rstb(args.rstb).read_bytes(), max_output_size=64 << 20))
    raw, e = rstb_set(raw, 'Pack/Actor/SpObj_ControlStick_A_01.pack', ((len(data) + 31) & ~31) + 0x1000, False)
    (OUT / 'romfs' / TABLE).parent.mkdir(parents=True, exist_ok=True)
    (OUT / 'romfs' / TABLE).write_bytes(zstd.ZstdCompressor(level=19).compress(bytes(raw)))
    print(json.dumps(dict(material=MATERIAL, hulls=changed, bytes=len(data), rstb=e)))


if __name__ == '__main__':
    main()
