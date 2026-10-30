#!/usr/bin/env python3
"""Minimal MSBT (UTF-16, LBL1 + TXT2, as TOTK's ActorMsg files) reader/writer.

read(data) -> (header bytes, {label: raw UTF-16 message bytes incl. terminator}, label order by index)
write(header, messages) -> bytes. Messages keep their raw bytes (control tags untouched); new ones get the next index.
LBL1 bucket = hash % bucket count, hash = h*0x492 + byte over the label (32-bit). Sections padded to 16 with 0xAB.
"""
import struct


def _sections(d):
    o = 0x20; out = {}
    while o < len(d):
        mg = d[o:o + 4].decode(); sz = struct.unpack_from('<I', d, o + 4)[0]
        out[mg] = d[o + 16:o + 16 + sz]; o = (o + 16 + sz + 15) & ~15
    return out


def read(d):
    assert d[:8] == b'MsgStdBn' and d[0xc] == 1, 'UTF-16 MSBT only'
    s = _sections(d); assert set(s) == {'LBL1', 'TXT2'}, set(s)
    lbl = s['LBL1']; n = struct.unpack_from('<I', lbl, 0)[0]; index = {}
    for i in range(n):
        c, off = struct.unpack_from('<II', lbl, 4 + 8 * i); p = off
        for _ in range(c):
            L = lbl[p]; index[lbl[p + 1:p + 1 + L].decode()] = struct.unpack_from('<I', lbl, p + 1 + L)[0]; p += 5 + L
    txt = s['TXT2']; cnt = struct.unpack_from('<I', txt, 0)[0]
    offs = list(struct.unpack_from(f'<{cnt}I', txt, 4)) + [len(txt)]
    raw = [txt[offs[i]:offs[i + 1]] for i in range(cnt)]
    order = sorted(index, key=index.get); assert [index[k] for k in order] == list(range(cnt))
    return (d[:0x20], int(n)), {k: raw[index[k]] for k in order}


def label_hash(label, n):
    h = 0
    for c in label.encode(): h = (h * 0x492 + c) & 0xffffffff
    return h % n


def _section(magic, body):
    out = magic.encode() + struct.pack('<I', len(body)) + bytes(8) + body
    while len(out) % 16: out += b'\xab'
    return out


def write(head, messages):
    header, n = head; labels = list(messages)
    buckets = [[] for _ in range(n)]
    for i, k in enumerate(labels): buckets[label_hash(k, n)].append((k, i))
    table = bytearray(struct.pack('<I', n)); data = bytearray(); base = 4 + 8 * n
    for b in buckets:
        table += struct.pack('<II', len(b), base + len(data))
        for k, i in b: data += bytes([len(k)]) + k.encode() + struct.pack('<I', i)
    lbl = bytes(table + data)
    offs = []; body = bytearray(); start = 4 + 4 * len(labels)
    for k in labels: offs.append(start + len(body)); body += messages[k]
    txt = struct.pack('<I', len(labels)) + struct.pack(f'<{len(labels)}I', *offs) + bytes(body)
    out = bytearray(header) + _section('LBL1', lbl) + _section('TXT2', txt)
    struct.pack_into('<H', out, 0xe, 2); struct.pack_into('<I', out, 0x12, len(out))
    return bytes(out)


def text(s):
    """Plain message text -> raw UTF-16LE with terminator."""
    return s.encode('utf-16-le') + b'\0\0'
