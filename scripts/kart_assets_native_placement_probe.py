#!/usr/bin/env python3
"""Execute isolated MK8DX ARM32 setup/transform code in private Unicorn memory.

Reads local extracted game files; never attaches to or edits a game process.
The macOS sandbox SIGILLs in Unicorn.mem_map, so run outside that sandbox.
This is a neutral, unit-scale setup probe, not live-game runtime evidence.
"""
from pathlib import Path
import hashlib, json, math, struct, sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.tools/kart-assets/python'))
from unicorn import Uc, UcError, UC_ARCH_ARM, UC_MODE_ARM, UC_HOOK_CODE
from unicorn.arm_const import *
from elftools.elf.elffile import ELFFile
from kart_assets_parts_placement import inspect

import os
# KART_BODY_INDEX = row in Parts.bin BODY (MK8 order: 0 K_Std, 1 K_Skl Pipe Frame, 14 B_Std, 31 K_Bds B Dasher).
BODY_INDEX=int(os.environ.get('KART_BODY_INDEX','0'))
OUT=ROOT/('assets/source-native-placement' if BODY_INDEX==0 else f'assets/source-native-placement-b{BODY_INDEX}')

def main():
    elfpath=ROOT/'.work/native/mk8dx-main.elf'
    with elfpath.open('rb') as f:
        e=ELFFile(f);segments=[(s['p_vaddr'],s.data())for s in e.iter_segments()if s['p_type']=='PT_LOAD']
    def read(a,n):return next(b[a-base:a-base+n]for base,b in segments if base<=a and a+n<=base+len(b))
    # Resolve imported symbols from actual MOD0 dynamic tags / ELF32 REL.
    mod=struct.unpack('<I',read(4,4))[0];assert read(mod,4)==b'MOD0'
    dyn=mod+struct.unpack('<i',read(mod+4,4))[0];tags={}
    for a in range(dyn,dyn+4096,8):
        tag,val=struct.unpack('<II',read(a,8));tags[tag]=val
        if tag==0:break
    names={}
    for a in range(tags[23],tags[23]+tags[2],8):
        slot,info=struct.unpack('<II',read(a,8));sym=read(tags[6]+(info>>8)*16,16)
        name=read(tags[5]+struct.unpack_from('<I',sym)[0],256).split(b'\0')[0].decode()
        names[slot]=name
    imports={}
    # ARM PLT has add-ip / add-ip / ldr-pc, 12-byte entries.
    for a in range(0xaf2164,0xaf2300,12):
        w1,w2,w3=struct.unpack('<3I',read(a,12))
        def imm(w):v=w&255;r=((w>>8)&15)*2;return ((v>>r)|(v<<(32-r)))&0xffffffff if r else v
        slot=a+8+imm(w1)+imm(w2)+(w3&4095)
        if slot in names:imports[a]=names[slot]
    expected={0xaf21a0:'__cxa_guard_acquire',0xaf21ac:'__cxa_guard_release',
        0xaf2224:'__aeabi_f2lz',0xaf2230:'sqrtf',0xaf223c:'sinf',0xaf2248:'cosf',0xaf2254:'atan2f'}
    assert all(imports.get(a)==n for a,n in expected.items())
    u=Uc(UC_ARCH_ARM,UC_MODE_ARM);u.ctl_set_cpu_model(UC_CPU_ARM_MAX)
    u.mem_map(0,0x2000000)
    for a,b in segments:u.mem_write(a,b)
    u.mem_map(0x2000000,0x300000)
    u.reg_write(UC_ARM_REG_C1_C0_2,15<<20);u.reg_write(UC_ARM_REG_FPEXC,1<<30)
    obj,indices,settings,stack,trap=0x2010000,0x2020000,0x2030000,0x21f0000,0x2200000
    def word(a,v):u.mem_write(a,struct.pack('<I',v))
    def vec(a,v):u.mem_write(a,struct.pack('<'+'f'*len(v),*v))
    def floats(a,n):return list(struct.unpack('<'+'f'*n,u.mem_read(a,n*4)))
    def sfloat(r):return struct.unpack('<f',struct.pack('<I',u.reg_read(r)))[0]
    imported_calls=[];current_steps=0
    def hook(mu,a,size,unused):
        nonlocal current_steps
        current_steps+=1
        if a in imports:
            name=imports[a];imported_calls.append(dict(address=hex(a),symbol=name))
            if name=='__cxa_guard_acquire':
                g=mu.reg_read(UC_ARM_REG_R0);mu.reg_write(UC_ARM_REG_R0,int(mu.mem_read(g,1)[0]==0))
            elif name=='__cxa_guard_release':mu.mem_write(mu.reg_read(UC_ARM_REG_R0),b'\x01')
            elif name=='__aeabi_f2lz':
                n=int(sfloat(UC_ARM_REG_R0))&0xffffffffffffffff
                mu.reg_write(UC_ARM_REG_R0,n&0xffffffff);mu.reg_write(UC_ARM_REG_R1,n>>32)
            elif name in ['sqrtf','sinf','cosf','atan2f']:
                x=sfloat(UC_ARM_REG_S0);y=sfloat(UC_ARM_REG_S1)
                result={'sqrtf':lambda:math.sqrt(x),'sinf':lambda:math.sin(x),
                    'cosf':lambda:math.cos(x),'atan2f':lambda:math.atan2(x,y)}[name]()
                mu.reg_write(UC_ARM_REG_S0,struct.unpack('<I',struct.pack('<f',result))[0])
            else:raise RuntimeError('Unmodeled imported call '+name)
            mu.reg_write(UC_ARM_REG_PC,mu.reg_read(UC_ARM_REG_LR))
        elif a<0x1000:raise RuntimeError(f'Unexpected escaped address {a:#x}')
    u.hook_add(UC_HOOK_CODE,hook);executions=[]
    def run(start,stop=trap,reset=True,**kw):
        nonlocal current_steps
        if reset:u.reg_write(UC_ARM_REG_SP,stack);u.reg_write(UC_ARM_REG_LR,trap)
        for k,v in kw.items():u.reg_write(globals()['UC_ARM_REG_'+k.upper()],v)
        current_steps=0
        try:u.emu_start(start,stop,count=500000)
        except UcError as err:raise RuntimeError(f'{err}; PC={u.reg_read(UC_ARM_REG_PC):#x}')from err
        assert u.reg_read(UC_ARM_REG_PC)==stop,hex(u.reg_read(UC_ARM_REG_PC))
        executions.append(dict(start=hex(start),stop=hex(stop),instructions=current_steps))
    parts=inspect(BODY_INDEX);raw=(ROOT/parts['source']).read_bytes();addresses={}
    for i,key in enumerate(['BODY','TIRE','BDTR','TRBD']):
        record=parts['records'][key];at=0x2040000+i*0x1000;addresses[key]=at;off=int(record['file_offset'],16)
        u.mem_write(at,raw[off:off+record['bytes']])
    word(settings+0x20,0);word(settings+0xa5c,2);word(settings+0xa60,2)
    run(0x2db594,0x2dbcb8,r0=settings,r8=addresses['BODY'],r12=addresses['TIRE'],
        r4=addresses['TIRE'],r3=addresses['BDTR'],lr=addresses['TRBD'])
    vec(indices,[0,0]);run(0x149514,r0=obj,r1=indices,r2=settings)   # rows are passed directly (inspect(BODY_INDEX)); index 0 within them
    constructor={hex(i):floats(obj+i,1)[0]for i in [0xc,0x10,0x14,0x18,0x1c,0x20,0x24,0x28,0x30,0x34,0x38]}
    controller,owner,state,actor=0x2050000,0x20b0000,0x20b1000,0x20d2000
    word(owner+0x1c,state);word(owner+0x14,actor)
    identity=[1,0,0,0,1,0,0,0,1,0,0,0];vec(actor+0x244,identity)
    physical=[];visual=[]
    for i in range(4):
        p=0x2070000+i*0x1000;m=0x2080000+i*0x1000;physical.append(p);visual.append(m)
        word(controller+8+4*i,p);word(controller+0x18+4*i,m);word(p+4,owner);word(p+8,m);word(m+4,owner)
        word(stack,0);word(stack+4,i%2);word(stack+8,int(i>=2))
        run(0x15fec4,0x15ffc0,r0=m,r1=owner,r2=indices,r3=4)
    word(controller+0x34,2);word(controller+0x38,2)
    word(stack,0x20d1000);vec(0x20d1000,[0,-1,0])
    u.reg_write(UC_ARM_REG_S0,0x3f800000)
    run(0x15a6dc,r0=controller,r1=obj,r2=0,r3=0x20d0000)
    body_offset=floats(0x20d0000,3);wheels=[]
    for i,(p,m)in enumerate(zip(physical,visual)):
        run(0x15d2f0,r0=p)
        packet=0x20c0000;u.mem_write(packet,bytes(0x200))
        run(0x15f7a8,r0=p,r1=packet,r2=packet+0xc)
        position=floats(packet,3);normal=floats(packet+0xc,3)
        bodyframe=0x20c1000;vec(bodyframe,identity)
        # Explicit static render pose: the 0x1615b4 camber input is 1.
        # Dynamic gameplay can vary that input; this selects zero camber.
        vec(packet+0xb8,[1.])
        run(0x160bb4,0x16105c,r0=m,r1=bodyframe,r2=packet)
        matrix=floats(m+0x2c,12);scale=floats(m+0x8c,3)
        assert all(math.isfinite(x)for x in matrix+scale)
        # Source 0x161468..0x16149c adds scaled matrix-X * axial offset to
        # render translation when handing the wheel attachment to the arm.
        import numpy as np
        mat=np.array(matrix[:9]).reshape(3,3).T
        inner=np.array(matrix[9:12])+mat[:,0]*scale[0]*floats(m+0xb8,1)[0]
        vec(packet+0x6c,inner.tolist())
        source_body_frame=identity.copy();source_body_frame[9:12]=body_offset
        vec(0x20d3000,source_body_frame)
        word(stack,packet);word(stack+4,p+0xc8);word(stack+8,p+0xec)
        u.reg_write(UC_ARM_REG_S0,0x3f800000);u.reg_write(UC_ARM_REG_S1,0)
        run(0x15f878,r0=p,r1=0x20d4000,r2=0x20d4100,r3=0x20d3000)
        arm_matrix=floats(0x20d4000,12)
        # Caller 0x15d9d4..0x15da18 supplies both matrices' translation from
        # the source arm anchor transformed by the body matrix.
        arm_matrix[9:12]=(np.array(floats(p+0xc8,3))+np.array(body_offset)).tolist()
        wheels.append(dict(name=['LF','RF','LB','RB'][i],spring_length=floats(p+0x78,1)[0],
            constructor_flags=list(u.mem_read(m+0x9c,3)),physical_center=position,
            normal=normal,render_matrix=matrix,render_center=matrix[9:12],render_scale=scale,
            axial_offsets=floats(m+0xb8,2),
            arm_source_anchors=floats(p+0xc8,9),arm_reference_vectors=floats(p+0xec,9),
            arm_inner_attachment=inner.tolist(),normal_arm_matrix=arm_matrix))
    result=dict(status='offline neutral ARM execution; no live-game test',input_game='MK8DX 1.7.1',
        source_elf=str(elfpath.relative_to(ROOT)),source_elf_sha256=hashlib.sha256(elfpath.read_bytes()).hexdigest(),
        source_parts_sha256=parts['sha256'],indices=dict(body=BODY_INDEX,tire=0),unit_scale=1,
        body_translation=body_offset,constructor=constructor,wheels=wheels,
        static_render_input=dict(camber_input=1,steering_angle=0,antigravity_blend=0,
            normal_arm_blend=1,antigravity_arm_blend=0),
        imported_functions={hex(a):n for a,n in expected.items()},imported_calls=imported_calls,
        imported_semantics='Single-thread C++ guard functions; float-to-integer truncation; host IEEE float math rounded to binary32. Native static initialization and all game transform instructions execute.',
        executions=executions,limits=['Scene renderer and live physics world are not instantiated.',
            'Probe stops after native neutral wheel matrix and scale calculation, before scene submission.',
            'Steering, spin, suspension motion, body pose animation and actor collision require separate tests.'],
        installed=False)
    OUT.mkdir(parents=True,exist_ok=True);(OUT/'native-probe.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(dict(body_translation=body_offset,wheels=[dict(name=x['name'],center=x['render_center'],scale=x['render_scale'])for x in wheels]),indent=2))

if __name__=='__main__':main()
