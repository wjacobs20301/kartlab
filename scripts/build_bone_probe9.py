#!/usr/bin/env python3
"""Run 9 (read-only): locate the Cart bone array by content near the host.

The array is not reachable as a sibling gsys::Model. The Switch heap is one
contiguous mapping; every heap object seen lies in [0x6508000000,0x65D0000000).
Scan host-1MB..host+1MB (clamped to that window) in 16-byte steps for the
bone signature and log each match's offset from the host model.
"""
from pathlib import Path
from compact_native_script import compact

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / 'runtime/candidates/native-rider-controls/autorun.as').read_text()
prefix = src[:src.index('void main(){')]
prefix = '\n'.join(l.strip() for l in prefix.splitlines()
                    if l.strip() and not l.lstrip().startswith('//'))

probe = r'''
bool near(float a,float b){return a>b-0.002f && a<b+0.002f;}
bool boneSig(ptr_t b){
 if(!near(ptr_deref_float(b+120),0.728f) || !near(ptr_deref_float(b+216),-0.728f))return false;
 if(!near(ptr_deref_float(b+312),0.7776f) || !near(ptr_deref_float(b+408),-0.7776f))return false;
 return true;
}
void dumpModel(){
 ActorBase@ k=getKart();if(k is null){sys::debugLog("BONE no-kart");return;}
 ptr_t list=ptr_deref_u64(ptr_from_ActorBase(k)+0x228);if(!riderGuestPointer(list))return;
 ptr_t mc=ptr_deref_u64(list+0x10);if(!riderGuestPointer(mc))return;
 ptr_t hm=ptr_deref_u64(mc+0x28);if(!riderGuestPointer(hm))return;
 ptr_t lo=hm-0x100000,hi=hm+0x100000;
 if(lo<0x6508000000)lo=0x6508000000;if(hi>0x65D0000000-0x200)hi=0x65D0000000-0x200;
 lo=lo&~ptr_t(15);
 sys::debugLog("BONE host="+hm+" scan="+lo+".."+hi);
 uint hits=0;
 for(ptr_t p=lo;p<hi;p+=16){
  if(near(ptr_deref_float(p+28),0.3766f) && boneSig(p)){hits++;sys::debugLog("BONE SIG at="+p+" off="+(int64(p)-int64(hm)));}
 }
 sys::debugLog("BONE hits="+hits);
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
out = ROOT / 'runtime/diagnostics/bone_probe_heapscan.as'
out.write_text(result)
print(out, n)
