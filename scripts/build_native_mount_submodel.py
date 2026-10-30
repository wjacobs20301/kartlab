#!/usr/bin/env python3
"""Offline native mounting host with an additive kart submodel.

Preserves every original ControlStick member except ModelInfo. The stock
skeleton, physics, AI, seat, attention and animation are retained. This is a
standing native mount diagnostic; no seated pose or driving claim is made.
"""
from pathlib import Path
import hashlib,json,struct,sys,zlib
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/kart-assets/python'))
import zstandard as zstd
from inspect_native_rider import byml,sarc


def encode_model_info(value):
    keys=sorted({k for d in [value,*value['SubModels']]for k in d})
    strings=sorted({v for d in [value,*value['SubModels']]for v in d.values()if isinstance(v,str)})
    out=bytearray(b'YB\x07\x00'+bytes(12))
    def align():out.extend(bytes((-len(out))%4))
    def string_table(values):
        align();at=len(out);out.extend(b'\xc2'+len(values).to_bytes(3,'little')+bytes(4*(len(values)+1)))
        for i,v in enumerate(values):
            struct.pack_into('<I',out,at+4+4*i,len(out)-at);out.extend(v.encode()+b'\0')
        struct.pack_into('<I',out,at+4+4*len(values),len(out)-at);return at
    def node(obj):
        align();at=len(out)
        if isinstance(obj,dict):
            entries=sorted(obj.items(),key=lambda x:keys.index(x[0]));out.extend(b'\xc1'+len(entries).to_bytes(3,'little')+bytes(8*len(entries)))
            slots=[(at+8+8*i,v,keys.index(k))for i,(k,v)in enumerate(entries)]
            for pos,v,key in slots:out[pos-4:pos-1]=key.to_bytes(3,'little')
        else:
            out.extend(b'\xc0'+len(obj).to_bytes(3,'little')+bytes(len(obj)));align();base=len(out);out.extend(bytes(4*len(obj)))
            slots=[(base+4*i,v,at+4+i)for i,v in enumerate(obj)]
        for i,(pos,v,_)in enumerate(slots):
            typ=0xa0 if isinstance(v,str)else(0xc1 if isinstance(v,dict)else 0xc0)
            typepos=pos-1 if isinstance(obj,dict)else at+4+i;out[typepos]=typ
            val=strings.index(v)if typ==0xa0 else node(v);struct.pack_into('<I',out,pos,val)
        return at
    k=string_table(keys);v=string_table(strings);r=node(value);struct.pack_into('<III',out,4,k,v,r)
    assert byml(out)==value;return bytes(out)


def pack_sarc(members):
    def namehash(name):
        h=0
        for x in name.encode():h=(h*0x65+x)&0xffffffff
        return h
    ordered=sorted(members,key=namehash);names=bytearray();entries=[];payload=bytearray()
    for name in ordered:
        names.extend(bytes((-len(names))%4));n=len(names)//4;names.extend(name.encode()+b'\0')
        payload.extend(bytes((-len(payload))%8));start=len(payload);payload.extend(members[name]);entries.append((namehash(name),0x01000000|n,start,len(payload)))
    header_size=20+12+16*len(entries)+8+len(names);data_at=(header_size+255)&~255
    out=bytearray(b'SARC'+struct.pack('<HHIIHH',20,0xfeff,data_at+len(payload),data_at,0x100,0))
    out.extend(b'SFAT'+struct.pack('<HHI',12,len(entries),0x65))
    for e in entries:out.extend(struct.pack('<4I',*e))
    out.extend(b'SFNT'+struct.pack('<HH',8,0)+names);out.extend(bytes(data_at-len(out)));out.extend(payload)
    assert sarc(out)==members;return bytes(out)


def main():
    rom=ROOT/'extracted/totk/romfs';out=ROOT/'assets/native-mount-submodel';out.mkdir(parents=True,exist_ok=True)
    dictionaries=sarc(zstd.ZstdDecompressor().decompress((rom/'Pack/ZsDic.pack.zs').read_bytes()));dic=zstd.ZstdCompressionDict(dictionaries['pack.zsdic'])
    path='Pack/Actor/SpObj_ControlStick_A_01.pack';original=(rom/(path+'.zs')).read_bytes();raw=zstd.ZstdDecompressor(dict_data=dic).decompress(original);members=sarc(raw)
    name='Component/ModelInfo/SpObj_ControlStick_A_01.engine__component__ModelInfo.bgyml';old=members[name];model=byml(old)
    assert model=={'FmdbName':'SpObj_ControlStick_A_01','ModelProjectName':'SpObj_ControlStick_A','SubModels':[]}
    model['SubModels']=[{'Bone':'Root','FmdbName':'SpObj_Cart_A_01','ModelProjectName':'SpObj_Cart_A','SearchModelKey':''}]
    members[name]=encode_model_info(model);candidate=pack_sarc(members)
    compressed=zstd.ZstdCompressor(level=19,dict_data=dic).compress(candidate);assert zstd.ZstdDecompressor(dict_data=dic).decompress(compressed)==candidate
    dest=out/'romfs'/(path+'.zs');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(compressed)
    rst_path='System/Resource/ResourceSizeTable.Product.110.rsizetable.zs';rst_src=(rom/rst_path).read_bytes();rst=bytearray(zstd.ZstdDecompressor().decompress(rst_src));assert rst[:6]==b'RESTBL'
    version,width,count,names=struct.unpack_from('<4I',rst,6);assert version==1 and len(rst)==22+count*8+names*(width+4)
    adjustments=[]
    for resource,increment in [(path,max(0,len(candidate)-len(raw))+4096),(name,max(0,len(members[name])-len(old))+1024)]:
        key=zlib.crc32(resource.encode());hits=[22+8*i+4 for i in range(count)if struct.unpack_from('<I',rst,22+8*i)[0]==key];assert len(hits)==1
        pos=hits[0];before=struct.unpack_from('<I',rst,pos)[0];after=before+increment;struct.pack_into('<I',rst,pos,after);adjustments.append(dict(path=resource,crc32=hex(key),before=before,after=after))
    rst_dst=out/'romfs'/rst_path;rst_dst.parent.mkdir(parents=True,exist_ok=True);rst_dst.write_bytes(zstd.ZstdCompressor(level=19).compress(rst))
    assert zstd.ZstdDecompressor().decompress(rst_dst.read_bytes())==rst
    report=dict(status='Offline native mounting/model diagnostic; runtime untested',source_sha256=hashlib.sha256(original).hexdigest(),candidate_sha256=hashlib.sha256(compressed).hexdigest(),original_decoded_bytes=len(raw),candidate_decoded_bytes=len(candidate),modified_members=[name],model_info=model,
                unchanged_members_verified=all(v==sarc(candidate)[k]for k,v in sarc(raw).items()if k!=name),resource_allocations=adjustments,
                resource_table_sha256=hashlib.sha256(rst_dst.read_bytes()).hexdigest(),
                limits=['Stock ControlStick collision retained, not kart collision','Stock standing Control pose, not seated animation','Submodel rendering and Root binding await game test','No full Mario Kart handling or Switch test'])
    (out/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))


if __name__=='__main__':main()
