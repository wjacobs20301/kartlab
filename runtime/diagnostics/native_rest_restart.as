ptr_t kartAddress=0;
uint kartId=0xffffffff;
float driveSpeed=0;
bool wasRiding=false;
bool worldReady(){
 return Player !is null && !pause::isPauseRequest("LoadingPause") && !pause::isPauseTarget("Actor") && abs(Player.pos_x)<100000 && abs(Player.pos_y)<100000 && abs(Player.pos_z)<100000;
}
bool guestPointer(ptr_t p){return p>=0x10000 && p<0x100000000000 && (p&7)==0;}
ptr_t resolvePadInput(){
 ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(hook==0)return 0;
 uint op=ptr_deref_u32(hook);if((op&0xfc000000)!=0x94000000)return 0;
 int64 delta=int64(op&0x03ffffff);if((op&0x02000000)!=0)delta-=0x04000000;
 ptr_t target=ptr_t(int64(hook)+delta*4);
 if(ptr_deref_u32(target)!=0xf0001382 || ptr_deref_u32(target+4)!=0xa9be7bfd)return 0;
 ptr_t base=target-0x65b80;if((base&0xfff)!=0)return 0;return base+0x3d90b8;
}
void forgetKart(){ActorWatcher::clearSlot(2);kartAddress=0;kartId=0xffffffff;driveSpeed=0;wasRiding=false;}
ActorBase@ getKart(){
 if(!worldReady() || kartAddress==0)return null;
 ActorBase@ a=ActorWatcher::get(2);if(a is null || ptr_from_ActorBase(a)!=kartAddress)return null;
 if(ptr_deref_u32(kartAddress+0x10)!=kartId)return null;
 uint state=ptr_deref_u32(kartAddress+0x24);if(state<2 || state>6)return null;
 return a;
}
bool riderGuestPointer(ptr_t p) {
 return p>=0x10000 && p<0x100000000000 && (p&7)==0;
}
bool riderHostIdentity(ActorBase@ host,uint expectedHostID) {
 if(host is null || expectedHostID==0xffffffff)return false;
 ptr_t p=ptr_from_ActorBase(host);
 if(!riderGuestPointer(p) || ptr_deref_u32(p+0x10)!=expectedHostID)return false;
 uint state=ptr_deref_u32(p+0x24);
 return state>=2 && state<=6;
}
bool playerOccupiesNativeSeat(ActorBase@ host,uint expectedHostID) {
 if(Player is null || !riderHostIdentity(host,expectedHostID))return false;
 ptr_t actor=ptr_from_ActorBase(host),player=ptr_from_ActorBase(Player);
 if(!riderGuestPointer(player))return false;
 uint playerID=ptr_deref_u32(player+0x10);
 if(playerID==0xffffffff)return false;
 uint playerState=ptr_deref_u32(player+0x24);
 if(playerState<2 || playerState>6)return false;
 uint count=ptr_deref_u32(actor+0x220);ptr_t list=ptr_deref_u64(actor+0x228);
 if(count<=129 || count>512 || !riderGuestPointer(list))return false;
 ptr_t component=ptr_deref_u64(list+0x408);
 if(!riderGuestPointer(component))return false;
 uint seats=ptr_deref_u32(component+0x20);ptr_t seatArray=ptr_deref_u64(component+0x28);
 if(seats!=1 || !riderGuestPointer(seatArray))return false;
 ptr_t seat=ptr_deref_u64(seatArray);
 if(!riderGuestPointer(seat))return false;
 uint seatID=ptr_deref_u32(seat+0x10),flags=ptr_deref_u32(seat+0x18);
 float cooldown=ptr_deref_float(seat+0x74);
 if(seatID!=playerID || flags==0 || !(cooldown<=0 && cooldown>=-1000))return false;
 ptr_t linkData=ptr_deref_u64(seat+8),playerLinkData=ptr_deref_u64(player+0x1a8);
 if(linkData!=playerLinkData || !riderGuestPointer(playerLinkData))return false;
 if(ptr_deref_u32(playerLinkData+0x48)!=playerID || ptr_deref_u64(playerLinkData+0x40)!=player)return false;
 return riderHostIdentity(host,expectedHostID) && ptr_deref_u32(player+0x10)==playerID;
}

