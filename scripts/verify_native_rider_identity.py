#!/usr/bin/env python3
"""Read-only independent check of native seat ActorLink identity semantics."""
from pathlib import Path
import hashlib,json,struct,sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/kart-assets/python'))
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM

def main():
    path=ROOT/'.work/native/totk-main.elf';data=path.read_bytes()
    digest=hashlib.sha256(data).hexdigest()
    assert digest=='fdc607b7037562de10004f3af39f379a91790a53527186421658e7ff5097c8b3'
    assert data[:6]==b'\x7fELF\x02\x01' and struct.unpack_from('<H',data,18)[0]==183
    at=struct.unpack_from('<Q',data,32)[0];width,count=struct.unpack_from('<HH',data,54)
    segments=[struct.unpack_from('<II6Q',data,at+i*width)for i in range(count)]
    def read(address,length):
        segment=next(s for s in segments if s[0]==1 and s[3]<=address and address+length<=s[3]+s[5])
        offset=segment[2]+address-segment[3];return data[offset:offset+length]
    ranges={'seat_index_lookup':(0x809da8,0x809dd0),'native_rider_query':(0x975968,0x975af0),'link_resolver':(0x68daec,0x68db3c)}
    disassembler=Cs(CS_ARCH_ARM64,CS_MODE_ARM);records={};instructions={}
    for name,(start,end)in ranges.items():
        raw=read(start,end-start);decoded=[]
        for instruction in disassembler.disasm(raw,start):
            assembly=(instruction.mnemonic+' '+instruction.op_str).strip();instructions[instruction.address]=assembly
            decoded.append(dict(address=hex(instruction.address),bytes=instruction.bytes.hex(),assembly=assembly))
        records[name]=dict(start=hex(start),end_exclusive=hex(end),sha256=hashlib.sha256(raw).hexdigest(),instructions=decoded)
    checks={0x809db8:'ldr w9, [x8, #0x20]',0x809dc4:'ldr x8, [x8, #0x28]',0x809dc8:'ldr x0, [x8, w1, uxtw #3]',
        0x9759b4:'ldr s0, [x19, #0x74]',0x9759c0:'ldr w8, [x19, #0x18]',0x9759e8:'ldr w8, [x19, #0x10]',0x9759f8:'ldr x20, [x19, #8]',0x975aac:'bl #0x68daec',
        0x68daec:'ldr w8, [x0, #0x10]',0x68daf8:'ldr x9, [x0, #8]',0x68dafc:'ldr w10, [x9, #0x48]',0x68db00:'cmp w10, w8',0x68db08:'ldr x0, [x9, #0x40]',0x68db10:'ldr w8, [x0, #0x24]',0x975a7c:'ldr w9, [x8, #0x1b0]'}
    for address,expected in checks.items():assert instructions[address]==expected,(hex(address),instructions[address],expected)
    source=ROOT/'.tools/totk-runtime/lotuskit/src/program/structs/engineActor.hpp'
    result=dict(status='Static native data-flow verified; runtime identity equality awaits log',carrier=str(path.relative_to(ROOT)),carrier_sha256=digest,source_layout=str(source.relative_to(ROOT)),source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),exact_instruction_checks=len(checks),ranges=records,
        conclusion='Seat +8 is an ActorBaseLink data pointer, not ActorBase. Seat +10 is a generation ID. Native resolver verifies that ID against linkData+48 and returns linkData+40.',
        safe_comparison=['Read known Player ActorBase ID at +10','Compare seat ID with Player ID before following any occupant link','Compare seat linkData with known Player own linkData at +1a8','Only dereference linkData after equality with known Player own linkData; verify actor+40==Player and ID+48 matches','Retain native nonzero seat flags and nonpositive finite cooldown checks; never identify Player solely from occupied flags'],
        limits=['Player own linkData+1a8 and Player ID+10 are pinned source-layout offsets; validate actual runtime snapshot before relying on them','No native function calls or memory writes','Read-only script snapshots cannot acquire the native resolver lock or reference count; execute on game script thread and refresh every logical frame','Static addresses/names are inferred semantics from verified bytes, not recovered source symbols','Only exact supplied TOTK 1.1.0 carrier covered'])
    dest=ROOT/'research/native-rider-identity-independent-check.json';dest.write_text(json.dumps(result,indent=2)+'\n');print('PASS',len(checks),'exact checks');print(dest)

if __name__=='__main__':main()
