#!/usr/bin/env python3
"""Match native Cart contact hulls to the recovered source neutral tire pose.

Keeps the proven native host, hull topology and materials. Optional chassis,
seat and native Cart dynamics changes are recorded explicitly in validation.
"""
from pathlib import Path
import argparse,copy,hashlib,json,struct,sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/kart-assets/python'))
import numpy as np
import zstandard as zstd
from inspect_native_rider import sarc,byml
from build_native_mount_submodel import pack_sarc
from build_cart_physics_trial import scalar_offsets
import kart_assets_native_cart as n
OUT=ROOT/'assets/source-native-contacts'

def v(d):return np.array([d[a]for a in 'XYZ'],dtype=float)
def d(a):return dict(zip('XYZ',map(float,a)))
def inertia_scaled(t,s):
 x,y,z=t;var=np.array([y+z-x,x+z-y,x+y-z])/2*s*s
 return np.array([var[1]+var[2],var[0]+var[2],var[0]+var[1]])
def main():
 global OUT
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--raised-chassis',action='store_true');parser.add_argument('--saddle-height',type=float,default=.5);parser.add_argument('--saddle-forward',type=float,default=0.0);parser.add_argument('--cart-dynamics',action='store_true');args=parser.parse_args()
 assert .5<=args.saddle_height<=1.0
 if args.raised_chassis:OUT=ROOT/'assets/source-native-contacts-raised-chassis'
 if args.saddle_height!=.5:OUT=OUT.with_name(OUT.name+'-seat-%03d'%round(args.saddle_height*100))
 if args.cart_dynamics:OUT=OUT.with_name(OUT.name+'-cart-dynamics')
 if args.saddle_forward!=0:OUT=OUT.with_name(OUT.name+'-fwd%03d'%round(args.saddle_forward*100))
 base=ROOT/'assets/native-mount-cart-physics';rel='Pack/Actor/SpObj_ControlStick_A_01.pack.zs'
 dictionaries=sarc(zstd.ZstdDecompressor().decompress((ROOT/'extracted/totk/romfs/Pack/ZsDic.pack.zs').read_bytes()));dic=zstd.ZstdCompressionDict(dictionaries['pack.zsdic'])
 original=(base/'romfs'/rel).read_bytes();raw=zstd.ZstdDecompressor(dict_data=dic).decompress(original);members=sarc(raw)
 seat_key='Component/RidableParam/SpObj_ControlStick_A_01.game__component__RidableParam.bgyml'
 if args.saddle_height!=.5:
  seat=bytearray(members[seat_key]);typ,at=scalar_offsets(seat)[('Seats',0,'SaddleOffset','Y')];assert typ==0xd2 and struct.unpack_from('<f',seat,at)[0]==.5
  struct.pack_into('<f',seat,at,args.saddle_height);members[seat_key]=bytes(seat)
 if args.saddle_forward!=0:
  # Root_Stand (the saddle bone) is 0.7 behind the kart origin; the Mario kart's seat back is at Z~-0.5,
  # so the rider must sit forward of it.
  seat=bytearray(members[seat_key]);typ,at=scalar_offsets(seat)[('Seats',0,'SaddleOffset','Z')];assert typ==0xd2 and struct.unpack_from('<f',seat,at)[0]==0.0
  struct.pack_into('<f',seat,at,args.saddle_forward);members[seat_key]=bytes(seat)
 entity_key='Phive/RigidBodyEntityParam/SpObj_ControlStick_A_01_Physical.phive__RigidBodyEntityParam.bgyml'
 dynamics=None
 if args.cart_dynamics:
  src=(ROOT/'.work/kart-runtime/cart-pack/Phive/RigidBodyEntityParam/SpObj_Cart_A_01.phive__RigidBodyEntityParam.bgyml').read_bytes();cart=byml(src);entity=bytearray(members[entity_key]);old_entity=byml(entity)
  assert old_entity['MotionType']==cart['MotionType']=='Dynamic' and old_entity['ShapeName']==cart['ShapeName']=='Physical'
  members[entity_key]=src
  dynamics=dict(source='Exact original native Cart rigid-body parameters',source_sha256=hashlib.sha256(src).hexdigest(),before=old_entity,after=cart,original_decoded_bytes=len(entity),candidate_decoded_bytes=len(src))
 key='Phive/ShapeParam/SpObj_ControlStick_A_01__Physical.phive__ShapeParam.bgyml';old=members[key];shape=copy.deepcopy(byml(old));before=copy.deepcopy(shape)
 probe=json.loads((ROOT/'assets/source-native-placement/native-probe.json').read_text());wheels={w['name']:w for w in probe['wheels']}
 # Source model-local bounds are measured from the actual tire LOD1 vertices.
 import io
 tire=n.k.ResFile(io.BytesIO((ROOT/'assets/standard-kart/source/TireK_Std.bfres').read_bytes()));model=list(tire.models.values())[0]
 shapes={name:i for i,name in enumerate(['LB','LF','RB','RF'])};records=[]
 for i,h in enumerate(shape['Polytope'][1:],1):
  offset=v(h['OffsetTranslation']);name=('L'if offset[0]>0 else'R')+('F'if offset[2]>0 else'B');wheel=wheels[name]
  p=n.source_lod(model,shapes[name],1,1,0)['p']*.16*np.array(wheel['render_scale'])
  lo,hi=p.min(0),p.max(0);half=(hi-lo)/2;center=(lo+hi)/2
  verts=np.array([v(x)for x in h['Vertices']]);native_half=(verts.max(0)-verts.min(0))/2;s=half/native_half
  target=np.array(wheel['render_center'])*.16+np.array([0,.3765999973,0])+center
  h['OffsetTranslation']=d(target)
  h['Vertices']=[d(v(x)*s)for x in h['Vertices']]
  a=h['AutoCalc']
  for field in ['Center','Min','Max']:a[field]=d(v(a[field])*s)
  a['Tensor']=d(inertia_scaled(v(a['Tensor']),s));a['Volume']*=float(np.prod(s))
  records.append(dict(name=name,native_contact=offset.tolist(),target_contact=target.tolist(),visual_center=(target-center).tolist(),visual_bounds_relative=[lo.tolist(),hi.tolist()],scale=s.tolist()))
 chassis_change=None
 if args.raised_chassis:
  h=shape['Polytope'][0];verts=np.array([v(x)for x in h['Vertices']]);lo=verts.min(0);hi=verts.max(0)
  # Simplified chassis envelope inside the imported lower body. The original
  # 3.7-unit platform overhangs the recovered 1.4-unit axle spacing and catches
  # slopes. Keep native bevel topology/material, with a narrower/higher belly.
  target_lo=np.array([-.70,.30,-1.25]);target_hi=np.array([.70,.60,1.35]);s=(target_hi-target_lo)/(hi-lo)
  translation=(target_lo+target_hi)/2-(lo+hi)/2*s
  old_offset=v(h['OffsetTranslation']);h['OffsetTranslation']=d(translation)
  h['Vertices']=[d(v(x)*s)for x in h['Vertices']]
  a=h['AutoCalc']
  for field in ['Center','Min','Max']:a[field]=d(v(a[field])*s)
  a['Tensor']=d(inertia_scaled(v(a['Tensor']),s));a['Volume']*=float(np.prod(s))
  chassis_change=dict(old_offset=old_offset.tolist(),scale=s.tolist(),new_offset=translation.tolist(),world_bounds=[target_lo.tolist(),target_hi.tolist()],kind='Authored simplified collision envelope, not source-game collision recovery')
 # Recompute aggregate center, bounds and diagonal inertia using the same
 # retained per-hull local metadata and volume weighting as the source table.
 hulls=shape['Polytope'];weights=np.array([h['AutoCalc']['Volume']for h in hulls]);centers=np.array([v(h['OffsetTranslation'])+v(h['AutoCalc']['Center'])for h in hulls]);total=weights.sum();center=(centers*weights[:,None]).sum(0)/total
 tensors=[]
 for h,c in zip(hulls,centers):
  delta=c-center;tensors.append(v(h['AutoCalc']['Tensor'])+np.dot(delta,delta)-delta*delta)
 aggregate=shape['AutoCalc'];aggregate['Center']=d(center);aggregate['Min']=d(np.min([v(h['OffsetTranslation'])+v(h['AutoCalc']['Min'])for h in hulls],axis=0));aggregate['Max']=d(np.max([v(h['OffsetTranslation'])+v(h['AutoCalc']['Max'])for h in hulls],axis=0));aggregate['Volume']=float(total);aggregate['Tensor']=d((np.array(tensors)*weights[:,None]).sum(0)/total)
 payload=bytearray(old);offsets=scalar_offsets(old);changes=[]
 for path,(typ,at)in offsets.items():
  a=before;b=shape
  for component in path:a=a[component];b=b[component]
  if a==b:continue
  assert typ==0xd2,(path,typ);struct.pack_into('<f',payload,at,b);changes.append(list(path))
 check=byml(payload)
 for h in check['Polytope']:assert h['AutoCalc']['Volume']>0
 assert len(payload)==len(old);assert args.raised_chassis or check['Polytope'][0]==before['Polytope'][0]
 members[key]=bytes(payload);packed=pack_sarc(members);assert len(packed)<=len(raw)
 compressed=zstd.ZstdCompressor(level=19,dict_data=dic).compress(packed);assert sarc(zstd.ZstdDecompressor(dict_data=dic).decompress(compressed))==members
 target=OUT/'romfs'/rel;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(compressed)
 table='System/Resource/ResourceSizeTable.Product.110.rsizetable.zs';dest=OUT/'romfs'/table;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes((base/'romfs'/table).read_bytes())
 report=dict(status='Offline source wheel contact candidate; runtime untested',candidate_sha256=hashlib.sha256(compressed).hexdigest(),source_sha256=hashlib.sha256(original).hexdigest(),modified_members=[key]+([seat_key]if args.saddle_height!=.5 or args.saddle_forward!=0 else[])+([entity_key]if args.cart_dynamics else[]),cart_dynamics=dynamics,saddle_offset_y=args.saddle_height,saddle_offset_z=args.saddle_forward,source_native_probe_sha256=hashlib.sha256((ROOT/'assets/source-native-placement/native-probe.json').read_bytes()).hexdigest(),wheel_contacts=records,typed_float_changes=len(changes),decoded_allocation_unchanged=True,original_pack_decoded_bytes=len(raw),candidate_pack_decoded_bytes=len(packed),resource_table_capacities_unchanged=True,chassis_hull_byte_semantics_unchanged=not args.raised_chassis,chassis_envelope=chassis_change,contact_materials_preserved=True,validation=['SARC and dictionary compression exact roundtrip','Only one actor member modified','BYML edits restricted to known float locations; header/topology/materials unchanged','Native AI and attention preserved; saddle/dynamics changes recorded explicitly','Existing resource table capacities retained'],limits=['Neutral static wheel pose; dynamic suspension/steering/spin not implemented','Chassis collision is a simplified envelope, not an exact mesh collision','Changes all ControlStick actors in this isolated experimental mod','Switch hardware not tested'])
 (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n');(OUT/'shape-decoded.json').write_text(json.dumps(check,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
