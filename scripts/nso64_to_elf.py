#!/usr/bin/env python3
"""Create an offline AArch64 analysis carrier with original NSO virtual offsets.

Input must be an independently decompressed NSO; original segment hashes and
build identity are checked. This does not reconstruct a linked, runnable ELF.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct


def convert(source, uncompressed, destination):
    original = Path(source).read_bytes()
    data = Path(uncompressed).read_bytes()
    assert original[:4] == data[:4] == b'NSO0'
    assert original[0x40:0x60] == data[0x40:0x60]
    assert not struct.unpack_from('<I', data, 12)[0] & 7
    segments = [struct.unpack_from('<4I', data, 16 + 16*i) for i in range(3)]
    image = bytearray(max(s[1]+s[2] for s in segments))
    records = []
    for i, (offset, address, size, extra) in enumerate(segments):
        payload = data[offset:offset+size]
        assert len(payload) == size
        digest = hashlib.sha256(payload).digest()
        assert struct.unpack_from('<I', original, 12)[0] & (1 << (i+3))
        assert digest == original[0xa0+32*i:0xc0+32*i]
        image[address:address+size] = payload
        records.append(dict(name=['.text', '.rodata', '.data'][i], address=address,
                            size=size, sha256=digest.hex()))
    shift = 0x1000
    names = b'\0.text\0.rodata\0.data\0.bss\0.shstrtab\0'
    sections = [(0,)*10]
    for i, s in enumerate(segments):
        sections.append((names.index(records[i]['name'].encode()+b'\0'), 1,
                         [6,2,3][i], s[1], shift+s[1], s[2], 0,0,16,0))
    end = segments[2][1]+segments[2][2]
    sections.append((names.index(b'.bss\0'),8,3,end,shift+end,segments[2][3],0,0,16,0))
    names_offset = shift+len(image)
    sections.append((names.index(b'.shstrtab\0'),3,0,0,names_offset,len(names),0,0,1,0))
    shoff = (names_offset+len(names)+7)&~7
    result = bytearray(shoff+64*len(sections))
    ident = b'\x7fELF\x02\x01\x01'+bytes(9)
    result[:64] = ident+struct.pack('<HHIQQQIHHHHHH',3,183,1,0,64,shoff,0,64,56,3,64,len(sections),5)
    for i,s in enumerate(segments):
        struct.pack_into('<II6Q',result,64+56*i,1,[5,4,6][i],shift+s[1],s[1],s[1],s[2],s[2]+(s[3]if i==2 else 0),0x1000)
    result[shift:shift+len(image)] = image
    result[names_offset:names_offset+len(names)] = names
    for i,s in enumerate(sections):
        struct.pack_into('<IIQQQQIIQQ',result,shoff+64*i,*s)
    Path(destination).write_bytes(result)
    report = dict(source=str(Path(source).resolve()),source_sha256=hashlib.sha256(original).hexdigest(),
                  uncompressed_sha256=hashlib.sha256(data).hexdigest(),
                  carrier_sha256=hashlib.sha256(result).hexdigest(),build_id=original[0x40:0x60].hex(),
                  architecture='AArch64 little endian (selected for known TOTK target)',segments=records,
                  address_rule='ELF virtual address equals original module offset; no runtime base assumed',
                  limitations=['Offline analysis carrier, not an executable',
                               'No relocations applied, no symbols invented, no original ELF reconstructed'])
    Path(str(destination)+'.json').write_text(json.dumps(report,indent=2)+'\n')
    return report


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('source');p.add_argument('uncompressed');p.add_argument('destination')
    args=p.parse_args()
    print(json.dumps(convert(args.source,args.uncompressed,args.destination),indent=2))
