#!/usr/bin/env python3
"""Prepare scalar-only Cart constraint trials; never changes extracted input."""
from pathlib import Path
import hashlib,json,struct,sys
from inspect_native_rider import sarc,byml
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/kart-assets/python'))
import zstandard as zstd

def scalar_offsets(data):
 def word(o):return struct.unpack_from('<I',data,o)[0]
 def count(o):return int.from_bytes(data[o+1:o+4],'little')
 def strings(o):return [data[o+word(o+4+4*i):data.index(0,o+word(o+4+4*i))].decode()for i in range(count(o))]
 keys=strings(word(4));result={}
 def walk(o,path):
  typ,n=data[o],count(o)
  if typ==0xc1:
   entries=[(path+(keys[int.from_bytes(data[o+4+8*i:o+7+8*i],'little')],),data[o+7+8*i],o+8+8*i)for i in range(n)]
  elif typ==0xc0:
   start=(o+4+n+3)&~3;entries=[(path+(i,),data[o+4+i],start+4*i)for i in range(n)]
  else:raise ValueError(hex(typ))
  for p,t,v in entries:
   if t in(0xc0,0xc1):walk(word(v),p)
   else:result[p]=(t,v)
 walk(word(12),());return result

def main():
 rom=ROOT/'extracted/totk/romfs';dic=sarc(zstd.ZstdDecompressor().decompress((rom/'Pack/ZsDic.pack.zs').read_bytes()))['pack.zsdic'];zd=zstd.ZstdCompressionDict(dic)
 src=rom/'Pack/Actor/SpObj_Cart_A_01.pack.zs';original=src.read_bytes();pack=zstd.ZstdDecompressor(dict_data=zd).decompress(original);members=sarc(pack)
 name='Phive/ConstraintControllerParam/SpObj_Cart_A_01.phive__ConstraintControllerParam.bgyml'
 member=members[name];before=byml(member);offsets=scalar_offsets(member)
 base=pack.find(member);assert base>=0 and pack.count(member)==1
 for mode in ['no-auto-ground-joints','zero-ground-forces']:
  changes={('ManualJointParam','SliderArray',0,'IsAutoConnect'):False,('ManualJointParam','SpringDamperArray',0,'IsAutoConnect'):False}
  if mode=='zero-ground-forces':
   pre=('ManualJointParam','SliderArray',0,'SliderParam')
   changes.update({pre+('EnableMotor',):False,pre+('MotorForce',):0.0,pre+('MotorVelocity',):0.0})
   pre=('ManualJointParam','SpringDamperArray',0,'SpringDamperParam')
   for group in ['AngularDampings','AngularForceLimitsMax','AngularForceLimitsMin','AngularStiffnesses','LinearDampings','LinearForceLimitsMax','LinearForceLimitsMin','LinearStiffnesses']:
    for axis in ['X','Y','Z']:changes[pre+(group,axis)]=0.0
  patched=bytearray(member);expected=json.loads(json.dumps(before));records=[]
  for path,value in changes.items():
   typ,pos=offsets[path];assert typ==(0xd0 if isinstance(value,bool) else 0xd2)
   obj=expected
   for key in path[:-1]:obj=obj[key]
   previous=obj[path[-1]];obj[path[-1]]=value
   struct.pack_into('<I'if typ==0xd0 else'<f',patched,pos,int(value)if typ==0xd0 else value)
   records.append({'path':list(path),'previous':previous,'candidate':value,'member_offset':pos})
  assert byml(patched)==expected
  candidate=bytearray(pack);candidate[base:base+len(member)]=patched
  assert len(candidate)==len(pack);assert sarc(candidate)[name]==patched
  output=zstd.ZstdCompressor(level=19,dict_data=zd).compress(candidate)
  assert zstd.ZstdDecompressor(dict_data=zd).decompress(output)==candidate
  out=ROOT/'assets/cart-physics-trials'/mode;dst=out/'romfs/Pack/Actor/SpObj_Cart_A_01.pack.zs';dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(output)
  report={'status':'Offline scalar-only physics trial; runtime untested.','source_sha256':hashlib.sha256(original).hexdigest(),'candidate_sha256':hashlib.sha256(output).hexdigest(),'source_decoded_bytes':len(pack),'candidate_decoded_bytes':len(candidate),'member':name,'changes':records,'dictionary_sha256':hashlib.sha256(dic).hexdigest(),'sarc_members_unchanged':set(sarc(candidate))==set(members),'allocation':'Decoded pack size and every member size unchanged.','limits':'Native Cart AI may reconnect or reconfigure these named constraints. Static configuration does not prove stable motion or steering.'}
  (out/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
  print(mode,len(records),'scalar changes;',len(output),'compressed bytes')
if __name__=='__main__':main()
