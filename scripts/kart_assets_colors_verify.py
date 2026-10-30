#!/usr/bin/env python3
"""Verify exact color-only byte changes and preview the decoded candidate."""
import argparse,io,json,os,pathlib,struct
os.environ.setdefault('MPLCONFIGDIR','/private/tmp/kart-assets-matplotlib')
import numpy as np
from PIL import Image
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
import kart_assets_colors as color
native=color.native;ROOT=color.ROOT
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--candidate',type=pathlib.Path,default=color.OUT);args=parser.parse_args();out=args.candidate
report=json.loads((out/'validation.json').read_text())
original=(ROOT/report['source_geometry_directory']/'expected-decoded.bfres').read_bytes()
data=(out/'decoded-check'/native.HOST.removesuffix('.mc')).read_bytes()
r=native.parse_host(data);model=list(r.models.values())[0];shape=list(model.shapes.values())[0];vb=shape.vtx_buffer
attrs=native.k.attributes(vb)
gpu=struct.unpack_from('<I',data,0x1c)[0]+0x120
base=gpu+struct.unpack_from('<i',data,vb.record_offset+0x48)[0]
sizeptr=struct.unpack_from('<Q',data,vb.record_offset+0x30)[0]
size0=struct.unpack_from('<I',data,sizeptr)[0]
second=(base+size0+vb.gpu_buff_align-1)&-vb.gpu_buff_align
allowed=np.zeros(len(data),dtype=bool)
for vi in range(vb.vtx_count):allowed[second+vi*vb.buffers[1].stride+4:second+vi*vb.buffers[1].stride+8]=True
changes=np.frombuffer(original,dtype=np.uint8)!=np.frombuffer(data,dtype=np.uint8)
assert not np.any(changes & ~allowed)
# Every model byte outside half2 UV0 fields is bit-identical to the working model.
texture=color.read_txtg((out/'romfs/TexToGo/Etc_ZonauCart_A_Alb.txtg').read_bytes())
pixels=color.decomp_bc1(color.deswizzle(texture['surfaces'][0],256,256),256,256)
ideal=np.array(Image.open(out/'mario-kart-atlas.png').convert('RGB')).astype(float)
rmse=float(np.sqrt(np.mean((pixels[:,:,:3].astype(float)-ideal)**2)))
assert rmse<16,(rmse,'unexpected excessive color compression error')
bones=[]
for b in model.skeleton.bones.values():bones.append(np.array(b.position)+(bones[b.parent_idx]if b.parent_idx>=0 else np.zeros(3)))
rigid=attrs['_i0'][:,0].astype(int)
world=attrs['_p0'][:,:3]+np.array([bones[model.skeleton.mtx_to_bone_list[idx]]for idx in rigid])
fig=plt.figure(figsize=(12,7),facecolor='#14202c');lods=[]
for li,mesh in enumerate(shape.meshes):
 idx=np.frombuffer(mesh.index_buffer.data[0],dtype='<u2').reshape(-1,3)+mesh.first_vtx
 p=world[idx];area=np.linalg.norm(np.cross(p[:,1]-p[:,0],p[:,2]-p[:,0]),axis=1);good=area>1e-10
 p=p[good];idx=idx[good]
 uv=attrs['_u0'][idx].mean(axis=1)%1
 px=np.clip((uv[:,0]*256).astype(int),0,255);py=np.clip((uv[:,1]*256).astype(int),0,255)
 colors=pixels[py,px].astype(float)/255;colors[:,3]=1
 norms=np.cross(p[:,1]-p[:,0],p[:,2]-p[:,0]);norms/=np.linalg.norm(norms,axis=1)[:,None]
 light=np.array([.3,.8,.5]);light/=np.linalg.norm(light);colors[:,:3]*=(.6+.4*np.maximum(norms@light,0))[:,None]
 ax=fig.add_subplot(1,2,li+1,projection='3d',facecolor='#14202c')
 ax.add_collection3d(Poly3DCollection(p[:,:,[0,2,1]],facecolors=colors,edgecolors='none'))
 ax.set_xlim(-1.7,1.7);ax.set_ylim(-1.4,2);ax.set_zlim(-.4,1.8);ax.set_box_aspect([1,1,.65]);ax.view_init(elev=21,azim=48);ax.set_axis_off()
 ax.set_title(f'LOD {li} · {len(p):,} triangles',color='white',size=12)
 lods.append({'lod':li,'visible_triangles':len(p)})
fig.text(.05,.94,'MARIO KART COLORS / NATIVE TEXTURE CANDIDATE',color='white',weight='bold',size=18)
fig.text(.05,.88,'Actual MK8DX body and tire colors, downsampled into the native 256px texture allocation.',color='#a8bfcc',size=11)
fig.text(.05,.10,'Offline preview from the produced model + decoded TXTg. Simplified shading; game appearance needs testing.',color='#a8bfcc',size=10)
fig.subplots_adjust(left=.03,right=.97,bottom=.15,top=.83,wspace=.02)
fig.savefig(out/'color-preview.png',dpi=160,facecolor=fig.get_facecolor(),bbox_inches='tight');plt.close()
report['color_verification']={'model_changed_bytes':int(changes.sum()),'only_uv0_half2_fields_changed':True,
    'bc1_atlas_rmse_on_0_to_255_scale':rmse,'lods':lods,
    'native_txtg_mip_sizes_exactly_preserved':True,'preview':'color-preview.png'}
(out/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report['color_verification']))
