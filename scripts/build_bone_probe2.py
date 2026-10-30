#!/usr/bin/env python3
"""Run 2: identify the g3d ModelObj / SkeletonObj under gsys::Model and
fingerprint-scan for the known neutral wheel-bone local translations.

Fingerprints (abs value, local-to-Skl_Root): 0.728 / 0.7776 (wheel X),
0.704 (wheel Z), 0.3766 (Skl_Root Y). All reads are either inside the
gsys::Model allocation (proven mapped) or one guarded level down a real
stored pointer; scans are bounded.
"""
from pathlib import Path
from compact_native_script import compact

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / 'runtime/candidates/native-rider-controls/autorun.as').read_text()
prefix = src[:src.index('void main(){')]
prefix = '\n'.join(l.strip() for l in prefix.splitlines()
                    if l.strip() and not l.lstrip().startswith('//'))

probe = r'''
void peek(const string &in lbl,ptr_t c){
 if(!riderGuestPointer(c)){sys::debugLog("BONE "+lbl+" skip="+c);return;}
 sys::debugLog("BONE "+lbl+"="+c+" v0="+ptr_deref_u64(c)+" u32_30="+ptr_deref_u32(c+0x30)+" p38="+ptr_deref_u64(c+0x38)+" p40="+ptr_deref_u64(c+0x40)+" p48="+ptr_deref_u64(c+0x48));
}
void scan(const string &in lbl,ptr_t base,uint n){
 if(!riderGuestPointer(base)){sys::debugLog("BONE scan-skip "+lbl+"="+base);return;}
 for(uint o=0;o<n;o+=4){
  float f=ptr_deref_float(base+o);float a=f<0?-f:f;
  if((a>0.725f&&a<0.731f)||(a>0.774f&&a<0.780f)||(a>0.701f&&a<0.707f)||(a>0.374f&&a<0.379f))
   sys::debugLog("BONE HIT "+lbl+"+"+o+"="+f);
 }
}
void dumpModel(){
 ActorBase@ k=getKart();if(k is null){sys::debugLog("BONE no-kart");return;}
 ptr_t list=ptr_deref_u64(ptr_from_ActorBase(k)+0x228);if(!riderGuestPointer(list)){sys::debugLog("BONE bad-list");return;}
 ptr_t mc=ptr_deref_u64(list+0x10);if(!riderGuestPointer(mc)){sys::debugLog("BONE bad-mc");return;}
 ptr_t model=ptr_deref_u64(mc+0x28);if(!riderGuestPointer(model)){sys::debugLog("BONE bad-model");return;}
 sys::debugLog("BONE model="+model+" pos="+k.pos_x+","+k.pos_y+","+k.pos_z);
 peek("c18",ptr_deref_u64(model+0x18));
 peek("c28",ptr_deref_u64(model+0x28));
 peek("c38",ptr_deref_u64(model+0x38));
 peek("c40",ptr_deref_u64(model+0x40));
 peek("c60",ptr_deref_u64(model+0x60));
 peek("c140",ptr_deref_u64(model+0x140));
 peek("c1a0",ptr_deref_u64(model+0x1a0));
 peek("c1a8",ptr_deref_u64(model+0x1a8));
 peek("c1d8",ptr_deref_u64(model+0x1d8));
 peek("c1e0",ptr_deref_u64(model+0x1e0));
 scan("model",model,0x2000);
 scan("c40",ptr_deref_u64(model+0x40),0x1000);
 scan("c60",ptr_deref_u64(model+0x60),0x1000);
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
out = ROOT / 'runtime/diagnostics/bone_probe_identify.as'
out.write_text(result)
print(out, n)
