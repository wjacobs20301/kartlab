#!/usr/bin/env python3
"""Write a separate original-color TXTg + UV candidate, without installing it.

Keeps the working model's position, normal, tangent, skin and index data. Only
UV0 is remapped into one native-size atlas; native Cart texture paths/header
identity, dimensions, formats and complete mip counts remain in use.
"""
from __future__ import annotations
import argparse,hashlib,io,json,math,pathlib,struct,subprocess,sys
import numpy as np
from PIL import Image
import kart_assets_native_cart as native
k=native.k;ROOT=k.ROOT
import zstandard as zstd
from kartbf.bntx.pixelfmt.bcn.decompress_ import decomp_bc1

OUT=ROOT/'assets/native-cart-color-mod'
TEXROOT=ROOT/'extracted/totk/romfs/TexToGo'


def tegra_addresses(width,height,bpp=8):
    """Map linear BC block offsets to Tegra block-linear offsets.

    Address layout follows AboodXD's documented Tegra algorithm (also used by
    BlenderBfresImporter and Switch Toolbox). Select each mip's block height.
    """
    w=max(1,(width+3)//4);h=max(1,(height+3)//4)
    bh=min(16,1<<max(0,((h+7)//8-1).bit_length()))
    gobs=(w*bpp+63)//64
    out=[]
    for y in range(h):
        for x in range(w):
            xx=x*bpp
            gob=(y//(8*bh))*512*bh*gobs+(xx//64)*512*bh+(y%(8*bh)//8)*512
            addr=gob+(xx%64//32)*256+(y%8//2)*64+(xx%32//16)*32+(y%2)*16+xx%16
            out.extend(range(addr,addr+bpp))
    out=np.array(out,dtype=np.int64)
    # Selected power-of-two retail Cart surfaces have no interior padding.
    assert len(out)==w*h*bpp and set(out)==set(range(w*h*bpp))
    return out


def swizzle(linear,width,height):
    addresses=tegra_addresses(width,height)
    assert len(linear)==len(addresses)
    out=np.zeros(len(linear),dtype=np.uint8);out[addresses]=np.frombuffer(linear,dtype=np.uint8)
    return out.tobytes()


def deswizzle(tiled,width,height):
    addresses=tegra_addresses(width,height)
    assert len(tiled)==len(addresses)
    return np.frombuffer(tiled,dtype=np.uint8)[addresses].tobytes()


def read_txtg(data):
    assert data[4:8]==b'6PK0'
    hs,version=struct.unpack_from('<HH',data)
    assert hs==0x50 and version==0x11
    width,height,depth=struct.unpack_from('<HHH',data,8);mips=data[14]
    assert depth==1
    records=[struct.unpack_from('<HBB',data,hs+i*4)for i in range(mips)]
    assert records==[(0,i,1)for i in range(mips)]
    sizes=[struct.unpack_from('<II',data,hs+mips*4+i*8)for i in range(mips)]
    pos=hs+mips*12;surfaces=[]
    for i,(size,codec)in enumerate(sizes):
        assert codec==6
        block=data[pos:pos+size];assert len(block)==size;pos+=size
        tiled=zstd.ZstdDecompressor().decompress(block)
        w=max(1,width>>i);h=max(1,height>>i)
        assert len(tiled)==max(1,(w+3)//4)*max(1,(h+3)//4)*8
        surfaces.append(tiled)
    assert pos==len(data)
    return {'width':width,'height':height,'mips':mips,'format':struct.unpack_from('<H',data,0x3c)[0],
            'header':data[:hs],'surfaces':surfaces}


def encode_bc1(image):
    # Pillow's native BC1 encoder; DDS only transports the 8-byte block stream.
    image=image.convert('RGB');w,h=image.size
    if w<4 or h<4:
        padded=Image.new('RGB',(max(4,w),max(4,h)))
        pixels=np.array(image);padded=Image.fromarray(np.pad(pixels,((0,max(4,h)-h),(0,max(4,w)-w),(0,0)),mode='edge'))
        image=padded
    buf=io.BytesIO();image.save(buf,format='DDS',pixel_format='DXT1')
    data=buf.getvalue();assert data[:4]==b'DDS ' and data[84:88]==b'DXT1'
    payload=data[128:];assert len(payload)==max(1,(w+3)//4)*max(1,(h+3)//4)*8
    return payload


def write_txtg(reference,surfaces):
    assert len(surfaces)==reference['mips']
    compressor=zstd.ZstdCompressor(level=20)
    frames=[compressor.compress(x)for x in surfaces]
    indices=b''.join(struct.pack('<HBB',0,i,1)for i in range(len(frames)))
    sizes=b''.join(struct.pack('<II',len(x),6)for x in frames)
    return reference['header']+indices+sizes+b''.join(frames)


def atlas_image():
    body=Image.open(ROOT/'assets/standard-kart/textures/BodyK_Std_Mro_Alb.png').convert('RGB')
    tire=Image.open(ROOT/'assets/standard-kart/textures/Tire_Std_Alb.png').convert('RGB')
    canvas=Image.new('RGB',(256,256))
    bodytile=body.resize((128,95),Image.Resampling.LANCZOS)
    for y in (0,95):
        for x in (0,128):canvas.paste(bodytile,(x,y))
    # Wrapped edge texels keep source UV exactly 0/1/2 from sampling tire rows.
    canvas.paste(canvas.crop((0,0,256,2)),(0,190))
    canvas.paste(canvas.crop((0,188,256,190)),(0,192))
    tiretile=tire.resize((64,54),Image.Resampling.LANCZOS)
    for x in range(0,256,64):canvas.paste(tiretile,(x,200))
    canvas.paste(canvas.crop((0,200,256,202)),(0,254))
    return canvas


def remap_uv(data):
    # Host geometry parser never parses/rebuilds unrelated material sections.
    parsed=native.parse_host(bytes(data));model=list(parsed.models.values())[0]
    main=list(model.shapes.values())[0];vb=main.vtx_buffer
    record=vb.record_offset
    gpu=struct.unpack_from('<I',data,0x1c)[0]+0x120
    sizeptr=struct.unpack_from('<Q',data,record+0x30)[0]
    cursor=gpu+struct.unpack_from('<i',data,record+0x48)[0];locations=[]
    for i,buffer in enumerate(vb.buffers):
        cursor=(cursor+vb.gpu_buff_align-1)&-vb.gpu_buff_align
        size=struct.unpack_from('<I',data,sizeptr+i*16)[0]
        locations.append(cursor);cursor+=size
    attrs=k.attributes(vb);p=attrs['_p0'];rigid=attrs['_i0'][:,0];uv=attrs['_u0']
    assert np.all(uv[rigid==0,0]>=-.501) and np.all(uv[rigid==0,0]<=1.001)
    assert np.all(uv[rigid==0,1]>=-.001) and np.all(uv[rigid==0,1]<=2.001)
    assert np.all(uv[rigid!=0,0]>=-.001) and np.all(uv[rigid!=0,0]<=4.001)
    new=uv.copy()
    body=rigid==0
    new[body,0]=((uv[body,0]+1)*128+.5)/256
    new[body,1]=(uv[body,1]*95+.5)/256
    new[~body,0]=(uv[~body,0]*64+.5)/256
    new[~body,1]=(200.5+uv[~body,1]*54)/256
    # UV descriptor in the retained native material vertex layout: half2 @4.
    uvattr=next(x for x in vb.attributes.values()if x.name=='_u0')
    assert uvattr.buffer_idx==1 and uvattr.offset==4
    for i,x in enumerate(new):struct.pack_into('<2e',data,locations[1]+i*vb.buffers[1].stride+4,*x)
    return {'vertices_with_remapped_uv':len(new),'body_uv_range':[uv[body].min(axis=0).tolist(),uv[body].max(axis=0).tolist()],
            'tire_uv_range':[uv[~body].min(axis=0).tolist(),uv[~body].max(axis=0).tolist()],
            'atlas_mapping':'body 2x2 tiles 128x95 in rows0..189, wrapped edges190..193; tire4x1 tiles64x54 in rows200..253, edges254..255'}


def build(geometry, atlas_override=None, uv_override=None, report_extra=None):
    OUT.mkdir(parents=True,exist_ok=True)
    atlas=atlas_override() if atlas_override else atlas_image();atlas.save(OUT/'mario-kart-atlas.png')
    textures=[]
    for name in ('Alb','Nrm','Mtl'):
        path=TEXROOT/f'Etc_ZonauCart_A_{name}.txtg';original=path.read_bytes();ref=read_txtg(original)
        # Check every retail mip's layout in both directions, retaining bytes.
        for i,tiled in enumerate(ref['surfaces']):
            w=max(1,ref['width']>>i);h=max(1,ref['height']>>i)
            assert swizzle(deswizzle(tiled,w,h),w,h)==tiled
        surfaces=[]
        for i in range(ref['mips']):
            w=max(1,ref['width']>>i);h=max(1,ref['height']>>i)
            if name=='Alb':
                assert ref['format']==0x302
                image=atlas.resize((w,h),Image.Resampling.LANCZOS)
                linear=encode_bc1(image)
            elif name=='Nrm':
                assert ref['format']==0x302
                # Native BC1 normal map flat regions use approximately RGB128.
                linear=encode_bc1(Image.new('RGB',(w,h),(128,128,128)))
            else:
                assert ref['format']==0x606
                # BC4 material mask has no original stone panel pattern.
                linear=b'\0'*len(ref['surfaces'][i])
            surfaces.append(swizzle(linear,w,h))
        result=write_txtg(ref,surfaces);check=read_txtg(result)
        assert check['header']==ref['header'] and check['surfaces']==surfaces
        dest=OUT/'romfs/TexToGo'/path.name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(result)
        if name=='Alb':
            decoded=decomp_bc1(deswizzle(check['surfaces'][0],256,256),256,256)
            Image.fromarray(decoded).save(OUT/'encoded-atlas-check.png')
        textures.append({'path':str(dest.relative_to(OUT)),'source_sha256':hashlib.sha256(original).hexdigest(),
            'candidate_sha256':hashlib.sha256(result).hexdigest(),'original_compressed_bytes':len(original),'candidate_compressed_bytes':len(result),
            'dimensions':[ref['width'],ref['height']],'mips':ref['mips'],'format':hex(ref['format']),
            'decoded_mip_sizes_unchanged':True,'header_preserved':True,'retail_layout_roundtrip':True})
    source=(geometry/'expected-decoded.bfres').read_bytes();data=bytearray(source)
    uvreport=remap_uv(data)
    if uv_override:uvreport.update(uv_override(data))
    modelpath=geometry/'romfs/Model'/native.HOST;originalpackage=modelpath.read_bytes();info=native.parse(originalpackage)
    gpu=struct.unpack_from('<I',data,0x1c)[0]+0x120
    fmsh=native.build_fmsh(bytes(data[gpu:gpu+info['index_out']]),bytes(data[gpu+info['index_out']:gpu+info['index_out']+info['vertex_out']]),work_mem=info['work_mem'])
    package,packedinfo=native.pack(bytes(data),fmsh)
    assert packedinfo['buffer_size']==len(data)==len(source)
    dest=OUT/'romfs/Model'/native.HOST;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(package)
    (OUT/'expected-decoded.bfres').write_bytes(data)
    checkdir=OUT/'decoded-check';checkdir.mkdir(exist_ok=True)
    subprocess.run([str(ROOT/'.tools/kart-assets/MeshCodec/build/tests/mc_test'),str(dest.parent),str(checkdir)],check=True)
    assert(checkdir/native.HOST.removesuffix('.mc')).read_bytes()==bytes(data)
    # Restrict differences to UV bytes in GPU data; metadata and index region exact.
    assert source[:gpu+info['index_out']]==data[:gpu+info['index_out']]
    report={'status':'host-validated original-color candidate; no in-game claim',
        'source_geometry_directory':str(geometry.relative_to(ROOT)),
        'source_geometry_compressed_sha256':hashlib.sha256(originalpackage).hexdigest(),
        'model_compressed_sha256':hashlib.sha256(package).hexdigest(),
        'model_original_decoded_bytes':len(source),'model_candidate_decoded_bytes':len(data),
        'model_metadata_and_indices_unchanged':True,'model_full_buffer_decoder_roundtrip':True,
        'textures':textures,'uv':uvreport,
        'albedo_sources':['Kart/BodyTex/BodyK_Std_Mro_Alb.szs','Kart/Tire/TireK_Std.szs'],
        'texture_format_reference':'https://github.com/KillzXGaming/Switch-Toolbox/blob/master/File_Format_Library/FileFormats/Texture/TXTG.cs',
        'restbl':'Model and every texture decoded allocation unchanged; no size expansion required.',
        'limits':['Mario/tire source images downsampled into256px combined atlas; not original1024px detail.',
                  'Original TOTK shader retained. Neutral128RGB native normal and zeroBC4 material mask remove Cart stone patterns but shader/color-space response requires runtime testing.',
                  'Severe minification mipmaps can mix atlas body/tire regions; confirm LOD appearance in game.',
                  'Texture resources remain under native Cart names and affect any use of those texture resources.',
                  'No runtime, script, controller or installed file changed by this build.']}
    if report_extra:report.update(report_extra)
    previous_path=OUT/'validation.json'
    if previous_path.exists():
        previous=json.loads(previous_path.read_text())
        if previous.get('model_compressed_sha256')==report['model_compressed_sha256'] and previous.get('runtime_observation'):
            report['runtime_observation']=previous['runtime_observation']
            report['status']=previous['status']
    (OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'model':report['model_compressed_sha256'],'textures':len(textures),'decoded_bytes':len(data)}))

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=pathlib.Path,default=OUT)
    parser.add_argument('--geometry',type=pathlib.Path,default=ROOT/'assets/native-cart-mod')
    args=parser.parse_args();OUT=args.out
    build(args.geometry)
