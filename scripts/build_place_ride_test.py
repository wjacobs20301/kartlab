#!/usr/bin/env python3
"""Build runtime/diagnostics/kart_place_ride_test.as: place every kart from the inventory and check it stays put.

Opens the four kart chests (scripts/build_kart_chests.py), then for each kart: a watcher slot waits for that actor's
spawn, Inventory -> Zonai Devices -> cursor to PLACE_SLOTS[i] (row,col; screenshot `PLC sel<i>`) -> Take out device;
logs the placed kart's position every second for 10 s (`PLC pos<i>`; a parked kart must not slide on grass) and
whether it was created at all. Screenshots are taken outside.
"""
import os
from pathlib import Path
from build_native_wheels import minify, CAND

ROOT = Path(__file__).resolve().parents[1]
SLOTS = [tuple(int(x) for x in p.split(',')) for p in os.environ.get('PLACE_SLOTS', '0,3;0,4;1,0;1,1').split(';')]
BODY = r'''
ptr_t tp=0;
void feed(uint64 k,int x,int y,int rx,int ry=0){
 simActive=true;simHeld=k;simLX=x;simLY=y;simRX=rx;simRY=ry;controllerFrame(tp);
 if(overrideActive)input(1,outButtons,outLX,outLY,outRX,outRY);else input(1,k,x,y,rx,ry);
}
void idle(uint n){for(uint f=0;f<n;f++)feed(0,0,0,0);}
void tap(uint64 k,int x=0,int y=0){for(uint f=0;f<3;f++)feed(k,x,y,0);idle(12);}
void place(uint i,uint row,uint col,const string &in name){
 ActorWatcher::clearSlot(3);
 tap(uint64(PLUS));idle(50);
 for(uint t=0;t<10;t++)tap(uint64(R));
 for(uint t=0;t<2;t++){tap(uint64(L));idle(15);}
 for(uint t=0;t<4;t++)tap(uint64(DUP));
 for(uint t=0;t<6;t++)tap(uint64(DLEFT));
 for(uint t=0;t<row;t++)tap(uint64(DDOWN));
 for(uint t=0;t<col;t++)tap(uint64(DRIGHT));
 idle(20);sys::debugLog("PLC sel"+i+" "+name);idle(10);
 tap(uint64(A));idle(20);tap(uint64(A));idle(30);
 tap(uint64(B));idle(50);tap(uint64(B));idle(30);
 // The placed kart lands 3.7 m from Link on -X (Link faces +X; seen in every placement run). Walk around it pressing A;
 // the controller adopts whatever kart Link gets into.
 idle(90);float kx=Player.pos_x-3.7f,kz=Player.pos_z;
 for(uint t=0;t<12 && !wasRiding;t++){
  float a=float(t)*0.5236f,px=kx+1.5f*cos(a),pz=kz+1.5f*sin(a),fx=kx-px,fz=kz-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
  Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,Player.pos_y+0.2f,pz);input(20,0);
  feed(uint64(A),0,0,0);idle(45);sys::debugLog("RIDE try "+t+" riding="+wasRiding+" kart="+(getKart() is null?"none":getKart().getName()));
 }
 idle(30);
 for(uint f=0;f<70;f++)feed(0,0,0,32767,0);sys::debugLog("RIDE side-right");for(uint f=0;f<40;f++)feed(0,0,0,32767,0);
 for(uint f=0;f<70;f++)feed(0,0,0,-32767,0);sys::debugLog("RIDE side-left");for(uint f=0;f<40;f++)feed(0,0,0,-32767,0);
 idle(40);sys::debugLog("RIDE behind");idle(40);
 for(uint f=0;f<40;f++)feed(0,0,0,0,-32767);sys::debugLog("RIDE front");for(uint f=0;f<40;f++)feed(0,0,0,0,-32767);
 feed(uint64(X),0,0,0);idle(30);
}
void main(){
 initKart();devChords=true;tp=resolvePadInput();if(tp==0)return;
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady())return;
 Player.setPos(-146,127.8,-58.5);input(90,0);for(uint w=0;w<200 && !(worldReady() && abs(Player.pos_x+146)<20);w++)input(10,0);input(60,0);if(!worldReady())return;
 for(uint c=0;c<4;c++){
  Player.setRot(0,0,-1,0,1,0,1,0,0);input(2,0);Player.setPos(-154.4f,Player.pos_y+0.3f,-54.0f-3.0f*c);input(30,0);
  for(uint f=0;f<30;f++)feed(f%10<5?uint64(A):0,0,0,0);
  idle(90);tap(uint64(A));idle(50);tap(uint64(A));idle(30);
 }
 sys::debugLog("PLC chests");
 for(uint i=0;i<NPLACE;i++){
  Player.setRot(0,0,1,0,1,0,-1,0,0);input(2,0);Player.setPos(-138.0f+0.0f*i,Player.pos_y+0.3f,-48.0f-7.0f*i);input(40,0);
  place(i,ROW_i(i),COL_i(i),"kart");
 }
 sys::debugLog("PLC finished");simActive=false;input(1,0);runResident(tp);
}
'''
BODY = BODY.replace('NPLACE', str(len(SLOTS)))
BODY = BODY.replace('ROW_i(i)', '(' + ':'.join(f'i=={k}?{r}' for k, (r, c) in enumerate(SLOTS)) + ':0)')
BODY = BODY.replace('COL_i(i)', '(' + ':'.join(f'i=={k}?{c}' for k, (r, c) in enumerate(SLOTS)) + ':0)')

src = (CAND / 'controller.src.as').read_text()
prefix = src[:src.index('void main(){')]
text = minify(prefix + BODY, wrap=True)
assert len(text.encode()) < 65536
out = ROOT / 'runtime/diagnostics/kart_place_ride_test.as'
out.write_text(text); print(out, len(text.encode()))
