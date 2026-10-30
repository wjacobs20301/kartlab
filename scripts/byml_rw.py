#!/usr/bin/env python3
"""BYML (little endian, versions 2..7 as used by TOTK) reader and writer that keeps value types.

Types: str (0xa0), Bin (0xa1 binary), bool (0xd0), int -> s32 (0xd1), float -> f32 (0xd2), U32 (0xd3), I64 (0xd4), U64 (0xd5), F64 (0xd6),
None (0xff), list (0xc0), dict (0xc1). Read values come back as these Python types (U32/I64/U64/F64 are int/float
subclasses), so read -> write keeps every type. Writer layout: header, key table, string table, root container tree,
8-byte values; containers are not deduplicated (valid BYML, not byte-identical to Nintendo's tool).
"""
import struct


class U32(int): pass
class I64(int): pass
class U64(int): pass
class F64(float): pass
class Bin(bytes): pass   # 0xa1: u32 size + data


def read(data):
    assert data[:2] == b'YB', 'little endian BYML only'
    version = struct.unpack_from('<H', data, 2)[0]
    w = lambda o: struct.unpack_from('<I', data, o)[0]
    cnt = lambda o: int.from_bytes(data[o + 1:o + 4], 'little')

    def strtab(off):
        if off == 0: return []
        assert data[off] == 0xc2
        out = []
        for i in range(cnt(off)):
            a = off + w(off + 4 + 4 * i); out.append(data[a:data.index(0, a)].decode())
        return out
    keys = strtab(w(4)); strings = strtab(w(8))

    def val(t, v):
        if t == 0xa0: return strings[v]
        if t in (0xc0, 0xc1): return node(v)
        if t == 0xd0: return bool(v)
        if t == 0xd1: return v - (1 << 32) if v >= 1 << 31 else v
        if t == 0xd2: return struct.unpack('<f', struct.pack('<I', v))[0]
        if t == 0xd3: return U32(v)
        if t == 0xd4: return I64(struct.unpack_from('<q', data, v)[0])
        if t == 0xd5: return U64(struct.unpack_from('<Q', data, v)[0])
        if t == 0xd6: return F64(struct.unpack_from('<d', data, v)[0])
        if t == 0xa1: return Bin(data[v + 4:v + 4 + w(v)])
        if t == 0xff: return None
        raise ValueError(f'BYML value type {t:#x}')

    def node(off):
        t, n = data[off], cnt(off)
        if t == 0xc1:
            return {keys[int.from_bytes(data[off + 4 + 8 * i:off + 7 + 8 * i], 'little')]: val(data[off + 7 + 8 * i], w(off + 8 + 8 * i)) for i in range(n)}
        if t == 0xc0:
            start = (off + 4 + n + 3) & ~3
            return [val(data[off + 4 + i], w(start + 4 * i)) for i in range(n)]
        raise ValueError(f'BYML node type {t:#x}')
    return node(w(12)), version


def _collect(v, keys, strings):
    if isinstance(v, dict):
        for k, x in v.items(): keys.add(k); _collect(x, keys, strings)
    elif isinstance(v, list):
        for x in v: _collect(x, keys, strings)
    elif isinstance(v, str): strings.add(v)


def _strtab(items):
    items = sorted(items, key=lambda s: s.encode())
    head = 4 + 4 * (len(items) + 1); offs = []; body = bytearray()
    for s in items: offs.append(head + len(body)); body += s.encode() + b'\0'
    offs.append(head + len(body))
    out = bytearray([0xc2]) + len(items).to_bytes(3, 'little') + b''.join(struct.pack('<I', o) for o in offs) + body
    while len(out) % 4: out.append(0)
    return bytes(out), {s: i for i, s in enumerate(items)}


def write(root, version=7):
    keys, strings = set(), set(); _collect(root, keys, strings)
    keytab, kidx = _strtab(keys); strtab, sidx = _strtab(strings) if strings else (b'', {})
    out = bytearray(16) + keytab
    str_off = len(out) if strings else 0
    out += strtab
    big = []   # (patch position, packed 8 bytes)

    def typecode(v):
        if isinstance(v, bool): return 0xd0
        if isinstance(v, dict): return 0xc1
        if isinstance(v, list): return 0xc0
        if isinstance(v, Bin): return 0xa1
        if isinstance(v, str): return 0xa0
        if v is None: return 0xff
        if isinstance(v, U32): return 0xd3
        if isinstance(v, I64): return 0xd4
        if isinstance(v, U64): return 0xd5
        if isinstance(v, F64): return 0xd6
        if isinstance(v, int): return 0xd1
        if isinstance(v, float): return 0xd2
        raise TypeError(type(v))

    def emit(v):
        """Write container v at the end of out; returns its offset."""
        while len(out) % 4: out.append(0)
        at = len(out)
        if isinstance(v, dict):
            items = sorted(v.items(), key=lambda kv: kv[0].encode())
            out.extend(bytes([0xc1]) + len(items).to_bytes(3, 'little') + bytes(8 * len(items)))
            pend = []
            for i, (k, x) in enumerate(items):
                p = at + 4 + 8 * i; t = typecode(x)
                out[p:p + 3] = kidx[k].to_bytes(3, 'little'); out[p + 3] = t; pend.append((p + 4, t, x))
        else:
            n = len(v); out.extend(bytes([0xc0]) + n.to_bytes(3, 'little') + bytes(n))
            while len(out) % 4: out.append(0)
            base = len(out); out.extend(bytes(4 * n)); pend = []
            for i, x in enumerate(v):
                t = typecode(x); out[at + 4 + i] = t; pend.append((base + 4 * i, t, x))
        for p, t, x in pend:
            if t in (0xc0, 0xc1): struct.pack_into('<I', out, p, emit(x))
            elif t == 0xa0: struct.pack_into('<I', out, p, sidx[x])
            elif t == 0xd0: struct.pack_into('<I', out, p, int(x))
            elif t == 0xd1: struct.pack_into('<i', out, p, x)
            elif t == 0xd2: struct.pack_into('<f', out, p, x)
            elif t == 0xd3: struct.pack_into('<I', out, p, x)
            elif t == 0xff: struct.pack_into('<I', out, p, 0)
            elif t == 0xa1: big.append((p, struct.pack('<I', len(x)) + bytes(x)))
            else: big.append((p, struct.pack({0xd4: '<q', 0xd5: '<Q', 0xd6: '<d'}[t], x)))
        return at
    root_off = emit(root)
    for p, b in big:
        while len(out) % 8: out.append(0)   # (binary blobs share this 8-byte alignment)
        struct.pack_into('<I', out, p, len(out)); out += b
    out[0:16] = b'YB' + struct.pack('<HIII', version, 16, str_off, root_off)
    return bytes(out)


if __name__ == '__main__':
    import sys
    from pathlib import Path
    for f in sys.argv[1:]:
        d = Path(f).read_bytes(); tree, ver = read(d); again, _ = read(write(tree, ver))
        print(f, 'roundtrip', again == tree)
