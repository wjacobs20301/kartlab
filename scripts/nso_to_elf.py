#!/usr/bin/env python3
"""Wrap a hactool-uncompressed ARM32 NSO in a static-analysis ELF.

Preserves segment bytes and module-relative addresses. This is an analysis
carrier, not a runnable executable. Compressed input must be decompressed by
hactool first. No relocations, source symbols, or original ELF are invented.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct


def convert(source, uncompressed, destination):
    original = Path(source).read_bytes()
    b = Path(uncompressed).read_bytes()
    assert original[:4] == b[:4] == b'NSO0'
    flags = struct.unpack_from('<I', b, 12)[0]
    if flags & 7:
        raise ValueError('NSO is still compressed')
    segments = [struct.unpack_from('<4I', b, 16 + 16*i) for i in range(3)]
    # ARM32 is established by the 16-byte dynamic-symbol table and instruction
    # stream in this supplied MK8DX build; do not apply this wrapper to TOTK.
    image = bytearray(max(s[1]+s[2] for s in segments))
    info = []
    for i, (offset, address, size, extra) in enumerate(segments):
        data = b[offset:offset+size]
        if len(data) != size:
            raise ValueError('truncated segment')
        expected = original[0xa0+32*i:0xc0+32*i]
        sha = hashlib.sha256(data).hexdigest()
        if struct.unpack_from('<I', original, 12)[0] & (1 << (i+3)):
            if bytes.fromhex(sha) != expected:
                raise ValueError('segment hash mismatch')
        image[address:address+size] = data
        info.append(dict(name=['.text','.rodata','.data'][i], module_address=address,
                         size=size, sha256=sha, nso_file_offset=offset))
    ro = segments[1][1]
    ds_off, ds_size = struct.unpack_from('<II', b, 0x90)
    sy_off, sy_size = struct.unpack_from('<II', b, 0x98)
    if sy_size % 16:
        raise ValueError('not an ELF32 symbol-table size')
    # ELF32 section headers: name, type, flags, addr, offset, size, link, info,
    # alignment, entry size. Segments begin at ELF offset 0x1000.
    shift = 0x1000
    shnames = b'\x00.text\x00.rodata\x00.data\x00.bss\x00.dynstr\x00.dynsym\x00.shstrtab\x00'
    def name(s): return shnames.index(s.encode()+b'\0')
    sections = [(0,)*10]
    for i, s in enumerate(segments):
        sections.append((name(info[i]['name']), 1, [6,2,3][i], s[1], shift+s[1], s[2], 0,0,4,0))
    bss_start = segments[2][1]+segments[2][2]
    sections += [(name('.bss'),8,3,bss_start,shift+bss_start,segments[2][3],0,0,4,0),
                 (name('.dynstr'),3,2,ro+ds_off,shift+ro+ds_off,ds_size,0,0,1,0),
                 (name('.dynsym'),11,2,ro+sy_off,shift+ro+sy_off,sy_size,5,1,4,16)]
    names_offset = shift+len(image)
    sections.append((name('.shstrtab'),3,0,0,names_offset,len(shnames),0,0,1,0))
    shoff = (names_offset+len(shnames)+3)&~3
    ident = b'\x7fELF\x01\x01\x01'+bytes(9)
    header = ident+struct.pack('<HHIIIIIHHHHHH',3,40,1,0,52,shoff,0x05000000,52,32,3,40,len(sections),7)
    phdrs = b''
    for i, s in enumerate(segments):
        phdrs += struct.pack('<8I',1,shift+s[1],s[1],s[1],s[2],s[2]+(s[3] if i==2 else 0),[5,4,6][i],0x1000)
    result = bytearray(shoff+40*len(sections))
    result[:len(header)] = header
    result[52:52+len(phdrs)] = phdrs
    result[shift:shift+len(image)] = image
    result[names_offset:names_offset+len(shnames)] = shnames
    for i,s in enumerate(sections): struct.pack_into('<10I',result,shoff+40*i,*s)
    Path(destination).write_bytes(result)
    provenance = dict(source=str(Path(source).resolve()), source_sha256=hashlib.sha256(original).hexdigest(),
        uncompressed=str(Path(uncompressed).resolve()), uncompressed_sha256=hashlib.sha256(b).hexdigest(),
        derived=str(Path(destination).resolve()), derived_sha256=hashlib.sha256(result).hexdigest(),
        nso_build_id=original[0x40:0x60].hex(), architecture='ARM32 little endian',
        address_rule='ELF virtual address equals NSO module offset; runtime base unknown',
        limitations=['Analysis carrier only; not executable on host or Switch',
                      'No relocation application; dynamic symbols copied verbatim',
                      'Does not reconstruct an original linked ELF or source code'], segments=info)
    Path(str(destination)+'.json').write_text(json.dumps(provenance,indent=2)+'\n')
    return provenance


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('source'); p.add_argument('uncompressed'); p.add_argument('destination')
    a=p.parse_args()
    print(json.dumps(convert(a.source,a.uncompressed,a.destination),indent=2))
