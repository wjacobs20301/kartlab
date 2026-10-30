#!/usr/bin/env python3
"""Kart seated pose: construct-seat lower body with original vehicle upper-body animation.

Same method as build_native_seated_hybrid.py (bone records copied, curve indices rebased), but the pelvis and legs come
from A_Pose_RaumiGolem_Ride: Link sitting in Mineru's construct, hips ~67 deg and knees ~108 deg (Horse_Wait: knee ~60).
Usage: build_kart_seated_pose.py [LOWER_CLIP] [OUT_DIR]
"""
import sys
from pathlib import Path
import hashlib,io,json,struct
import kart_assets_export as k
from inspect_native_rider import sarc
from kartbf.bfrespy.skeletal_anim import SkeletonAnim,BoneAnim
import zstandard as zstd
ROOT=k.ROOT
LOWER=sys.argv[1] if len(sys.argv)>1 else 'A_Pose_RaumiGolem_Ride'
UPPER_TOO=len(sys.argv)>3 and sys.argv[3]=='full'  # also take arms/torso/head from LOWER
import os,math
# Optional authored legs (degrees, Euler XYZ as stored): LEGS="hipX,hipY,hipZ,knee,ankleX,ankleY,ankleZ" (left side;
# right mirrors with hipZ+180). Written into each Vehicle_Wait clip's OWN leg base blocks (records point there, no curves),
# so the source clip (e.g. the construct seat) is untouched.
LEGS=[float(x) for x in os.environ['LEGS'].split(',')] if os.environ.get('LEGS') else None
# Optional lean into turns (degrees, for *Turn_R* clips; *Turn_L* mirrored): LEAN="spine1Z,spine2Y,headX".
# Axes from forward kinematics on Player_Animation.Skeleton: Spine_1 Z / Spine_2 Y tilt the torso toward Link's right
# for +, Head X turns the head left for +. Written as static values (construct-seat base + delta) into the clip's own
# base blocks, like LEGS.
LEAN=[float(x) for x in os.environ['LEAN'].split(',')] if os.environ.get('LEAN') else None
def lean_delta(clip,bone):
    if not LEAN or ('Turn_R' not in clip and 'Turn_L' not in clip):return None
    sgn=1 if 'Turn_R' in clip else -1
    d={'Spine_1':(0,0,LEAN[0]),'Spine_2':(0,LEAN[1],0),'Head':(-LEAN[2],0,0)}.get(bone)
    return None if d is None else tuple(sgn*x for x in d)
# 14 values = left 7 then right 7 (right hip Z absolute), e.g. from a forward-kinematics solve on Player_Animation.Skeleton.
def leg_euler(name):
    if len(LEGS)==14:
        L,R=LEGS[:7],LEGS[7:]
        return {'Leg_1_L':tuple(L[:3]),'Leg_1_R':tuple(R[:3]),'Leg_2_L':(0,0,L[3]),'Leg_2_R':(0,0,R[3]),
                'Ankle_L':tuple(L[4:7]),'Ankle_R':tuple(R[4:7])}.get(name)
    hx,hy,hz,kn,ax,ay,az=LEGS
    return {'Leg_1_L':(hx,hy,hz),'Leg_1_R':(hx,hy,hz+180),'Leg_2_L':(0,0,kn),'Leg_2_R':(0,0,kn),
            'Ankle_L':(ax,ay,az),'Ankle_R':(ax,ay,az)}.get(name)
OUT=ROOT/(sys.argv[2] if len(sys.argv)>2 else 'assets/kart-seated-golem')
def main():
 rom=ROOT/'extracted/totk/romfs';rel='Model/Player_Animation.anim.bfres.zs';compressed=(rom/rel).read_bytes()
 dictionary=sarc(zstd.ZstdDecompressor().decompress((rom/'Pack/ZsDic.pack.zs').read_bytes()))['zs.zsdic'];dic=zstd.ZstdCompressionDict(dictionary)
 source=zstd.ZstdDecompressor(dict_data=dic).decompress(compressed);data=bytearray(source)
 for cls in [SkeletonAnim,BoneAnim]:
  old=cls.load
  def capture(self,loader,old=old):self.record_offset=loader.tell();return old(self,loader)
  cls.load=capture
 f=k.ResFile(io.BytesIO(source));horse={b.name:b for b in f.skeletal_anims[LOWER].bone_anims}
 names={'Skl_Root','Waist','Leg_1_L','Leg_2_L','Ankle_L','Toe_L','Leg_1_R','Leg_2_R','Ankle_R','Toe_R'}
 if UPPER_TOO:names|={b.name for b in f.skeletal_anims[LOWER].bone_anims}-{'Root'}
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
    ld=lean_delta(name,bone.name)
    if ld:
     own=struct.unpack_from('<Q',source,pos+16)[0];struct.pack_into('<Q',data,pos+16,own)
     vflags=struct.unpack_from('<I',source,pos+40)[0];assert vflags&0x38==0x10,hex(vflags)
     struct.pack_into('<I',data,pos+40,vflags&~0x7fc0);data[pos+46]=0;count=0;allowed.update(range(pos+40,pos+47))
     base=src.base_data.rotate[:3]
     struct.pack_into('<3f',data,own,*[b+math.radians(x) for b,x in zip(base,ld)]);allowed.update(range(own,own+12))
    if LEGS and leg_euler(bone.name):
     own=struct.unpack_from('<Q',source,pos+16)[0];struct.pack_into('<Q',data,pos+16,own)
     assert struct.unpack_from('<I',source,pos+40)[0]&0x38==struct.unpack_from('<I',source,off+40)[0]&0x38  # same base layout
     struct.pack_into('<3f',data,own,*[math.radians(v) for v in leg_euler(bone.name)]);allowed.update(range(own,own+12))
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
   if lean_delta(record['name'],b.name):
    assert len(b.curves)==0
   elif LEGS and leg_euler(b.name):
    assert all(abs(x-math.radians(v))<1e-5 for x,v in zip(b.base_data.rotate[:3],leg_euler(b.name)));assert len(b.curves)==0
   else:assert b.base_data.rotate==expected.base_data.rotate and b.base_data.translate==expected.base_data.translate
   if not lean_delta(record['name'],b.name):assert len(b.curves)==len(expected.curves)
  assert total==record['new_curves']
 result=zstd.ZstdCompressor(level=19,dict_data=dic).compress(data);assert zstd.ZstdDecompressor(dict_data=dic).decompress(result)==data
 dest=OUT/'romfs'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(result)
 report=dict(status='Offline seated lower-body prototype; runtime untested',source=rel,source_sha256=hashlib.sha256(compressed).hexdigest(),candidate_sha256=hashlib.sha256(result).hexdigest(),decoded_bytes=len(data),decoded_allocation_unchanged=True,changes=records,lower_body_source=LOWER+' pelvis/legs/feet',upper_body_source='Original per-direction Vehicle_Wait arm/torso/head/hand curves',validation=['Full archive parses before/after','Only targeted bone headers and affected curve counts/capacities/index scalars change','63bone binding indices, clip duration, names, dictionary and relocation layout preserved','All upper-body base values/curve references retained','Exact dictionary compression roundtrip'],limits=['Not yet a custom authored kart pose','Global Vehicle_Wait variants affected','Native IK, seat fit, transitions and movement require live testing','Source lower-body curves sampled within original48frame clip range'])
 (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items()if k!='changes'},indent=2))
if __name__=='__main__':main()
