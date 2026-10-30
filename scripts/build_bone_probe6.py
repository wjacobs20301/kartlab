#!/usr/bin/env python3
"""Run 6: find the rotation slot in the 96-byte local bone entry.

Wheels are held lifted (local Y=1.2) so rotation is visible. A 60-degree yaw
quaternion (x,y,z,w)=(0,0.5,0,0.866) is written each frame into a different
candidate slot per wheel:
  LF (idx1): entry+4..+16      (identity (0,0,0,1) observed there)
  RF (idx2): entry+80..+92     (identity (-0,0,0,1) observed there)
  LB (idx3): entry+0..+12      (alternate alignment)
  RB (idx4): untouched rotation (control)
Note: the host harness stub lacks ptr_write_float; the real runtime registers it.
"""
from pathlib import Path
from compact_native_script import compact

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / 'runtime/candidates/native-rider-controls/autorun.as').read_text()
prefix = src[:src.index('void main(){')]
prefix = '\n'.join(l.strip() for l in prefix.splitlines()
                    if l.strip() and not l.lstrip().startswith('//'))

probe = r'''
ptr_t resolveModel(){
 ActorBase@ k=getKart();if(k is null)return 0;
 ptr_t list=ptr_deref_u64(ptr_from_ActorBase(k)+0x228);if(!riderGuestPointer(list))return 0;
 ptr_t mc=ptr_deref_u64(list+0x10);if(!riderGuestPointer(mc))return 0;
 ptr_t model=ptr_deref_u64(mc+0x28);if(!riderGuestPointer(model))return 0;
 return model;
}
void quat(ptr_t p){ptr_write_float(p,0);ptr_write_float(p+4,0.5f);ptr_write_float(p+8,0);ptr_write_float(p+12,0.866f);}
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
 sys::debugLog("BONE rotating");
 while(true){
  ptr_t model=resolveModel();
  if(model!=0){
   ptr_t b=model+35280;
   for(uint i=1;i<=4;i++)ptr_write_float(b+96*i+28,1.2f);
   quat(b+96+4);
   quat(b+192+80);
   quat(b+288);
  }
  input(1,0);controllerFrame(pad);
 }
}
'''

result = compact(prefix + probe)
n = len(result.encode())
assert n < 8192, n
out = ROOT / 'runtime/diagnostics/bone_probe_rotslot.as'
out.write_text(result)
print(out, n)
