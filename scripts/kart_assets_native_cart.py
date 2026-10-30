#!/usr/bin/env python3
"""Build an experimental native Cart geometry swap, retaining TOTK materials.

Never modifies extracted input. Requires the decoded native model and local
MeshCodec dependencies documented in research/kart-assets.md. Geometry remains
within every original GPU allocation and every draw uses original bounds-safe
index buffers padded with degenerate triangles.
"""
from __future__ import annotations
import argparse, hashlib, io, json, math, pathlib, struct, sys, subprocess
import numpy as np
import kart_assets_export as k
ROOT=k.ROOT
sys.path.insert(0,str(ROOT/'.tools/kart-assets/totk-meshcodec'))
from mcpack import pack, parse, build_fmsh
from kartbf.bfrespy.switch.memory_pool import BufferTextureViewInfo
from kartbf.bfrespy.switch.model.model_parser import ModelParser
from kartbf.bfrespy.switch.model.shape_parser import ShapeParser
from kartbf.bfrespy.switch.model.vertex_buffer import VertexBufferParser
from kartbf.bfrespy.models.shape import Shape, Mesh
from kartbf.bfrespy.models.skeleton import Skeleton
from kartbf.bfrespy.common import ResDict

HOST='SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc'
REFERENCE=ROOT/'assets/totk-cart-reference'
OUT=ROOT/'assets/native-cart-mod'


def geometry_read(loader,model):
    # Geometry-only route. V10 material parser fails on the retail external
    # shader dictionaries. Material bytes are left exactly as supplied.
    model.flags=loader.read_uint32();model.name=loader.load_string()
    model.path=loader.load_string();model.skeleton=loader.load(Skeleton)
    loader.read_offset();model.shapes=loader.load_dict_values(Shape)
    model.materials=ResDict()


def instrument(cls,method):
    old=getattr(cls,method)
    def load(loader, obj):
        obj.record_offset=loader.tell()-4
        return old(loader,obj)
    setattr(cls,method,staticmethod(load))


def parse_host(data):
    ModelParser.read=staticmethod(geometry_read)
    instrument(ShapeParser,'read');instrument(VertexBufferParser,'load')
    old=Mesh.load
    def load_mesh(self,loader):
        self.record_offset=loader.tell();return old(self,loader)
    Mesh.load=load_mesh
    BufferTextureViewInfo.buff_offs=struct.unpack_from('<I',data,0x1c)[0]+0x120
    return k.ResFile(io.BytesIO(data))


def source_lod(model, shape, lod, scale, rigid):
    sh=list(model.shapes.values())[shape];m=sh.meshes[lod]
    at=k.attributes(sh.vtx_buffer)
    ind=np.frombuffer(m.index_buffer.data[0],dtype='<u2').astype(np.uint32)
    count=int(ind.max())+1
    start=m.first_vtx
    return {'p':at['_p0'][start:start+count,:3]*scale,
            'n':at['_n0'][start:start+count,:3],
            'u':at['_u0'][start:start+count,:2],
            'rigid':np.full(count,rigid,dtype=np.uint8),'i':ind}


def low_wheel(rigid, segments=6):
    # Configurable low-detail capped cylinder around the original wheel X axle.
    radius=.25426;half_width=.184
    p=[];n=[];u=[]
    for x in (-half_width,half_width):
        for j in range(segments):
            a=j*math.tau/segments;p.append([x,radius*math.cos(a),radius*math.sin(a)])
            n.append([0,math.cos(a),math.sin(a)]);u.append([j/segments,0 if x<0 else 1])
    p.extend([[-half_width,0,0],[half_width,0,0]])
    n.extend([[-1,0,0],[1,0,0]]);u.extend([[.5,.5],[.5,.5]])
    ind=[]
    for j in range(segments):
        a=j;b=(j+1)%segments;c=j+segments;d=(j+1)%segments+segments
        ind.extend([a,c,b,b,c,d,segments*2,a,b,segments*2+1,d,c])
    return {'p':np.array(p),'n':np.array(n),'u':np.array(u),'rigid':np.full(segments*2+2,rigid,dtype=np.uint8),'i':np.array(ind,dtype=np.uint32).reshape(-1,3)[:,[0,2,1]].reshape(-1)}


def combine(parts):
    out={key:np.concatenate([p[key] for p in parts])for key in ('p','n','u','rigid')}
    indices=[];offset=0
    for p in parts:indices.append(p['i']+offset);offset+=len(p['p'])
    out['i']=np.concatenate(indices);return out


