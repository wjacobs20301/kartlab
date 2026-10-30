#!/usr/bin/env python3
"""Find flat open ground for handling tests: drop the kart onto candidate points and log where it settles."""
from pathlib import Path
from build_native_wheels import minify, CAND
ROOT = Path(__file__).resolve().parents[1]
BODY = r'''
ptr_t tp=0;
void feed(uint64 k){simActive=true;simHeld=k;simLX=0;simLY=0;simRX=0;simRY=0;controllerFrame(tp);input(1,k,0,0,0,0);}
void drop(float x,float z){
 ActorBase@ a=getKart();if(a is null){sys::debugLog("SITE nokart");return;}
 a.setPos(x,185,z);@a=null;
 float lastY=0;uint still=0;
 for(uint f=0;f<200 && worldReady();f++){
  feed(0);
  ActorBase@ k=getKart();if(k is null)return;
  if(f>20 && abs(k.pos_y-lastY)<0.01f)still++;else still=0;lastY=k.pos_y;
  if(still>15)break;
 }
 ActorBase@ k=getKart();if(k is null)return;Matrix33f r=k.rot;
 sys::debugLog("SITE "+x+" "+z+" y="+k.pos_y+" at="+k.pos_x+","+k.pos_z+" up="+r.a4);
}
void site(float x,float z){drop(x,z);drop(x+15,z);drop(x-15,z);drop(x,z+15);drop(x,z-15);}
void main(){
 initKart();tp=resolvePadInput();if(tp==0)return;
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady())return;
 controllerFrame(tp);feed(uint64(ZL|ZR|DUP));
 for(uint f=0;f<165;f++)feed(0);
 site(-250,-60);site(-200,-90);site(-300,-90);site(-250,-110);site(-150,-60);site(-350,-60);
 sys::debugLog("SITE done");
 while(true)sleep(1);
}
'''
src = (CAND / 'controller.src.as').read_text()
prefix = src[:src.index('void main(){')]
text = minify(prefix + BODY, wrap=True)
out = ROOT / 'runtime/diagnostics/site_survey.as'; out.write_text(text); print(out, len(text.encode()))
