#!/usr/bin/env python3
"""Offline seated lower body with original vehicle upper-body animation.

Reuses existing Horse_Wait bone/curve data only for pelvis and legs. Native
vehicle arm/head/torso curves remain, and every curve index is rebased.
"""
from pathlib import Path
import hashlib,io,json,struct
import kart_assets_export as k
from inspect_native_rider import sarc
from kartbf.bfrespy.skeletal_anim import SkeletonAnim,BoneAnim
import zstandard as zstd
ROOT=k.ROOT;OUT=ROOT/'assets/native-seated-hybrid'
def main():
 rom=ROOT/'extracted/totk/romfs';rel='Model/Player_Animation.anim.bfres.zs';compressed=(rom/rel).read_bytes()
 dictionary=sarc(zstd.ZstdDecompressor().decompress((rom/'Pack/ZsDic.pack.zs').read_bytes()))['zs.zsdic'];dic=zstd.ZstdCompressionDict(dictionary)
 source=zstd.ZstdDecompressor(dict_data=dic).decompress(compressed);data=bytearray(source)
 for cls in [SkeletonAnim,BoneAnim]:
  old=cls.load
  def capture(self,loader,old=old):self.record_offset=loader.tell();return old(self,loader)
  cls.load=capture
 f=k.ResFile(io.BytesIO(source));horse={b.name:b for b in f.skeletal_anims['Horse_Wait'].bone_anims}
 names={'Skl_Root','Waist','Leg_1_L','Leg_2_L','Ankle_L','Toe_L','Leg_1_R','Leg_2_R','Ankle_R','Toe_R'}
 allowed=set();records=[]
 for name,a in f.skeletal_anims.items():
  if not name.startswith('Vehicle_Wait'):continue
  assert a.frame_cnt==48 and len(a.bone_anims)==63
  cursor=0;changes=[]
  for bone in a.bone_anims:
   pos=bone.record_offset;count=len(bone.curves)
   if bone.name in names:
    src=horse[bone.name];off=src.record_offset
    data[pos:pos+56]=source[off:off+56];allowed.update(range(pos,pos+56));count=len(src.curves);changes.append(bone.name)
   # begin_curve is an index in the clip's flattened curve-result cache.
   assert struct.unpack_from('<i',source,pos+48)[0]==bone.begin_curve
   struct.pack_into('<i',data,pos+48,cursor);allowed.update(range(pos+48,pos+52));cursor+=count
  assert set(changes)==names
  pos=a.record_offset;old_count=struct.unpack_from('<I',source,pos+68)[0];assert old_count==sum(len(b.curves)for b in a.bone_anims)
  struct.pack_into('<I',data,pos+68,cursor);allowed.update(range(pos+68,pos+72))
  # Original48frame clips use224bytes per baked curve. Retain at least the
  # original allocation; this is a conservative capacity, not baked payload.
  assert a.baked_size==old_count*224
  capacity=max(a.baked_size,cursor*224);struct.pack_into('<I',data,pos+72,capacity);allowed.update(range(pos+72,pos+76))
  records.append(dict(name=name,bones=changes,old_curves=old_count,new_curves=cursor,baked_capacity=capacity))
 assert len(records)==33 and len(data)==len(source)
 assert all(a==b or i in allowed for i,(a,b)in enumerate(zip(source,data)))
 check=k.ResFile(io.BytesIO(data))
 for record in records:
  a=check.skeletal_anims[record['name']];old=f.skeletal_anims[record['name']];assert a.frame_cnt==48 and len(a.bone_anims)==63 and a.bind_idxs==old.bind_idxs
  total=0
  for b,previous in zip(a.bone_anims,old.bone_anims):
   assert b.name==previous.name and b.begin_curve==total;total+=len(b.curves)
   expected=horse[b.name]if b.name in names else previous
   assert b.base_data.rotate==expected.base_data.rotate and b.base_data.translate==expected.base_data.translate
   assert len(b.curves)==len(expected.curves)
  assert total==record['new_curves']
 result=zstd.ZstdCompressor(level=19,dict_data=dic).compress(data);assert zstd.ZstdDecompressor(dict_data=dic).decompress(result)==data
 dest=OUT/'romfs'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(result)
 report=dict(status='Offline seated lower-body prototype; runtime untested',source=rel,source_sha256=hashlib.sha256(compressed).hexdigest(),candidate_sha256=hashlib.sha256(result).hexdigest(),decoded_bytes=len(data),decoded_allocation_unchanged=True,changes=records,lower_body_source='Supplied Horse_Wait pelvis/legs/feet',upper_body_source='Original per-direction Vehicle_Wait arm/torso/head/hand curves',validation=['Full archive parses before/after','Only targeted bone headers and affected curve counts/capacities/index scalars change','63bone binding indices, clip duration, names, dictionary and relocation layout preserved','All upper-body base values/curve references retained','Exact dictionary compression roundtrip'],limits=['Not yet a custom authored kart pose','Global Vehicle_Wait variants affected','Native IK, seat fit, transitions and movement require live testing','Source lower-body curves sampled within original48frame clip range'])
 (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items()if k!='changes'},indent=2))
if __name__=='__main__':main()
