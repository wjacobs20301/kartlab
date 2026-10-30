#!/usr/bin/env python3
"""Prepare a metadata-only root-offset comparison; no installed edits."""
from pathlib import Path
import hashlib,json,struct,subprocess
import kart_assets_native_cart as native
from kartbf.bfrespy.models.skeleton import Bone
ROOT=native.ROOT;OUT=ROOT/'assets/controlstick-root-trial'
HOST='SpObj_ControlStick_A.SpObj_ControlStick_A_01.bfres.mc'
def main():
 OUT.mkdir(exist_ok=True,parents=True)
 original=(ROOT/'.work/native-mount/model/compressed'/HOST).read_bytes();source=(ROOT/'.work/native-mount/model/decoded'/HOST.removesuffix('.mc')).read_bytes();data=bytearray(source)
 old=Bone.load
 def capture(self,loader):
  self.record_offset=loader.tell();read=loader.read_vector3f;seen=[]
  def vector():
   at=loader.tell();value=read();seen.append(at);return value
  loader.read_vector3f=vector
  try:result=old(self,loader)
  finally:loader.read_vector3f=read
  self.position_offset=seen[-1];return result
 Bone.load=capture
 parsed=native.parse_host(source);model=list(parsed.models.values())[0];bones=list(model.skeleton.bones.values());target=next(b for b in bones if b.name=='Skl_Root');assert target.position==(0,0,0)
 at=target.position_offset;assert struct.unpack_from('<3f',data,at)==target.position
 struct.pack_into('<f',data,at+4,0.3765999973)
 changes=[]
 for i,b in enumerate(bones):
  j=i;descendant=False
  while j>=0:
   if bones[j].name=='Skl_Root':descendant=True;break
   j=bones[j].parent_idx
  if descendant:
   flags_at=b.position_offset-32;before=struct.unpack_from('<I',data,flags_at)[0];assert before==b._flags
   after=before&~(1<<31)
   if b is target:after&=~(1<<27)
   struct.pack_into('<I',data,flags_at,after);changes.append(dict(bone=b.name,flags_before=before,flags_after=after))
 check=native.parse_host(bytes(data));assert list(check.models.values())[0].skeleton.bones['Skl_Root'].position[1]>0.37
 info=native.parse(original);result,_=native.pack(bytes(data),info['fmsh']);dest=OUT/'romfs/Model'/HOST;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(result)
 decoded=OUT/'decoded-check';decoded.mkdir(exist_ok=True);subprocess.run([str(ROOT/'.tools/kart-assets/MeshCodec/build/tests/mc_test'),str(dest.parent),str(decoded)],check=True)
 assert (decoded/HOST.removesuffix('.mc')).read_bytes()==data
 (OUT/'expected-decoded.bfres').write_bytes(data)
 report=dict(status='Offline root binding hypothesis; runtime untested',original_sha256=hashlib.sha256(original).hexdigest(),candidate_sha256=hashlib.sha256(result).hexdigest(),bone_translation_offset=at,old_translation=list(target.position),new_translation=[0,.3765999973,0],flags=changes,full_decoder_roundtrip=True,decoded_size_unchanged=len(source)==len(data),original_fmsh_preserved=native.parse(result)['fmsh']==info['fmsh'],hypothesis='Main ControlStick Skl_Root zero may override matching kart submodel Skl_Root; testing height restoration, not established until visual comparison.',limits=['Stock ControlStick visuals remain for comparison','No geometry, physics, seat or animation clip edits'])
 (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
