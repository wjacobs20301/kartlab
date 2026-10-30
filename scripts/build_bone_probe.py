#!/usr/bin/env python3
"""Build a read-only runtime bone/model-chain discovery diagnostic.

Run 1: spawn the kart through the real input path, then dump only the pointer
window INSIDE the Model object (engine::component::Model, proven mapped by the
modelMtx read at +0x1f8). No deref of unverified pointers, so a bogus guest
pointer cannot fault the game. Analyse the dump offline to identify the g3d
ModelObj pointer, then follow it in a targeted run 2.
"""
from pathlib import Path
from compact_native_script import compact

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / 'runtime/candidates/native-rider-controls/autorun.as').read_text()
prefix = src[:src.index('void main(){')]
prefix = '\n'.join(l.strip() for l in prefix.splitlines()
                    if l.strip() and not l.lstrip().startswith('//'))

probe = r'''
void dumpModel(){
 ActorBase@ k=getKart();if(k is null){sys::debugLog("BONE no-kart");return;}
 ptr_t actor=ptr_from_ActorBase(k);
 ptr_t list=ptr_deref_u64(actor+0x228);
 sys::debugLog("BONE actor="+actor+" list="+list+" pos="+k.pos_x+","+k.pos_y+","+k.pos_z);
 if(!riderGuestPointer(list)){sys::debugLog("BONE bad-list");return;}
 ptr_t mc=ptr_deref_u64(list+0x10);
 sys::debugLog("BONE modelComp="+mc);
 if(!riderGuestPointer(mc)){sys::debugLog("BONE bad-mc");return;}
 ptr_t model=ptr_deref_u64(mc+0x28);
 sys::debugLog("BONE model="+model);
 if(!riderGuestPointer(model)){sys::debugLog("BONE bad-model");return;}
 sys::debugLog("BONE modelMtxT="+ptr_deref_float(model+0x204)+","+ptr_deref_float(model+0x214)+","+ptr_deref_float(model+0x224));
 for(uint o=0;o<0x1f8;o+=8){
  ptr_t v=ptr_deref_u64(model+o);
  if(riderGuestPointer(v))sys::debugLog("BONE m+"+o+"="+v);
 }
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
out = ROOT / 'runtime/diagnostics/bone_probe_model_window.as'
out.write_text(result)
print(out, n)
