#!/usr/bin/env python3
"""Run 7: guarded rotation-slot test.

Run 6b crashed: a write landed on a live heap pointer, so the bone array is
NOT reliably at model+35280. This probe locates the array by signature and
validates it every frame before writing; on mismatch it rescans, and writes
nothing if no valid array is found.

Signature (fields never written by us):
  Skl_Root entry: Y translate (+28) ~= 0.3766
  wheel entries 1..4: X translate (+24) ~= +0.728, -0.728, +0.7776, -0.7776
  entries 0..4: scale (+56,+60,+64) == 1
Test: wheels lifted to local Y=1.2; 90-degree yaw quaternion (0,.7071,0,.7071)
into LB (idx3) slot +4 and RB (idx4) slot +80.
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
bool near(float a,float b){return a>b-0.002f && a<b+0.002f;}
bool boneSig(ptr_t b){
 if(!near(ptr_deref_float(b+28),0.3766f))return false;
 if(!near(ptr_deref_float(b+120),0.728f) || !near(ptr_deref_float(b+216),-0.728f))return false;
 if(!near(ptr_deref_float(b+312),0.7776f) || !near(ptr_deref_float(b+408),-0.7776f))return false;
 for(uint i=0;i<5;i++){ptr_t e=b+96*i;if(ptr_deref_float(e+56)!=1.0f || ptr_deref_float(e+60)!=1.0f || ptr_deref_float(e+64)!=1.0f)return false;}
 return true;
}
ptr_t boneModel=0,boneBase=0;
ptr_t findBones(){
 ptr_t model=resolveModel();if(model==0){boneModel=0;boneBase=0;return 0;}
 if(model==boneModel && boneBase!=0 && boneSig(boneBase))return boneBase;
 boneModel=model;boneBase=0;
 for(uint o=0;o+480<0xDD00;o+=16){if(near(ptr_deref_float(model+o+28),0.3766f) && boneSig(model+o)){boneBase=model+o;sys::debugLog("BONE found off="+o);return boneBase;}}
 sys::debugLog("BONE not-found");return 0;
}
void quat(ptr_t p){ptr_write_float(p,0);ptr_write_float(p+4,0.7071f);ptr_write_float(p+8,0);ptr_write_float(p+12,0.7071f);}
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
  ptr_t b=findBones();
  if(b!=0){
   for(uint i=1;i<=4;i++)ptr_write_float(b+96*i+28,1.2f);
   quat(b+288+4);
   quat(b+384+80);
  }
  input(1,0);controllerFrame(pad);
 }
}
'''

result = compact(prefix + probe)
n = len(result.encode())
assert n < 8192, n
out = ROOT / 'runtime/diagnostics/bone_probe_guarded.as'
out.write_text(result)
print(out, n)
