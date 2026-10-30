#!/usr/bin/env python3
"""Run 8 (read-only): find the Cart SUBMODEL's gsys::Model.

The bone array was only coincidentally at host+35280; it belongs to the Cart
submodel, a separate gsys::Model allocation. Identify Model objects by the
host model's vtable (u64 at +0), searching:
  - components 1 (IModel), 2 (ModelInfoRef), 3 (ModelBindRef): [0..0x100]
  - the host gsys::Model [0..0x1f8]
each at one and two pointer levels. For any Model found (same type, so the
host-proven range 0..0xDD00 is mapped), scan it for the bone signature.
No writes.
"""
from pathlib import Path
from compact_native_script import compact

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / 'runtime/candidates/native-rider-controls/autorun.as').read_text()
prefix = src[:src.index('void main(){')]
prefix = '\n'.join(l.strip() for l in prefix.splitlines()
                    if l.strip() and not l.lstrip().startswith('//'))

probe = r'''
bool hp(ptr_t v){return v>=0x6508000000 && v<0x65D0000000 && (v&7)==0;}
bool near(float a,float b){return a>b-0.002f && a<b+0.002f;}
bool boneSig(ptr_t b){
 if(!near(ptr_deref_float(b+28),0.3766f))return false;
 if(!near(ptr_deref_float(b+120),0.728f) || !near(ptr_deref_float(b+216),-0.728f))return false;
 if(!near(ptr_deref_float(b+312),0.7776f) || !near(ptr_deref_float(b+408),-0.7776f))return false;
 return true;
}
ptr_t hm=0;uint64 mvt=0;
void chk(const string &in lbl,ptr_t s){
 if(s==hm)return;
 sys::debugLog("BONE SUB "+lbl+"="+s+" delta="+(int64(s)-int64(hm)));
 for(uint o=0;o+480<0xDD00;o+=16){if(near(ptr_deref_float(s+o+28),0.3766f) && boneSig(s+o)){sys::debugLog("BONE SIG "+lbl+" off="+o);return;}}
 sys::debugLog("BONE nosig "+lbl);
}
void wk(const string &in lbl,ptr_t obj,uint n,bool dp){
 for(uint o=0;o<n;o+=8){
  ptr_t v=ptr_deref_u64(obj+o);if(!hp(v))continue;
  if(ptr_deref_u64(v)==mvt){chk(lbl+"+"+o,v);continue;}
  if(!dp)continue;
  for(uint p=0;p<0x40;p+=8){ptr_t w=ptr_deref_u64(v+p);if(hp(w) && ptr_deref_u64(w)==mvt)chk(lbl+"+"+o+">"+p,w);}
 }
}
void dumpModel(){
 ActorBase@ k=getKart();if(k is null){sys::debugLog("BONE no-kart");return;}
 ptr_t list=ptr_deref_u64(ptr_from_ActorBase(k)+0x228);if(!riderGuestPointer(list)){sys::debugLog("BONE bad-list");return;}
 ptr_t mc=ptr_deref_u64(list+0x10);if(!riderGuestPointer(mc))return;
 hm=ptr_deref_u64(mc+0x28);if(!riderGuestPointer(hm))return;
 mvt=ptr_deref_u64(hm);
 sys::debugLog("BONE host="+hm+" vt="+mvt+" hp="+hp(hm));
 for(uint c=2;c<=3;c++){ptr_t comp=ptr_deref_u64(list+c*8);sys::debugLog("BONE comp"+c+"="+comp);if(riderGuestPointer(comp))wk("comp"+c,comp,0x100,true);}
 wk("host",hm,0x1f8,true);
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
out = ROOT / 'runtime/diagnostics/bone_probe_submodel.as'
out.write_text(result)
print(out, n)
