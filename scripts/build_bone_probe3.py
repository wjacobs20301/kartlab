#!/usr/bin/env python3
"""Run 3: find the wheel bone matrices.

Scan the FULL gsys::Model allocation (proven mapped to ~0xEDE0) and the far
c60 region for tight wheel fingerprints (X ±0.728/±0.7776, Z ±0.704), and
raw-dump the floats around the Skl_Root Y=0.3766 hit at model+0x984 so the
matrix stride/layout is readable.
"""
from pathlib import Path
from compact_native_script import compact

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / 'runtime/candidates/native-rider-controls/autorun.as').read_text()
prefix = src[:src.index('void main(){')]
prefix = '\n'.join(l.strip() for l in prefix.splitlines()
                    if l.strip() and not l.lstrip().startswith('//'))

probe = r'''
void scan(const string &in lbl,ptr_t base,uint n){
 if(!riderGuestPointer(base)){sys::debugLog("BONE scan-skip "+lbl);return;}
 for(uint o=0;o<n;o+=4){
  float f=ptr_deref_float(base+o);float a=f<0?-f:f;
  if((a>0.7272f&&a<0.7288f)||(a>0.7768f&&a<0.7784f)||(a>0.7032f&&a<0.7048f))
   sys::debugLog("BONE HIT "+lbl+"+"+o+"="+f);
 }
}
void raw(const string &in lbl,ptr_t base,uint start,uint count){
 for(uint i=0;i<count;i++){uint o=start+i*4;sys::debugLog("BONE RAW "+lbl+"+"+o+"="+ptr_deref_float(base+o));}
}
void dumpModel(){
 ActorBase@ k=getKart();if(k is null){sys::debugLog("BONE no-kart");return;}
 ptr_t list=ptr_deref_u64(ptr_from_ActorBase(k)+0x228);if(!riderGuestPointer(list)){sys::debugLog("BONE bad-list");return;}
 ptr_t mc=ptr_deref_u64(list+0x10);if(!riderGuestPointer(mc)){sys::debugLog("BONE bad-mc");return;}
 ptr_t model=ptr_deref_u64(mc+0x28);if(!riderGuestPointer(model)){sys::debugLog("BONE bad-model");return;}
 sys::debugLog("BONE model="+model+" pos="+k.pos_x+","+k.pos_y+","+k.pos_z);
 ptr_t c60=ptr_deref_u64(model+0x60);
 scan("model",model,0xDD00);
 scan("c60",c60,0x8000);
 raw("model",model,0x960,28);
}
void main(){
 initKart();ptr_t pad=resolvePadInput();if(pad==0){sys::debugLog("BONE pad-mismatch");while(true)sleep(1);}
 input(180,0);
 for(uint n=0;n<35;n++){
  if(worldReady() && Player.pos_x< -100 && Player.pos_x> -400 && Player.pos_y>50)break;
  input(1,1);input(90,0);
 }
 input(60,0);if(!worldReady()){sys::debugLog("BONE world-timeout");while(true)sleep(1);}
 controllerFrame(pad);input(1,uint64(ZL|ZR|DUP));controllerFrame(pad);
 for(uint f=0;f<165;f++){input(1,0);controllerFrame(pad);}
 sleep(120);
 dumpModel();
 sys::debugLog("BONE done");
 while(true)sleep(1);
}
'''

result = compact(prefix + probe)
n = len(result.encode())
assert n < 8192, n
out = ROOT / 'runtime/diagnostics/bone_probe_wheels.as'
out.write_text(result)
print(out, n)
