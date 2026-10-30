#!/usr/bin/env python3
"""Build runtime/diagnostics/kart_pair_test.as: spawn a B Dasher, then a Standard Kart, in one session (resources are
shared by path across packs; both must keep their own model). Screenshot at `PAIR both`. Earlier notes:

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
void idle(uint n){for(uint f=0;f<n;f++)feed(0,0,0,0);}
void main(){
 initKart();devChords=true;tp=resolvePadInput();if(tp==0)return;
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady())return;
 Player.setPos(-140,127.8,-75);input(90,0);for(uint w=0;w<200 && !(worldReady() && abs(Player.pos_x+140)<20);w++)input(10,0);input(60,0);if(!worldReady())return;
 Player.setRot(0,0,1,0,1,0,-1,0,0);idle(30);
 kartType=2;idle(4);for(uint f=0;f<4;f++)feed(uint64(ZL|ZR|DUP),0,0,0);idle(30);
 sys::debugLog("PAIR first ready="+(getKart() !is null)+" "+(getKart() is null?"":getKart().getName()));
 Player.setRot(0,0,1,0,1,0,-1,0,0);input(2,0);Player.setPos(Player.pos_x,Player.pos_y+0.3f,Player.pos_z-4.0f);input(30,0);
 kartType=0;idle(4);for(uint f=0;f<4;f++)feed(uint64(ZL|ZR|DUP),0,0,0);idle(30);
 sys::debugLog("PAIR second ready="+(getKart() !is null)+" "+(getKart() is null?"":getKart().getName()));
 Player.setRot(0,0,1,0,1,0,-1,0,0);input(2,0);Player.setPos(Player.pos_x-2.0f,Player.pos_y+0.3f,Player.pos_z+2.0f);input(30,0);
 for(uint f=0;f<30;f++)feed(0,0,0,32767,0);idle(30);
 sys::debugLog("PAIR both");idle(40);
 sys::debugLog("PAIR finished");simActive=false;input(1,0);runResident(tp);
}
'''

src = (CAND / 'controller.src.as').read_text()
prefix = src[:src.index('void main(){')]
text = minify(prefix + BODY, wrap=True)
assert len(text.encode()) < 65536
out = ROOT / 'runtime/diagnostics/kart_pair_test.as'
out.write_text(text); print(out, len(text.encode()))
