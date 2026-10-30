#!/usr/bin/env python3
"""Validate exported glTF buffers and render an offline source-model preview."""
import json,pathlib, numpy as np
from PIL import Image
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/standard-kart'
g=json.loads((OUT/'standard-kart.gltf').read_text());blob=(OUT/g['buffers'][0]['uri']).read_bytes()
assert len(blob)==g['buffers'][0]['byteLength']
def read(idx):
 a=g['accessors'][idx];v=g['bufferViews'][a['bufferView']];width={'SCALAR':1,'VEC2':2,'VEC3':3}[a['type']]
 dt='<u4' if a['componentType']==5125 else '<f4'
 data=np.frombuffer(blob,dtype=dt,count=a['count']*width,offset=v.get('byteOffset',0)+a.get('byteOffset',0)).reshape(-1,width)
 assert np.isfinite(data).all();return data
fig=plt.figure(figsize=(11,8),facecolor='#14202c');ax=fig.add_subplot(projection='3d',facecolor='#14202c')
allpos=[];triangles=0
for i,node in enumerate(g['nodes']):
 if 'mesh' not in node:continue
 parent=next(n for n in g['nodes'] if i in n.get('children',[]))
 translation=np.array(parent.get('translation',[0,0,0]))
 mesh=g['meshes'][node['mesh']];p=mesh['primitives'][0]
 pos=read(p['attributes']['POSITION'])+translation;indices=read(p['indices']).reshape(-1,3)
 assert indices.max()<len(pos)
 uv=read(p['attributes']['TEXCOORD_0'])
 texidx=g['materials'][p['material']]['pbrMetallicRoughness']['baseColorTexture']['index']
 imageuri=g['images'][g['textures'][texidx]['source']]['uri'];im=np.array(Image.open(OUT/imageuri))/255
 centeruv=uv[indices].mean(axis=1)%1
 px=np.clip((centeruv[:,0]*im.shape[1]).astype(int),0,im.shape[1]-1)
 py=np.clip((centeruv[:,1]*im.shape[0]).astype(int),0,im.shape[0]-1)
 colors=im[py,px];colors[:,3]=1
 # Draw source Y-up as plot Z-up; axes retain original labels.
 plotpos=pos[:,[0,2,1]]
 poly=Poly3DCollection(plotpos[indices],facecolors=colors,edgecolors='none',shade=False)
 ax.add_collection3d(poly);allpos.append(plotpos);triangles+=len(indices)
positions=np.concatenate(allpos);lo=positions.min(axis=0);hi=positions.max(axis=0);middle=(lo+hi)/2;radius=max(hi-lo)/2*1.08
ax.set_xlim(middle[0]-radius,middle[0]+radius);ax.set_ylim(middle[1]-radius,middle[1]+radius);ax.set_zlim(middle[2]-radius,middle[2]+radius)
ax.set_box_aspect([1,1,1]);ax.view_init(elev=23,azim=48);ax.set_axis_off()
fig.text(.06,.92,'STANDARD KART / SOURCE MODEL',color='white',size=20,weight='bold')
fig.text(.06,.87,'Mario Kart 8 Deluxe · body + four standard tires · 2,889 triangles',color='#a8bfcc',size=11)
fig.text(.06,.08,'Offline conversion preview. Original wheel rest transforms. No TOTK gameplay is shown.',color='#a8bfcc',size=10)
plt.savefig(OUT/'source-preview.png',dpi=160,facecolor=fig.get_facecolor(),bbox_inches='tight');plt.close()
print(json.dumps({'meshes_checked':len(g['meshes']),'triangles':triangles,'buffer_bytes':len(blob),'bounds_source_xyz':[positions[:,[0,2,1]].min(axis=0).tolist(),positions[:,[0,2,1]].max(axis=0).tolist()]}))
