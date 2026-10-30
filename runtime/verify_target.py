#!/usr/bin/env python3
"""Record exact target identity and cited upstream symbol bytes (not semantic proof)."""
import argparse, hashlib, json, re, struct
from pathlib import Path
import lz4.block
ROOT = Path(__file__).resolve().parent.parent
WANTED = ['engine::actor::ActorBase::forceSetMatrix', 'engine::actor::ActorMgr::requestCreateActorAsync',
          'phive::RigidBodyBase::getNextLinearVelocity', 'phive::RigidBodyBase::requestSetLinearVelocity']
def verify(main, symbols):
    data = main.read_bytes()
    if data[:4] != b'NSO0': raise ValueError('Expected an NSO0 main executable')
    expected = json.loads((ROOT/'runtime/dependencies.json').read_text())['totk']['main_build_id']
    build_id=data[0x40:0x60].hex().upper()
    if build_id != expected: raise ValueError(f'Wrong target build ID: {build_id}')
    flags=struct.unpack_from('<I',data,0xc)[0]
    segments=[]
    for i,name in enumerate(['text','rodata','data']):
        offset,virtual,size=struct.unpack_from('<III',data,0x10+i*0x10)
        packed=struct.unpack_from('<I',data,0x60+4*i)[0]
        raw=data[offset:offset+packed] if flags&(1<<i) else data[offset:offset+size]
        raw=lz4.block.decompress(raw,uncompressed_size=size) if flags&(1<<i) else raw
        if len(raw)!=size: raise ValueError(f'Invalid {name} size')
        digest=hashlib.sha256(raw).digest()
        if flags&(1<<(i+3)) and digest != data[0xa0+i*0x20:0xc0+i*0x20]: raise ValueError(f'{name} hash mismatch')
        segments.append((name,virtual,raw))
    found={}
    for address,symbol in re.findall(r'0x([0-9a-fA-F]+), "([^"]+)"',symbols.read_text()):
        if symbol not in WANTED: continue
        address=int(address,16)
        segment=next((s for s in segments if s[1]<=address and address+32<=s[1]+len(s[2])),None)
        if not segment or segment[0]!='text': raise ValueError(f'{symbol} does not map to text')
        window=segment[2][address-segment[1]:address-segment[1]+32]
        if not any(window): raise ValueError(f'{symbol} points to zeros')
        found[symbol]={'main_offset':hex(address),'segment':segment[0],'first_32_bytes':window.hex(),'window_sha256':hashlib.sha256(window).hexdigest()}
    if set(found)!=set(WANTED): raise ValueError('Missing or zero symbol')
    return {'main_build_id':build_id,'main_sha256':hashlib.sha256(data).hexdigest(),
            'symbol_source_commit':'59dcfccd77b6d4bcfa718bff806bc55be640edb7',
            'verification_boundary':'NSO ID and enabled hashes verified; upstream offsets map to nonzero text. Symbol meanings/ABI are upstream claims, not independently proved.',
            'symbols':found}
def main():
    p=argparse.ArgumentParser();p.add_argument('--main',type=Path,default=ROOT/'extracted/totk/exefs/main');p.add_argument('--output',type=Path)
    a=p.parse_args();r=verify(a.main,ROOT/'.tools/totk-runtime/lotuskit/syms/output/TOTK_110/syms_exl_reloc.inc');s=json.dumps(r,indent=2)+'\n'
    if a.output: a.output.write_text(s)
    else: print(s,end='')
if __name__=='__main__':main()
