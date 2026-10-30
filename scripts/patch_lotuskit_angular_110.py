#!/usr/bin/env python3
"""Add two truthful angular-velocity methods to one pinned module derivative.

Reuses the exact existing asSFuncPtr/THISCALL registration ABI and still-live
registerPhive frame. Existing API entries are untouched. Assembly is source,
not recovered pseudocode. Every added instruction lies in an existing gap.
"""
from pathlib import Path
import hashlib,json,struct,subprocess,sys
import lz4.block
from patch_lotuskit_spawn_init import decode,branch,branch_target
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/kart-assets/python'))
from elftools.elf.elffile import ELFFile
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
OUT=ROOT/'runtime/candidates/angular-velocity-110'
SOURCE=ROOT/'runtime/candidates/linear-velocity-110/subsdk9'
EXPECTED='42f1c503f317df24591482291a4591fbd4a069946e8aeef34ee00b348911980f'
HOOK=0x3f15c


def adrp(register,source,target):
    delta=(target>>12)-(source>>12);assert -(1<<20)<=delta<(1<<20)
    value=delta&0x1fffff
    return 0x90000000|((value&3)<<29)|((value>>2)<<5)|register


def main():
    original=SOURCE.read_bytes();assert hashlib.sha256(original).hexdigest()==EXPECTED
    segments=decode(original);text=bytearray(segments[0][1]);start=len(text)
    assert start==0x21bd80 and struct.unpack_from('<I',text,HOOK)[0]==0xf94023f9
    subprocess.run(['xcrun','clang','-target','aarch64-none-elf','-c',str(OUT/'binding.s'),'-o',str(OUT/'binding.o')],check=True)
    with (OUT/'binding.o').open('rb')as f:
        elf=ELFFile(f);assert elf['e_machine']=='EM_AARCH64'
        assert not any(s.num_relocations()for s in elf.iter_sections()if s['sh_type']in('SHT_RELA','SHT_REL'))
        stub=bytearray(elf.get_section_by_name('.text').data())
        syms={s.name:s['st_value']for s in elf.get_section_by_name('.symtab').iter_symbols()}
    assert start+len(stub)<=segments[1][0]
    patches={'binding_return':branch(start+syms['binding_return'],HOOK+4),
             'binding_error':branch(start+syms['binding_error'],0x3f194),
             'binding_main_page':adrp(8,start+syms['binding_main_page'],0x2c2000)}
    for name,word in patches.items():
        off=syms[name];assert struct.unpack_from('<I',stub,off)[0]==0
        struct.pack_into('<I',stub,off,word)
    struct.pack_into('<I',text,HOOK,branch(HOOK,start));text.extend(stub)
    assert branch_target(HOOK,struct.unpack_from('<I',text,HOOK)[0])==start
    assert branch_target(start+syms['binding_return'],patches['binding_return'])==HOOK+4
    assert branch_target(start+syms['binding_error'],patches['binding_error'])==0x3f194
    assert text[:HOOK]==segments[0][1][:HOOK]and text[HOOK+4:start]==segments[0][1][HOOK+4:]
    listing=[];dis=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    for i in dis.disasm(stub[:0xd0],start):listing.append(f'{i.address:08x} {i.bytes.hex()} {i.mnemonic} {i.op_str}')
    assert any('adrp x8, #0x2c2000'in l for l in listing)
    (OUT/'binding-verified.asm').write_text('\n'.join(listing)+'\n')
    output=bytearray(original[:256]);flags=struct.unpack_from('<I',output,12)[0]
    output[64:96]=hashlib.sha256(original[64:96]+text).digest()
    for i,(address,payload)in enumerate(segments):
        if i==0:payload=bytes(text)
        packed=lz4.block.compress(payload,store_size=False,mode='high_compression',compression=12)if flags&(1<<i)else payload
        struct.pack_into('<III',output,16+i*16,len(output),address,len(payload));struct.pack_into('<I',output,96+i*4,len(packed))
        output[160+i*32:192+i*32]=hashlib.sha256(payload).digest();output.extend(packed)
    checked=decode(output);assert checked[0][1]==text and checked[1:]==segments[1:]
    assert output[0x3c:0x40]==original[0x3c:0x40]
    dest=OUT/'subsdk9';assert not dest.exists();dest.write_bytes(output)
    report=dict(status='Offline candidate pending startup/native steering tests',source_sha256=EXPECTED,
                candidate_sha256=hashlib.sha256(output).hexdigest(),hook=hex(HOOK),stub=hex(start),stub_bytes=len(stub),
                new_methods=['void setAngularVel(const Vector3f &in)','void setAngularVel(float, float, float)'],
                angular_native_main_offset='0x7a4cfc',mainbase='Existing relocated GOT2c2168 -> s_ModuleInfos +48, mirrors original wrapper',
                validation=['One original instruction changes; epilogue load replayed','All added bytes fit original text/RO alignment gap',
                            'No object relocations left unresolved','Local ADR/call relative offsets assembled by Clang',
                            'External branch targets decoded; ADRP disassembly checked','RO/data/BSS/layout unchanged','Original and derived segment hashes pass'],
                limits=['Exact pinned module and TOTK1.1.0 only','New methods require runtime validation','Does not implement a mount or steering controller'])
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))


if __name__=='__main__':main()
