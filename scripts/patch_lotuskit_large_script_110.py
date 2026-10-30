#!/usr/bin/env python3
"""Raise the startup/local script size limit of one pinned module derivative.

pushExecLocalFileModule reads each script into a stack char[0x2000] (8,191 bytes
max). This derivative reads into a 64 KiB AngelScript-engine-heap buffer instead
(see runtime/candidates/large-script-110/scriptbuf.s), so scripts up to 65,535
bytes load. The thread stack frame is unchanged and the 64 KiB exlaunch malloc
heap is no longer used for the script text at all. Allocation failure falls back
to the original stack buffer/limit. Five original instructions change; all
added bytes lie in the existing text/RO alignment gap. Assembly is source.
"""
from pathlib import Path
import hashlib,json,re,struct,subprocess,sys
import lz4.block
from patch_lotuskit_spawn_init import decode,branch,branch_target
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/kart-assets/python'))
from elftools.elf.elffile import ELFFile
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
OUT=ROOT/'runtime/candidates/large-script-110'
SOURCE=ROOT/'runtime/candidates/angular-velocity-110/subsdk9'
EXPECTED='b0dc2c3bf8b19d95e43c8ad58d3e461d485a2e1ad0b9d2060f843a8a6d80ad06'
BUFSIZE=0x10000
# Module-relative targets (debug ELF .work/native/lotuskit-110-subsdk9.elf).
READ_TEXT_FILE=0x72da0;AS_ALLOC=0x30540;AS_FREE=0x30560;STRLEN=0x1fd300;BUILD=0x4ab10
READ_CALL=0x4b9e8;ERR_PRINT0=0x4ba1c;ERR_PRINT1=0x4ba28;ERR_NEW=0x4ba30;SUCCESS=0x4bab8;JOIN=0x4bb28
ADD_X0_SP_70=0x9101c3e0;MOV_X0_X23=0xaa1703e0;MOV_X0_34=0xd2800680;ADD_X1_X24_10=0x91004301


def call(source,target):
    return branch(source,target)|0x80000000  # BL shares B's imm26 encoding


def call_target(source,instruction):
    assert instruction>>26==0x25
    return branch_target(source,instruction&~0x80000000)


