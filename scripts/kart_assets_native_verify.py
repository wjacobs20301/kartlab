#!/usr/bin/env python3
"""Read the independently decoded native kart and inspect actual bound geometry."""
import argparse,json, pathlib,sys,io,os
os.environ.setdefault('MPLCONFIGDIR','/private/tmp/kart-assets-matplotlib')
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
import kart_assets_native_cart as native
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--refined',action='store_true');args=parser.parse_args()
k=native.k;out=k.ROOT/('assets/native-cart-mod-refined' if args.refined else 'assets/native-cart-mod')
data=(out/'decoded-check'/native.HOST.removesuffix('.mc')).read_bytes()
r=native.parse_host(data);model=list(r.models.values())[0];shape=list(model.shapes.values())[0]
at=k.attributes(shape.vtx_buffer)
bones=[]
for b in model.skeleton.bones.values():
 position=np.array(b.position)+(bones[b.parent_idx]if b.parent_idx>=0 else np.zeros(3));bones.append(position)
rigid=at['_i0'][:,0].astype(int);assert rigid.min()>=0 and rigid.max()<len(model.skeleton.mtx_to_bone_list)
world=at['_p0'][:,:3]+np.array([bones[model.skeleton.mtx_to_bone_list[idx]]for idx in rigid])
fig=plt.figure(figsize=(12,7),facecolor='#14202c');results=[]
for li,mesh in enumerate(shape.meshes):
 idx=np.frombuffer(mesh.index_buffer.data[0],dtype='<u2').reshape(-1,3)+mesh.first_vtx
 p=world[idx];area=np.linalg.norm(np.cross(p[:,1]-p[:,0],p[:,2]-p[:,0]),axis=1)
 good=area>1e-10;p=p[good];actualidx=idx[good]
 assert idx.max()<shape.vtx_buffer.vtx_count
 ax=fig.add_subplot(1,2,li+1,projection='3d',facecolor='#14202c')
 colors=np.array([[.63,.68,.67,1.]if np.all(rigid[i]==0)else [.16,.20,.22,1.]for i in actualidx])
 face_norm=np.cross(p[:,1]-p[:,0],p[:,2]-p[:,0]);face_norm/=np.linalg.norm(face_norm,axis=1)[:,None]
 light=np.array([.3,.8,.5]);light/=np.linalg.norm(light)
 colors[:,:3]*=(.4+.6*np.maximum(face_norm@light,0))[:,None]
 poly=Poly3DCollection(p[:,:,[0,2,1]],facecolors=colors,edgecolors='none');ax.add_collection3d(poly)
 ax.set_xlim(-1.7,1.7);ax.set_ylim(-1.4,2.0);ax.set_zlim(-.4,1.8);ax.set_box_aspect([1,1,.65]);ax.view_init(elev=21,azim=48);ax.set_axis_off()
 ax.set_title(f"LOD {li} · {len(p):,} non-degenerate triangles",color='white',size=12)
 results.append({'lod':li,'nondegenerate_triangles':len(p),'bounds_world':[p.reshape(-1,3).min(axis=0).tolist(),p.reshape(-1,3).max(axis=0).tolist()]})
fig.text(.05,.94,'NATIVE CART / KART GEOMETRY CANDIDATE',color='white',weight='bold',size=19)
fig.text(.05,.88,'Parsed from the independently decoded replacement package. Native wheel bones retained.',color='#a8bfcc',size=11)
fig.text(.05,.10,'Offline geometry preview with neutral illustrative colors. Game shading and gameplay remain untested.',color='#a8bfcc',size=10)
fig.subplots_adjust(left=.03,right=.97,bottom=.15,top=.83,wspace=.02)
fig.savefig(out/'geometry-preview.png',dpi=160,facecolor=fig.get_facecolor(),bbox_inches='tight');plt.close()
report=json.loads((out/'validation.json').read_text());report['parsed_native_geometry']=results
(out/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(results))
