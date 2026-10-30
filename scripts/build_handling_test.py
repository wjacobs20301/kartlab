#!/usr/bin/env python3
"""Build runtime/diagnostics/native_handling_test.as: measured handling run for the MK8DX model.

Phases (all logged as `HDL <label> f=<frame> ...` every 5 logical frames):
  circle  full throttle + full right steer, 240 frames (acceleration, top speed, turn radius)
  brake   full reverse stick, 60 frames (braking time)
  drift   rebuild speed for 60 frames, then hold R + right steer 200 frames (charge tiers), release
  boost   full throttle, straight-ish, 90 frames after release (boost speed)
  coast   neutral, 120 frames
Then B dismounts and the resident controller takes over. The test position is near the save's
Hyrule Castle Town Ruins spawn; circles keep it local.
"""
from pathlib import Path
from build_native_wheels import minify, CAND

ROOT = Path(__file__).resolve().parents[1]

BODY = r'''
ptr_t tp=0;uint hf=0;
void hsample(const string &in l){
 ActorBase@ a=getKart();if(a is null){sys::debugLog("HDL "+l+" missing");return;}
 RigidBody@ b=a.getMainRigidBody();if(b is null)return;
 Vector3f v=b.vel;Matrix33f r=a.rot;
 sys::debugLog("HDL "+l+" f="+hf+" pos="+a.pos_x+","+a.pos_y+","+a.pos_z+" vel="+v.x+","+v.y+","+v.z+" heading="+r.a2+","+r.a8
  +" up="+r.a4+" cmd="+driveSpeed+" drift="+driftDir+" charge="+driftCharge+" tier="+driftTier+" boost="+boostLeft+" mounted="+playerIsRiding(a));
}
void feed(uint64 k,int x,int y,int rx){
 simActive=true;simHeld=k;simLX=x;simLY=y;simRX=rx;simRY=0;controllerFrame(tp);
 if(overrideActive)input(1,outButtons,outLX,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
// Mario Kart controls: y>0 holds A (gas), y<0 holds B (brake/reverse); k adds other buttons (R drift).
void run(uint n,uint64 k,int x,int y,const string &in l){
 uint64 pedal=y>0?uint64(A):y<0?uint64(B):0;
 for(uint f=0;f<n && worldReady();f++){feed(k|pedal,x,0,0);hf++;if(f%10==0)hsample(l);}
}
void main(){
 initKart();tp=resolvePadInput();if(tp==0)return;
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady())return;
 // Open, gently sloping field south of Lookout Landing, found by research/site-survey.log
 // (kart dropped on a 30 m cross around (-150,-60): settled at 125.7..127.5, up >= 0.99).
 Player.setPos(-150,127.8,-62);input(90,0);if(!worldReady())return;
 sys::debugLog("HDL site player="+Player.pos_x+","+Player.pos_y+","+Player.pos_z);
 controllerFrame(tp);feed(uint64(ZL|ZR|DUP),0,0,0);
 for(uint f=0;f<165;f++)feed(0,0,0,0);
 input(1,1);input(90,0);
 if(!playerIsRiding(getKart())){sys::debugLog("HDL mount failed");return;}
 feed(0,0,0,0); // release A after getting in, as a player does
 hsample("start");
 // Everything stays on the full-lock circle, which is clear of the ruins' rubble.
 run(240,0,32767,32767,"circle");
 run(200,uint64(R),32767,32767,"drift");
 run(90,0,32767,32767,"boost");
 run(60,0,0,-32767,"brake");
 run(90,0,0,0,"coast");
 feed(uint64(X),0,0,0);run(30,0,0,0,"exit");
 sys::debugLog("HDL finished");simActive=false;input(1,0);runResident(tp);
}
'''

src = (CAND / 'controller.src.as').read_text()
prefix = src[:src.index('void main(){')]
text = minify(prefix + BODY, wrap=True)
assert len(text.encode()) < 65536
out = ROOT / 'runtime/diagnostics/native_handling_test.as'
out.write_text(text)
print(out, len(text.encode()))