def snorm10(v):
    value=np.rint(np.clip(v,-1,1)*511).astype(np.int32)
    return ((int(value[0])&1023)|((int(value[1])&1023)<<10)|((int(value[2])&1023)<<20))


def build(refined=False, out_override=None, geometry_override=None, report_extra=None):
    out=ROOT/('assets/native-cart-mod-refined' if refined else 'assets/native-cart-mod')
    if out_override is not None:out=out_override
    tire_lod=1 if refined else 2
    wheel_segments=8 if refined else 6
    original=(REFERENCE/'compressed'/HOST).read_bytes()
    original_info=parse(original)
    data=bytearray((REFERENCE/'decoded'/HOST.removesuffix('.mc')).read_bytes())
    original_decoded=bytes(data)
    # Source BFRESs use the full parser before the geometry-only host override.
    body=k.ResFile(io.BytesIO((ROOT/'assets/standard-kart/source/BodyK_Std.bfres').read_bytes()))
    tire=k.ResFile(io.BytesIO((ROOT/'assets/standard-kart/source/TireK_Std.bfres').read_bytes()))
    bm=list(body.models.values())[0];tm=list(tire.models.values())[0]
    # Native rigid matrix order: Skl_Root, Wheel_00 LF, Wheel_01 RF,
    # Wheel_02 LB, Wheel_03 RB. Source order: LB LF RB RF.
    mapping=[3,1,4,2]
    high=combine([source_lod(bm,0,0,.16,0)]+[source_lod(tm,i,tire_lod,.14365,mapping[i])for i in range(4)])
    low=combine([source_lod(bm,0,2,.16,0)]+[low_wheel(i,wheel_segments)for i in range(1,5)])
    if geometry_override is not None:high,low=geometry_override(bm,tm)
    host=parse_host(original_decoded);model=list(host.models.values())[0]
    assert model.skeleton.mtx_to_bone_list==(1,2,3,4,5)
    gpu=BufferTextureViewInfo.buff_offs
    u64=lambda pos:struct.unpack_from('<Q',data,pos)[0]
    records=[]
    for si,shape in enumerate(model.shapes.values()):
        vb=shape.vtx_buffer;vpos=vb.record_offset
        sizeptr=u64(vpos+0x30);strideptr=u64(vpos+0x38)
        buffoffs=struct.unpack_from('<i',data,vpos+0x48)[0]
        locations=[];cursor=gpu+buffoffs
        for j,buffer in enumerate(vb.buffers):
            cursor=(cursor+vb.gpu_buff_align-1)&-vb.gpu_buff_align
            size=struct.unpack_from('<I',data,sizeptr+j*16)[0]
            assert size==len(buffer.data[0]);locations.append((cursor,size,buffer.stride))
            # All unused vertices stay well-defined at origin with valid normal.
            data[cursor:cursor+size]=b'\0'*size;cursor+=size
        shape_record={'name':shape.name,'gpu_buffers':locations,'lods':[]}
        for li,mesh in enumerate(shape.meshes):
            mpos=mesh.record_offset
            indexloc=gpu+struct.unpack_from('<I',data,mpos+0x20)[0]
            capacity=len(mesh.index_buffer.data[0])//2
            assert mesh.index_format.name=='UINT16_LITTLE_ENDIAN'
            data[indexloc:indexloc+capacity*2]=b'\0'*(capacity*2)
            first=mesh.first_vtx
            nextfirst=shape.meshes[li+1].first_vtx if li+1<len(shape.meshes) else vb.vtx_count
            slotcap=nextfirst-first
            for vi in range(first,nextfirst):
                struct.pack_into('<I',data,locations[1][0]+vi*locations[1][2],snorm10([0,1,0]))
            if si==0:
                a=high if li==0 else low
                assert len(a['p'])<=slotcap and len(a['i'])<=capacity
                for vi,(p,n,uv,rigid) in enumerate(zip(a['p'],a['n'],a['u'],a['rigid'])):
                    idx=first+vi
                    struct.pack_into('<3eBB',data,locations[0][0]+idx*locations[0][2],*p,int(rigid),0)
                    struct.pack_into('<I2e4b',data,locations[1][0]+idx*locations[1][2],snorm10(n),*uv,127,0,0,127)
                data[indexloc:indexloc+len(a['i'])*2]=a['i'].astype('<u2').tobytes()
                shape_record['lods'].append({'lod':li,'vertices':len(a['p']),'triangles':len(a['i'])//3,'vertex_capacity':slotcap,'triangle_capacity':capacity//3})
            else:
                shape_record['lods'].append({'lod':li,'hidden':'all indices degenerate','vertex_capacity':slotcap,'triangle_capacity':capacity//3})
        # Conservative per-submesh AABBs and per-bone spheres cover new shapes
        # throughout original wheel animation. Keep pointer/count layout intact.
        boundptr=u64(shape.record_offset+0x38)
        for j in range(len(shape.submesh_boundings)):
            struct.pack_into('<6f',data,boundptr+j*24,0,0,0,4,4,4)
        radiusptr=u64(shape.record_offset+0x40)
        for j in range(len(shape.bounding_radius_list)):
            struct.pack_into('<4f',data,radiusptr+j*16,0,0,0,4)
        records.append(shape_record)
    assert len(data)==len(original_decoded)
    filesz=struct.unpack_from('<I',data,0x1c)[0]
    indexout=original_info['index_out'];vertexout=original_info['vertex_out']
    fmsh=build_fmsh(bytes(data[gpu:gpu+indexout]),bytes(data[gpu+indexout:gpu+indexout+vertexout]), work_mem=original_info['work_mem'])
    compressed,info=pack(bytes(data),fmsh)
    assert info['buffer_size']==len(data)==original_info['buffer_size']
    dest=out/'romfs/Model'/HOST;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(compressed)
    # Ground truth expected buffer for independent C++ decoder comparison.
    (out/'expected-decoded.bfres').write_bytes(data)
    report={'status':'experimental geometry candidate, runtime untested','host':'SpObj_Cart_A_01',
        'source_body_scale':.16,'source_tire_scale':.14365,'wheel_placement':'native TOTK cart skeleton sockets',
        'high_lod':f'original MK8DX body LOD0 plus tires LOD{tire_lod}',
        'low_lod':f'original MK8DX body LOD2 plus authored {wheel_segments}-sided capped wheel cylinders',
        'material':'unmodified native Mt_Etc_ZonauCart_A material and original textures; Mario atlas not installed',
        'original_compressed_bytes':len(original),'candidate_compressed_bytes':len(compressed),
        'original_decoded_allocation_bytes':len(original_decoded),'candidate_decoded_allocation_bytes':info['buffer_size'],
        'restbl':'Decoded resource allocation unchanged; no expansion required for this model candidate.',
        'original_compressed_sha256':hashlib.sha256(original).hexdigest(),'candidate_compressed_sha256':hashlib.sha256(compressed).hexdigest(),
        'expected_decoded_sha256':hashlib.sha256(data).hexdigest(),'shapes':records,
        'packer_commit':'032c41d18cb8399c7c01c04f0ab140689327431c',
        'decoder_commit':'b3600954872dbc2893a1bcc9e851c1e364f303ab',
        'limitations':['Source body and wheels remapped to native bones; native collision and seating remain unchanged.',
                       'Replaces every native cart visual using this model; not a separate new actor.',
                       'Native shaders, texture names, skeleton, buffer capacities and draw counts retained.',
                       'No MK8 driving physics or Mario character supplied by this visual swap.',
                       'Actual Ryujinx and Switch load, rendering, culling, riding and LOD transitions need runtime test.']}
    if report_extra:report.update(report_extra)
    # Cross-check actual produced package through the independent C++ decoder.
    check=out/'decoded-check';check.mkdir(exist_ok=True)
    subprocess.run([str(ROOT/'.tools/kart-assets/MeshCodec/build/tests/mc_test'),str(dest.parent),str(check)],check=True)
    decoded=(check/HOST.removesuffix('.mc')).read_bytes()
    assert decoded==bytes(data),'independent decoder disagrees with expected complete BFRES/GPU buffer'
    report['independent_decoder_roundtrip']={'tool':'dt-12345/MeshCodec mc_test with documented ARM64 and untested NullCodec min-size fixes',
        'byte_identical':True,'sha256':hashlib.sha256(decoded).hexdigest(),
        'scope':'cross-implementation format check; not game runtime proof'}
    (out/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:report[k]for k in ('status','original_compressed_bytes','candidate_compressed_bytes','candidate_decoded_allocation_bytes')}))

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--refined',action='store_true',help='Use rounder wheels; write separate assets/native-cart-mod-refined output')
    build(refined=parser.parse_args().refined)