bool playerIsRiding(ActorBase@ a){return worldReady() && playerOccupiesNativeSeat(a,kartId);}
void stopKart(ActorBase@ a){
 if(a is null)return;RigidBody@ b=a.getMainRigidBody();if(b is null)return;
 Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void spawnKart(){
 if(!worldReady())return;
 ActorBase@ old=getKart();
 if(old !is null){TextWriter::toast(150,"KartLab: your kart is already nearby. Approach it and press A.\n");return;}
 forgetKart();Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,length=sqrt(fx*fx+fz*fz);if(length<0.1f)return;fx/=length;fz/=length;
 actor::createAndWatch(2,"SpObj_ControlStick_A_01",Player.pos_x+fx*2.0f,Player.pos_y+0.5f,Player.pos_z+fz*2.0f);
 for(uint f=0;f<150 && worldReady();f++){
  ActorBase@ a=ActorWatcher::get(2);
  if(a !is null){
   kartAddress=ptr_from_ActorBase(a);kartId=ptr_deref_u32(kartAddress+0x10);
   if(a.getMainRigidBody() !is null){
    ActorWatcher::pauseSlot(2);a.setRot(fz,0,fx,0,1,0,-fx,0,fz);
    TextWriter::toast(240,"KartLab: approach the kart and press A to control. Left stick drives; B dismounts.\n");
    sys::debugLog("KART spawned native host id="+kartId);return;
   }
  }
  @a=null;sleep(1);
 }
 forgetKart();TextWriter::toast(150,"KartLab: spawn unavailable.\n");
}
void updateDrive(int ix,int iy){
 ActorBase@ a=getKart();bool riding=playerIsRiding(a);
 if(riding!=wasRiding){sys::debugLog("KART mounted="+riding);if(!riding)stopKart(a);driveSpeed=0;wasRiding=riding;}
 if(!riding || a is null)return;
 if(abs(float(ix))>32768 || abs(float(iy))>32768){stopKart(a);driveSpeed=0;return;}
 float steer=float(ix)/32768.0f,throttle=float(iy)/32768.0f;
 if(abs(steer)<0.15f)steer=0;if(abs(throttle)<0.15f)throttle=0;
 float target=throttle*(throttle<0?1.0f:2.5f),change=target-driveSpeed,limit=throttle==0?0.08f:0.045f;
 if(change>limit)change=limit;if(change< -limit)change= -limit;driveSpeed+=change;
 Matrix33f r=a.rot;float length=sqrt(r.a2*r.a2+r.a8*r.a8);
 RigidBody@ b=a.getMainRigidBody();if(b is null)return;
 if(length<0.1f || r.a4<0.4f){stopKart(a);driveSpeed=0;return;}
 Vector3f v=b.vel;b.setVel(r.a2*driveSpeed/length,v.y,r.a8*driveSpeed/length);
 b.setAngularVel(-r.a7*2.0f,steer*0.45f*(driveSpeed/2.5f),r.a1*2.0f);
}
void initKart(){
 tas::doBlockOnLoadingPause(false);
 for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
 sys::debugLog("KART native rider controls: ready");
}
void sampleTest(const string &in phase,ptr_t pad){
 ActorBase@ a=getKart();if(a is null){sys::debugLog("DRIVE "+phase+" missing");return;}
 Matrix33f r=a.rot;
 RigidBody@ body=a.getMainRigidBody();ptr_t bp=ptr_from_RigidBody(body);
 if(bp!=0)sys::debugLog("REST "+phase+" flags="+ptr_deref_u64(bp+0x68)+" actual="+ptr_deref_float(bp+0xf8)+","+ptr_deref_float(bp+0xfc)+","+ptr_deref_float(bp+0x100));
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
 spawnKart();input(165,0);sampleTest("beforeA",pad);input(1,1);input(90,0);sampleTest("afterA",pad);
 if(!playerIsRiding(getKart())){sys::debugLog("DRIVE mount failed");while(true)sleep(1);}
 for(uint phase=0;phase<6;phase++){
  uint frames=phase==0?90:phase==1?0:phase==2?180:phase==3?120:phase==4?120:60;
  int x=0;
  int y=(phase==2 || phase==5)?0:phase==3?-32767:32767;
  for(uint f=0;f<frames && worldReady();f++){
   input(1,0,x,y);updateDrive(ptr_deref_s32(pad+8),ptr_deref_s32(pad+12));
   if(f%30==0)sampleTest("p"+phase+"f"+f,pad);
  }
  sampleTest("end"+phase,pad);
 }
 input(1,2);updateDrive(0,0);
 for(uint f=0;f<60;f++){input(1,0);updateDrive(0,0);if(f%15==0)sampleTest("exit"+f,pad);}
 sampleTest("afterB",pad);
 for(uint f=0;f<90;f++){input(1,0,0,32767);updateDrive(ptr_deref_s32(pad+8),ptr_deref_s32(pad+12));}
 sampleTest("unmountedEnd",pad);sys::debugLog("DRIVE finished");while(true)sleep(1);
}
