#!/usr/bin/env python3
"""Build runtime/diagnostics/kart_place_test.as: place every kart from the inventory and check it stays put.

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
 ActorWatcher::assignSlotAwaitSpawn(3,"");
 tap(uint64(A));idle(20);tap(uint64(A));idle(30);
 tap(uint64(B));idle(50);tap(uint64(B));idle(30);
 // first kart spawned after Take out (other actors spawning nearby are skipped: the watcher re-arms)
 for(uint f=0;f<240;f++){
  idle(1);ActorBase@ c=ActorWatcher::get(3);
  if(c !is null){string nm=c.getName();if(nm.findFirst("SpObj_ControlStick_A_0")==0)break;sys::debugLog("PLC skip "+nm);ActorWatcher::clearSlot(3);ActorWatcher::assignSlotAwaitSpawn(3,"");}
 }
 float x0=0,z0=0,y0=0;bool seen=false;
 for(uint s=0;s<12;s++){
  idle(30);ActorBase@ w=ActorWatcher::get(3);
  if(w is null){sys::debugLog("PLC pos"+i+" t="+s+" none");continue;}
  if(!seen){seen=true;x0=w.pos_x;y0=w.pos_y;z0=w.pos_z;}
  float dx=w.pos_x-x0,dz=w.pos_z-z0;
  sys::debugLog("PLC pos"+i+" t="+s+" "+w.getName()+" "+w.pos_x+","+w.pos_y+","+w.pos_z+" moved="+sqrt(dx*dx+dz*dz)+" up="+w.rot.a4);
 }
 sys::debugLog("PLC done"+i+" created="+seen);
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
out = ROOT / 'runtime/diagnostics/kart_place_test.as'
out.write_text(text); print(out, len(text.encode()))
