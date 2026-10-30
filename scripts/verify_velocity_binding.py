#!/usr/bin/env python3
"""Independent static cross-check of TOTK 1.1.0 velocity binding semantics.

Reads the local NSO analysis carrier, never executes or patches game code.
"""
from pathlib import Path
import hashlib
import json
import struct
import sys

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/kart-assets/python'))
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM


def main():
    source=ROOT/'.work/native/totk-main.elf'
    b=source.read_bytes()
    if b[:6]!=b'\x7fELF\x02\x01' or struct.unpack_from('<H',b,18)[0]!=183:
        raise ValueError('Expected little endian ELF64 AArch64 analysis carrier')
    # Derive address-to-file mapping from ELF program headers rather than
    # treating virtual module offsets as source file offsets.
    phoff=struct.unpack_from('<Q',b,32)[0]
    entsize,count=struct.unpack_from('<HH',b,54)
    segments=[]
    for i in range(count):
        typ,flags,off,addr,_,filesz,memsz,align=struct.unpack_from('<II6Q',b,phoff+i*entsize)
        if typ==1: segments.append((addr,filesz,off))
    def read(addr,length):
        for base,size,off in segments:
            if base<=addr and addr+length<=base+size:
                return b[off+addr-base:off+addr-base+length]
        raise ValueError(f'Unmapped range {addr:x}')
    md=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    ranges={
        'linear_request_candidate':(0x6bf8f8,0x6bfc78),
        'upstream_mislabeled_request_angular':(0x7a4cfc,0x7a4f14),
        'linear_getter':(0x11bb3b8,0x11bb42c),
        'linear_impulse':(0xccc234,0xccc370),
    }
    decoded={}
    all_inst={}
    for name,(start,end) in ranges.items():
        data=read(start,end-start)
        lines=[]
        for ins in md.disasm(data,start):
            line=f'{ins.mnemonic} {ins.op_str}'.strip()
            all_inst[ins.address]=line
            lines.append({'address':hex(ins.address),'bytes':ins.bytes.hex(),'assembly':line})
        decoded[name]={'start':hex(start),'end_exclusive':hex(end),
                       'sha256':hashlib.sha256(data).hexdigest(),'instructions':lines}
    checks={
        0x6bfc28:'str w8, [x19, #0x4c]',
        0x6bfc30:'stur x9, [x19, #0x44]',
        0x6bfc38:'orr w9, w9, #0x80',
        0x7a4ec4:'str w8, [x19, #0x58]',
        0x7a4ecc:'str x9, [x19, #0x50]',
        0x7a4ed4:'orr w9, w9, #0x100',
        0x11bb3d8:'tbnz w8, #7, #0x11bb3fc',
        0x11bb408:'ldur x8, [x21, #0x44]',
        0x11bb410:'ldr w9, [x21, #0x4c]',
        0xccc29c:'fdiv s1, s1, s0',
        0xccc310:'bl #0x6bf8f8',
    }
    for addr,expected in checks.items():
        if all_inst.get(addr)!=expected:
            raise ValueError(f'Instruction mismatch at {addr:x}: {all_inst.get(addr)!r}')
    out={'carrier':str(source.relative_to(ROOT)),'sha256':hashlib.sha256(b).hexdigest(),
         'method':'Static Capstone 5.0.7 decode of measured ELF PT_LOAD mappings',
         'checks':'11 exact address/instruction checks passed',
         'conclusion':'The upstream TOTK_110 linear request entry selects the angular channel; 0x6bf8f8 writes the channel consumed by the linear getter and linear impulse helper.',
         'limits':['No runtime invocation or controller behavior tested by this script.',
                   'Native function names are semantic inferences from cross-channel data flow, not recovered source symbols.',
                   'Only supplied TOTK 1.1.0 carrier covered; no claims for other game versions.'],
         'ranges':decoded}
    dest=ROOT/'research/velocity-binding-independent-check.json'
    dest.write_text(json.dumps(out,indent=2)+'\n')
    print(out['checks']);print(dest)


if __name__=='__main__':main()
