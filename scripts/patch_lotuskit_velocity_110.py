#!/usr/bin/env python3
"""Correct one pinned TOTK1.1.0 lookup entry after native byte analysis.

Original 0x7a4cfc writes angular velocity fields/bit8. 0x6bf8f8 writes
the linear fields/bit7 read by getNextLinearVelocity and used by impulse.
The derived NSO preserves text, data, virtual addresses and BSS exactly.
"""
import hashlib,json,struct
from pathlib import Path
import lz4.block
from patch_lotuskit_spawn_init import decode
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'runtime/candidates/zero-create-arg/subsdk9'
EXPECTED='59d61add33f737325500a48eb94d35f0d4db59564a99cca60d07459d3fe82841'
OUT=ROOT/'runtime/candidates/linear-velocity-110'


def main():
    original=SOURCE.read_bytes();assert hashlib.sha256(original).hexdigest()==EXPECTED
    segments=decode(original);raw=bytearray(segments[1][1]);offset=0x244ab0-segments[1][0]
    assert struct.unpack_from('<II',raw,offset)==(0x31abb2c6,0x107a4cfc)
    struct.pack_into('<I',raw,offset+4,0x106bf8f8)
    output=bytearray(original[:256]);flags=struct.unpack_from('<I',output,12)[0]
    output[64:96]=hashlib.sha256(original[64:96]+raw).digest()
    for i,(address,payload) in enumerate(segments):
        if i==1:payload=bytes(raw)
        packed=lz4.block.compress(payload,store_size=False,mode='high_compression',compression=12)if flags&(1<<i)else payload
        struct.pack_into('<III',output,16+16*i,len(output),address,len(payload))
        struct.pack_into('<I',output,96+4*i,len(packed))
        output[160+32*i:192+32*i]=hashlib.sha256(payload).digest();output.extend(packed)
    check=decode(output);assert check[0]==segments[0]and check[2]==segments[2]
    assert len(check[1][1])==len(segments[1][1]);assert output[0x3c:0x40]==original[0x3c:0x40]
    diffs=[i for i,(a,b)in enumerate(zip(check[1][1],segments[1][1]))if a!=b]
    assert all(offset+4<=i<offset+8 for i in diffs)
    OUT.mkdir(parents=True,exist_ok=True);dest=OUT/'subsdk9';assert not dest.exists();dest.write_bytes(output)
    report=dict(status='Offline candidate pending runtime test',source_sha256=EXPECTED,
                candidate_sha256=hashlib.sha256(output).hexdigest(),lookup_address='0x244ab0',symbol_hash='0x31abb2c6',
                previous_main_offset='0x7a4cfc',corrected_main_offset='0x6bf8f8',
                verification=['All NSO segment hashes verified before/after','One 32-bit RO lookup value changed',
                              'Text including spawn-initialization fix, data, virtual layout and BSS unchanged'],
                evidence='research/physics-api-native-110.json',
                limits=['Static native analysis predicts linear behavior; gameplay/hardware not established until tested'])
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))


if __name__=='__main__':main()
