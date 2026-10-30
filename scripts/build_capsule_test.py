#!/usr/bin/env python3
"""Build runtime/diagnostics/kart_capsule_test.as: inventory karts.

1. ZL+ZR+Y with the Pipe Frame selected drops its capsule; Link walks onto it pressing A (item-get popup, screenshot
   at `CAP pickup`). 2. Holding D-pad Up opens the Zonai device menu (screenshot at `CAP menu`); releasing drops the
   selected device. 3. A Standard Bike created with createSimple (not watched by the controller, like one placed from a
   capsule) is mounted: the controller must adopt it (`KART adopted Standard Bike`) and drive it (`CAP driving`).
Logs `CAP <phase>` lines; screenshots are taken outside.
"""
from pathlib import Path
from build_native_wheels import minify, CAND

ROOT = Path(__file__).resolve().parents[1]

BODY = r'''
ptr_t tp=0;
void feed(uint64 k,int x,int y,int rx,int ry=0){
 simActive=true;simHeld=k;simLX=x;simLY=y;simRX=rx;simRY=ry;controllerFrame(tp);
 if(overrideActive)input(1,outButtons,outLX,outLY,outRX,outRY);else input(1,k,x,y,rx,ry);
}
void cap(const string &in l){ActorBase@ a=getKart();sys::debugLog("CAP "+l+" riding="+playerIsRiding(a)+" kart="+(a is null?"none":a.getName())+" type="+spawnedType+" v="+driveSpeed+" player="+Player.pos_x+","+Player.pos_y+","+Player.pos_z);}
void main(){
 initKart();devChords=true;tp=resolvePadInput();if(tp==0)return;
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady())return;
 Player.setPos(-150,127.8,-62);input(90,0);for(uint w=0;w<200 && !(worldReady() && abs(Player.pos_x+150)<20);w++)input(10,0);input(60,0);if(!worldReady())return;
 cap("field");
 kartType=1;
 for(uint f=0;f<4;f++)feed(0,0,0,0);
 for(uint f=0;f<4;f++)feed(uint64(ZL|ZR|Y),0,0,0);
 for(uint f=0;f<40;f++)feed(0,0,0,0);
 cap("dropped");
 for(uint c=0;c<2;c++){
  actor::createAndWatch(3,c==0?"SpObj_ControlStick_Capsule_A_01":"SpObj_ControlStick_Capsule_A_04",Player.pos_x+1.0f,Player.pos_y+0.3f,Player.pos_z);
  for(uint f=0;f<60;f++){feed(0,0,0,0);if(f%20==0){ActorBase@ w=ActorWatcher::get(3);sys::debugLog("CAP cap"+c+" "+(w is null?"null":w.getName()+" "+w.pos_x+","+w.pos_y+","+w.pos_z));}}
  ActorBase@ w=ActorWatcher::get(3);
  if(w !is null){Player.setPos(w.pos_x-0.9f,Player.pos_y,w.pos_z);Player.setRot(0,0,1,0,1,0,-1,0,0);input(5,0);}
  for(uint f=0;f<40 && worldReady();f++)feed(f%8<4?uint64(A):0,0,0,0);
  @w=ActorWatcher::get(3);sys::debugLog("CAP after-pick"+c+" "+(w is null?"gone":w.getName()+" "+w.pos_x+","+w.pos_z));
  cap("pickup"+c);
  for(uint f=0;f<90;f++)feed(0,0,0,0);
  for(uint f=0;f<6;f++)feed(uint64(A),0,0,0);for(uint f=0;f<30;f++)feed(0,0,0,0);
 }
 ActorWatcher::clearSlot(3);
 cap("pickup");
 for(uint f=0;f<90;f++)feed(0,0,0,0);
 cap("pickup2");
 for(uint f=0;f<6;f++)feed(uint64(A),0,0,0);
 for(uint f=0;f<40;f++)feed(0,0,0,0);
 for(uint f=0;f<4;f++)feed(uint64(PLUS),0,0,0);
 for(uint f=0;f<60;f++)feed(0,0,0,0);
 for(uint t=0;t<10;t++){for(uint f=0;f<3;f++)feed(uint64(R),0,0,0);for(uint f=0;f<12;f++)feed(0,0,0,0);}
 for(uint t=0;t<2;t++){for(uint f=0;f<3;f++)feed(uint64(L),0,0,0);for(uint f=0;f<30;f++)feed(0,0,0,0);}
 cap("inv0");
 for(uint t=1;t<6;t++){for(uint f=0;f<3;f++)feed(0,32767,0,0);for(uint f=0;f<30;f++)feed(0,0,0,0);cap("inv"+t);}
 for(uint f=0;f<3;f++)feed(uint64(A),0,0,0);for(uint f=0;f<30;f++)feed(0,0,0,0);cap("sub");
 for(uint f=0;f<3;f++)feed(uint64(A),0,0,0);for(uint f=0;f<40;f++)feed(0,0,0,0);cap("chosen");
 for(uint f=0;f<4;f++)feed(uint64(B),0,0,0);
 for(uint f=0;f<60;f++)feed(0,0,0,0);
 for(uint f=0;f<4;f++)feed(uint64(B),0,0,0);
 for(uint f=0;f<60;f++)feed(0,0,0,0);
 cap("thrown");
 for(uint f=0;f<90 && !wasRiding;f++)feed(f%8<4?uint64(A):0,0,f<40?9000:0,0);
 cap("placed");
 if(!wasRiding){
  Matrix33f r=Player.rot;float kx=Player.pos_x-4*r.a2,kz=Player.pos_z-4*r.a8;
  actor::createAndWatch(3,"SpObj_ControlStick_A_04",kx,Player.pos_y+0.6f,kz);
  for(uint f=0;f<150;f++){feed(0,0,0,0);if(f%30==0){ActorBase@ w=ActorWatcher::get(3);sys::debugLog("CAP w3 "+(w is null?"null":w.getName()+" "+w.pos_x+","+w.pos_y+","+w.pos_z));}}
  ActorBase@ w=ActorWatcher::get(3);if(w !is null){kx=w.pos_x;kz=w.pos_z;}
  for(uint t=0;t<8 && !wasRiding;t++){
   Player.setRot(0,0,-1,0,1,0,1,0,0);input(2,0);Player.setPos(kx+1.4f,Player.pos_y,kz);input(20,0);
   feed(uint64(A),0,0,0);for(uint f=0;f<40;f++)feed(0,0,0,0);
   cap("try mount "+t);
  }
 }
 for(uint f=0;f<20;f++)feed(0,0,0,0);
 for(uint f=0;f<120 && worldReady();f++){feed(uint64(A),f>60?20000:0,0,0);if(f==90)cap("driving");}
 cap("drove");
 feed(uint64(X),0,0,0);for(uint f=0;f<30;f++)feed(0,0,0,0);
 sys::debugLog("CAP finished");simActive=false;input(1,0);runResident(tp);
}
'''

src = (CAND / 'controller.src.as').read_text()
prefix = src[:src.index('void main(){')]
text = minify(prefix + BODY, wrap=True)
assert len(text.encode()) < 65536
out = ROOT / 'runtime/diagnostics/kart_capsule_test.as'
out.write_text(text); print(out, len(text.encode()))
