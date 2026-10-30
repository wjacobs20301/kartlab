ptr_t kartAddress=0;
uint kartId=0xffffffff;
float driveSpeed=0;
bool wasRiding=false;
bool parked=false,parkLocked=false;
uint parkStable=0;float parkY=0;
bool locationReady(){return Player !is null && !pause::isPauseRequest("LoadingPause") && abs(Player.pos_x)<100000 && abs(Player.pos_y)<100000 && abs(Player.pos_z)<100000;}
bool worldReady(){return locationReady() && !pause::isPauseTarget("Actor");}
ptr_t resolvePadInput(){
 ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(hook==0)return 0;
 uint op=ptr_deref_u32(hook);if((op&0xfc000000)!=0x94000000)return 0;
 int64 delta=int64(op&0x03ffffff);if((op&0x02000000)!=0)delta-=0x04000000;
 ptr_t target=ptr_t(int64(hook)+delta*4);
 if(ptr_deref_u32(target)!=0xf0001382 || ptr_deref_u32(target+4)!=0xa9be7bfd)return 0;
 ptr_t base=target-0x65b80;if((base&0xfff)!=0)return 0;return base+0x3d90b8;
}
void forgetKart(){ActorWatcher::clearSlot(2);kartAddress=0;kartId=0xffffffff;driveSpeed=0;wasRiding=false;parked=false;parkLocked=false;parkStable=0;}
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
void parkKart(ActorBase@ a){
 RigidBody@ b=a.getMainRigidBody();if(b is null)return;
 if((ptr_deref_u64(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){parkLocked=false;parkStable=0;return;}
 Vector3f v=b.vel;Matrix33f r=a.rot;float dy=abs(a.pos_y-parkY);parkY=a.pos_y;
 if(dy>0.006f || r.a4<0.5f){parkLocked=false;parkStable=0;}
 if(!parkLocked){if(dy<0.006f && abs(v.y)<0.3f && r.a4>0.5f)parkStable++;else parkStable=0;if(parkStable>=30)parkLocked=true;}
 b.setVel(0,parkLocked?0:v.y,0);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void spawnKart(){
 if(!worldReady())return;
 ActorBase@ old=getKart();
 if(playerIsRiding(old)){TextWriter::toast(150,"Dismount before recalling the kart.\n");return;}
 Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,length=sqrt(fx*fx+fz*fz);if(length<0.1f)return;fx/=length;fz/=length;
 float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
 if(old !is null){stopKart(old);old.setPos(x,y,z);@old=null;parkLocked=false;parkStable=0;}
 else{forgetKart();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
 for(uint f=0;f<150 && worldReady();f++){
  ActorBase@ a=ActorWatcher::get(2);
  if(a !is null){
   kartAddress=ptr_from_ActorBase(a);kartId=ptr_deref_u32(kartAddress+0x10);
   if(a.getMainRigidBody() !is null){
    ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=getKart();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);stopKart(a);parked=true;parkY=a.pos_y;
    TextWriter::toast(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
    sys::debugLog("KART ready id="+kartId);return;
   }
  }
  @a=null;sleep(1);
 }
 forgetKart();TextWriter::toast(150,"KartLab: spawn unavailable.\n");
}
void updateDrive(int ix,int iy){
 ActorBase@ a=getKart();bool riding=playerIsRiding(a);
 if(riding!=wasRiding){sys::debugLog("KART mounted="+riding);driveSpeed=0;wasRiding=riding;parked=!riding;parkLocked=false;parkStable=0;if(a !is null)parkY=a.pos_y;}
 if(!riding || a is null){if(a !is null && parked)parkKart(a);return;}
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
 sys::debugLog("KART ready");
}
bool chordLatched=true,spawnPending=false,loadCleared=false;
uint spawnDelay=0;
void controllerFrame(ptr_t pad){
 if(!locationReady()){
  if(!loadCleared){forgetKart();loadCleared=true;}
  chordLatched=true;spawnPending=false;spawnDelay=0;return;
 }
 loadCleared=false;uint64 held=ptr_deref_u64(pad),mask=uint64(ZL|ZR|DUP);
 if((held&mask)==0)chordLatched=false;
 if(!chordLatched && (held&mask)==mask){chordLatched=true;spawnPending=true;sys::debugLog("KART spawn queued");}
 if(!worldReady())return;
 if(spawnPending && (held&mask)==0){if(++spawnDelay>=15){spawnPending=false;spawnDelay=0;spawnKart();}}else spawnDelay=0;
 updateDrive(ptr_deref_s32(pad+8),ptr_deref_s32(pad+12));
}
void runResident(ptr_t pad){while(true){controllerFrame(pad);sleep(1);}}
void main(){
 initKart();ptr_t pad=resolvePadInput();if(pad==0){TextWriter::toast(300,"KartLab: runtime input signature mismatch.\n");return;}
 TextWriter::toast(300,"KartLab: ZL+ZR+Up spawns a kart. A controls; left stick drives; B dismounts.\n");
 runResident(pad);
}
