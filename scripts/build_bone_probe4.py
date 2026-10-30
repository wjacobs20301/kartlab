#!/usr/bin/env python3
"""Run 4: read the 96-byte per-bone local structure and locate the world
matrix array.

- raw-dump 72 floats from model+35280 (Skl_Root, LF, RF local entries) to
  reveal translate/rotation layout within the 0x60 stride.
- scan the full gsys::Model allocation for world-translate values near the
  live kart position (wheel world coords), to find the world/skinning matrix
  array that the rigid-bound tires actually use.
"""
from pathlib import Path
from compact_native_script import compact

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / 'runtime/candidates/native-rider-controls/autorun.as').read_text()
prefix = src[:src.index('void main(){')]
prefix = '\n'.join(l.strip() for l in prefix.splitlines()
                    if l.strip() and not l.lstrip().startswith('//'))

probe = r'''
void raw(const string &in lbl,ptr_t base,uint start,uint count){
 for(uint i=0;i<count;i++){uint o=start+i*4;sys::debugLog("BONE RAW "+lbl+"+"+o+"="+ptr_deref_float(base+o));}
}
void wscan(const string &in lbl,ptr_t base,uint n,float cx,float cz){
 for(uint o=0;o<n;o+=4){
  float f=ptr_deref_float(base+o);
  if((f>cx-0.95f&&f<cx+0.95f)&&!(f>cx-0.02f&&f<cx+0.02f)){
   float g=ptr_deref_float(base+o+8);
   if(g>cz-0.95f&&g<cz+0.95f)sys::debugLog("BONE W "+lbl+"+"+o+" x="+f+" z="+g);
  }
 }
}
void dumpModel(){
 ActorBase@ k=getKart();if(k is null){sys::debugLog("BONE no-kart");return;}
 ptr_t list=ptr_deref_u64(ptr_from_ActorBase(k)+0x228);if(!riderGuestPointer(list)){sys::debugLog("BONE bad-list");return;}
 ptr_t mc=ptr_deref_u64(list+0x10);if(!riderGuestPointer(mc)){sys::debugLog("BONE bad-mc");return;}
 ptr_t model=ptr_deref_u64(mc+0x28);if(!riderGuestPointer(model)){sys::debugLog("BONE bad-model");return;}
 sys::debugLog("BONE model="+model+" pos="+k.pos_x+","+k.pos_y+","+k.pos_z);
 raw("L",model,35280,72);
 wscan("w",model,0xDD00,k.pos_x,k.pos_z);
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
out = ROOT / 'runtime/diagnostics/bone_probe_struct.as'
out.write_text(result)
print(out, n)
