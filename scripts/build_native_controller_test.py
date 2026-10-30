#!/usr/bin/env python3
"""Exercise the actual resident controller with deterministic emulated pad input."""
from pathlib import Path
from compact_native_script import compact
ROOT=Path(__file__).resolve().parents[1]
s=(ROOT/'runtime/candidates/native-rider-controls/autorun.as').read_text()
s=s[:s.index('void main(){')]
s='\n'.join(line.strip() for line in s.splitlines() if line.strip() and not line.lstrip().startswith('//'))
test='''
void sampleTest(const string &in phase,ptr_t pad){
 ActorBase@ a=getKart();if(a is null){sys::debugLog("DRIVE "+phase+" missing");return;}
 Matrix33f r=a.rot;
 sys::debugLog("DRIVE "+phase+" pos="+a.pos_x+","+a.pos_y+","+a.pos_z+" up="+r.a4+" heading="+r.a2+","+r.a8+" mounted="+playerIsRiding(a)+" speed="+driveSpeed+" pad="+ptr_deref_s32(pad+8)+","+ptr_deref_s32(pad+12));
}
void main(){
 initKart();ptr_t pad=resolvePadInput();if(pad==0)return;
 input(180,0);
 for(uint n=0;n<35;n++){
  if(worldReady() && Player.pos_x< -100 && Player.pos_x> -400 && Player.pos_y>50)break;
  input(1,1);input(90,0);
 }
 input(60,0);if(!worldReady()){sys::debugLog("DRIVE world timeout");while(true)sleep(1);}
 controllerFrame(pad);input(1,uint64(ZL|ZR|DUP));controllerFrame(pad);
 for(uint f=0;f<165;f++){input(1,0);controllerFrame(pad);}
 sampleTest("beforeA",pad);input(1,1);input(90,0);sampleTest("afterA",pad);
 if(!playerIsRiding(getKart())){sys::debugLog("DRIVE mount failed");while(true)sleep(1);}
 for(uint phase=0;phase<6;phase++){
  uint frames=phase==0?180:phase==1?120:phase==2?60:phase==3?120:phase==4?90:60;
  int x=phase==1?24000:phase==4?-24000:0;
  int y=(phase==2 || phase==5)?0:phase==3?-32767:32767;
  for(uint f=0;f<frames && worldReady();f++){
   input(1,0,x,y);controllerFrame(pad);
   if(f%30==0)sampleTest("p"+phase+"f"+f,pad);
  }
  sampleTest("end"+phase,pad);
 }
 input(1,2);controllerFrame(pad);
 for(uint f=0;f<60;f++){input(1,0);controllerFrame(pad);if(f%15==0)sampleTest("exit"+f,pad);}
 sampleTest("afterB",pad);
 for(uint f=0;f<90;f++){input(1,0,0,32767);controllerFrame(pad);}
 sampleTest("unmountedEnd",pad);sampleTest("parkStart",pad);
 for(uint f=0;f<180;f++){input(1,0);controllerFrame(pad);}
 sampleTest("parkEnd",pad);uint oldId=kartId;
 input(1,uint64(ZL|ZR|DUP));controllerFrame(pad);
 for(uint f=0;f<180;f++){input(1,0);controllerFrame(pad);}
 sampleTest("recall",pad);input(1,1);
 for(uint f=0;f<90;f++){input(1,0);controllerFrame(pad);}
 sampleTest("remounted",pad);sys::debugLog("RECALL same="+(oldId==kartId));
 sys::debugLog("DRIVE finished");input(1,0);runResident(pad);
}
'''
result=compact(s+test)
assert len(result.encode())<8192,len(result.encode())
p=ROOT/'runtime/diagnostics/native_controller_matrix.as';p.write_text(result);print(p,len(result.encode()))
