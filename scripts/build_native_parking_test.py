#!/usr/bin/env python3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
s=(ROOT/'runtime/candidates/native-rider-controls/autorun.as').read_text().split('void main(){')[0]
s='\n'.join(x.strip()for x in s.splitlines()if x.strip())
test='''
void snap(const string &in tag){ActorBase@ a=getKart();if(a is null){sys::debugLog("PARK missing");return;}sys::debugLog("PARK "+tag+" pos="+a.pos_x+","+a.pos_y+","+a.pos_z+" rider="+playerIsRiding(a)+" parked="+parked+" id="+kartId);}
void neutral(ptr_t p,uint n){for(uint f=0;f<n;f++){input(1,0);controllerFrame(p);}}
void summon(ptr_t p){input(1,uint64(ZL|ZR|DUP));controllerFrame(p);neutral(p,150);}
void main(){
initKart();ptr_t p=resolvePadInput();if(p==0)return;input(180,0);
for(uint n=0;n<35;n++){if(worldReady() && Player.pos_y>50)break;input(1,1);input(90,0);}
neutral(p,60);
summon(p);input(1,1);neutral(p,90);
if(!playerIsRiding(getKart())){sys::debugLog("PARK mount failed");runResident(p);return;}
for(uint f=0;f<300;f++){input(1,0,f>=180?24000:0,32767);controllerFrame(p);}
neutral(p,60);input(1,2);controllerFrame(p);neutral(p,30);snap("start");neutral(p,180);snap("end");
summon(p);snap("recalled");input(1,1);neutral(p,90);snap("remounted");
if(playerIsRiding(getKart())){for(uint f=0;f<90;f++){input(1,0,0,32767);controllerFrame(p);}neutral(p,60);}
sys::debugLog("PARK finished");input(1,0);runResident(p);
}
'''
out='\n'.join(x.strip()for x in(s+test).splitlines()if x.strip())+'\n'
assert len(out.encode())<8192,len(out.encode())
p=ROOT/'runtime/diagnostics/native_parking_recall.as';p.write_text(out);print(p,len(out.encode()))
