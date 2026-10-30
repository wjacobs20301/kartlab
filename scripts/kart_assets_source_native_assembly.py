#!/usr/bin/env python3
"""Add actual missing normal suspension arms and preserve native wheel centers.

Source BODY/TireShaftTransform anchors establish which body points the arms join.
Arm geometry is explicitly adapted between those source-derived body anchors and
TOTK's unchanged native wheel centers, without moving wheel bones or collision.
"""
from __future__ import annotations
import hashlib,io,json,pathlib,struct,subprocess,sys
import numpy as np
from PIL import Image
import kart_assets_colors as color
n=color.native;k=n.k;ROOT=k.ROOT
GEOMETRY=ROOT/'assets/source-native-assembly-geometry'
OUT=ROOT/'assets/source-native-assembly-mod'


def read_parts():
    path=ROOT/'extracted/mk8dx/romfs/Common/Mush/Parts.bin';data=path.read_bytes()
    assert data[:4]==b'STRP';size,count,hs,version=struct.unpack_from('<IHHI',data,4)
    assert size==len(data) and hs==16+count*4 and version==1000
    starts=[hs+x for x in struct.unpack_from('<'+str(count)+'I',data,16)]
    sections={}
    for start,end in zip(starts,starts[1:]+[len(data)]):
        magic,rows,repeat,reserved,parameter=struct.unpack_from('<4sHHII',data,start)
        sections[magic[::-1].decode()]={'offset':start,'end':end,'rows':rows,'repeat':repeat}
    body=sections['BODY'];assert (body['end']-body['offset']-16)//body['rows']==320
    first=body['offset']+16
    front=struct.unpack_from('<3f',data,first+0xa0);back=struct.unpack_from('<3f',data,first+0xc4)
    assert np.allclose(front,[2.1,-.1,5.6])and np.allclose(back,[2.18,.34,-3.2])
    return {'source':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(data).hexdigest(),
        'body_row':0,'record_offset':first,'record_bytes':320,
        'front_shaft_anchor':list(front),'back_shaft_anchor':list(back),
        'front_anchor_record_offset':'0xa0','back_anchor_record_offset':'0xc4',
        'field_interpretation_source':'https://github.com/KillzXGaming/MK8-Parts-Bin-Converter/blob/master/PartsLibrary/PartObjects/BodyObject/TireShaftTransform.cs',
        'interpretation_boundary':'Named field mapping from primary parser source. Complete source-game tire-placement equations not recovered.'}


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    parts=read_parts()
    arm_path=ROOT/'extracted/mk8dx/romfs/Kart/Arm/ArmK_Std.szs'
    original=arm_path.read_bytes();decoded=k.decompress(io.BytesIO(original)).getvalue()
    arm_resource=k.ResFile(io.BytesIO(decoded));arms=list(arm_resource.models.values())[1]
    assert arms.name=='ArmK_StdN'
    outsource=OUT/'source';outsource.mkdir(exist_ok=True);(outsource/'ArmK_Std.bfres').write_bytes(decoded)
    bntx=next(e for name,e in arm_resource.external_files.items()if name.endswith('.bntx'))
    (outsource/'ArmK_Std.bntx').write_bytes(bntx.data)
    textures=k.BNTX(io.BytesIO(bntx.data));tex=next(t for t in textures.nx.textures if t.name=='ArmK_StdN_Alb')
    arm_image=Image.fromarray(np.asarray(tex.pixels).astype(np.uint8)).convert('RGB');arm_image.save(OUT/'ArmK_StdN_Alb.png')
    mapping=[3,1,4,2] # LB LF RB RF source order ->native matrix IDs
    probe=json.loads((ROOT/'assets/source-native-placement/native-probe.json').read_text())
    assert probe['indices']=={'body':0,'tire':0} and len(probe['wheels'])==4
    wheel_by_matrix={i+1:w for i,w in enumerate(probe['wheels'])}
    body_translation=np.array(probe['body_translation'])*.16
    targets={i:np.array(w['render_center'])*.16+np.array([0,.3765999973,0])for i,w in wheel_by_matrix.items()}
    source_tip=float(k.attributes(list(arms.shapes.values())[0].vtx_buffer)['_p0'][:137,0].max())
    anchors=[];ranges={};arm_uv={}
    def arm_part(shape_idx,lod):
        matrix=mapping[shape_idx];is_front=matrix in (1,2);sign=1 if matrix in (1,3)else-1
        w=wheel_by_matrix[matrix]
        transform=np.array(w['normal_arm_matrix'][:9]).reshape(3,3).T
        translation=np.array(w['normal_arm_matrix'][9:12])
        anchor=translation*.16+np.array([0,.3765999973,0])
        target=targets[matrix]
        a=n.source_lod(arms,shape_idx,lod,1.,0)
        a['p']=(a['p']@transform.T+translation)*.16
        normal=a['n']@np.linalg.inv(transform)
        normal/=np.linalg.norm(normal,axis=1)[:,None];a['n']=normal
        span=target-anchor
        if lod==1:anchors.append({'source_shape':list(arms.shapes.values())[shape_idx].name,'matrix_axle':matrix,
            'body_anchor_world':anchor.tolist(),'native_axle_world':target.tolist(),'native_arm_matrix':w['normal_arm_matrix'],
            'native_inner_attachment':w['arm_inner_attachment'], 'source_pose':'Neutral native transform; not an arbitrary stretched shaft'})
        return a
    def geometry(bm,tm):
        highparts=[n.source_lod(bm,0,0,.16,0)]
        lowparts=[n.source_lod(bm,0,2,.16,0)]
        for arr in (highparts,lowparts):arr[0]['p']+=body_translation
        for i in range(4):
            matrix=mapping[i];scale=np.array(wheel_by_matrix[matrix]['render_scale'])
            tire=n.source_lod(tm,i,1,.16,matrix)
            tire['p']*=scale
            tire['n']/=scale;tire['n']/=np.linalg.norm(tire['n'],axis=1)[:,None]
            highparts.append(tire)
            low=n.low_wheel(matrix,5);low['p']*=.16/.14365*scale;lowparts.append(low)
        for key,lod,arr in [('high',1,highparts),('low',2,lowparts)]:
            start=sum(len(a['p'])for a in arr);newarms=[arm_part(i,lod)for i in range(4)]
            arm_uv[key]=np.concatenate([a['u']for a in newarms]);
            for a in newarms:a['u']=np.zeros_like(a['u'])
            arr.extend(newarms)
            ranges[key]=(start,sum(len(a['p'])for a in arr))
        return n.combine(highparts),n.combine(lowparts)
    armmeta={'source':str(arm_path.relative_to(ROOT)),'source_sha256':hashlib.sha256(original).hexdigest(),
        'normal_driving_model':arms.name,'antigravity_model':'ArmK_StdG intentionally excluded',
        'adaptation':'Neutral wheel and normal-arm matrices computed by isolated source ARM instructions, uniformly converted at0.16. No arbitrary shaft stretching.',
        'physics_boundary':'Matching wheel-bone and contact-hull edits are built separately by build_source_native_contacts.py; no installed file changed.'}
    n.build(out_override=GEOMETRY,geometry_override=geometry,report_extra={'parts_evidence':parts,'suspension':armmeta,
        'high_lod':'actual bodyLOD0 + actual tireLOD1 + actual normal-armLOD1',
        'low_lod':'actual bodyLOD2 + authored five-sided wheels + actual normal-armLOD2'})
    def make_atlas():
        atlas=color.atlas_image();tile=arm_image.resize((64,2),Image.Resampling.LANCZOS)
        for y in (194,196):
            for x in range(0,256,64):atlas.paste(tile,(x,y))
        atlas.paste(atlas.crop((0,194,256,196)),(0,198));return atlas
    def uv_arms(data):
        # Main shape GPU array layout is unchanged from the native Cart.
        resource=n.parse_host(bytes(data));shape=list(list(resource.models.values())[0].shapes.values())[0];vb=shape.vtx_buffer
        gpu=struct.unpack_from('<I',data,0x1c)[0]+0x120;vp=vb.record_offset
        base=gpu+struct.unpack_from('<i',data,vp+0x48)[0]
        sizes=struct.unpack_from('<Q',data,vp+0x30)[0];size0=struct.unpack_from('<I',data,sizes)[0]
        second=(base+size0+vb.gpu_buff_align-1)&-vb.gpu_buff_align
        changed=[]
        for li,key in enumerate(['high','low']):
            first=shape.meshes[li].first_vtx;start,end=ranges[key];uv=arm_uv[key]
            assert len(uv)==end-start
            assert uv.min()>=-1.001 and uv.max()<=2.501
            for i,x in enumerate(uv):
                # Actual 96px arm albedo reduced into a narrow native-size shelf.
                value=(((x[0]+1)*64+.5)/256,(194.5+x[1]*2)/256)
                struct.pack_into('<2e',data,second+(first+start+i)*vb.buffers[1].stride+4,*value)
            changed.append({'lod':li,'relative_vertex_range':[start,end],'absolute_vertex_range':[first+start,first+end]})
        return {'arm_uv_ranges':changed,'arm_albedo_shelf':'actual ArmK_StdN_Alb tiled4x2 at64x2 per tile across rows194..197'}
    color.OUT=OUT
    color.build(GEOMETRY,atlas_override=make_atlas,uv_override=uv_arms,report_extra={'parts_evidence':parts,'suspension':armmeta,
        'arm_connections':anchors,'actual_mesh_coverage':['entire bodyLOD0','four tireLOD1 meshes','four normal-armLOD1 meshes'],
        'known_source_omissions':['Mario emblem overlay from separate Emblem_Mro texture is not yet baked; no glider/antigravity models in ground kart.']})
    # Set native rigid wheel sockets to the executed source neutral centers.
    # There are no inverse skin matrices in this five-rigid-matrix skeleton.
    from kartbf.bfrespy.models.skeleton import Bone
    old_load=Bone.load
    def capture(self,loader):
        read=loader.read_vector3f;seen=[]
        def vector():
            at=loader.tell();value=read();seen.append(at);return value
        loader.read_vector3f=vector
        try:result=old_load(self,loader)
        finally:loader.read_vector3f=read
        self.position_offset=seen[-1];return result
    Bone.load=capture
    data=bytearray((OUT/'expected-decoded.bfres').read_bytes())
    model=list(n.parse_host(bytes(data)).models.values())[0];assert model.skeleton.num_smooth_mtxs==0
    bone_changes=[]
    for i in range(4):
        bone=model.skeleton.bones['Wheel_%02d'%i];target=np.array(wheel_by_matrix[i+1]['render_center'])*.16
        at=bone.position_offset;assert np.allclose(struct.unpack_from('<3f',data,at),bone.position)
        struct.pack_into('<3f',data,at,*target)
        bone_changes.append(dict(bone=bone.name,old=list(bone.position),new=target.tolist()))
    path=OUT/'romfs/Model'/n.HOST;info=n.parse(path.read_bytes());packed,_=n.pack(bytes(data),info['fmsh']);path.write_bytes(packed)
    (OUT/'expected-decoded.bfres').write_bytes(data)
    subprocess.run([str(ROOT/'.tools/kart-assets/MeshCodec/build/tests/mc_test'),str(path.parent),str(OUT/'decoded-check')],check=True)
    assert (OUT/'decoded-check'/n.HOST.removesuffix('.mc')).read_bytes()==data
    # Persist placement evidence after callbacks measured all endpoints.
    report=json.loads((OUT/'validation.json').read_text());report['arm_connections']=anchors;report['bone_changes']=bone_changes;report['model_compressed_sha256']=hashlib.sha256(packed).hexdigest();report['source_native_probe']='assets/source-native-placement/native-probe.json';report['source_body_translation']=body_translation.tolist();report['source_tire_scale']=.16;report['sockets_and_geometry_full_decoder_roundtrip']=True
    report['geometry_budget']=json.loads((GEOMETRY/'validation.json').read_text())['shapes'][0]['lods']
    report['limits'].extend(['Neutral source pose only: no independent animated wheel spin/steering or dynamic suspension.',
        'Native ControlStick host requires the raised-root model and matching steering-animation override.',
        'Wheel contact hulls must match these sockets before driving tests; see source-native-contact candidate.',
        'Source transform probe uses mocked neutral scene state and modeled math imports, not a running MK8DX scene.'])
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'candidate':str(OUT.relative_to(ROOT)),'arms':len(anchors),'source_tip_x':source_tip,'vertex_ranges':ranges}))

if __name__=='__main__':main()
