#!/usr/bin/env python3
"""Align native steering clip root constants with the raised host bone trial.

No curves, pose bones, section sizes, resource allocations or installed files
are changed. Static bindings do not prove the clips are active at runtime.
"""
from pathlib import Path
import hashlib,io,json,struct,sys
import kart_assets_export as k
from inspect_native_rider import sarc
from kartbf.bfrespy.skeletal_anim import BoneAnim,BoneAnimData
sys.path.insert(0,str(k.ROOT/'.tools/kart-assets/python'))
import zstandard as zstd

def main():
    root=k.ROOT;rom=root/'extracted/totk/romfs';path='Model/SpObj_ControlStick_A.anim.bfres.zs'
    compressed=(rom/path).read_bytes()
    dictionary=sarc(zstd.ZstdDecompressor().decompress((rom/'Pack/ZsDic.pack.zs').read_bytes()))['zs.zsdic']
    dic=zstd.ZstdCompressionDict(dictionary)
    original=zstd.ZstdDecompressor(dict_data=dic).decompress(compressed);data=bytearray(original)
    load=BoneAnim.load;init=BoneAnimData.__init__
    def capture_anim(self,loader):
        self.record_offset=loader.tell();return load(self,loader)
    def capture_data(self,loader,flags):
        self.record_offset=loader.tell();return init(self,loader,flags)
    BoneAnim.load=capture_anim;BoneAnimData.__init__=capture_data
    parsed=k.ResFile(io.BytesIO(original));records=[];allowed=set()
    for animation in parsed.skeletal_anims.values():
        bone=next(b for b in animation.bone_anims if b.name=='Skl_Root')
        assert not bone.curves and bone.base_data.translate==(0,0,0) and int(bone.flags_base)==0x38
        at=bone.record_offset+40;assert struct.unpack_from('<I',data,at)[0]==bone._flags
        flags=bone._flags&~(1<<27);struct.pack_into('<I',data,at,flags);allowed.update(range(at,at+4))
        translation=bone.base_data.record_offset+12+16
        assert struct.unpack_from('<3f',data,translation)==(0,0,0)
        struct.pack_into('<f',data,translation+4,.3765999973);allowed.update(range(translation+4,translation+8))
        records.append(dict(animation=animation.name,bone=bone.name,flags_offset=at,flags_before=bone._flags,flags_after=flags,translation_y_offset=translation+4,translation_y=.3765999973))
    assert len(records)==2 and len(data)==len(original)
    assert all(a==b or i in allowed for i,(a,b)in enumerate(zip(original,data)))
    checked=k.ResFile(io.BytesIO(data))
    for animation in checked.skeletal_anims.values():
        bone=next(b for b in animation.bone_anims if b.name=='Skl_Root')
        assert abs(bone.base_data.translate[1]-.3766)<1e-6 and not bone._flags&(1<<27) and not bone.curves
    result=zstd.ZstdCompressor(level=19,dict_data=dic).compress(data)
    assert zstd.ZstdDecompressor(dict_data=dic).decompress(result)==data
    out=root/'assets/controlstick-animation-root-trial';dest=out/'romfs'/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(result)
    report=dict(status='Offline constant-root animation comparison; runtime untested',source=path,source_sha256=hashlib.sha256(compressed).hexdigest(),candidate_sha256=hashlib.sha256(result).hexdigest(),decoded_size_unchanged=True,decoded_bytes=len(data),changes=records,
        evidence='Both supplied ControlStick steering clips explicitly bind Skl_Root with constant zero translation and TRANSLATE_ZERO. A model-only bone offset may be overridden when either clip is active.',
        limits=['Whether these clips are active in the current actor state needs runtime observation','Requires compatible raised-root model trial for consistent rest/animated transforms','No seated pose, rider/saddle, handle/hand transforms or physics edits','Source curves and all bytes outside four scalar fields retained'])
    (out/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))

if __name__=='__main__':main()
