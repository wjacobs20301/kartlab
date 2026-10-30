#!/usr/bin/env python3
"""Run 5: propagation test. Continuously write a +2.0 Y lift into all four
wheel local-translates (entry+28) and hold, so a Ryujinx screenshot shows
whether local bone-matrix writes reach the rendered wheels.

Phases: spawn -> settle -> log "BONE settled" + hold 600 frames (baseline
screenshot window) -> log "BONE lifting" -> lift forever (lifted screenshot).
Local array base = model+35280, stride 96, wheels at indices 1..4.
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
 ptr_t model=resolveModel();
 if(model==0){sys::debugLog("BONE no-model");while(true)sleep(1);}
 ptr_t base=model+35280;
 sys::debugLog("BONE settled model="+model+" LFy="+ptr_deref_float(base+96+28));
 for(uint f=0;f<600;f++){input(1,0);controllerFrame(pad);}
 sys::debugLog("BONE lifting");
 while(true){
  model=resolveModel();
  if(model!=0){
   base=model+35280;
   ptr_write_float(base+96*1+28,2.0f);
   ptr_write_float(base+96*2+28,2.0f);
   ptr_write_float(base+96*3+28,2.0f);
   ptr_write_float(base+96*4+28,2.0f);
  }
  input(1,0);controllerFrame(pad);
 }
}
'''

result = compact(prefix + probe)
n = len(result.encode())
assert n < 8192, n
out = ROOT / 'runtime/diagnostics/bone_probe_lift.as'
out.write_text(result)
print(out, n)
