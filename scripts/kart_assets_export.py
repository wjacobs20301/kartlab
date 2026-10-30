#!/usr/bin/env python3
"""Export local MK8DX standard-kart BFRESs to an editable, textured glTF.

Inputs remain untouched. Dependency setup is documented in research/kart-assets.md.
The output preserves source units/axes and wheel bone transforms. It is a source
asset, not a TOTK actor or finished game model.
"""
from __future__ import annotations
import argparse, hashlib, importlib, io, json, pathlib, struct, sys, types
import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEPENDENCY = ROOT / '.tools/kart-assets/BlenderBfresImporter'
sys.path.insert(0, str(ROOT / '.tools/kart-assets/python'))
# Load the format parser without importing its Blender UI registration code.
pkg = types.ModuleType('kartbf')
pkg.__path__ = [str(DEPENDENCY / 'io_scene_bfres')]
sys.modules['kartbf'] = pkg
from kartbf.bfrespy.res_file import ResFile
from kartbf.bfrespy.external_file import ExternalFile
from kartbf.bntx import BNTX
from kartbf.yaz0 import decompress
from PIL import Image


def external_file_load(self, loader):
    # Switch external-file records are pointer u64 + length u64 (16-byte stride).
    # Upstream reads length u32 and gets the second record 4 bytes too early.
    offset = loader.read_offset()
    size = loader.read_uint64() if loader.is_switch else loader.read_uint32()
    self.data = loader.load_custom(bytes, lambda: loader.read_bytes(size), offset=offset)
ExternalFile.load = external_file_load


def attributes(vb):
    """Decode relevant original GPU formats; IEEE binary16 uses struct 'e'."""
    result = {}
    formats = {0x811:'3f', 0x80f:'4e', 0x808:'2e', 0x80d:'2f',
               0x100:'B', 0x207:'2h', 0x007:'2H', 0x20a:'4b', 0x10a:'4B'}
    for a in vb.attributes.values():
        buffer = vb.buffers[a.buffer_idx]
        if a.format_.value == 0x20b:
            packed = np.array([struct.unpack_from('<I', buffer.data[0], i*buffer.stride + a.offset)[0]
                               for i in range(vb.vtx_count)], dtype=np.uint32)
            value = np.stack([((packed >> shift) & 1023).astype(np.int32) for shift in (0,10,20)], axis=1)
            value = np.where(value >= 512, value - 1024, value)
            result[a.name] = np.maximum(value / 511., -1.)
            continue
        if a.format_.value not in formats:
            continue
        fmt = '<' + formats[a.format_.value]
        v = np.array([struct.unpack_from(fmt, buffer.data[0], i*buffer.stride+a.offset)
                      for i in range(vb.vtx_count)])
        if a.format_.value == 0x007: v = v/65535.
        if a.format_.value == 0x207: v = np.maximum(v/32767., -1.)
        if a.format_.value == 0x20a: v = np.maximum(v/127., -1.)
        result[a.name] = v
    return result


