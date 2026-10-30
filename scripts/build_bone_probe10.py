#!/usr/bin/env python3
"""Run 10 (read-only): find the pointer path to the Cart bone buffer.

1. Chain hypothesis from earlier dumps: Y=*(*(host+0x18)+0x38); array=Y+0x568?
2. Targeted scan: for each heap pointer v in host[0..0x1f8] scan v[0..0x2000];
   for each heap pointer w=*(v+p), p<0x80, scan w[0..0x1000]. Log the path.
3. Fallback content scan host +-16MB.
All dereferences are restricted to the contiguous heap window
[0x6508000000, 0x65D0000000).
"""
from pathlib import Path
from compact_native_script import compact

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / 'runtime/candidates/native-rider-controls/autorun.as').read_text()
prefix = src[:src.index('void main(){')]
prefix = '\n'.join(l.strip() for l in prefix.splitlines()
                    if l.strip() and not l.lstrip().startswith('//'))

probe = r'''
bool hp(ptr_t v){return v>=0x6508000000 && v<0x65CF000000 && (v&7)==0;}
bool near(float a,float b){return a>b-0.002f && a<b+0.002f;}
bool sig(ptr_t b){
 return near(ptr_deref_float(b+28),0.3766f) && near(ptr_deref_float(b+120),0.728f) && near(ptr_deref_float(b+216),-0.728f) && near(ptr_deref_float(b+312),0.7776f) && near(ptr_deref_float(b+408),-0.7776f);
}
uint found=0;ptr_t hm=0;
void sc(const string &in l,ptr_t s,uint n){
 for(uint o=0;o<n;o+=16){if(sig(s+o)){found++;sys::debugLog("BONE SIG "+l+" +"+o+" at="+(s+o)+" hostoff="+(int64(s+o)-int64(hm)));}}
}
void dumpModel(){
 ActorBase@ k=getKart();if(k is null){sys::debugLog("BONE no-kart");return;}
 ptr_t list=ptr_deref_u64(ptr_from_ActorBase(k)+0x228);if(!riderGuestPointer(list))return;
 ptr_t mc=ptr_deref_u64(list+0x10);if(!riderGuestPointer(mc))return;
 hm=ptr_deref_u64(mc+0x28);if(!hp(hm))return;
 sys::debugLog("BONE host="+hm);
 ptr_t x=ptr_deref_u64(hm+0x18);
 if(hp(x)){ptr_t y=ptr_deref_u64(x+0x38);sys::debugLog("BONE chain x="+(int64(x)-int64(hm))+" y="+(int64(y)-int64(hm)));if(hp(y)){sys::debugLog("BONE chainsig="+sig(y+0x568));sc("chainY",y,0x2000);}}
 for(uint o=0;o<0x1f8;o+=8){
  ptr_t v=ptr_deref_u64(hm+o);if(!hp(v))continue;
  sc("h"+o,v,0x2000);
  for(uint p=0;p<0x80;p+=8){ptr_t w=ptr_deref_u64(v+p);if(hp(w))sc("h"+o+">"+p,w,0x1000);}
 }
 sys::debugLog("BONE targeted found="+found);
 if(found==0){
  ptr_t lo=hm-0x1000000,hi=hm+0x1000000;if(lo<0x6508000000)lo=0x6508000000;if(hi>0x65CF000000)hi=0x65CF000000;
  lo=lo&~ptr_t(15);sc("wide",lo,uint(hi-lo));
  sys::debugLog("BONE wide found="+found);
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
out = ROOT / 'runtime/diagnostics/bone_probe_path.as'
out.write_text(result)
print(out, n)
