#!/usr/bin/env python3
"""Check every installed mod file against the installed ResourceSizeTable: a file larger than its entry fails to load
(that is how a stray Pipe Frame albedo copied over Etc_ZonauCart_A_Alb.txtg broke the Standard Kart). Prints problems;
exit code 1 if any. Sizes: .zs files decompressed (pack/byml need RSTB > size), .txtg raw, .bfres.mc skipped (the
entry is the decoded allocation, checked by the model builders)."""
import struct, sys, zlib
from pathlib import Path
import zstandard as zstd
from inspect_native_rider import sarc
ROOT = Path(__file__).resolve().parents[1]
MOD = Path.home() / 'Library/Application Support/Ryujinx/mods/contents/0100f2c0115b6000/KartLab_110/romfs'
TABLE = 'System/Resource/ResourceSizeTable.Product.110.rsizetable.zs'
raw = zstd.ZstdDecompressor().decompress((MOD / TABLE).read_bytes(), max_output_size=64 << 20)
count = struct.unpack_from('<I', raw, 14)[0]
entries = {struct.unpack_from('<I', raw, 22 + 8 * i)[0]: struct.unpack_from('<I', raw, 26 + 8 * i)[0] for i in range(count)}
pk = sarc(zstd.ZstdDecompressor().decompress((ROOT / 'extracted/totk/romfs/Pack/ZsDic.pack.zs').read_bytes()))
dicts = [zstd.ZstdCompressionDict(v) for v in pk.values()]
bad = 0
for f in sorted(MOD.rglob('*')):
    if not f.is_file() or f.name.endswith('.bfres.mc') or 'Resource/ResourceSizeTable' in str(f): continue
    rel = f.relative_to(MOD).as_posix(); data = f.read_bytes(); key = rel
    if rel.endswith('.zs'):
        key = rel[:-3]; size = None
        for d in [None] + dicts:
            try: size = len((zstd.ZstdDecompressor(dict_data=d) if d else zstd.ZstdDecompressor()).decompress(data, max_output_size=512 << 20)); break
            except Exception: pass
    else: size = len(data)
    e = entries.get(zlib.crc32(key.encode()))
    status = 'no-entry' if e is None else ('OK' if size is not None and size <= e else 'TOO BIG')
    if status == 'TOO BIG': bad += 1
    if status != 'OK' or '-v' in sys.argv: print(f'{status:8} {key} size={size} rstb={e}')
print('problems:', bad); sys.exit(1 if bad else 0)
