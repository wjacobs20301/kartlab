#!/usr/bin/env python3
"""Read-only native Control Stick pack evidence. Writes only analyst JSON."""
import hashlib
import json
from pathlib import Path
import re
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/kart-assets/python'))
import zstandard


def sarc(data):
    if data[:4] != b'SARC':
        raise ValueError('Not SARC')
    endian = '<' if data[6:8] == b'\xff\xfe' else '>'
    header = struct.unpack_from(endian + 'H', data, 4)[0]
    start = struct.unpack_from(endian + 'I', data, 12)[0]
    count = struct.unpack_from(endian + 'H', data, header + 6)[0]
    names = header + 12 + count * 16 + 8
    files = {}
    for i in range(count):
        _, attr, a, b = struct.unpack_from(endian + '4I', data, header+12+i*16)
        off = names+(attr & 0xffffff)*4
        name = data[off:data.index(0, off)].decode()
        files[name] = data[start+a:start+b]
    return files


def byml(data):
    if data[:2] != b'YB':
        raise ValueError('Only little endian BYML supported')
    def word(off):
        return struct.unpack_from('<I', data, off)[0]
    def count(off):
        return int.from_bytes(data[off+1:off+4], 'little')
    def strings(off):
        if data[off] != 0xc2:
            raise ValueError('Expected string table')
        out = []
        for i in range(count(off)):
            a = off+word(off+4+i*4)
            out.append(data[a:data.index(0, a)].decode())
        return out
    keys, values = map(strings, struct.unpack_from('<II', data, 4))
    def value(typ, val):
        if typ == 0xa0: return values[val]
        if typ in (0xc0, 0xc1): return node(val)
        if typ == 0xd0: return bool(val)
        if typ == 0xd1: return val if val < 2**31 else val-2**32
        if typ == 0xd2: return struct.unpack('<f', struct.pack('<I', val))[0]
        if typ == 0xd3: return val
        if typ == 0xff: return None
        raise ValueError(f'Unsupported BYML value type {typ:x}')
    def node(off):
        typ, n = data[off], count(off)
        if typ == 0xc1:
            return {keys[int.from_bytes(data[off+4+i*8:off+7+i*8], 'little')]:
                    value(data[off+7+i*8], word(off+8+i*8)) for i in range(n)}
        if typ == 0xc0:
            start = (off+4+n+3) & ~3
            return [value(data[off+4+i], word(start+i*4)) for i in range(n)]
        raise ValueError(f'Unsupported BYML node type {typ:x}')
    return node(word(12))


def main():
    romfs = ROOT / 'extracted/totk/romfs'
    dictionaries = sarc(zstandard.ZstdDecompressor().decompress((romfs/'Pack/ZsDic.pack.zs').read_bytes()))
    source = romfs / 'Pack/Actor/SpObj_ControlStick_A_01.pack.zs'
    compressed = source.read_bytes()
    pack = sarc(zstandard.ZstdDecompressor(dict_data=zstandard.ZstdCompressionDict(dictionaries['pack.zsdic'])).decompress(compressed))
    wanted = ['Component/RidableParam/SpObj_ControlStick_A_01.game__component__RidableParam.bgyml',
              'Attention/ClientParam/SpObj_ControlStick_A_01_Ride.game__attention__ClientParam.bgyml',
              'Phive/ControllerSetParam/SpObj_ControlStick_A_01.phive__ControllerSetParam.bgyml',
              'Component/ActorPositionCalculatorParam/SpObj_ControlStick_A_01.game__component__ActorPositionCalculatorParam.bgyml',
              'Component/SLink/SpObj_ControlStick_A_01.engine__component__SLinkParam.bgyml']
    result = {'source':str(source.relative_to(ROOT)), 'source_sha256':hashlib.sha256(compressed).hexdigest(),
              'members': {name: {'sha256':hashlib.sha256(pack[name]).hexdigest(), 'decoded':byml(pack[name])} for name in wanted},
              'ai_strings': [m.group().decode() for m in re.finditer(rb'[ -~]{5,}',pack['AI/SpObj_ControlStick_A_01.root.ainb'])],
              'limits': 'Static asset evidence only; AI strings alone do not prove observed behavior. No native mount call, animation mutation or constraint/glue API exposed by the pinned AngelScript bindings.'}
    dest = ROOT / 'research/native-rider-evidence.json'
    dest.write_text(json.dumps(result, indent=2)+'\n')
    print(dest)


if __name__ == '__main__': main()
