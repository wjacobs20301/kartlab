#!/usr/bin/env python3
"""Prepare an isolated native vehicle-pose comparison without new allocations.

The selected Vehicle_Wait headers reuse the supplied Horse_Wait animation's
curves/bone data. Names, dictionary, relocation layout and all payloads remain.
This is an existing TOTK riding pose comparison, not a Mario kart pose retarget.
"""
from pathlib import Path
import hashlib,io,json,struct,sys
import kart_assets_export as k
from inspect_native_rider import sarc
from kartbf.bfrespy.skeletal_anim import SkeletonAnim
import zstandard as zstd
ROOT=k.ROOT;OUT=ROOT/'assets/native-seated-pose-trial'
def main():
 rom=ROOT/'extracted/totk/romfs';rel='Model/Player_Animation.anim.bfres.zs';compressed=(rom/rel).read_bytes()
 dictionary=sarc(zstd.ZstdDecompressor().decompress((rom/'Pack/ZsDic.pack.zs').read_bytes()))['zs.zsdic'];dic=zstd.ZstdCompressionDict(dictionary)
 source=zstd.ZstdDecompressor(dict_data=dic).decompress(compressed);data=bytearray(source)
 old=SkeletonAnim.load
 def capture(self,loader):self.record_offset=loader.tell();return old(self,loader)
 SkeletonAnim.load=capture
 parsed=k.ResFile(io.BytesIO(source));animations=parsed.skeletal_anims;horse=animations['Horse_Wait'];at=horse.record_offset
 assert source[at:at+4]==b'FSKA';assert horse.frame_cnt==300 and len(horse.bone_anims)==70
 # Native v10 FSKA is80bytes. Keep name/path pointers (8..24), use source
 # flags(4..8) and actual source data/binding/counts(24..80). Both headers have
 # identical pointer-bearing field positions already covered by relocation.
 records=[];allowed=set()
 for name,animation in animations.items():
  if not name.startswith('Vehicle_Wait'):continue
  pos=animation.record_offset;assert source[pos:pos+4]==b'FSKA';assert animation.frame_cnt==48 and len(animation.bone_anims)==63
  for start,end in [(4,8),(24,80)]:data[pos+start:pos+end]=source[at+start:at+end];allowed.update(range(pos+start,pos+end))
  records.append(dict(name=name,header_offset=pos,previous_frames=animation.frame_cnt,previous_bones=len(animation.bone_anims),frames=horse.frame_cnt,bones=len(horse.bone_anims)))
 assert len(records)==33;assert len(data)==len(source)
 assert all(a==b or i in allowed for i,(a,b)in enumerate(zip(source,data)))
 checked=k.ResFile(io.BytesIO(data));assert list(checked.skeletal_anims.keys())==list(animations.keys())
 for record in records:
  a=checked.skeletal_anims[record['name']];assert a.frame_cnt==300 and len(a.bone_anims)==70 and a.bind_idxs==horse.bind_idxs
  assert [(b.name,b.base_data.rotate,b.base_data.translate)for b in a.bone_anims]==[(b.name,b.base_data.rotate,b.base_data.translate)for b in horse.bone_anims]
 result=zstd.ZstdCompressor(level=19,dict_data=dic).compress(data);assert zstd.ZstdDecompressor(dict_data=dic).decompress(result)==data
 dest=OUT/'romfs'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(result)
 report=dict(status='Offline existing seated riding pose trial; runtime untested',source=rel,source_sha256=hashlib.sha256(compressed).hexdigest(),candidate_sha256=hashlib.sha256(result).hexdigest(),decoded_allocation_unchanged=True,decoded_bytes=len(data),animation_count=len(animations),header_changes=records,source_animation='Horse_Wait',validation=['Full archive parse before/after','Only selected80byteheaders changed; names/path/dictionary/relocations/payloads unchanged','Every selected header now references the exact supplied native riding bone/curve data','Dictionary compression roundtrip byte-identical'],limits=['Changes Vehicle_Wait variants globally, including ordinary native vehicles','No custom kart seated animation authored yet','Native controller/mount collision/IK/transitions still require visual and gameplay testing','Horse pose may not fit kart seat/steering wheel','No installed edits by this builder'])
 (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items()if k!='header_changes'},indent=2))
if __name__=='__main__':main()