def export(root, out):
    out.mkdir(parents=True, exist_ok=True)
    source = out/'source'; source.mkdir(exist_ok=True)
    texdir = out/'textures'; texdir.mkdir(exist_ok=True)
    files = ['Kart/Body/BodyK_Std.szs', 'Kart/Tire/TireK_Std.szs',
             'Kart/BodyTex/BodyK_Std_Mro_Alb.szs']
    manifest = {'format_version':1, 'input_game':'MK8DX 1.7.1', 'parser_repository':
        'https://github.com/ranidspace/BlenderBfresImporter', 'parser_commit':'9fb84c24537a8a610b30be9c67bec7470638b71c', 'inputs':[], 'models':[], 'textures':[],
        'units':'unaltered MK8DX source units; physical scale in TOTK unresolved',
        'axes':'unaltered source; Y up, wheel LF/RF point +Z by bone naming',
        'limits':['Source asset only, not installable TOTK content.',
                  'PBR base color preview replaces Turbo_UBER shader; no shader-equivalence claim.',
                  'Tire rest positions preserved; body-specific runtime placement not applied.',
                  'Only LOD0 exported; original BFRES preserves all LODs.']}
    resources = []
    for rel in files:
        p=root/rel; original=p.read_bytes()
        data=decompress(io.BytesIO(original)).getvalue() if original[:4]==b'Yaz0' else original
        assert data[:8] == b'FRES    '
        local=source/(p.stem+'.bfres');local.write_bytes(data)
        r=ResFile(io.BytesIO(data));resources.append(r)
        manifest['inputs'].append({'path':rel, 'bytes':len(original), 'sha256':hashlib.sha256(original).hexdigest(),
            'decoded_file':str(local.relative_to(out)), 'decoded_sha256':hashlib.sha256(data).hexdigest(),
            'bfres_version':hex(r.version)})
        for name, ext in r.external_files.items():
            if not name.endswith('.bntx'):continue
            bp=source/(p.stem+'.bntx');bp.write_bytes(ext.data)
            assert ext.data[:4]==b'BNTX'
            b=BNTX(io.BytesIO(ext.data))
            for t in b.nx.textures:
                # BC decoder provides rows in top-left image order. Preserve that
                # order for PNG; glTF uses top-left texture coordinate convention.
                pixels=np.asarray(t.pixels)
                if pixels.ndim==2: rgba=np.stack([pixels]*3+[np.ones_like(pixels)],axis=2)
                elif pixels.shape[-1]==2:
                    # Preserve decoded BC5 XY as RG; don't assume a normal convention.
                    xy=(pixels+1)/2 if t.fmt_dtype.name=='SNORM' else pixels
                    rgba=np.concatenate([xy,np.zeros((*pixels.shape[:2],1)),np.ones((*pixels.shape[:2],1))],axis=2)
                else:rgba=pixels
                if rgba.dtype!=np.uint8:rgba=np.rint(np.clip(rgba,0,1)*255).astype(np.uint8)
                assert rgba.shape==(t.height,t.width,4),(t.name,rgba.shape)
                Image.fromarray(rgba).save(texdir/(t.name+'.png'))
                manifest['textures'].append({'name':t.name,'source':rel,'width':t.width,'height':t.height,
                    'format':t.format_.__name__, 'dtype':t.fmt_dtype.name,'png_encoding':('SNORM XY remapped from [-1,1] to [0,1]' if t.format_.__name__=='BC5' and t.fmt_dtype.name=='SNORM' else 'decoded channels, unapplied selectors'),'channel_selectors':list(t.channel_types)})
    g={'asset':{'version':'2.0','generator':'kart_assets_export.py'},'scene':0,
       'scenes':[{'nodes':[]}], 'nodes':[], 'meshes':[], 'accessors':[], 'bufferViews':[],
       'buffers':[{'uri':'standard-kart.bin','byteLength':0}],
       'images':[{'uri':'textures/BodyK_Std_Mro_Alb.png'},{'uri':'textures/Tire_Std_Alb.png'}],
       'textures':[{'source':0},{'source':1}],
       'materials':[{'name':'Mario body base-color preview','pbrMetallicRoughness':{'baseColorTexture':{'index':0},'metallicFactor':0,'roughnessFactor':0.7}},
                    {'name':'Standard tire base-color preview','pbrMetallicRoughness':{'baseColorTexture':{'index':1},'metallicFactor':0,'roughnessFactor':0.8}}]}
    blob=bytearray()
    def accessor(a, typ, component=5126, target=34962):
        a=np.ascontiguousarray(a,dtype='<u4' if component==5125 else '<f4')
        while len(blob)%4:blob.append(0)
        offset=len(blob);blob.extend(a.tobytes())
        bv=len(g['bufferViews']);g['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':a.nbytes,'target':target})
        ac={'bufferView':bv,'componentType':component,'count':len(a),'type':typ}
        if typ=='VEC3':ac.update(min=a.min(axis=0).tolist(),max=a.max(axis=0).tolist())
        idx=len(g['accessors']);g['accessors'].append(ac);return idx
    for r in resources:
        for model in r.models.values():
            mi={'name':model.name,'bones':[], 'materials':[], 'shapes':[]}
            mroot=len(g['nodes']);g['nodes'].append({'name':model.name,'children':[]});g['scenes'][0]['nodes'].append(mroot)
            bone_nodes=[]
            for bi,b in enumerate(model.skeleton.bones.values()):
                assert tuple(b.rotation)==(0.,0.,0.,1.),'unexpected rotation'
                bn=len(g['nodes']);bone_nodes.append(bn)
                g['nodes'].append({'name':b.name,'translation':list(b.position),'scale':list(b.scale),'children':[]})
                parent=mroot if b.parent_idx<0 else bone_nodes[b.parent_idx]
                g['nodes'][parent]['children'].append(bn)
                mi['bones'].append({'name':b.name,'parent_idx':b.parent_idx,'position':b.position,'rotation':b.rotation,'scale':b.scale})
            for material in model.materials.values():
                mi['materials'].append({'name':material.name,'textures':[x.name for x in material.texture_refs],
                    'shader_archive':material.shader_assign.shader_archive_name,'shader_model':material.shader_assign.shading_model_name})
            for sh in model.shapes.values():
                assert sh.vtx_skin_count==0,'only rigid kart meshes supported'
                mesh=sh.meshes[0];assert mesh.first_vtx==0
                assert mesh.primitive_type.name=='TRIANGLES'
                dtype='<u2' if mesh.index_format.name=='UINT16_LITTLE_ENDIAN' else '<u4'
                indices=np.frombuffer(mesh.index_buffer.data[0],dtype=dtype).astype('<u4')
                indices=indices[:int(mesh.index_count)]
                count=int(indices.max())+1;at=attributes(sh.vtx_buffer)
                assert len(indices)%3==0 and len(at['_p0'])>=count
                positions=at['_p0'][:count,:3];normals=at['_n0'][:count,:3]
                normals=normals / np.linalg.norm(normals,axis=1)[:,None]
                assert np.isfinite(positions).all() and np.isfinite(normals).all()
                attrs={'POSITION':accessor(positions,'VEC3'),'NORMAL':accessor(normals,'VEC3')}
                for k in range(3):
                    if f'_u{k}' in at:attrs[f'TEXCOORD_{k}']=accessor(at[f'_u{k}'][:count,:2],'VEC2')
                meshidx=len(g['meshes']);g['meshes'].append({'name':sh.name,'primitives':[{'attributes':attrs,
                    'indices':accessor(indices,'SCALAR',5125,34963),'mode':4,'material':0 if model.name.startswith('Body') else 1}]})
                ni=len(g['nodes']);g['nodes'].append({'name':sh.name,'mesh':meshidx})
                g['nodes'][bone_nodes[sh.bone_idx]]['children'].append(ni)
                mi['shapes'].append({'name':sh.name,'vertices_exported':count,'triangles':len(indices)//3,'bone_idx':sh.bone_idx,
                     'bounds_local':[positions.min(axis=0).tolist(),positions.max(axis=0).tolist()],
                     'lod_index_counts':[int(x.index_count) for x in sh.meshes]})
            manifest['models'].append(mi)
    g['buffers'][0]['byteLength']=len(blob)
    (out/'standard-kart.bin').write_bytes(blob)
    (out/'standard-kart.gltf').write_text(json.dumps(g,indent=2)+'\n')
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    return manifest

if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--romfs',type=pathlib.Path,default=ROOT/'extracted/mk8dx/romfs')
    ap.add_argument('--out',type=pathlib.Path,default=ROOT/'assets/standard-kart')
    args=ap.parse_args();m=export(args.romfs,args.out)
    print(json.dumps({'models':len(m['models']),'meshes':sum(len(x['shapes']) for x in m['models']),
        'triangles':sum(s['triangles'] for x in m['models'] for s in x['shapes']), 'textures':len(m['textures'])}))
