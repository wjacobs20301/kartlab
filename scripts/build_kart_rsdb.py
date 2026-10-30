#!/usr/bin/env python3
"""RSDB rows for kart actors that have no vanilla actor (SpObj_ControlStick_A_04 = Standard Bike) and the kart capsules.

Each new row is a copy of its source row (NEW: A_04 from A_02; capsules from Capsule_A_01 with ActorName and
CapsuleContent changed) in every table that has the source: ActorInfo, GameActorInfo, AttachmentActorInfo,
PouchActorInfo. EDIT changes fields of existing rows. Rows stay sorted by __RowId (the tables are byte-sorted, looked up by binary search).
The Tag table (bit matrix) is left alone: an actor without a row simply has no tags (about 3000 vanilla actors).
Output: assets/kart-rsdb/romfs/RSDB/*.rstbl.byml.zs and an RSTB with their sizes raised (on top of --rstb).
Usage: build_kart_rsdb.py [--rstb PATH]
"""
import argparse, bisect, copy, json, struct
from pathlib import Path
import zstandard as zstd
from inspect_native_rider import sarc
import byml_rw
from build_kart_variant import rstb_set, MOD, TABLE

ROOT = Path(__file__).resolve().parents[1]
CAP = 'SpObj_ControlStick_Capsule_A_0{}'; DEV = 'SpObj_ControlStick_A_0{}'
# new row id -> (row it is copied from, field overrides); applied in every table that has the source row
CONTENT = {1: 1, 2: 6, 3: 5, 4: 4}   # capsule number -> kart actor number (B Dasher is the new A_05)
NEW = {DEV.format(n): (DEV.format(2), {}) for n in (4, 5, 6)}   # Standard Bike, B Dasher, Pipe Frame
for n in (2, 3, 4):   # inventory capsules (build_kart_capsules.py)
    NEW[CAP.format(n)] = (CAP.format(1), {'ActorName': CAP.format(n),
                                          'CapsuleContent': f'Work/Actor/{DEV.format(CONTENT[n])}.engine__actor__ActorParam.gyml'})
for n in (2, 3, 4):   # 5-capsule bundles (what the kart chests hold; Capsule_A_01_Bundle_B is vanilla, 5 Steering Sticks)
    NEW[CAP.format(n) + '_Bundle_B'] = (CAP.format(1) + '_Bundle_B', {
        'ActorName': CAP.format(n), 'BundleActor': f'Work/Actor/{CAP.format(n)}.engine__actor__ActorParam.gyml',
        'CapsuleContent': f'Work/Actor/{DEV.format(CONTENT[n])}.engine__actor__ActorParam.gyml'})
# existing/new rows changed in place: a kart taken apart again goes back to the pouch as its own capsule
EDIT = {DEV.format(CONTENT[n]): {'PushToPouchSpecialParts': f'Work/Actor/{CAP.format(n)}.engine__actor__ActorParam.gyml'} for n in (2, 3, 4)}
# Every kart: the same instance heap (the vanilla A_01/A_03 160 KB rows were too small for the kart; placing the
# Standard Kart or B Dasher from the inventory used the capsule but created nothing) and a kart-sized model box.
for n in (1, 4, 5, 6):
    EDIT.setdefault(DEV.format(n), {}).update({'InstanceHeapSize': 262144,
        'ModelAabbMin': {'X': -1.2, 'Y': -0.1, 'Z': -1.6}, 'ModelAabbMax': {'X': 1.2, 'Y': 1.6, 'Z': 1.7}})
TABLES = ['ActorInfo', 'GameActorInfo', 'AttachmentActorInfo', 'PouchActorInfo']
OUT = ROOT / 'assets/kart-rsdb'


def f32(v):
    """Floats as the f32 the table stores (so the read-back check compares equal)."""
    if isinstance(v, dict): return {k: f32(x) for k, x in v.items()}
    if isinstance(v, float): return struct.unpack('<f', struct.pack('<f', v))[0]
    return v


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--rstb', type=Path); args = ap.parse_args()
    pk = sarc(zstd.ZstdDecompressor().decompress((ROOT / 'extracted/totk/romfs/Pack/ZsDic.pack.zs').read_bytes()))
    dic = zstd.ZstdCompressionDict(pk['zs.zsdic'])
    src_table = args.rstb or (MOD / TABLE)
    raw = bytearray(zstd.ZstdDecompressor().decompress(src_table.read_bytes(), max_output_size=64 << 20))
    report = {}
    for t in TABLES:
        rel = f'RSDB/{t}.Product.110.rstbl.byml'
        rows, version = byml_rw.read(zstd.ZstdDecompressor(dict_data=dic).decompress((ROOT / 'extracted/totk/romfs' / (rel + '.zs')).read_bytes(), max_output_size=256 << 20))
        ids = [r['__RowId'].encode() for r in rows]; assert ids == sorted(ids), t
        added = []
        for new, (src, over) in NEW.items():
            assert new.encode() not in ids
            if src.encode() not in ids: continue
            row = copy.deepcopy(rows[ids.index(src.encode())]); row['__RowId'] = new
            for f, v in over.items():
                if f in row: row[f] = type(row[f])(v)
            i = bisect.bisect_left(ids, new.encode()); rows.insert(i, row); ids.insert(i, new.encode()); added.append(new)
        for rid, over in EDIT.items():
            if rid.encode() not in ids: continue
            row = rows[ids.index(rid.encode())]
            for f, v in over.items():
                if f in row: row[f] = type(row[f])(f32(v)); added.append(f'{rid}.{f}')
        data = byml_rw.write(rows, version)
        assert byml_rw.read(data)[0] == rows
        out = OUT / 'romfs' / (rel + '.zs'); out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(zstd.ZstdCompressor(level=19, dict_data=dic).compress(data))
        raw, entry = rstb_set(raw, rel, ((len(data) + 31) & ~31) + 0x1000, False)
        report[t] = dict(rows=len(rows), added=added, bytes=len(data), rstb=entry)
    (OUT / 'romfs' / TABLE).parent.mkdir(parents=True, exist_ok=True)
    (OUT / 'romfs' / TABLE).write_bytes(zstd.ZstdCompressor(level=19).compress(bytes(raw)))
    (OUT / 'validation.json').write_text(json.dumps(report, indent=1) + '\n'); print(json.dumps(report, indent=1))


if __name__ == '__main__':
    main()
