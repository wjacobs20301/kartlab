#!/usr/bin/env python3
"""Read the retail Cart material using its external binary string dictionary.

Writes only a compact evidence report. Does not rewrite materials or install any
candidate. Fixes upstream parser's signed IDs, Node cache values and array string
lookup locally, without editing its source tree.
"""
import io,json,pathlib,struct,sys,hashlib
import kart_assets_export as k
ROOT=k.ROOT
sys.path.insert(0,str(ROOT/'.tools/kart-assets/totk-meshcodec'))
from mcpack import decompress
from kartbf.bfrespy import common
from kartbf.bfrespy.switch.switchcore import ResFileSwitchLoader
from kartbf.bfrespy.switch.memory_pool import BufferTextureViewInfo
from kartbf.bfrespy.models.material import ShaderParamType


def strings_from_external():
    source=ROOT/'extracted/totk/romfs/Shader/ExternalBinaryString.bfres.mc'
    original=source.read_bytes();data=decompress(original)
    assert data[:8]==b'FRES    'and data[0xee]&4
    u64=lambda p:struct.unpack_from('<Q',data,p)[0]
    values=u64(0xb8);dictionary=u64(0xc0);count=struct.unpack_from('<I',data,dictionary+4)[0]
    mapping={}
    for i in range(count):
        pos=dictionary+8+(i+1)*16;strpos=u64(pos+8)
        size=struct.unpack_from('<H',data,strpos)[0]
        name=data[strpos+2:strpos+2+size].decode('utf-8')
        assert data[strpos+2+size]==0
        key=u64(values+i*8);assert key not in mapping;mapping[key]=name
    assert len(mapping)==count
    common.stringcache=mapping
    return {'path':str(source.relative_to(ROOT)),'sha256':hashlib.sha256(original).hexdigest(),'entries':count},mapping


def load_strings(self,count,encoding=None):
    # Upstream indexes an initially empty list for cached IDs; append instead.
    offsets=self.read_uint64s(count);result=[]
    for offset in offsets:
        if offset==0:result.append('')
        elif offset in common.stringcache:result.append(common.stringcache[offset])
        else:
            with self.temporary_seek(offset,io.SEEK_SET):result.append(self.read_string(encoding))
    return tuple(result)


def main():
    evidence,mapping=strings_from_external();ResFileSwitchLoader.load_strings=load_strings
    path=ROOT/'assets/totk-cart-reference/decoded/SpObj_Cart_A.SpObj_Cart_A_01.bfres'
    data=path.read_bytes();BufferTextureViewInfo.buff_offs=struct.unpack_from('<I',data,0x1c)[0]+0x120
    parsed=k.ResFile(io.BytesIO(data));model=list(parsed.models.values())[0]
    mats=[]
    for mat in model.materials.values():
        shader=mat.shader_assign
        mats.append({'name':mat.name,'shader_archive':shader.shader_archive_name,'shader_model':shader.shading_model_name,
            'textures':[x.name for x in mat.texture_refs],
            'sampler_assignments':{key:str(value)for key,value in shader.sampler_assigns.items()},
            'stored_shader_options':{key:str(value)for key,value in shader.shaderoptions.items()},
            'parameters':[{'name':p.name,'type':p.type.name,'source_data_offset':p.data_offs}for p in mat.shaderparams.values()]})
    first=data.index(b'FMAT');u64=lambda p:struct.unpack_from('<Q',data,p)[0]
    sinfo=u64(first+0x10);assign=u64(sinfo);descs=u64(assign+0x20);paramdata=u64(first+0x58)
    count=struct.unpack_from('<H',data,assign+0x4a)[0]
    matches=[]
    for i in range(count):
        pos=descs+i*24;name=u64(pos+8);off,typ=struct.unpack_from('<HH',data,pos+16)
        if ShaderParamType(typ).name=='TEX_SRT':
            mode=struct.unpack_from('<I',data,paramdata+off)[0]
            values=struct.unpack_from('<5f',data,paramdata+off+4)
            matches.append({'name':mapping[name],'name_id':hex(name),'type':'TEX_SRT','source_data_offset':off,
                'absolute_bfres_offset':hex(paramdata+off),'mode':mode,'scale':list(values[:2]),
                'rotation':values[2],'translation':list(values[3:]),'descriptor_offset':hex(pos)})
    assert matches==[{'name':'p_tex_srt3','name_id':'0x75d8768c4e332776','type':'TEX_SRT','source_data_offset':272,
        'absolute_bfres_offset':'0x1c88','mode':0,'scale':[100.,100.],'rotation':0.,'translation':[0.,0.],'descriptor_offset':'0x3a98'}],matches
    report={'evidence_kind':'format-aware static material and external-string parse','external_string_source':evidence,
        'decoded_cart_source_sha256':hashlib.sha256(data).hexdigest(),'materials':mats,'main_texture_srts':matches,
        'interpretation':'Observed: main material stores default toon-spec SRT selection; hidden ZonauLight material explicitly selects3. Inference: p_tex_srt3 is an auxiliary transform and need not affect base albedo. Runtime color candidate leaves this field untouched.',
        'limits':['Stored option defaults do not establish effective shader defaults or texture sampling execution.',
                  'Retained shader actual color appearance is established separately by parent runtime observation.']}
    (ROOT/'research/kart-materials.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'materials':len(mats),'external_strings':len(mapping),'srt':matches}))

if __name__=='__main__':main()
