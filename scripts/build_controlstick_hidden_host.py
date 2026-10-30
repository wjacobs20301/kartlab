#!/usr/bin/env python3
"""Hide stock ControlStick draws while retaining all native mounting bones.

Writes separate offline candidates with original and trial Skl_Root transforms.
The kart remains an external SubModel, so this edits no Mario model or textures.
"""
from pathlib import Path
import hashlib,json,struct,subprocess
import kart_assets_native_cart as native
from kartbf.bfrespy.switch.memory_pool import BufferTextureViewInfo

ROOT=native.ROOT
HOST='SpObj_ControlStick_A.SpObj_ControlStick_A_01.bfres.mc'

def build(mode,source_compressed,source_decoded):
    out=ROOT/'assets/controlstick-hidden-host'/mode
    original=source_compressed.read_bytes();source=source_decoded.read_bytes();data=bytearray(source)
    model=list(native.parse_host(source).models.values())[0];gpu=BufferTextureViewInfo.buff_offs
    info=native.parse(original);records=[];allowed=set()
    for shape in model.shapes.values():
        for lod,mesh in enumerate(shape.meshes):
            at=gpu+struct.unpack_from('<I',source,mesh.record_offset+0x20)[0]
            size=len(mesh.index_buffer.data[0]);assert size>0 and size%6==0
            assert source[at:at+size]==mesh.index_buffer.data[0]
            data[at:at+size]=bytes(size);allowed.update(range(at,at+size))
            records.append(dict(shape=shape.name,lod=lod,offset=at,bytes=size,method='Every index zero; all triangles degenerate'))
    assert all(a==b or i in allowed for i,(a,b)in enumerate(zip(source,data)))
    # Only index bytes change. Re-encode those buffers with the pinned MeshCodec
    # implementation and retain native vertex allocations and work-memory size.
    index_out,vertex_out=info['index_out'],info['vertex_out']
    fmsh=native.build_fmsh(bytes(data[gpu:gpu+index_out]),bytes(data[gpu+index_out:gpu+index_out+vertex_out]),work_mem=info['work_mem'])
    result,packed_info=native.pack(bytes(data),fmsh)
    assert packed_info['buffer_size']==len(source)==len(data)
    dest=out/'romfs/Model'/HOST;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(result)
    check=out/'decoded-check';check.mkdir(exist_ok=True)
    subprocess.run([str(ROOT/'.tools/kart-assets/MeshCodec/build/tests/mc_test'),str(dest.parent),str(check)],check=True)
    assert (check/HOST.removesuffix('.mc')).read_bytes()==data
    before=list(native.parse_host(source).models.values())[0]
    after=list(native.parse_host(bytes(data)).models.values())[0]
    assert [(b.name,b.parent_idx,b.position,b.rotation,b._flags)for b in before.skeleton.bones.values()]==[(b.name,b.parent_idx,b.position,b.rotation,b._flags)for b in after.skeleton.bones.values()]
    report=dict(status='Offline hidden-host diagnostic; runtime untested',mode=mode,
        source_compressed=str(source_compressed.relative_to(ROOT)),source_sha256=hashlib.sha256(original).hexdigest(),candidate_sha256=hashlib.sha256(result).hexdigest(),
        decoded_bytes=len(data),allocation_unchanged=True,decoder_byte_identical=True,only_index_buffer_edits=True,draws=records,
        preserved_bones=[dict(name=b.name,parent=b.parent_idx,translation=list(b.position))for b in after.skeleton.bones.values()],
        requires='Compatible native-mount Cart SubModel actor pack and kart model/textures',
        limits=['Keeps native standing ControlStick pose; no seated animation supplied','Host visuals hidden, but interaction/AI and native bones remain','No collision, saddle or external kart model edits','Root-offset mode preserves prior trial transform; binding-height hypothesis needs game comparison','No Switch test'])
    (out/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print(mode,report['candidate_sha256'])

def main():
    base=ROOT/'.work/native-mount/model'
    build('original-root',base/'compressed'/HOST,base/'decoded'/HOST.removesuffix('.mc'))
    trial=ROOT/'assets/controlstick-root-trial'
    if (trial/'expected-decoded.bfres').exists():
        build('raised-root',trial/'romfs/Model'/HOST,trial/'expected-decoded.bfres')

if __name__=='__main__':main()
