#!/usr/bin/env python3
"""Build runtime/diagnostics/heap_stress_test.as: provoke the LotusKit malloc race (research/heap-race.md).

Same start as the spark test (wait for the world, open field, spawn + mount the kart), but the script allocates and frees
CHURN long strings (>15 chars, so heap, not SSO) between every frame from boot to the end, while the game's own threads
request actors (ActorMgr::requestCreateActorAsync -> LotusKit's by-value std::string of the actor name). Then drives
full-lock circles and straight runs for DRIVE frames (terrain streaming = more actor requests). Logs `HS <phase>`;
passes on `HS finished`. Env: CHURN (default 1500), DRIVE (default 1800), OUTFILE.
"""
from pathlib import Path
import os
from build_native_wheels import minify, CAND

ROOT = Path(__file__).resolve().parents[1]
CHURN = int(os.environ.get('CHURN', '1500'))
DRIVE = int(os.environ.get('DRIVE', '1800'))

BODY = r'''
ptr_t tp=0;uint churned=0;
void churn(){string keep="";for(uint i=0;i<CHURN;i++){string t="Weapon_Sword_heapstress_"+i+"_"+keep.length();keep=t.substr(0,24)+keep.substr(0,8);}churned+=CHURN;}
void wf(uint n){for(uint i=0;i<n;i++){churn();input(1,0);}}
void feed(uint64 k,int x,int y,int rx){
 churn();simActive=true;simHeld=k;simLX=x;simLY=y;simRX=rx;simRY=0;controllerFrame(tp);
 if(overrideActive)input(1,outButtons,outLX,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
void hs(const string &in l){ActorBase@ a=getKart();sys::debugLog("HS "+l+" churned="+churned+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+driveSpeed+" mounted="+playerIsRiding(a)+" contended="+(fxScr==0?0:ptr_deref_u64(fxScr+0x7ff0)));}
void main(){
 initKart();tp=resolvePadInput();if(tp==0)return;
 hs("boot");wf(180);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){churn();input(1,1);wf(90);}
 wf(60);if(!worldReady())return;
 hs("world");
 Player.setPos(-150,127.8,-62);wf(90);for(uint w=0;w<200 && !(worldReady() && abs(Player.pos_x+150)<20);w++)wf(10);wf(60);if(!worldReady())return;
 hs("field");
 controllerFrame(tp);feed(uint64(ZL|ZR|DUP),0,0,0);
 for(uint f=0;f<25;f++)feed(0,0,0,0);
 for(uint t=0;t<10 && !playerIsRiding(getKart());t++){
  ActorBase@ k=getKart();if(k is null){wf(10);continue;}
  Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
  float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
  Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);wf(2);Player.setPos(px,k.pos_y+0.3f,pz);wf(20);
  hs("try mount t="+t);
  churn();input(1,1);wf(30);
 }
 if(!playerIsRiding(getKart())){hs("mount failed");return;}
 feed(0,0,0,0);hs("mounted");
 for(uint f=0;f<DRIVE && worldReady();f++){int sx=(f/300)%2==0?32767:0;feed(uint64(A),sx,0,0);if(f%150==0)hs("drive"+f);}
 feed(uint64(X),0,0,0);for(uint f=0;f<30;f++)feed(0,0,0,0);
 hs("finished");simActive=false;input(1,0);runResident(tp);
}
'''.replace('CHURN', str(CHURN)).replace('DRIVE', str(DRIVE))
src = (CAND / 'controller.src.as').read_text()
prefix = src[:src.index('void main(){')]
text = minify(prefix + BODY, wrap=True)
assert len(text.encode()) < 65536
out = ROOT / os.environ.get('OUTFILE', 'runtime/diagnostics/heap_stress_test.as')
out.write_text(text)
print(out, len(text.encode()))
