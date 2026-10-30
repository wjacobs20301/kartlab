#!/usr/bin/env python3
"""Read-only probe: does the native ControlStick animation turn Handle_J with the stick?

Locates the HOST model's bone records inside the host gsys::Model allocation (same 96-byte record
format as the Cart: rows +0/+16/+32, translate +48) by signature: a Skl_Root record with translate
(0, 0.3766, 0) followed by a Handle_J record with translate (0, 0.2, 0.6137). Then mounts and
logs Handle_J's rotation rows under neutral, full right, full left, forward and reverse input.
No writes beyond the installed controller's own wheel animation.
"""
from pathlib import Path
from build_native_wheels import minify, CAND

ROOT = Path(__file__).resolve().parents[1]

BODY = r'''
ptr_t tp=0,hjRec=0;
bool near(float a,float b){return a>b-0.003f && a<b+0.003f;}
ptr_t hostModel(){
 ActorBase@ a=getKart();if(a is null)return 0;
 ptr_t list=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!riderGuestPointer(list))return 0;
 ptr_t mc=ptr_deref_u64(list+0x10);if(!riderGuestPointer(mc))return 0;
 return ptr_deref_u64(mc+0x28);
}
void findHandle(){
 ptr_t m=hostModel();if(!riderGuestPointer(m))return;
 for(uint o=0;o<0x3000;o+=4){
  ptr_t s=m+o;
  if(near(ptr_deref_float(s+52),0.3766f) && near(ptr_deref_float(s+48),0) && near(ptr_deref_float(s+56),0)
   && near(ptr_deref_float(s+148),0.2f) && near(ptr_deref_float(s+152),0.6137f)){
   hjRec=s+96;sys::debugLog("HANDLE found sklRec=host+"+o+" hj=host+"+(o+96));return;
  }
 }
 sys::debugLog("HANDLE not-found");
}
void logHandle(const string &in l){
 if(hjRec==0)return;
 sys::debugLog("HANDLE "+l+" r0="+ptr_deref_float(hjRec)+","+ptr_deref_float(hjRec+4)+","+ptr_deref_float(hjRec+8)
  +" r1="+ptr_deref_float(hjRec+16)+","+ptr_deref_float(hjRec+20)+","+ptr_deref_float(hjRec+24)
  +" r2="+ptr_deref_float(hjRec+32)+","+ptr_deref_float(hjRec+36)+","+ptr_deref_float(hjRec+40)
  +" t="+ptr_deref_float(hjRec+48)+","+ptr_deref_float(hjRec+52)+","+ptr_deref_float(hjRec+56));
}
void hold(uint n,int x,int y,const string &in l){
 for(uint f=0;f<n && worldReady();f++){input(1,0,x,y);controllerFrame(tp);}
 logHandle(l);
}
void main(){
 initKart();tp=resolvePadInput();if(tp==0)return;
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady())return;
 controllerFrame(tp);input(1,uint64(ZL|ZR|DUP));controllerFrame(tp);
 for(uint f=0;f<165;f++){input(1,0);controllerFrame(tp);}
 findHandle();logHandle("unmounted");
 input(1,1);input(90,0);
 if(!playerIsRiding(getKart())){sys::debugLog("HANDLE mount failed");return;}
 hold(45,0,0,"neutral");hold(45,32767,0,"right");hold(45,0,0,"neutral2");
 hold(45,-32767,0,"left");hold(45,16000,0,"halfright");hold(30,0,0,"neutral3");
 hold(45,0,32767,"forward");hold(45,0,-32767,"reverse");hold(45,0,0,"neutral4");
 sys::debugLog("HANDLE done");
 while(true){input(1,0);controllerFrame(tp);}
}
'''

src = (CAND / 'controller.src.as').read_text()
prefix = src[:src.index('void main(){')]
out = ROOT / 'runtime/diagnostics/handle_probe.as'
text = minify(prefix + BODY, wrap=True)
assert len(text.encode()) < 65536
out.write_text(text)
print(out, len(text.encode()))
