#!/usr/bin/env python3
"""Align native ControlStick hand targets with the imported steering wheel.

Keeps the hidden host, raised submodel root, native seat and interaction bones.
Edits only three rest-bone translations and two constant animation translations.
"""
import hashlib,io,json,struct,subprocess
import kart_assets_native_cart as n
from kartbf.bfrespy.models.skeleton import Bone
from kartbf.bfrespy.skeletal_anim import BoneAnim,BoneAnimData
import zstandard as zstd
from inspect_native_rider import sarc
ROOT=n.ROOT;OUT=ROOT/'assets/kart-grip-targets';HOST='SpObj_ControlStick_A.SpObj_ControlStick_A_01.bfres.mc'
def main():
 src=ROOT/'assets/controlstick-hidden-host/raised-root';original=(src/'romfs/Model'/HOST).read_bytes();source=(src/'decoded-check'/HOST.removesuffix('.mc')).read_bytes();data=bytearray(source)
 old=Bone.load
 def capture(self,loader):
  read=loader.read_vector3f;seen=[]
  def vector():at=loader.tell();v=read();seen.append(at);return v
  loader.read_vector3f=vector
  try:r=old(self,loader)
  finally:loader.read_vector3f=read
  self.position_offset=seen[-1];return r
 Bone.load=capture
 model=list(n.parse_host(source).models.values())[0];records=[];allowed=set()
 # Neutral source steering-ring component bounds in the converted body mesh:
 # X ±.2701, Y .7176..1.2285, Z .3575...6281. Center≈(0,.97305,.4928).
 center_y=.97305;center_z=.4928;root_y=.3765999973;parent_y=.2
 child_x=center_y-root_y-parent_y;parent_z=center_z+.1209
 for name in ['Handle_L','Handle_R','Handle_J']:
  bone=model.skeleton.bones[name];target=list(bone.position)
  if name=='Handle_J':axis=2;target[axis]=parent_z
  else:axis=0;target[axis]=child_x
  at=bone.position_offset;assert struct.unpack_from('<3f',data,at)==bone.position
  struct.pack_into('<f',data,at+4*axis,target[axis]);allowed.update(range(at+4*axis,at+4*axis+4));records.append(dict(bone=name,before=list(bone.position),after=target))
 assert all(a==b or i in allowed for i,(a,b)in enumerate(zip(source,data)))
 info=n.parse(original);result,_=n.pack(bytes(data),info['fmsh']);dest=OUT/'romfs/Model'/HOST;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(result)
 check=OUT/'decoded-check';check.mkdir(exist_ok=True);subprocess.run([str(ROOT/'.tools/kart-assets/MeshCodec/build/tests/mc_test'),str(dest.parent),str(check)],check=True);assert (check/HOST.removesuffix('.mc')).read_bytes()==data
 # Steering clips explicitly provide Handle_J translation; update that constant
 # as well, preserving every rotational steering curve.
 path='Model/SpObj_ControlStick_A.anim.bfres.zs';compressed=(ROOT/'assets/controlstick-animation-root-trial/romfs'/path).read_bytes();dictionary=sarc(zstd.ZstdDecompressor().decompress((ROOT/'extracted/totk/romfs/Pack/ZsDic.pack.zs').read_bytes()))['zs.zsdic'];dic=zstd.ZstdCompressionDict(dictionary)
 original_anim=zstd.ZstdDecompressor(dict_data=dic).decompress(compressed);animdata=bytearray(original_anim);init=BoneAnimData.__init__
 def capture_base(self,loader,flags):self.record_offset=loader.tell();return init(self,loader,flags)
 BoneAnimData.__init__=capture_base
 animations=n.k.ResFile(io.BytesIO(original_anim));animrecords=[];animallowed=set()
 for anim in animations.skeletal_anims.values():
  bone=next(b for b in anim.bone_anims if b.name=='Handle_J');base=bone.base_data
  assert int(bone.flags_base)==0x38 and base.translate==(0.,.20000000298023224,0.)
  at=base.record_offset+12+16+8;struct.pack_into('<f',animdata,at,parent_z);animallowed.update(range(at,at+4));animrecords.append(dict(animation=anim.name,handle_z=parent_z))
 assert len(animrecords)==2 and all(a==b or i in animallowed for i,(a,b)in enumerate(zip(original_anim,animdata)))
 packed_anim=zstd.ZstdCompressor(level=19,dict_data=dic).compress(animdata);assert zstd.ZstdDecompressor(dict_data=dic).decompress(packed_anim)==animdata
 dest=OUT/'romfs'/path;dest.write_bytes(packed_anim)
 report=dict(status='Offline hand target fit trial; runtime untested',candidate_model_sha256=hashlib.sha256(result).hexdigest(),candidate_animation_sha256=hashlib.sha256(packed_anim).hexdigest(),rest_bone_changes=records,animation_changes=animrecords,estimated_grip_world={'left':[.2107,center_y,center_z],'right':[-.210737,center_y,center_z]},reference='BodyK_Std LOD0 connected steering-ring bounds after source body recenter/0.16 scaling',validation=['Independent model decoder exact byte roundtrip','Model GPU stream byte-identical; only three translation scalars changed','Both steering clip translations changed consistently; curves intact','No mount, saddle, Control or RootStand changes','All decoded sizes unchanged'],limits=['Steering-ring identification/hand fit require game visual confirmation','Native hand target orientation retained; palm orientation may need custom pose work','No runtime controller or physics changes'])
 (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