def main():
    original=SOURCE.read_bytes();assert hashlib.sha256(original).hexdigest()==EXPECTED
    segments=decode(original);old=segments[0][1];text=bytearray(old)
    word=lambda off:struct.unpack_from('<I',text,off)[0]
    # The exact original instructions this derivative replaces.
    assert call_target(READ_CALL,word(READ_CALL))==READ_TEXT_FILE
    dis=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    asm=lambda off:(lambda i:f'{i.mnemonic} {i.op_str}')(next(dis.disasm(bytes(old[off:off+4]),off)))
    expect={READ_CALL-0xc:'mov x1, #0x2000',ERR_PRINT0:'add x0, sp, #0x70',ERR_PRINT1:'add x0, sp, #0x70',
            ERR_NEW:'mov x0, #0x34',SUCCESS:'add x1, x24, #0x10',0x4ba18:'tbz w2, #0, #0x4bab8',
            JOIN:'cbz x4, #0x4bba4',0x4b83c:'stp x23, x24, [sp, #0x30]',0x4b974:'ldp x23, x24, [sp, #0x30]',
            0x4bb2c:'ldp x23, x24, [sp, #0x30]',0x4b7c8:'mov x12, #0x2070'}
    for off,text_ in expect.items():assert asm(off)==text_,(hex(off),asm(off))
    assert word(ERR_PRINT0)==ADD_X0_SP_70 and word(ERR_NEW)==MOV_X0_34 and word(SUCCESS)==ADD_X1_X24_10
    # x23 is otherwise unused by pushExecLocalFileModule (0x4b7c0-0x4bc00).
    uses=[i.address for i in dis.disasm(bytes(old[0x4b7c0:0x4bc00]),0x4b7c0)if re.search(r'\b[xw]23\b',i.op_str)]
    assert uses==[0x4b83c,0x4b974,0x4bb2c],uses
    start=(len(text)+3)&~3;text.extend(b'\0'*(start-len(text)))
    assert start==0x21beac
    subprocess.run(['xcrun','clang','-target','aarch64-none-elf','-c',str(OUT/'scriptbuf.s'),'-o',str(OUT/'scriptbuf.o')],check=True)
    with (OUT/'scriptbuf.o').open('rb')as f:
        elf=ELFFile(f);assert elf['e_machine']=='EM_AARCH64'
        assert not any(s.num_relocations()for s in elf.iter_sections()if s['sh_type']in('SHT_RELA','SHT_REL'))
        stub=bytearray(elf.get_section_by_name('.text').data())
        syms={s.name:s['st_value']for s in elf.get_section_by_name('.symtab').iter_symbols()}
    assert start+len(stub)<=segments[1][0]
    at=lambda name:start+syms[name]
    fills={'call_alloc':call(at('call_alloc'),AS_ALLOC),'call_read':call(at('call_read'),READ_TEXT_FILE),
           'call_free_error':call(at('call_free_error'),AS_FREE),'call_strlen':call(at('call_strlen'),STRLEN),
           'call_build':call(at('call_build'),BUILD),'call_free_ok':call(at('call_free_ok'),AS_FREE),
           'success_return':branch(at('success_return'),JOIN)}
    for name,value in fills.items():
        off=syms[name];assert struct.unpack_from('<I',stub,off)[0]==0
        struct.pack_into('<I',stub,off,value)
    sites={READ_CALL:call(READ_CALL,at('read_stub')),ERR_PRINT0:MOV_X0_X23,ERR_PRINT1:MOV_X0_X23,
           ERR_NEW:call(ERR_NEW,at('error_stub')),SUCCESS:branch(SUCCESS,at('success_stub'))}
    for off,value in sites.items():struct.pack_into('<I',text,off,value)
    text.extend(stub)
    changed=[i for i in range(0,len(old)&~3,4)if text[i:i+4]!=old[i:i+4]]
    assert changed==sorted(sites),changed
    assert text[len(old)&~3:len(old)]==old[len(old)&~3:]
    assert call_target(READ_CALL,word(READ_CALL))==at('read_stub') and call_target(ERR_NEW,word(ERR_NEW))==at('error_stub')
    assert branch_target(SUCCESS,word(SUCCESS))==at('success_stub')
    stubword=lambda name:struct.unpack_from('<I',stub,syms[name])[0]
    assert call_target(at('call_alloc'),stubword('call_alloc'))==AS_ALLOC and call_target(at('call_read'),stubword('call_read'))==READ_TEXT_FILE
    assert call_target(at('call_free_error'),stubword('call_free_error'))==AS_FREE==call_target(at('call_free_ok'),stubword('call_free_ok'))
    assert call_target(at('call_strlen'),stubword('call_strlen'))==STRLEN and call_target(at('call_build'),stubword('call_build'))==BUILD
    assert branch_target(at('success_return'),stubword('success_return'))==JOIN
    listing=['# patched sites']
    for off in sorted(sites):
        i=next(dis.disasm(bytes(text[off:off+4]),off));j=next(dis.disasm(bytes(old[off:off+4]),off))
        listing.append(f'{off:08x} {j.mnemonic} {j.op_str}  ->  {i.mnemonic} {i.op_str}')
    listing.append('# stub')
    for i in dis.disasm(bytes(stub),start):listing.append(f'{i.address:08x} {i.bytes.hex()} {i.mnemonic} {i.op_str}')
    assert sum(1 for l in listing if ' .word'in l or 'udf'in l)==0
    (OUT/'scriptbuf-verified.asm').write_text('\n'.join(listing)+'\n')
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
    report=dict(status='Offline candidate pending startup and large-script runtime tests',source_sha256=EXPECTED,
                candidate_sha256=hashlib.sha256(output).hexdigest(),stub=hex(start),stub_bytes=len(stub),
                script_limit_bytes=BUFSIZE-1,fallback_limit_bytes=0x2000-1,
                patched_sites={hex(k):hex(v)for k,v in sites.items()},
                buffer='AngelScript engine heap (asAllocImpl/asFreeImpl), freed after build and on read error',
                validation=['Five original instructions change; every other original text byte identical',
                            'All added bytes fit original text/RO alignment gap','No object relocations left unresolved',
                            'Every external call/branch target decoded and checked','Stack frame size (0x2070) unchanged',
                            'RO/data/BSS/layout unchanged','Original and derived segment hashes pass'],
                limits=['Exact pinned module and TOTK 1.1.0 only','pushExecLocalFileModuleNXTas (.nxtas) keeps its 0x2000 buffers',
                        'Logger::dumpTextFileIntoNS and other readTextFile callers unchanged','Requires runtime validation'])
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))


if __name__=='__main__':main()
