#!/usr/bin/env python3
"""Offline parameter study, explicitly NOT a verified native mod candidate.

Compares the decoded BODY tire endpoints with one nominal type-1 spring state.
This makes the remaining placement question visible without touching a mod.
"""
import json, pathlib, shutil
import numpy as np
from PIL import Image
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from kart_assets_parts_placement import inspect
ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT/'assets/source-placement-study'

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    src = ROOT/'assets/standard-kart'
    g = json.loads((src/'standard-kart.gltf').read_text())
    blob = (src/'standard-kart.bin').read_bytes()
    parts = inspect()['combined']
    # Native initial spring parameters for the investigated normal type-1
    # branch imply rest length 3.5, stiffness .1, damping .9, gravity .15.
    # The final constructor selection and model origin still need corroboration.
    spring = np.float32(3.5); delta = np.float32(0); velocity = np.float32(0)
    history = []
    for _ in range(100):
        spring = np.float32(np.clip(np.float32(spring + delta), 2., 3.5))
        damping = np.float32(.9 if delta >= 0 else .3)
        velocity = np.float32(-((spring - np.float32(3.5)) * np.float32(.1)) - delta*damping - np.float32(.15))
        delta = np.float32(delta + velocity)
        history.append(float(spring))
    for node in g['nodes']:
        name = node.get('name', '')
        if name in ['TireK_LF', 'TireK_RF', 'TireK_LB', 'TireK_RB']:
            front = name[-1] == 'F'; sign = 1 if '_L' in name else -1
            endpoint = np.array(parts['front_tire_suspension_endpoint' if front else 'back_tire_suspension_endpoint'])
            endpoint[0] *= sign; endpoint[1] -= spring
            node['translation'] = endpoint.tolist()
            node['scale'] = parts['front_tire_scale' if front else 'back_tire_scale']
    g['asset']['generator'] = 'kart_assets_placement_study.py; unverified nominal suspension study'
    (OUT/'standard-kart.gltf').write_text(json.dumps(g, indent=2)+'\n')
    (OUT/'standard-kart.bin').write_bytes(blob)
    (OUT/'textures').mkdir(exist_ok=True)
    for name in ['BodyK_Std_Mro_Alb.png', 'Tire_Std_Alb.png']:
        shutil.copyfile(src/'textures'/name, OUT/'textures'/name)
    report = dict(installed=False, native_candidate=False, status='REJECTED PARAMETER STUDY',
        source_settings='research/kart-source-placement.json',
        spring_settled_after_100=float(spring), spring_history=history,
        proven=['BODY/BDTR flag-selected suspension endpoints',
                'TRBD applies rear tire scale (1.4,1.3,1.3), front remains (1,1,1)'],
        rejection_reason='Later native trace proves standard kart uses derived suspension strategy 2, not strategy 1. The omitted axial/model transform step invalidates these direct preview centers. Wheels also visibly tuck into the body.',
        assumptions=['standard constructor branch selects rest 3.5/stiffness .1/damping .9 (unverified)',
                     'cart and wheel model frames share the preview origin',
                     'normal steady suspension state may be used for a static preview'],
        limitation='These assumptions must be resolved before rebinding native wheel bones or changing physics.')
    (OUT/'validation.json').write_text(json.dumps(report, indent=2)+'\n')
    def read(idx):
        ac=g['accessors'][idx]; view=g['bufferViews'][ac['bufferView']]
        width={'SCALAR':1,'VEC2':2,'VEC3':3}[ac['type']]
        return np.frombuffer(blob,dtype='<u4' if ac['componentType']==5125 else '<f4',
            count=ac['count']*width,offset=view.get('byteOffset',0)).reshape(-1,width)
    fig=plt.figure(figsize=(10,7),facecolor='#14202c');ax=fig.add_subplot(projection='3d',facecolor='#14202c')
    positions=[]
    for i,node in enumerate(g['nodes']):
        if 'mesh' not in node:continue
        parent=next(n for n in g['nodes'] if i in n.get('children',[]))
        p=g['meshes'][node['mesh']]['primitives'][0]
        pos=read(p['attributes']['POSITION'])*parent.get('scale',[1,1,1])+parent.get('translation',[0,0,0])
        inds=read(p['indices']).reshape(-1,3);uv=read(p['attributes']['TEXCOORD_0'])
        im=np.array(Image.open(OUT/'textures'/('BodyK_Std_Mro_Alb.png' if p['material']==0 else 'Tire_Std_Alb.png')))/255
        cuv=uv[inds].mean(1)%1;colors=im[(cuv[:,1]*im.shape[0]).astype(int),(cuv[:,0]*im.shape[1]).astype(int)]
        q=pos[:,[0,2,1]];positions.append(q)
        ax.add_collection3d(Poly3DCollection(q[inds],facecolors=colors,edgecolors='none'))
    allp=np.concatenate(positions);mid=(allp.min(0)+allp.max(0))/2;r=np.ptp(allp,axis=0).max()*.54
    ax.set_xlim(mid[0]-r,mid[0]+r);ax.set_ylim(mid[1]-r,mid[1]+r);ax.set_zlim(mid[2]-r,mid[2]+r)
    ax.set_box_aspect([1,1,1]);ax.view_init(elev=23,azim=48);ax.set_axis_off()
    fig.text(.05,.93,'SOURCE PLACEMENT STUDY / REJECTED',color='white',size=17,weight='bold')
    fig.text(.05,.87,'Exact Parts endpoints + rear scaling; nominal spring state. No installed files changed.',color='#a8bfcc',size=9)
    fig.text(.05,.06,'Remaining question: source model frames and selected spring constructor. This is not an installation candidate.',color='#a8bfcc',size=9)
    fig.savefig(OUT/'study-preview.png',dpi=150,bbox_inches='tight',facecolor=fig.get_facecolor());plt.close(fig)
    print(json.dumps(dict(out=str(OUT), nominal_spring_length=float(spring))))

if __name__=='__main__':main()
