#!/usr/bin/env python3
"""Kart chests: four Zonai treasure chests just outside Lookout Landing's east fence (Hyrule Field, map section E-4),
each holding five capsules of one kart (Standard Kart, Pipe Frame, B Dasher, Standard Bike).

Each chest is a new TBox_Field_Stone_Zonau entry (Zonai stone chest, a kind vanilla also puts in Dynamic files) in
Banc/MainField/E-4_Dynamic.bcett.byml, shaped like the vanilla Zonai chests (Dynamic.Drop__DropActor, Hash, Phive.Placement.ID = Hash, SRTHash, Rotate, Translate) with fresh hashes.
Drops are the 5-capsule bundles (vanilla SpObj_ControlStick_Capsule_A_01_Bundle_B; the others are RSDB rows from
build_kart_rsdb.py). The new hashes are not in GameDataList, so the opened state is not saved (chests may close again).
Output: assets/kart-chests/romfs (+ RSTB on --rstb). Usage: build_kart_chests.py [--rstb PATH]
"""
import argparse, json, random, struct
from pathlib import Path
import zstandard as zstd
from inspect_native_rider import sarc
import byml_rw
from build_kart_variant import rstb_set, MOD, TABLE

ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / 'extracted/totk/romfs'
REL = 'Banc/MainField/E-4_Dynamic.bcett.byml'
OUT = ROOT / 'assets/kart-chests'
# [chosen] a row on the open grass outside Lookout Landing's east fence, facing east (the field)
BASE = (-156.0, 126.4, -54.0); STEP = 3.0; YAW = 1.5707964
DROPS = ['SpObj_ControlStick_Capsule_A_01_Bundle_B', 'SpObj_ControlStick_Capsule_A_02_Bundle_B',
         'SpObj_ControlStick_Capsule_A_03_Bundle_B', 'SpObj_ControlStick_Capsule_A_04_Bundle_B']


def f32(x):
    return struct.unpack('<f', struct.pack('<f', x))[0]


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--rstb', type=Path); args = ap.parse_args()
    pk = sarc(zstd.ZstdDecompressor().decompress((ROM / 'Pack/ZsDic.pack.zs').read_bytes()))
    dic = zstd.ZstdCompressionDict(pk['bcett.byml.zsdic'])
    tree, ver = byml_rw.read(zstd.ZstdDecompressor(dict_data=dic).decompress((ROM / (REL + '.zs')).read_bytes(), max_output_size=256 << 20))
    actors = tree['Actors']; used = {int(a['Hash']) for a in actors}; srt = {int(a.get('SRTHash', 0)) for a in actors}
    template = next(a for a in actors if a.get('Gyaml', '').startswith('TBox_Field_Stone'))
    rng = random.Random(0x4b415254)   # fixed seed: same hashes every build
    added = []
    for i, drop in enumerate(DROPS):
        h = rng.getrandbits(64)
        while h in used: h = rng.getrandbits(64)
        s = rng.getrandbits(32)
        while s in srt: s = rng.getrandbits(32)
        used.add(h); srt.add(s)
        a = {'Dynamic': {'Drop__DropActor': drop}, 'Gyaml': 'TBox_Field_Stone_Zonau', 'Hash': byml_rw.U64(h),
             'Phive': {'Placement': {'ID': byml_rw.U64(h)}}, 'Rotate': [0.0, f32(YAW), 0.0], 'SRTHash': byml_rw.U32(s),
             'Translate': [f32(BASE[0]), f32(BASE[1]), f32(BASE[2] - STEP * i)]}
        assert type(template['Hash']) is byml_rw.U64 and type(template['SRTHash']) is byml_rw.U32
        actors.append(a); added.append(dict(drop=drop, hash=h, pos=a['Translate']))
    data = byml_rw.write(tree, ver)
    assert byml_rw.read(data)[0] == tree
    out = OUT / 'romfs' / (REL + '.zs'); out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(zstd.ZstdCompressor(level=19, dict_data=dic).compress(data))
    raw = bytearray(zstd.ZstdDecompressor().decompress((args.rstb or MOD / TABLE).read_bytes(), max_output_size=64 << 20))
    raw, e = rstb_set(raw, REL, ((len(data) + 31) & ~31) + 0x1000, True)
    (OUT / 'romfs' / TABLE).parent.mkdir(parents=True, exist_ok=True)
    (OUT / 'romfs' / TABLE).write_bytes(zstd.ZstdCompressor(level=19).compress(bytes(raw)))
    report = dict(file=REL, actors=len(actors), bytes=len(data), rstb=e, chests=added)
    (OUT / 'validation.json').write_text(json.dumps(report, indent=1) + '\n'); print(json.dumps(report, indent=1))


if __name__ == '__main__':
    main()
