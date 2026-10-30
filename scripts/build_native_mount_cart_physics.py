#!/usr/bin/env python3
"""Combine native ControlStick mounting with the proven Cart contact hulls.

Only the host's ModelInfo, Physical shape and one saddle-height scalar change.
This keeps original native interaction/AI rather than inventing a rider action.
"""
from pathlib import Path
import hashlib,json,struct,sys,zlib
from build_native_mount_submodel import ROOT,pack_sarc
from inspect_native_rider import sarc,byml
from build_cart_physics_trial import scalar_offsets
import zstandard as zstd


def main():
    rom=ROOT/'extracted/totk/romfs';out=ROOT/'assets/native-mount-cart-physics';out.mkdir(exist_ok=True,parents=True)
    d=sarc(zstd.ZstdDecompressor().decompress((rom/'Pack/ZsDic.pack.zs').read_bytes()));dic=zstd.ZstdCompressionDict(d['pack.zsdic'])
    path='Pack/Actor/SpObj_ControlStick_A_01.pack';src=(rom/(path+'.zs')).read_bytes();original=zstd.ZstdDecompressor(dict_data=dic).decompress(src);old=sarc(original)
    members=sarc(zstd.ZstdDecompressor(dict_data=dic).decompress((ROOT/'assets/native-mount-submodel/romfs'/(path+'.zs')).read_bytes()))
    shape='Phive/ShapeParam/SpObj_ControlStick_A_01__Physical.phive__ShapeParam.bgyml'
    members[shape]=(ROOT/'.work/kart-runtime/cart-pack/Phive/ShapeParam/SpObj_Cart_A_01__Physical.phive__ShapeParam.bgyml').read_bytes()
    seat='Component/RidableParam/SpObj_ControlStick_A_01.game__component__RidableParam.bgyml';payload=bytearray(members[seat]);typ,at=scalar_offsets(payload)[('Seats',0,'SaddleOffset','Y')];assert typ==0xd2 and struct.unpack_from('<f',payload,at)[0]==0
    struct.pack_into('<f',payload,at,0.5);members[seat]=bytes(payload);assert byml(payload)['Seats'][0]['SaddleOffset']['Y']==0.5
    changes=[k for k in members if members[k]!=old[k]];assert len(changes)==3
    packed=pack_sarc(members);compressed=zstd.ZstdCompressor(level=19,dict_data=dic).compress(packed);assert zstd.ZstdDecompressor(dict_data=dic).decompress(compressed)==packed
    dest=out/'romfs'/(path+'.zs');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(compressed)
    table='System/Resource/ResourceSizeTable.Product.110.rsizetable.zs';raw=bytearray(zstd.ZstdDecompressor().decompress((rom/table).read_bytes()));count=struct.unpack_from('<I',raw,14)[0];adjustments=[]
    for resource,increment in [(path,max(0,len(packed)-len(original))+4096)]+[(k,max(0,len(members[k])-len(old[k]))+1024)for k in changes if k!=seat]:
        key=zlib.crc32(resource.encode());hits=[22+8*i+4 for i in range(count)if struct.unpack_from('<I',raw,22+8*i)[0]==key];assert len(hits)==1;pos=hits[0];before=struct.unpack_from('<I',raw,pos)[0];after=before+increment;struct.pack_into('<I',raw,pos,after);adjustments.append(dict(path=resource,before=before,after=after))
    dest=out/'romfs'/table;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(zstd.ZstdCompressor(level=19).compress(raw))
    report=dict(status='Offline native riding/contact diagnostic; runtime untested',candidate_sha256=hashlib.sha256(compressed).hexdigest(),source_sha256=hashlib.sha256(src).hexdigest(),modified_members=changes,
                physical_shape='Exact supplied native Cart hulls with Material_Cart wheel contacts',saddle_offset_y=0.5,original_decoded_bytes=len(original),candidate_decoded_bytes=len(packed),resource_allocations=adjustments,
                validation=['Typed scalar edit of original saddle offset','Other actor members remain byte-identical','SARC and dictionary compression roundtrip pass'],
                limits=['Standing Control pose, not seated kart animation','Existing approximate kart wheelbase retained','Native ride + movement require game validation','ControlStick base/handle remain visible'])
    (out/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))


if __name__=='__main__':main()
