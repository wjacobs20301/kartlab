#!/usr/bin/env python3
"""Build runtime/diagnostics/kart_chest_test.as: kart chests at Lookout Landing (scripts/build_kart_chests.py).
Opens the four chests (screenshots at `CAP open<n>`), shows the Zonai Devices tab (`CAP tab`), takes out the
selected kart and drives it (must be adopted). Older capsule steps below are from build_capsule_test.py:

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
 initKart();tp=resolvePadInput();if(tp==0)return;
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady())return;
 Player.setPos(-146,127.8,-58.5);input(90,0);for(uint w=0;w<200 && !(worldReady() && abs(Player.pos_x+146)<20);w++)input(10,0);input(60,0);if(!worldReady())return;
 Player.setRot(0,0,-1,0,1,0,1,0,0);for(uint f=0;f<60;f++)feed(0,0,0,0);
 cap("chests");
 for(uint c=0;c<4;c++){
  Player.setRot(0,0,-1,0,1,0,1,0,0);input(2,0);Player.setPos(-154.4f,Player.pos_y+0.3f,-54.0f-3.0f*c);input(30,0);
  for(uint f=0;f<30;f++)feed(f%10<5?uint64(A):0,0,0,0);
  for(uint f=0;f<90;f++)feed(0,0,0,0);
  cap("open"+c);
  for(uint f=0;f<4;f++)feed(uint64(A),0,0,0);for(uint f=0;f<60;f++)feed(0,0,0,0);
  for(uint f=0;f<4;f++)feed(uint64(A),0,0,0);for(uint f=0;f<40;f++)feed(0,0,0,0);
 }
 Player.setRot(0,0,1,0,1,0,-1,0,0);input(2,0);Player.setPos(-140,Player.pos_y+0.3f,-58.5);input(30,0);
 for(uint f=0;f<4;f++)feed(uint64(PLUS),0,0,0);for(uint f=0;f<60;f++)feed(0,0,0,0);
 for(uint t=0;t<10;t++){for(uint f=0;f<3;f++)feed(uint64(R),0,0,0);for(uint f=0;f<12;f++)feed(0,0,0,0);}
 for(uint t=0;t<2;t++){for(uint f=0;f<3;f++)feed(uint64(L),0,0,0);for(uint f=0;f<30;f++)feed(0,0,0,0);}
 cap("tab");
 for(uint f=0;f<3;f++)feed(uint64(A),0,0,0);for(uint f=0;f<30;f++)feed(0,0,0,0);
 for(uint f=0;f<3;f++)feed(uint64(A),0,0,0);for(uint f=0;f<40;f++)feed(0,0,0,0);
 for(uint f=0;f<4;f++)feed(uint64(B),0,0,0);for(uint f=0;f<60;f++)feed(0,0,0,0);
 for(uint f=0;f<4;f++)feed(uint64(B),0,0,0);for(uint f=0;f<150;f++)feed(0,0,0,0);
 cap("placed");
 for(uint f=0;f<120 && !wasRiding;f++)feed(f%8<4?uint64(A):0,0,f<50?9000:0,0);
 cap("mounted");
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
out = ROOT / 'runtime/diagnostics/kart_chest_test.as'
out.write_text(text); print(out, len(text.encode()))
