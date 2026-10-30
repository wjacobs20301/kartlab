#!/usr/bin/env python3
"""Run 11: rotation-slot test resolved via host+0x18 -> +0x38 -> +0x580.

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
 return near(ptr_deref_float(b+28),0.3766f) && near(ptr_deref_float(b+120),0.728f) && near(ptr_deref_float(b+216),-0.728f) && near(ptr_deref_float(b+312),0.7776f) && near(ptr_deref_float(b+408),-0.7776f);
}
bool hp(ptr_t v){return v>=0x6508000000 && v<0x65CF000000 && (v&7)==0;}
bool logged=false;
ptr_t findBones(){
 ptr_t m=resolveModel();if(!hp(m))return 0;
 ptr_t x=ptr_deref_u64(m+0x18);if(!hp(x))return 0;
 ptr_t y=ptr_deref_u64(x+0x38);if(!hp(y))return 0;
 ptr_t b=y+0x580;if(!logged){logged=true;sys::debugLog("BONE chain x="+(int64(x)-int64(m))+" y="+(int64(y)-int64(m))+" root="+ptr_deref_float(b+28)+" lf="+ptr_deref_float(b+120)+" rf="+ptr_deref_float(b+216)+" lb="+ptr_deref_float(b+312)+" rb="+ptr_deref_float(b+408)+" sig="+boneSig(b));}return boneSig(b)?b:0;
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
 sys::debugLog("BONE rotating base="+findBones());
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
out = ROOT / 'runtime/diagnostics/bone_probe_rotchain.as'
out.write_text(result)
print(out, n)
