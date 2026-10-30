ptr_t kartAddress=0;
uint kartId=0xffffffff;
float driveSpeed=0;
bool wasRiding=false;
bool parked=false;float parkX=0,parkZ=0;
float steerInput=0,wheelSteer=0,spinFront=0,spinRear=0,lastX=0,lastZ=0;bool haveLast=false;
// ---- Mario Kart handling: Mario + Standard Kart + Standard Tires + Super Glider (MK8DX 1.7.1) ----
// [table]  = MK8DX Performance.bin row for this combination (research/handling/standard_reference.json)
// [native] = recovered MK8DX speed step 0x189644: v += min((T-v)*G, M) (research/movement-code.md)
// [chosen] = not recoverable from the data; picked for TOTK scale and feel
// MK8DX simulates at 60 Hz; each TOTK logical frame (30 Hz) runs two MK steps. Speeds in MK units/frame.
const float MK_SPEED=7.775f;      // [table] PRSL ground top speed, 0 coins
const float MK_ACCEL_GAIN=0.011f; // [table] PRAC strength (G)
const float MK_ACCEL_CAP=0.09f;   // [table] PRAC limiter (M)
const float MK_STEER=0.0118f;     // [table] PRTL steer, rad per MK frame
const float MK_DRIFT=0.0196f;     // [table] PRTL drift, rad per MK frame
const float MK_CHARGE=0.9f;       // [table] PRTL charge (not used by the recovered charge routine)
const float MK_TRACTION=0.75f;    // [table] PRON road traction
const float MT_SPEED=1.105f;      // [table] PRMT mini-turbo / super-mini-turbo speed
const uint MT_FRAMES=31,SMT_FRAMES=92; // [table] PRMT boost lengths (MK frames)
const uint UMT_FRAMES=153;        // [chosen] ultra length (not in the table): SMT + (SMT - MT)
const float CHARGE_MT=252,CHARGE_SMT=534,CHARGE_UMT=816; // [table] PRMT charge thresholds
const float MS_PER_MK=1.8f;       // [chosen] m/s per MK unit/frame (top speed about 14 m/s)
const float MK_REVERSE=2.7f;      // [chosen] reverse top speed, MK units (about 4.9 m/s)
const float MK_BRAKE=0.11f;       // [chosen] braking per MK frame (top speed to 0 in ~1.2 s)
const float MK_COAST=0.07f;       // [chosen] coasting deceleration per MK frame (~1.9 s)
const float MK_OVERSPEED=0.993f;  // [chosen] decay above target (after a boost)
const float MK_BOOST_GAIN=0.05f,MK_BOOST_CAP=0.3f; // [chosen] stronger push while boosting
const float GRIP=0.35f;           // [chosen] fraction of traction removing sideways slip per MK frame
// Drift, recovered from MK8DX drift update 0x179c74 / constructor 0x178050 / charge routine 0x17b744 (kart values):
const float DRIFT_BODY=0.53f;     // [native] body angle into the turn (rad), approached at 7%/frame, min step 0.001
const float DRIFT_TRACK=0.8f;     // [native] drift steer state limit, approached at 10%/frame, step <= 0.07
const float CHARGE_IN=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f; // [native] charge per frame: 5 if inward >= 0.71 else 2
const float HOP_SPEED=4.2f;       // [chosen] drift hop, m/s upward (~0.4 m, visible from the chase camera)
// Off-road (toggle ZL+ZR+D-pad Down, default OFF): MK8DX PROF row 11 (Standard Kart off-road traction 11) columns 0..2 are
// the terrain speed multipliers 0.7 / 0.5 / 0.3. [chosen] TOTK materials: light off-road (grass, soil, sand, snow) 0.7;
// heavy (deep sand/snow, mud, tar, shallow water) 0.5. Boosts ignore it, as in Mario Kart.
// Air (MK8DX has no separate jump-handling stat): [chosen] steering 30% of ground, speed held (no accel/brake),
// no hop, drift carries through but does not charge. Trick: R within 8 frames of take-off -> [chosen] 31-frame boost
// on landing (MK8 mini-turbo length, PRMT). Airborne = ground ray finds nothing within 0.7 m for 2+ frames.
// Trick: a flat 360 deg spin of the body around the travel direction (bodyOff, the drift body angle, runs 0 -> 2pi while
// the travel heading stays put). A barrel roll was tried first: TOTK drops the rider when the vehicle goes upside down.
const int TRICK_ROLL_FRAMES=15;   // [chosen] 0.5 s
int trickRoll=0,trickRollDir=1;
const int AUTO_GLIDE_FRAMES=24;const float AUTO_GLIDE_FALL=5.0f;bool autoGlideOn=true,autoGlideBlocked=false,autoGlideChordLatched=true;
void startTrick(float steer){trickRoll=TRICK_ROLL_FRAMES;trickRollDir=steer< -0.3f?-1:1;}   // stick left spins the other way
const float AIR_STEER=0.3f,AIR_GAP=0.7f;const int TRICK_WINDOW=8,TRICK_FRAMES=31;   // trick: also R up to 6 frames before take-off
// Glider (Y while airborne and >= 2.5 m up; Y again folds): [table] PRSG row 14 = 8.225 MK units/frame glide speed;
// [chosen] descent 1.6 m/s level, 4.5 pushing the stick forward (dive, +6% speed), 0.6 pulling back; steering 60% of ground.
const float GLIDE_GCOMP=0.95f;   // [measured] TOTK pulls the kart down ~0.95 m/s per frame; added back so the glide sink settles at target
const float GLIDE_SPEED=8.225f,GLIDE_SINK=1.6f,GLIDE_DIVE=4.5f,GLIDE_FLOAT=0.6f,GLIDE_STEER=0.6f,GLIDE_MIN_HEIGHT=2.5f;
const float AIR_MAX_FALL=9.0f,GLIDE_SIDE_DRAG=0.08f,AIR_SIDE_DRAG=0.01f;   // [chosen] per half-frame step
const float GLIDE_BANK=0.55f,GLIDE_PITCH=0.35f,GLIDE_TILT_GAIN=4.0f,GLIDE_MAX_LEAN=0.65f;   // [chosen] ~29 deg bank, ~19 deg nose-down, ~33 deg combined max
bool airborne=false,trickDone=false,gliding=false,gliderLatch=true;int airFrames=0,groundFrames=0,trickWindow=0,rPressAge=99;
const bool OFFROAD_DEFAULT=false;
const float OFFROAD_LIGHT=0.7f,OFFROAD_HEAVY=0.5f;   // [table] PROF
bool offroadOn=OFFROAD_DEFAULT,offroadChordLatched=true;
float mkSpeed=0,driftCharge=0,bodyOff=0,driftTrack=0;int driftDir=0,driftTier=0,boostLeft=0,hopWindow=0;bool hopHeld=false,gasLatch=true,idleHold=false;
bool menuOpen(){return pause::isPauseRequest("GamePause") || pause::isPauseRequest("PreGamePause") || pause::isPauseRequest("PostGamePause") || pause::isPauseTarget("Custom_PhysicsUpdateWorld");}
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
void forgetKart(){gliderScale=0;gliderWritten=false;ActorWatcher::clearSlot(2);kartAddress=0;kartId=0xffffffff;resetHandling();wasRiding=false;parked=false;parkX=0;parkZ=0;haveLast=false;}
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
 if((ptr_deref_u64(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){parkX=a.pos_x;parkZ=a.pos_z;return;}
 float dx=parkX-a.pos_x,dz=parkZ-a.pos_z;
 if(dx*dx+dz*dz>4){parkX=a.pos_x;parkZ=a.pos_z;dx=0;dz=0;}
 float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx< -0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz< -0.5f)vz=-0.5f;
 Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
// Kart bodies (scripts/build_kart_variant.py): each is its own actor sharing the kart pack; tyre scales from MK8's
// placement probe (front, rear render scale Y).
int kartType=0,spawnedType=0;bool kartChordLatched=true,capChordLatched=true,devChords=false;
string kartActor(int t){return t==1?"SpObj_ControlStick_A_06":t==2?"SpObj_ControlStick_A_05":t==3?"SpObj_ControlStick_A_04":"SpObj_ControlStick_A_01";}   // variants are new actors A_04..A_06
string kartName(int t){return t==1?"Pipe Frame":t==2?"B Dasher":t==3?"Standard Bike":"Standard Kart";}
const int KART_TYPES=4;bool isBike(int t){return t==3;}
string kartCapsule(int t){return "SpObj_ControlStick_Capsule_A_0"+(t+1);}   // inventory capsules (scripts/build_kart_capsules.py)
// ---- Adopting a kart the controller did not spawn (placed from a capsule, a Steering Stick in the world, an old one):
// while Link is not riding our kart, look at what he rides. Player component 130 holds a link to the ridden actor at
// +0x28 (BaseProcLinkData: +0x40 actor, +0x48 id; found by scanning the Player for the kart's link data, all four
// other hits are attention/AI links). A ControlStick actor (name read straight from ActorBase+0x218, mActorName) is
// taken over: watcher slot 2, its type from the last digit of its name.
const string KART_PREFIX="SpObj_ControlStick_A_0";
uint adoptTick=0;
int kartTypeOfActor(ptr_t a){
 ptr_t s=ptr_deref_u64(a+0x218);if(s<0x1000000 || s>0x8000000000)return -1;
 for(uint i=0;i<KART_PREFIX.length();i++)if(ptr_deref_u8(s+i)!=KART_PREFIX[i])return -1;
 uint d=ptr_deref_u8(s+22);if(ptr_deref_u8(s+23)!=0)return -1;
 return d==49?0:d==54?1:d==53?2:d==52?3:-1;   // A_01 Standard, A_06 Pipe Frame, A_05 B Dasher, A_04 Bike (A_02/A_03 vanilla)
}
void adoptRiddenKart(){
 if(Player is null || (adoptTick++)%10!=0)return;
 ptr_t p=ptr_from_ActorBase(Player);uint n=ptr_deref_u32(p+0x220);ptr_t list=ptr_deref_u64(p+0x228);
 if(n<=130 || n>600 || !gptr(list))return;
 ptr_t c=ptr_deref_u64(list+8*130);if(!gptr(c))return;
 ptr_t ld=ptr_deref_u64(c+0x28);if(!gptr(ld))return;
 ptr_t k=ptr_deref_u64(ld+0x40);if(!gptr(k) || k==kartAddress)return;
 uint id=ptr_deref_u32(ld+0x48);if(ptr_deref_u32(k+0x10)!=id)return;
 uint st=ptr_deref_u32(k+0x24);if(st<2 || st>6)return;
 int t=kartTypeOfActor(k);if(t<0)return;
 forgetKart();ActorWatcher::assignSlot(2,k);kartAddress=k;kartId=id;spawnedType=t;kartType=t;
 ActorBase@ a=ActorWatcher::get(2);
 if(a is null || ptr_from_ActorBase(a)!=k || !playerIsRiding(a)){forgetKart();return;}
 sys::debugLog("KART adopted "+kartName(t));
}
float kartTireF(int t){return t==1?1.0f:t==2?1.18f:t==3?1.275f:1.0f;}
float kartTireR(int t){return t==1?1.2f:t==2?1.42f:t==3?1.275f:1.3f;}
void spawnKart(){
 if(!worldReady())return;
 ActorBase@ old=getKart();
 if(playerIsRiding(old)){TextWriter::toast(150,"Dismount before recalling the kart.\n");return;}
 Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,length=sqrt(fx*fx+fz*fz);if(length<0.1f)return;fx/=length;fz/=length;
 float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
 if(old !is null && spawnedType!=kartType){forgetKart();@old=null;}   // a different kart was chosen: spawn it (the old one stays)
 if(old !is null){stopKart(old);old.setPos(x,y,z);@old=null;parkX=0;parkZ=0;haveLast=false;}
 else{forgetKart();actor::createAndWatch(2,kartActor(kartType),x,y,z);spawnedType=kartType;sleep(60);}   // let creation get past its first frames before touching the actor
 for(uint f=0;f<600 && worldReady();f++){   // up to 20 s: a first load of a kart pack can take a while
  ActorBase@ a=ActorWatcher::get(2);
  if(a !is null){
   kartAddress=ptr_from_ActorBase(a);if(!gptr(kartAddress)){@a=null;sleep(1);continue;}kartId=ptr_deref_u32(kartAddress+0x10);
   if(f%60==0)sys::debugLog("KART spawn wait f="+f+" ptr="+formatInt(int64(kartAddress),"H")+" state="+ptr_deref_u32(kartAddress+0x24)+" ct="+gptr(ptr_deref_u64(kartAddress+0x228)));
   // Wait until the component table and physics component exist: a freshly created kart actor can be visible to
   // ActorWatcher before them, and LotusKit's getMainRigidBody reads *(actor+0x228)+0x50 unchecked (null+0x50 crash).
   ptr_t ct=ptr_deref_u64(kartAddress+0x228);bool physReady=gptr(ct) && gptr(ptr_deref_u64(ct+0x50)) && gptr(ptr_deref_u64(ptr_deref_u64(ct+0x50)+0x20));
   if(physReady && a.getMainRigidBody() !is null){
    ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=getKart();
    if(a is null){ptr_t k=kartAddress;sys::debugLog("KART spawn lost: watcher="+(ActorWatcher::get(2) !is null)+" state="+(gptr(k)?ptr_deref_u32(k+0x24):99)+" id="+(gptr(k)?ptr_deref_u32(k+0x10):0)+"/"+kartId);return;}a.setRot(fz,0,fx,0,1,0,-fx,0,fz);stopKart(a);parked=true;parkX=a.pos_x;parkZ=a.pos_z;
    TextWriter::toast(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
    sys::debugLog("KART ready id="+kartId);return;
   }
  }
  @a=null;sleep(1);
 }
 {ActorBase@ a=ActorWatcher::get(2);ptr_t k=a is null?0:ptr_from_ActorBase(a);ptr_t ct=gptr(k)?ptr_deref_u64(k+0x228):0;
  sys::debugLog("KART spawn unavailable: world="+worldReady()+" watcher="+(a !is null)+" ptr="+formatInt(int64(k),"H")+" state="+(gptr(k)?ptr_deref_u32(k+0x24):99)+" ct="+gptr(ct)+" phys="+(gptr(ct) && gptr(ptr_deref_u64(ct+0x50))));}
 forgetKart();TextWriter::toast(150,"KartLab: spawn unavailable.\n");
}
// Cart submodel bone records: host model -> +0x18 (embedded at +0x258) -> +0x38 -> +0x580.
// Each record is 96 bytes; record i starts at base+96*i-24: 3x4 rotation rows +0/+16/+32,
// translate +48. Verified by the neutral translates we never write; any mismatch writes nothing.
ptr_t wheelBones(ActorBase@ a){
 ptr_t list=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!riderGuestPointer(list))return 0;
 ptr_t mc=ptr_deref_u64(list+0x10);if(!riderGuestPointer(mc))return 0;
 ptr_t m=ptr_deref_u64(mc+0x28);if(!riderGuestPointer(m))return 0;
 ptr_t x=ptr_deref_u64(m+0x18);if(x!=m+0x258)return 0;
 ptr_t y=ptr_deref_u64(x+0x38);if(!riderGuestPointer(y))return 0;
 int64 d=int64(y)-int64(m);if(d< -0x10000000 || d>0x10000000)return 0;
 ptr_t b=y+0x580;
 // Neutral sockets: Skl_Root at y 0.3766, wheels mirrored left/right at a kart-sized track (every body's sockets come
 // from MK8's own placement code, scripts/build_kart_variant.py); anything else writes nothing.
 float lf=ptr_deref_float(b+120),rf=ptr_deref_float(b+216),lb=ptr_deref_float(b+312),rb=ptr_deref_float(b+408);
 if(abs(ptr_deref_float(b+28)-0.3766f)>(isBike(spawnedType)?0.08f:0.002f) || abs(lf+rf)>0.002f || abs(lb+rb)>0.002f)return 0;   // (a leaning bike moves its root)
 if(isBike(spawnedType)){if(abs(lf)>0.01f || abs(lb)>0.01f)return 0;}   // bike: both sockets of an axle on the centre line
 else if(lf<0.5f || lf>1.2f || lb<0.5f || lb>1.2f)return 0;
 return b;
}
// Rotation R = yaw(steer) * roll(spin) about the axle (local X); forward is local +Z, +X is left.
// Records store the bone's axis vectors (R's columns): Handle_J's +90 deg rest reads (0,1,0),(-1,0,0).
void wheelRotation(ptr_t t,float sp,float cp,float sd,float cd){
 ptr_write_float(t,cd);ptr_write_float(t+4,0);ptr_write_float(t+8,-sd);
 ptr_write_float(t+16,sd*sp);ptr_write_float(t+20,cp);ptr_write_float(t+24,cd*sp);
 ptr_write_float(t+32,sd*cp);ptr_write_float(t+36,-sp);ptr_write_float(t+40,cd*cp);
}
const float TREAD_PERIOD=0.3927f;   // 2*pi/16 tread blocks
float visualSpinStep(float step){
 float m=abs(step),half=TREAD_PERIOD*0.5f;
 if(m<=half*0.9f)return step;
 float blocks=floor((m-half)/TREAD_PERIOD);if(blocks>3)blocks=3;
 float v=(blocks+0.5f)*TREAD_PERIOD;return step<0?-v:v;
}
void animateWheels(ActorBase@ a){
 if(a is null){haveLast=false;return;}
 Matrix33f r=a.rot;float length=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
 if(haveLast && length>0.1f){float dx=x-lastX,dz=z-lastZ;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/length;}
 lastX=x;lastZ=z;haveLast=true;
 // Visual spin. Each tire has 16 tread blocks (0.393 rad apart) and TOTK draws at 30 Hz, so true rolling speed
 // strobes and a capped speed looks slow. [chosen] Below half a block per frame the spin is proportional;
 // above that each frame advances a whole number of blocks plus a half: the hub turns quickly and the tread
 // alternates between two phases, which reads as a blurred fast-spinning tire instead of a slow crawl.
 spinFront+=visualSpinStep(ds/(0.28328f*kartTireF(spawnedType)));spinRear+=visualSpinStep(ds/(0.28328f*kartTireR(spawnedType)));   // tyre radius x body tyre scale
 if(spinFront>6.2832f)spinFront-=6.2832f;if(spinFront< -6.2832f)spinFront+=6.2832f;
 if(spinRear>6.2832f)spinRear-=6.2832f;if(spinRear< -6.2832f)spinRear+=6.2832f;
 wheelSteer+=(-steerInput*0.45f-wheelSteer)*0.25f;
 ptr_t b=wheelBones(a);if(b==0)return;
 float sf=sin(spinFront),cf=cos(spinFront),sr=sin(spinRear),cr=cos(spinRear),sd=sin(wheelSteer),cd=cos(wheelSteer);
 wheelRotation(b+72,sf,cf,sd,cd);wheelRotation(b+168,sf,cf,sd,cd);
 wheelRotation(b+264,sr,cr,0,1);wheelRotation(b+360,sr,cr,0,1);
 if(isBike(spawnedType))bikeLean(b);
}
// Bike lean: roll the cart's Skl_Root record (record 0, b-24; everything is rigid to it or its children) about the
// forward axis through the ground under the wheels. + rolls the top toward -X (Link's right).
const float BIKE_LEAN=0.38f,BIKE_DRIFT_LEAN=0.5f,BIKE_PIVOT_Y=-0.30f;   // [chosen] ~22 deg turning, ~29 deg drifting
float bikeRoll=0;
void bikeLean(ptr_t b){
 float sp=abs(mkSpeed)/MK_SPEED;if(sp>1)sp=1;
 float target=airborne||gliding?0:(driftDir!=0?driftDir*BIKE_DRIFT_LEAN*(0.7f+0.3f*abs(steerInput)):steerInput*BIKE_LEAN*sp);
 bikeRoll+=(target-bikeRoll)*0.12f;
 float c=cos(bikeRoll),s=sin(bikeRoll);ptr_t r=b-24;
 ptr_write_float(r,c);ptr_write_float(r+4,s);ptr_write_float(r+8,0);
 ptr_write_float(r+16,-s);ptr_write_float(r+20,c);ptr_write_float(r+24,0);
 ptr_write_float(r+32,0);ptr_write_float(r+36,0);ptr_write_float(r+40,1);
 ptr_write_float(r+48,s*BIKE_PIVOT_Y);ptr_write_float(r+52,0.3766f+BIKE_PIVOT_Y-c*BIKE_PIVOT_Y);ptr_write_float(r+56,0);
}
void resetHandling(){trickRoll=0;airborne=false;trickDone=false;gliding=false;airFrames=0;groundFrames=0;trickWindow=0;mkSpeed=0;bodyOff=0;driftTrack=0;driveSpeed=0;driftCharge=0;driftDir=0;driftTier=0;boostLeft=0;hopWindow=0;hopHeld=false;gasLatch=true;idleHold=false;}
int groundMat=-1;float groundDist=99;   // updated by groundFrame (ray cast under the kart)
float terrainSpeedFactor(){
 if(!offroadOn || groundDist>=0.8f)return 1;
 int m=groundMat;
 if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;   // HeavySand, HeavySnow, Bog, Tar, Water, ContaminatedWater
 if(m==1||m==2||m==3||m==5)return OFFROAD_LIGHT;                  // Soil, Grass, Sand, Snow
 return 1;
}
// One 60 Hz MK8DX speed step. Returns the new speed in MK units/frame.
float speedStep(float v,float throttle){
 if(boostLeft>0){
  boostLeft--;float t=MK_SPEED*MT_SPEED;
  if(v<t){float inc=(t-v)*MK_BOOST_GAIN;if(inc>MK_BOOST_CAP)inc=MK_BOOST_CAP;return v+inc;}
  return t;
 }
 if(throttle>0){
  if(v<0)return v+MK_BRAKE>0?0:v+MK_BRAKE;              // stop reversing first
  float t=MK_SPEED*throttle*terrainSpeedFactor();
  if(v<t){float inc=(t-v)*MK_ACCEL_GAIN;if(inc>MK_ACCEL_CAP)inc=MK_ACCEL_CAP;return v+inc;} // [native] form
  float d=v*MK_OVERSPEED;return d<t?t:d;
 }
 if(throttle<0){
  if(v>0)return v-MK_BRAKE<0?0:v-MK_BRAKE;              // brake, then reverse
  float t=-MK_REVERSE*(-throttle);
  if(v>t){float inc=(v-t)*MK_ACCEL_GAIN;if(inc>MK_ACCEL_CAP)inc=MK_ACCEL_CAP;return v-inc;}
  return v;
 }
 if(v>0)return v-MK_COAST<0?0:v-MK_COAST;
 return v+MK_COAST>0?0:v+MK_COAST;
}
void driftTierToast(int tier){
 sys::debugLog("KART drift tier="+tier+" charge="+driftCharge);
 if(tier==1)TextWriter::toast(30,"Mini-Turbo\n");else if(tier==2)TextWriter::toast(30,"Super Mini-Turbo\n");else TextWriter::toast(30,"Ultra Mini-Turbo\n");
}
void updateDrive(int ix,int iy,uint64 held){
 steerInput=0;
 ActorBase@ a=getKart();bool riding=playerIsRiding(a);
 if(!riding && Player !is null){adoptRiddenKart();@a=getKart();riding=playerIsRiding(a);}
 if(riding!=wasRiding){sys::debugLog("KART mounted="+riding);resetHandling();wasRiding=riding;parked=!riding;if(a !is null){parkX=a.pos_x;parkZ=a.pos_z;}}
 if(!riding || a is null){if(a !is null && parked)parkKart(a);return;}
 if(abs(float(ix))>32768 || abs(float(iy))>32768){stopKart(a);resetHandling();return;}
 // Mario Kart 8 Deluxe controls: A gas, B brake (hold when stopped to reverse), R or ZR hop/drift, stick steers.
 float steer=float(ix)/32768.0f,throttle=0;
 if(abs(steer)<0.15f)steer=0;
 bool gas=(held&uint64(A))!=0,brake=(held&uint64(B))!=0;
 if(!gas)gasLatch=false;                 // the A press used to get in must be released first
 if(brake)throttle=-1;else if(gas && !gasLatch)throttle=1;
 steerInput=steer;
 Matrix33f r=a.rot;float length=sqrt(r.a2*r.a2+r.a8*r.a8);
 RigidBody@ b=a.getMainRigidBody();if(b is null)return;
 if(length<0.1f || r.a4<0.4f){stopKart(a);resetHandling();return;}
 // Travel heading = body heading with the drift body angle removed (MK8DX turns the body inward while the
 // kart keeps travelling along the arc). bodyOff > 0 means the nose points further right than travel.
 float bx=r.a2/length,bz=r.a8/length,co=cos(bodyOff),so=sin(bodyOff);
 float fx=bx*co+bz*so,fz=-bx*so+bz*co;  // travel direction on the ground plane
 camFx=fx;camFz=fz;camBraking=brake && mkSpeed>0.5f;
 float lx=fz,lz=-fx;                    // a sideways axis
 Vector3f v=b.vel;
 float actualF=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
 // Do not wind up against walls: commanded speed stays near what the body actually does.
 float actualMk=actualF/MS_PER_MK;
 if(mkSpeed>0 && mkSpeed>actualMk+0.6f)mkSpeed=actualMk+0.6f<0?0:actualMk+0.6f;
 if(mkSpeed<0 && mkSpeed<actualMk-0.6f)mkSpeed=actualMk-0.6f>0?0:actualMk-0.6f;
 // Drift: press R to hop; steering while R is held (within the hop window) locks a direction.
 bool r_held=(held&uint64(R|ZR))!=0,fast=mkSpeed>MK_SPEED*0.35f;
 // Air state from a ray under the kart (the same query as the ground effects).
 if(fxReady())groundRay(a.pos_x,a.pos_y+0.2f,a.pos_z);
 bool overGround=groundDist<AIR_GAP;
 if(overGround){groundFrames++;airFrames=0;}else{airFrames++;groundFrames=0;}
 bool wasAir=airborne;
 bool rPressNow=r_held && !hopHeld;rPressAge=rPressNow?0:rPressAge+1;
 if(!airborne && airFrames>=2){
  airborne=true;trickWindow=TRICK_WINDOW;trickDone=false;sys::debugLog("KART airborne");
  // A trick press just before leaving the ground (ramp lip) counts too: [chosen] 6-frame pre-buffer.
  if(rPressAge<=6+airFrames){trickDone=true;startTrick(steer);sndPlay(S_TRICK,CH_SHOT);TextWriter::toast(30,"Trick!\n");sys::debugLog("KART trick (buffered)");}
 }
 if(airborne && groundFrames>=1){
  airborne=false;
  if(gliding){gliding=false;sys::debugLog("KART glider landed");}
  if(trickDone){if(boostLeft<TRICK_FRAMES)boostLeft=TRICK_FRAMES;sndPlay(S_MINI,CH_SHOT);sys::debugLog("KART trick boost");}
  trickDone=false;sys::debugLog("KART landed");
 }
 float hop=0;
 bool rPress=r_held && !hopHeld;
 if(airborne){
  if(trickWindow>0){trickWindow--;if(rPress && !trickDone){trickDone=true;startTrick(steer);sndPlay(S_TRICK,CH_SHOT);TextWriter::toast(30,"Trick!\n");sys::debugLog("KART trick");}}
 }else if(rPress){hop=HOP_SPEED;hopWindow=24;sndPlay(S_HOP,CH_SHOT);}   // MK8 hops at any speed
 hopHeld=r_held;
 // Glider: Y toggles while airborne and high enough (the ray reaches 2.2 m, so "no hit" means higher than that).
 bool yHeld=(held&uint64(Y))!=0;
 if(!yHeld)gliderLatch=false;
 if(yHeld && !gliderLatch){
  gliderLatch=true;
  if(gliding){gliding=false;autoGlideBlocked=true;sys::debugLog("KART glider folded");}
  else if(airborne && groundDist>=GLIDE_MIN_HEIGHT){gliding=true;sndPlay(S_GOPEN,CH_SHOT);driftDir=0;driftCharge=0;driftTier=0;TextWriter::toast(30,"Glider!\n");sys::debugLog("KART glider open");}
 }
 // Auto-glider (MK8 glide ramps): open once per airtime after AUTO_GLIDE_FRAMES of falling with no ground in ray
 // reach; folding it with Y keeps it closed until landing. ZL+ZR+D-pad Right toggles the feature.
 if(!airborne)autoGlideBlocked=false;
 if(autoGlideOn && airborne && !gliding && !autoGlideBlocked && trickRoll==0 && airFrames>=AUTO_GLIDE_FRAMES && v.y< -AUTO_GLIDE_FALL && groundDist>=GLIDE_MIN_HEIGHT){
  gliding=true;autoGlideBlocked=true;sndPlay(S_GOPEN,CH_SHOT);driftDir=0;driftCharge=0;driftTier=0;sys::debugLog("KART glider auto");
 }
 if(driftDir==0 && !airborne && r_held && hopWindow>0 && abs(steer)>0.3f){driftDir=steer>0?1:-1;driftCharge=0;driftTier=0;sys::debugLog("KART drift start dir="+driftDir);}
 if(driftDir!=0 && (!r_held || !fast)){
  int frames=driftTier==3?int(UMT_FRAMES):driftTier==2?int(SMT_FRAMES):driftTier==1?int(MT_FRAMES):0;
  if(frames>0 && r_held==false){boostLeft=frames;sndPlay(driftTier==3?S_ULTRA:S_MINI,CH_SHOT);sys::debugLog("KART boost tier="+driftTier+" frames="+frames);}
  driftDir=0;driftCharge=0;driftTier=0;
 }
 // Stopped with no pedal: hold position on slopes with the same gentle anchor used for parking.
 if(!airborne && throttle==0 && boostLeft==0 && driftDir==0 && hop==0 && abs(mkSpeed)<MK_COAST){
  mkSpeed=0;driveSpeed=0;bodyOff=0;driftTrack=0;
  if(!idleHold){idleHold=true;parkX=a.pos_x;parkZ=a.pos_z;}
  parkKart(a);return;
 }
 idleHold=false;
 float yaw=0,oldOff=bodyOff;
 for(int step=0;step<2;step++){
  if(hopWindow>0)hopWindow--;
  if(gliding){float t=GLIDE_SPEED*(iy>16000?1.06f:1.0f);mkSpeed+=(t-mkSpeed)*0.02f;}
  else if(!airborne || boostLeft>0)mkSpeed=speedStep(mkSpeed,throttle);
  float bodyTarget=0;
  if(gliding){
   driftTrack=0;yaw+=steer*MK_STEER*GLIDE_STEER;
  }else if(driftDir!=0){
   float inward=steer*driftDir;if(inward>1)inward=1;if(inward< -1)inward=-1;
   // Steer state tracks +/-0.8 (10% of the gap per frame, at most 0.07); intensity = clamp(state,0,1).
   float trackTarget=inward>=0?DRIFT_TRACK:-DRIFT_TRACK,dt=(trackTarget-driftTrack)*0.1f;
   if(dt>0.07f)dt=0.07f;if(dt< -0.07f)dt=-0.07f;driftTrack+=dt;
   float intensity=driftTrack<0?0:driftTrack>1?1:driftTrack;
   // [native] turn = rate * intensity^2 ; [chosen] 0.75 + 0.25*inward keeps stick control over the arc.
   yaw+=driftDir*MK_DRIFT*intensity*intensity*(0.75f+0.25f*inward);
   if(!airborne)driftCharge+=inward>=CHARGE_INWARD?CHARGE_IN:CHARGE_OUT;      // [native] exact MK8DX charge rule
   int tier=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>CHARGE_MT?1:0;
   if(tier>driftTier){driftTier=tier;driftTierToast(tier);}
   bodyTarget=driftDir*DRIFT_BODY;
  }else{
   driftTrack=0;
   float speedFactor=abs(mkSpeed)/(MK_SPEED*0.25f);if(speedFactor>1)speedFactor=1;
   yaw+=steer*MK_STEER*speedFactor*(mkSpeed<0?-1.0f:1.0f)*(airborne?AIR_STEER:1.0f);
  }
  // [native] body angle approach: 7% of the gap per frame, minimum step 0.001.
  if(trickRoll>0){bodyOff+=6.2832f/float(TRICK_ROLL_FRAMES*2)*float(trickRollDir);}
  else{
   float gap=bodyTarget-bodyOff,ds=gap*0.07f;
   if(abs(ds)<0.001f)ds=abs(gap)<0.001f?gap:(gap>0?0.001f:-0.001f);
   bodyOff+=ds;
  }
  if(!airborne)lateral*=1-GRIP*MK_TRACTION;
  // In the air sideways speed was never removed: each glider turn turned forward speed into sideways speed and it
  // built up into a constant slide (user: drifted half the map while gliding). Air drag on it: glider strong, plain air light.
  else lateral*=gliding?1-GLIDE_SIDE_DRAG:1-AIR_SIDE_DRAG;
 }
 if(trickRoll>0){trickRoll--;if(trickRoll==0 || !airborne){trickRoll=0;while(bodyOff>3.1416f)bodyOff-=6.2832f;while(bodyOff< -3.1416f)bodyOff+=6.2832f;}}
 driveSpeed=mkSpeed*MS_PER_MK;
 float speedMs=driveSpeed;
 float vy=v.y+hop;
 if(gliding){
  float sink=iy>16000?GLIDE_DIVE:iy< -16000?GLIDE_FLOAT:GLIDE_SINK;   // stick forward dives, back floats
  vy+=(-sink-vy)*0.3f+GLIDE_GCOMP;                                   // ease into the glide descent (gravity compensated)
 }
 // Terminal fall speed: TOTK lets the rider go once he has been falling faster than ~10-13 m/s for ~1.5 s (free falls
 // from ~240 m: released at caps 12, 18, 32 m/s; never at 6 or 9 m/s over 200 m; a 2.4 m/s glide never). The kart's
 // speed ends ~1.2 m/s above the cap after gravity, so 9 keeps it at ~10.2 m/s.
 if(gliding && vy< -AIR_MAX_FALL)vy=-AIR_MAX_FALL;   // glider only (user: free fall must stay normal speed)
 b.setVel(fx*speedMs+lx*lateral,vy,fz*speedMs+lz*lateral);
 // yaw is radians per two MK frames (1/30 s). Positive yaw turns toward +X (left); stick right is steer>0.
 // The body turns with the travel heading plus the change in drift body angle this frame.
 // Body tilt: rotate the up axis (r.a1, r.a4, r.a7) toward a target up; omega = gain * (up x target).
 // Ground/air: target = world up (self-levelling, as before). Glider: bank into the turn and pitch with the stick.
 float tx=0,ty=1,tz=0,gain=2.0f;
 if(gliding){
  float pitch=float(iy)/32768.0f;if(pitch>1)pitch=1;if(pitch< -1)pitch=-1;
  float bank=steer*GLIDE_BANK,nose=pitch*GLIDE_PITCH;          // stick right: right side down; stick forward: nose down
  tx=-lx*bank+fx*nose;tz=-lz*bank+fz*nose;
  // Combined bank + nose-down lean capped (tan GLIDE_MAX_LEAN ~ 33 deg). Mid-glide releases were not the lean: they
  // were the control stick's riding node reading Link's jittering body velocity (scripts/build_fall_release_patch.py).
  float hl2=sqrt(tx*tx+tz*tz);if(hl2>GLIDE_MAX_LEAN){tx*=GLIDE_MAX_LEAN/hl2;tz*=GLIDE_MAX_LEAN/hl2;}
  ty=1;float tl=sqrt(tx*tx+ty*ty+tz*tz);tx/=tl;ty/=tl;tz/=tl;gain=GLIDE_TILT_GAIN;
 }
 float ux=r.a1,uy=r.a4,uz=r.a7;
 float wx=(uy*tz-uz*ty)*gain,wz=(ux*ty-uy*tx)*gain;   // world axes (a body-axis version flipped the kart)
 b.setAngularVel(wx,-(yaw+bodyOff-oldOff)*30.0f,wz);
}
// ---- Drift sparks and boost flames through TOTK's own particle system (nn::vfx), research/drift-sparks.md.
// Needs runtime/candidates/native-call7-110 (ptr_call). Script-owned memory: the last 32 KiB of LotusKit's 1 MiB
// WebSocket send queue (.bss 0x2d9000), which LotusKit only touches after its debug server is started (exact
// L+R+ZL+ZR+Plus+Minus combo or wsListen()) and a client connects, so the module layout stays unchanged.
// Scratch layout: +0x00/+0x10 effect handles (sparks, flame), +0x30..+0x60 ground-burst handles, +0x100 3x4 matrix,
// +0x140 scale, +0x1000/+0x3000 transform queues, +0x5000 shared ground-burst queue, +0x7000 ground ray-cast query
// (64 entries x 0x60 each, filled by the game's 0x229a3c0 and drained every frame by nn::vfx).
const uint FX_ROOT=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float SPARK_SCALE=0.35f,FLAME_SCALE=0.15f;   // [chosen] from screenshots
ptr_t fxM=0,fxSys=0,fxScr=0;int fxSpark=-2,fxFlame=-1;
// Compare a C string in game memory with name without building strings: LotusKit's script heap has no lock, and
// thousands of small allocations in one frame raised the rate of heap-corruption crashes in testing.
bool fxNameIs(ptr_t p,const string &in name){
 uint n=name.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=name[i])return false;
 return ptr_deref_u8(p+n)==0;
}
int fxFind(const string &in name){
 ptr_t res=ptr_deref_u64(ptr_deref_u64(fxSys+0x2ee8)+8);if(res==0 || ptr_deref_u8(res+0x571)==0)return -1;  // static effects = resource 1
 int n=ptr_deref_s32(res+0x558);ptr_t sets=ptr_deref_u64(res+0x430);
 for(int i=0;i<n;i++)if(fxNameIs(ptr_deref_u64(sets+0x28*i)+0x10,name))return i;
 return -1;
}
bool fxReady(){
 if(fxSpark>=0)return true;
 if(fxSpark==-1)return false;           // looked once and failed: stay off
 fxSpark=-1;
 ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(hook==0)return false;
 uint op=ptr_deref_u32(hook);int64 delta=int64(op&0x03ffffff);if((op&0x02000000)!=0)delta-=0x04000000;
 ptr_t target=ptr_t(int64(hook)+delta*4),base=target-0x65b80;
 if((base&0xfff)!=0 || ptr_deref_u32(target)!=0xf0001382)return false;
 fxScr=base+FX_SCRATCH;fxM=sys::mainOffset();
 ptr_t inst=ptr_deref_u64(ptr_deref_u64(fxM+FX_ROOT));if(inst==0)return false;
 fxSys=ptr_deref_u64(inst+0x11b8);if(fxSys==0)return false;
 int spark=fxFind("Ply_ShockWave_Spark");fxFlame=fxFind("Chm_FlameThrower_ScraBuild");  // Zonai flame emitter jet
 sys::debugLog("KART fx spark="+spark+" flame="+fxFlame);
 if(spark<0)return false;
 fxSpark=spark;return true;
}
ptr_t fxLive(int slot){ptr_t h=fxScr+0x10*slot,e=ptr_deref_u64(h);if(e==0)return 0;return ptr_deref_u32(e+0x234)==ptr_deref_u32(h+8)?e:0;}
ptr_t fxStart(int slot,int id){
 ptr_t e=fxLive(slot);if(e!=0)return e;
 ptr_t h=fxScr+0x10*slot;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
 ptr_call(fxM+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*slot,0,0,0,0,0);
 return fxLive(slot);
}
void fxStop(int slot){if(fxScr==0)return;ptr_t e=fxLive(slot);if(e!=0)ptr_call(fxM+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*slot,0);}
// Queue one emission transform: kart orientation, at a point given in kart-local metres (+X left, +Z forward).
void fxPlace(ptr_t e,ActorBase@ a,float lx,float ly,float lz,float s){
 Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
 float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
 ptr_write_float(m,r.a0);ptr_write_float(m+4,r.a1);ptr_write_float(m+8,r.a2);ptr_write_float(m+12,px);
 ptr_write_float(m+16,r.a3);ptr_write_float(m+20,r.a4);ptr_write_float(m+24,r.a5);ptr_write_float(m+28,py);
 ptr_write_float(m+32,r.a6);ptr_write_float(m+36,r.a7);ptr_write_float(m+40,r.a8);ptr_write_float(m+44,pz);
 ptr_write_float(fxScr+0x140,s);ptr_write_float(fxScr+0x144,s);ptr_write_float(fxScr+0x148,s);
 ptr_call(fxM+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
// EmitterSet colour multiplier (+0x40, multiplies every emitter's colour each frame). The spark texture is orange.
void fxTint(ptr_t e,float r,float g,float b){ptr_write_float(e+0x40,r);ptr_write_float(e+0x44,g);ptr_write_float(e+0x48,b);}
// Mario Kart 8 Deluxe spark colours: mini-turbo blue, super mini-turbo orange, ultra mini-turbo purple.
void sparkFrame(ActorBase@ a){
 bool sparks=a !is null && wasRiding && driftDir!=0 && driftTier>0;
 bool flame=a !is null && wasRiding && boostLeft>0;
 if(!sparks && !flame && fxScr==0)return;
 if(!fxReady()){return;}
 if(!sparks)fxStop(0);
 if(!flame || fxFlame<0)fxStop(1);
 if(sparks){
  ptr_t e=fxStart(0,fxSpark);
  if(e!=0){
   if(driftTier==1)fxTint(e,0.25f,0.8f,6.0f);else if(driftTier==2)fxTint(e,1.0f,1.0f,1.0f);else fxTint(e,2.2f,0.4f,6.0f);
   ptr_t b=wheelBones(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
   if(b!=0){wx=abs(ptr_deref_float(b+312));wy=ptr_deref_float(b+28)+ptr_deref_float(b+316)-0.3683f;wz=ptr_deref_float(b+32)+ptr_deref_float(b+320);}
   fxPlace(e,a,wx,wy,wz,SPARK_SCALE);fxPlace(e,a,-wx,wy,wz,SPARK_SCALE);
  }
 }
 // Mini-turbo boost: twin exhaust jets out of the back of the kart (the jet fires along local -Z).
 if(flame && fxFlame>=0){ptr_t e=fxStart(1,fxFlame);if(e!=0){fxPlace(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);fxPlace(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
// ---- Ground surface: material under the kart, and the matching kicked-up effect at the rear wheels.
// Ray cast = the game's own QueryPhysicsRayCastDistanceToGroundFromPosition evaluate (0x20e4da4) run on a fake query object
// in scratch (vtable main+0x4578958; params/outputs are plain pointers). Link's collision filter is used, so the ray hits
// terrain and objects he can stand on. Material ids: TOTK's table at *(main+0x4637298)+0x250 (Soil 1, Grass 2, ...).
const uint FX_RAY_EVAL=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int groundSlot=-1,groundTick=0;
int gid0=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;  // effect ids per class, looked up once (no arrays in this runtime)
bool groundRay(float x,float y,float z){
 ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
 for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
 ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,ptr_from_ActorBase(Player));
 ptr_write_u64(q,fxM+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
 ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);  // flags: all false
 ptr_write_float(v+4,2.0f);ptr_write_u64(q+0x38,v+4);                                               // ray length (m)
 ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
 ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
 ptr_write_float(v+0x50,x);ptr_write_float(v+0x54,y);ptr_write_float(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
 ptr_call(fxM+FX_RAY_EVAL,q,0,0,0,0,0,0,0,0,0,0);
 if(ptr_deref_u8(v+0x10)==0){groundMat=-1;groundDist=99;return false;}
 groundMat=ptr_deref_s32(v+0x40);groundDist=ptr_deref_float(v+0x14);return true;
}
// Effect class per material: 0 grass, 1 soil/dirt, 2 sand, 3 snow, 4 water, 5 mud, 6 hard (stone/metal/wood/ice...).
int groundClass(int m){
 if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
 if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return -1;return 6;
}
string groundEffectTest="";  // diagnostics only: overrides the grass effect name
string groundEffect(int c){
 if(c==0 && groundEffectTest!="")return groundEffectTest;
 if(c==0)return "ReFX_Grass_L";if(c==1||c==2)return "ReFX_Sand_L";if(c==3)return "ReFX_Snow_L";
 if(c==4)return "Water_Splash01_Move";if(c==5)return "RctFld_Mud_Splash_S";return "Ply_SlipSmoke_Stone";
}
int groundId(int c){
 if(c==0){if(gid0==-2)gid0=fxFind(groundEffect(0));return gid0;}if(c==1){if(gid1==-2)gid1=fxFind(groundEffect(1));return gid1;}
 if(c==2){if(gid2==-2)gid2=fxFind(groundEffect(2));return gid2;}if(c==3){if(gid3==-2)gid3=fxFind(groundEffect(3));return gid3;}
 if(c==4){if(gid4==-2)gid4=fxFind(groundEffect(4));return gid4;}if(c==5){if(gid5==-2)gid5=fxFind(groundEffect(5));return gid5;}
 if(gid6==-2)gid6=fxFind(groundEffect(6));return gid6;
}
const float GROUND_SCALE=1.2f,GROUND_MIN_SPEED=3.0f;  // [chosen]
const int GROUND_BURST=6;   // [chosen] frames between bursts: TOTK's ground effects are one-shot (per footstep / hoof)
// Bursts rotate through handle slots 3..6 (scratch +0x30..+0x60). They share one transform queue (+0x5000): each burst
// only needs its spawn transform. A slot is killed before reuse (age 4 x 6 frames = 0.8 s, enough for the particles).
int groundBurstTick=0,groundBurstSlot=0;
void groundStopAll(){if(fxScr==0)return;for(int k=3;k<7;k++)fxStop(k);}
ptr_t fxStartShared(int slot,int id,ptr_t queue){
 ptr_t h=fxScr+0x10*slot;fxStop(slot);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
 ptr_call(fxM+FX_CREATE,fxSys,h,id,1,0,queue,0,0,0,0,0);
 return fxLive(slot);
}
void groundFrame(ActorBase@ a){
 bool active=a !is null && wasRiding && fxReady();
 if(!active){groundStopAll();groundSlot=-1;return;}
  // groundMat/groundDist come from the ray in updateDrive (every frame while riding)
 int c=groundDist<0.8f?groundClass(groundMat):-1;
 bool offroad=c>=0 && c<6,show=c>=0 && abs(driveSpeed)>GROUND_MIN_SPEED && (offroad || driftDir!=0);
 groundSlot=show?c:-1;
 if(!show){groundBurstTick=0;return;}
 if(groundBurstTick-->0)return;
 groundBurstTick=GROUND_BURST;
 int id=groundId(c);if(id<0)return;
 int slot=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
 ptr_t e=fxStartShared(slot,id,fxScr+0x5000);if(e==0)return;
 float wx=0.78f,wz=-0.75f;ptr_t b=wheelBones(a);if(b!=0){wx=abs(ptr_deref_float(b+312));wz=ptr_deref_float(b+32)+ptr_deref_float(b+320);}
 fxPlace(e,a,wx,0,wz,GROUND_SCALE);fxPlace(e,a,-wx,0,wz,GROUND_SCALE);
}
// ---- Glider model (assets/kart-glider): MK8 Super Glider in host shape pCylinder11, rigid-bound to host bone Control
// (bone 1; its record is two before Skl_Root's at host+2384, i.e. host+2192). Rest scale is 0 (folded). Opening scales
// it up over ~6 frames at the attach point behind the seat; folding scales it back to 0.
const float GLIDER_Y=-0.15f,GLIDER_Z=-0.45f,GLIDER_STORE=1000.0f;   // mesh stored 1/1000 size (scripts/build_glider.py)   // [chosen] attach point in kart space (glider frame base)
float gliderScale=0;bool gliderWritten=false;
// Bone records of the host model live in its model object; find Skl_Root's (translate 0,0.3766,0) followed by Handle_J's
// (translate 0,0.5966,0.4928, the rim pivot) by scanning, once per kart (record layout as in research/steering-rim-animation.md).
ptr_t hostModelAt=0,hostSklAt=0;
ptr_t hostBones(ActorBase@ a){
 ptr_t list=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!riderGuestPointer(list))return 0;
 ptr_t mc=ptr_deref_u64(list+0x10);if(!riderGuestPointer(mc))return 0;
 ptr_t m=ptr_deref_u64(mc+0x28);if(!riderGuestPointer(m))return 0;
 if(m==hostModelAt && hostSklAt!=0)return hostSklAt;
 hostModelAt=m;hostSklAt=0;gliderWritten=false;   // new kart (model instances are pooled: a reused one can keep an open glider)
 for(uint o=0;o<0x4000;o+=4){
  ptr_t r=m+o;
  if(abs(ptr_deref_float(r+52)-0.3766f)<0.003f && abs(ptr_deref_float(r+48))<0.003f && abs(ptr_deref_float(r+56))<0.003f
   && abs(ptr_deref_float(r+96+52)-0.5966f)<0.003f && abs(ptr_deref_float(r+96+56)-0.4928f)<0.003f){hostSklAt=r;sys::debugLog("KART host Skl_Root record at +"+o);break;}
 }
 return hostSklAt;
}
// Link's hand targets: host bones Handle_L/Handle_R (5, 6: records Skl_Root+192/+288, children of the steering rim
// Handle_J at +96, not animated by any clip; Link's hands follow them). Karts keep them on the rim (rest). On the bike
// they go to the handlebar grips (+-0.62, 0.96, 0.43 in Skl_Root space, from the bike mesh), turned with the front
// wheel about the bike's steering axis (pivot 0, 0.645, 0.752; axis 0, 0.906, -0.423), and written in the rim's
// CURRENT frame (its record: axis columns at +0/+16/+32, translate +48) so the rim's own spin does not move them.
// Written every frame: host model instances are shared between kart types.
void gripTarget(ptr_t rec,ptr_t j,float px,float py,float pz){
 float dx=px-ptr_deref_float(j+48),dy=py-ptr_deref_float(j+52),dz=pz-ptr_deref_float(j+56);
 for(uint c=0;c<3;c++)ptr_write_float(rec+48+4*c,ptr_deref_float(j+16*c)*dx+ptr_deref_float(j+16*c+4)*dy+ptr_deref_float(j+16*c+8)*dz);
}
void handTargets(ActorBase@ a){
 if(a is null)return;ptr_t skl=hostBones(a);if(skl==0)return;
 if(!isBike(spawnedType)){
  ptr_write_float(skl+192+48,0);ptr_write_float(skl+192+52,-0.0001f);ptr_write_float(skl+192+56,-0.2107f);
  ptr_write_float(skl+288+48,0);ptr_write_float(skl+288+52,-0.0001f);ptr_write_float(skl+288+56,0.2107f);
  return;
 }
 // Rodrigues: grip offset from the pivot turned by the front wheel's steer angle about the steering axis
 float ax=0,ay=0.906f,az=-0.423f,c=cos(wheelSteer),s=sin(wheelSteer);
 for(int side=-1;side<=1;side+=2){
  float vx=0.62f*side,vy=0.96f-0.645f,vz=0.43f-0.752f,d=ax*vx+ay*vy+az*vz;
  float cx=ay*vz-az*vy,cy=az*vx-ax*vz,cz=ax*vy-ay*vx;
  float rx=vx*c+cx*s+ax*d*(1-c),ry=vy*c+cy*s+ay*d*(1-c),rz=vz*c+cz*s+az*d*(1-c);
  // then the bike's lean (bikeLean: roll about the forward axis through the ground under the wheels)
  float gx=rx,gy=0.645f+ry,lc=cos(bikeRoll),ls=sin(bikeRoll);
  float lx=lc*gx-ls*gy+ls*BIKE_PIVOT_Y,ly=ls*gx+lc*gy+BIKE_PIVOT_Y-lc*BIKE_PIVOT_Y;
  gripTarget(side>0?skl+192:skl+288,skl+96,lx,ly,0.752f+rz);   // +X is Link's left: Handle_L
 }
}
void gliderFrame(ActorBase@ a){
 float target=(a !is null && wasRiding && gliding)?1:0;
 if(target==0 && gliderScale==0 && gliderWritten)return;
 if(a is null)return;
 ptr_t skl=hostBones(a);if(skl==0)return;
 if(gliderScale<target){gliderScale+=0.17f;if(gliderScale>target)gliderScale=target;}
 else if(gliderScale>target){gliderScale-=0.2f;if(gliderScale<target)gliderScale=target;}
 ptr_t r=skl-192;float sc=gliderScale*GLIDER_STORE;   // Control = bone 1, two records before Skl_Root (bone 3)
 ptr_write_float(r,sc);ptr_write_float(r+4,0);ptr_write_float(r+8,0);
 ptr_write_float(r+16,0);ptr_write_float(r+20,sc);ptr_write_float(r+24,0);
 ptr_write_float(r+32,0);ptr_write_float(r+36,0);ptr_write_float(r+40,sc);
 ptr_write_float(r+48,0);ptr_write_float(r+52,GLIDER_Y);ptr_write_float(r+56,GLIDER_Z);
 gliderWritten=true;
}
// ---- Seated legs: TOTK's foot IK plants Link's feet on the surface under him (the kart floor) and folded the authored
// seated legs into a kneel. While riding, turn it off with the game's own setter (OneShotPhysicsSetFootIKDisable ->
// 0x1085b5c(physicsComponent, enable)); physics component = actor+0x228 -> +0x50 -> +0x20. Restored on getting out.
const uint FOOTIK_SET=0x1085b5c;
bool footIkOff=false;
bool gptr(ptr_t p){return p>0x1000000 && p<0x8000000000 && (p&7)==0;}
ptr_t playerPhysics(){
 if(Player is null)return 0;ptr_t p=ptr_deref_u64(ptr_from_ActorBase(Player)+0x228);if(!gptr(p))return 0;
 p=ptr_deref_u64(p+0x50);if(!gptr(p))return 0;p=ptr_deref_u64(p+0x20);return gptr(p)?p:0;
}
void footIkFrame(){
 if(!wasRiding && !footIkOff)return;
 ptr_t phys=playerPhysics();if(phys==0)return;
 ptr_call(sys::mainOffset()+FOOTIK_SET,phys,wasRiding?0:1,0,0,0,0,0,0,0,0,0);
 footIkOff=wasRiding;
}
// Kart sounds (v2, scripts/build_kart_sound_db.py): MK8DX sounds on keys "Kart_*" appended to the kart's SLink user,
// played with the game's xlink2 search-and-play 0x809ee0(user, const char* key, Handle*, 0) (what the AI node
// OneShotXLinkSearchAndEmit calls; user = *(*(*(actor+0x228)+0x68)+0x78)) and faded with 0xb226a4(Handle*, -1)
// (OneShotXLinkFadeByKey's SLink path). Handle = {s8 pool, s16 index, u32 id}, empty = {-1,-1,0}.
// Speed reaches the sounds through the kart's own property ControlStick_StickSpeedXY (the engine and rolling sounds
// use its existing curve 213, pitch (0, 0.65)..(1, 1.0)): property holder X has names at +0x118 (count +0x110) and
// is set with the game's 0x11acb98(X, index, float*) (Cart's own WheelRoll code); X = *(*(*(actor+0x228))+0x10) (0xe195cc).
// Scratch: key text +0x7800, channel handles +0x7880 + 8*ch, property float +0x7a00.
const uint SND_PLAY=0x809ee0,SND_FADE=0xb226a4,PROP_SET=0x11acb98;
const int CH_ENGINE=0,CH_SIZZLE=1,CH_DRIFT=2,CH_RUN=3,CH_SLIP=4,CH_FLUTTER=5,CH_SHOT=6;
const float SND_ROT_PER_MS=1.0f/14.0f;    // [chosen] top speed (14 m/s) = 1 = top of curve 213
// Sounds are chosen by number every frame and a key string is built only when one starts: building strings every
// frame raised the rate of LotusKit's script-heap corruption crash (a pointer overwritten with "Kart_Gli..." text).
const int S_ENGINE=1,S_DASH=2,S_IDLE=3,S_SIZZLE=4,S_DRIFT=7,S_FLUTTER=8,S_RUN=10,S_SLIP=20,S_LANDS=30;
const int S_MINI=40,S_ULTRA=41,S_HOP=42,S_LAND=43,S_TRICK=44,S_GOPEN=45,S_GCLOSE=46,S_HORN=47;
int sndLogs=0;int chKey0=0,chKey1=0,chKey2=0,chKey3=0,chKey4=0,chKey5=0;
string surfaceName(int s){return s==0?"Grass":s==1?"Dirt":s==2?"Sand":s==3?"Snow":s==4?"Water":s==5?"Stone":"Wood";}
string keyName(int id){
 if(id==S_ENGINE)return "Kart_Engine";if(id==S_DASH)return "Kart_EngineDash";if(id==S_IDLE)return "Kart_Idle";
 if(id>=S_SIZZLE && id<S_SIZZLE+3)return "Kart_Sizzle"+(id-S_SIZZLE+1);if(id==S_DRIFT)return "Kart_DriftSteer";
 if(id==S_FLUTTER)return "Kart_GliderFlutter";if(id>=S_RUN && id<S_RUN+7)return "Kart_Run_"+surfaceName(id-S_RUN);
 if(id>=S_SLIP && id<S_SLIP+7)return "Kart_Slip_"+surfaceName(id-S_SLIP);if(id>=S_LANDS && id<S_LANDS+7)return "Kart_Land_"+surfaceName(id-S_LANDS);
 if(id==S_MINI)return "Kart_MiniTurbo";if(id==S_ULTRA)return "Kart_UltraTurbo";if(id==S_HOP)return "Kart_Hop";if(id==S_LAND)return "Kart_Land";
 if(id==S_TRICK)return "Kart_Trick";if(id==S_HORN)return "Kart_Horn";if(id==S_GOPEN)return "Kart_GliderOpen";if(id==S_GCLOSE)return "Kart_GliderClose";return "";
}
ptr_t sndX=0;int sndProp=-1;bool sndXTried=false;
ptr_t sndUser(){
 ActorBase@ a=getKart();if(a is null || !fxReady())return 0;
 ptr_t x=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!gptr(x))return 0;
 x=ptr_deref_u64(x+0x68);if(!gptr(x))return 0;
 ptr_t u=ptr_deref_u64(x+0x78);return gptr(u)?u:0;
}
void sndPlay(int id,int ch){
 ptr_t u=sndUser();if(u==0 || id<=0)return;string key=keyName(id);
 ptr_t k=fxScr+0x7800,h=fxScr+0x7880+8*ch;uint n=key.length();
 for(uint w=0;w<4;w++){uint64 v=0;for(uint i=0;i<8;i++){uint c=w*8+i;if(c<n)v|=uint64(key[c])<<(8*i);}ptr_write_u64(k+8*w,v);}
 ptr_write_u64(h,0xffff00ff);
 ptr_call(fxM+SND_PLAY,u,k,h,0,0,0,0,0,0,0,0);
 if(sndLogs<80){sndLogs++;sys::debugLog("KART snd "+key+" h="+ptr_deref_u64(h));}
}
void sndFade(int ch){if(fxScr==0)return;ptr_t h=fxScr+0x7880+8*ch;if(ptr_deref_u64(h)!=0xffff00ff)ptr_call(fxM+SND_FADE,h,0xffffffff,0,0,0,0,0,0,0,0,0);ptr_write_u64(h,0xffff00ff);}
int chKey(int ch){return ch==0?chKey0:ch==1?chKey1:ch==2?chKey2:ch==3?chKey3:ch==4?chKey4:chKey5;}
void chSetKey(int ch,int k){if(ch==0)chKey0=k;else if(ch==1)chKey1=k;else if(ch==2)chKey2=k;else if(ch==3)chKey3=k;else if(ch==4)chKey4=k;else chKey5=k;}
// Keep channel ch playing loop `key` ("" = silent): fades the old loop and starts the new one when it changes.
void sndLoop(int ch,int key){
 if(chKey(ch)==key)return;
 if(chKey(ch)!=0)sndFade(ch);
 if(key!=0)sndPlay(key,ch);
 chSetKey(ch,key);
}
bool propNames(ptr_t x){
 if(!gptr(x))return false;uint n=ptr_deref_u32(x+0x110);if(n==0 || n>16)return false;
 ptr_t names=ptr_deref_u64(x+0x118);if(!gptr(names))return false;
 for(uint i=0;i<n;i++){ptr_t s=ptr_deref_u64(names+8*i);if(gptr(s) && fxNameIs(s,"ControlStick_StickSpeedXY")){sndProp=int(i);return true;}}
 return false;
}
void sndFindX(){
 // 0xe195cc (used before 0x134c7a4 by the game's own property users): X = *(*(*(actor+0x228))+0x10)
 sndXTried=true;sndX=0;sndProp=-1;
 ActorBase@ a=getKart();if(a is null)return;
 ptr_t p=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!gptr(p))return;
 p=ptr_deref_u64(p);if(!gptr(p))return;
 p=ptr_deref_u64(p+0x10);if(!gptr(p))return;
 if(propNames(p))sndX=p;
 sys::debugLog("KART snd prop X="+(sndX!=0)+" idx="+sndProp+" n="+ptr_deref_u32(p+0x110));
}
void sndSpeed(float ms){
 if(sndX==0 || sndProp<0)return;
 ptr_t f=fxScr+0x7a00;
 ptr_write_float(f,abs(ms)*SND_ROT_PER_MS);
 ptr_call(fxM+PROP_SET,sndX,sndProp,f,0,0,0,0,0,0,0,0);
 // The game clears this property every frame (it is a per-frame input, written by the actor's own logic before
 // its sounds update), so it is written again every frame; a lock flag (*(X+0x168)[idx]) does not survive the clear.
}
// MK8 surface bank for the ground under the kart: 0 Grass, 1 Dirt, 2 Sand, 3 Snow, 4 Water, 5 Stone, 6 Wood.
int lastMatName=-2,lastSurface=-1;
bool matNameHas(int m,const string &in w){
 ptr_t t=ptr_deref_u64(fxM+0x4637298);if(t==0 || m<0 || m>=54)return false;ptr_t s=ptr_deref_u64(t+0x250+8*m);if(!gptr(s))return false;
 uint n=w.length();for(uint i=0;i<28;i++){if(ptr_deref_u8(s+i)==0)return false;bool ok=true;for(uint k=0;k<n && ok;k++)if(ptr_deref_u8(s+i+k)!=w[k])ok=false;if(ok)return true;}
 return false;
}
int surfaceSound(){
 if(groundMat==lastMatName)return lastSurface;
 lastMatName=groundMat;int c=groundClass(groundMat);
 lastSurface=c<0?-1:c==0?0:c==1?1:c==2?2:c==3?3:c==4?4:c==5?1:(matNameHas(groundMat,"Wood")?6:5);
 return lastSurface;
}
bool sndWasAir=false,sndWasGlide=false;
void soundFrame(){
 if(!wasRiding){
  if(chKey0!=0 || chKey1!=0 || chKey2!=0 || chKey3!=0 || chKey4!=0 || chKey5!=0){for(int c=0;c<6;c++)sndLoop(c,0);}
  sndXTried=false;sndWasAir=false;sndWasGlide=false;return;
 }
 if(!sndXTried)sndFindX();
 float sp=abs(driveSpeed);sndSpeed(sp);
 // Gliding: only the wind/flutter (MK8 drops the engine and wheel layers on the glider).
 sndLoop(CH_ENGINE,gliding?0:boostLeft>0?S_DASH:sp<0.6f?S_IDLE:S_ENGINE);
 sndLoop(CH_SIZZLE,(driftDir!=0 && driftTier>0 && !gliding)?S_SIZZLE+driftTier-1:0);
 int surf=(airborne || gliding)?-1:surfaceSound();
 sndLoop(CH_DRIFT,(driftDir!=0 && !airborne && !gliding)?S_DRIFT:0);
 sndLoop(CH_RUN,(surf>=0 && sp>1.0f && driftDir==0)?S_RUN+surf:0);
 sndLoop(CH_SLIP,(surf>=0 && driftDir!=0)?S_SLIP+surf:0);
 sndLoop(CH_FLUTTER,gliding?S_FLUTTER:0);
 if(sndWasGlide && !gliding)sndPlay(S_GCLOSE,CH_SHOT);
 if(sndWasAir && !airborne){sndPlay(S_LAND,CH_SHOT);int s2=surfaceSound();if(s2>=0)sndPlay(S_LANDS+s2,CH_SHOT+1);}
 sndWasAir=airborne;sndWasGlide=gliding;
}
// ---- MK8-style chase camera (LotusKit camera::freeze(up, pos, at) overrides the game's LookAtCamera each frame;
// camera::toggleFreeze() hands it back). Follows the travel heading with lag, so turns swing and drifts show the kart
// side-on; pulls back with speed and boosts (plus a kick when a boost starts), closes in on the brake, rises with lag in
// the air and goes high and wide on the glider. Right stick looks around (springs back). ZL+ZR+D-pad Left toggles it.
// All [chosen] values; MK8DX's camera tables were not decoded.
const bool MKCAM_DEFAULT=true;
const float CAM_DIST=6.2f,CAM_HEIGHT=2.4f,CAM_LOOK_AHEAD=1.6f,CAM_LOOK_UP=1.2f,CAM_DRIFT_SWING=0.16f;
const float CAM_MAX_LAG=3.0f,CAM_LEAD=0.07f;   // [chosen] seconds of fall to lead
const float CAM_GLIDE_DIST=7.6f,CAM_GLIDE_HEIGHT=4.4f,CAM_BOOST_BACK=0.8f,CAM_KICK=0.7f,CAM_BRAKE_IN=0.5f;
bool mkCamOn=MKCAM_DEFAULT,mkCamChordLatched=true,camFrozen=false,camInit=false,camBraking=false;
float camFx=0,camFz=1,camHx=0,camHz=1,camDist=CAM_DIST,camH=CAM_HEIGHT,camY=0,camKick=0,camLook=0;int camLastBoost=0;
void camRelease(){if(camFrozen){camera::toggleFreeze();camFrozen=false;}camInit=false;}
void cameraFrame(ActorBase@ a,int rx,int ry){
 if(!mkCamOn || a is null || !wasRiding){camRelease();return;}
 float sp=abs(driveSpeed);
 if(boostLeft>camLastBoost+5)camKick=1;camLastBoost=boostLeft;camKick*=0.88f;
 float tx=camFx,tz=camFz;
 if(driftDir!=0){float c=cos(-driftDir*CAM_DRIFT_SWING),s2=sin(-driftDir*CAM_DRIFT_SWING);float nx=tx*c+tz*s2,nz=-tx*s2+tz*c;tx=nx;tz=nz;}
 if(!camInit){camHx=tx;camHz=tz;camY=a.pos_y;camDist=CAM_DIST;camH=CAM_HEIGHT;}
 float rate=gliding?0.06f:airborne?0.05f:0.13f;
 camHx+=(tx-camHx)*rate;camHz+=(tz-camHz)*rate;float hl=sqrt(camHx*camHx+camHz*camHz);if(hl<0.01f){camHx=tx;camHz=tz;hl=1;}camHx/=hl;camHz/=hl;
 float look=float(rx)/32768.0f;if(abs(look)<0.2f)look=0;float lookT=look*1.8f;
 if(float(ry)/32768.0f< -0.7f)lookT=3.1416f;   // right stick down: look behind (MK8 look-back)
 camLook+=(lookT-camLook)*(lookT>3.0f?0.35f:0.15f);
 float lc=cos(camLook),ls=sin(camLook),dx=camHx*lc+camHz*ls,dz=-camHx*ls+camHz*lc;
 float dist=gliding?CAM_GLIDE_DIST:CAM_DIST+sp*0.035f+(boostLeft>0?CAM_BOOST_BACK:0)-(camBraking?CAM_BRAKE_IN:0);
 dist+=camKick*CAM_KICK;
 float h=gliding?CAM_GLIDE_HEIGHT:CAM_HEIGHT+sp*0.01f;
 camDist+=(dist-camDist)*(camKick>0.5f?0.3f:0.1f);camH+=(h-camH)*0.08f;
 // Aim at where the kart will be when the frame shows (fast falls move ~3 m per frame at 90 m/s).
 float ky=a.pos_y;if(airborne){RigidBody@ cb=a.getMainRigidBody();if(cb !is null)ky+=cb.vel.y*CAM_LEAD;}
 camY+=(ky-camY)*((airborne||gliding)?0.12f:0.35f);
 // Fast falls: the lagging height left the kart below the frame. Keep the camera within CAM_MAX_LAG of the kart and
 // aim at the kart itself, so a free fall is followed from above, looking down.
 if(camY-ky>CAM_MAX_LAG)camY=ky+CAM_MAX_LAG;if(ky-camY>CAM_MAX_LAG)camY=ky-CAM_MAX_LAG;
 double px=a.pos_x-dx*camDist,py=camY+camH,pz=a.pos_z-dz*camDist;
 double ax=a.pos_x+dx*CAM_LOOK_AHEAD,ay=ky+(gliding?0.4f:CAM_LOOK_UP),az=a.pos_z+dz*CAM_LOOK_AHEAD;
 camera::freeze(0,1,0,px,py,pz,ax,ay,az);camFrozen=true;camInit=true;
}
void initKart(){
 tas::doBlockOnLoadingPause(false);
 for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
 sys::debugLog("KART ready");
}
bool hornLatch=false;
bool chordLatched=true,spawnPending=false,loadCleared=false;
uint spawnDelay=0;
// Input remapping while driving. The runtime keeps Record::currentInput (pad) as the player's RAW input
// (raw-input-110 patch), and the resident loop gives the game a rewritten copy via input() one frame later.
bool overrideActive=false,exitLatch=false;uint64 outButtons=0;int outLX=0,outLY=0,outRX=0,outRY=0;
// Test hook: diagnostics simulate the player here instead of the physical controller.
bool simActive=false;uint64 simHeld=0;int simLX=0,simLY=0,simRX=0,simRY=0;
void controllerFrame(ptr_t pad){
 uint64 held=simActive?simHeld:ptr_deref_u64(pad);
 int lx=simActive?simLX:ptr_deref_s32(pad+8),ly=simActive?simLY:ptr_deref_s32(pad+12);
 int rx=simActive?simRX:ptr_deref_s32(pad+16),ry=simActive?simRY:ptr_deref_s32(pad+20);
 overrideActive=false;outButtons=held;outLX=lx;outLY=ly;outRX=rx;outRY=ry;
 if(!locationReady()){
  camRelease();
  if(!loadCleared){forgetKart();loadCleared=true;}
  chordLatched=true;spawnPending=false;spawnDelay=0;exitLatch=false;return;
 }
 loadCleared=false;
 // Karts come from the inventory (capsules from the kart chests at Lookout Landing, scripts/build_kart_chests.py).
 // The old spawn / pick / capsule chords stay for the automatic tests only (they set devChords).
 if(devChords){
 uint64 mask=uint64(ZL|ZR|DUP);
 if((held&mask)==0)chordLatched=false;
 if(!chordLatched && (held&mask)==mask){chordLatched=true;spawnPending=true;sys::debugLog("KART spawn queued");}
 uint64 kartMask=uint64(ZL|ZR|X);
 if((held&kartMask)==0)kartChordLatched=false;
 if(!wasRiding && !kartChordLatched && (held&kartMask)==kartMask){
  kartChordLatched=true;kartType=(kartType+1)%KART_TYPES;sys::debugLog("KART type="+kartType);
  TextWriter::toast(120,"Kart: "+kartName(kartType)+" (ZL+ZR+Up to spawn, ZL+ZR+Y for a capsule)\n");
 }
 uint64 capMask=uint64(ZL|ZR|Y);
 if((held&capMask)==0)capChordLatched=false;
 if(!wasRiding && !capChordLatched && (held&capMask)==capMask && Player !is null){
  capChordLatched=true;Matrix33f r=Player.rot;
  actor::createSimple(kartCapsule(kartType),Player.pos_x+1.5f*r.a2,Player.pos_y+0.8f,Player.pos_z+1.5f*r.a8);
  sys::debugLog("KART capsule "+kartType);TextWriter::toast(90,kartName(kartType)+" capsule\n");
 }
 }
 uint64 camMask=uint64(ZL|ZR|DLEFT);
 if((held&camMask)==0)mkCamChordLatched=false;
 if(!mkCamChordLatched && (held&camMask)==camMask){
  mkCamChordLatched=true;mkCamOn=!mkCamOn;sys::debugLog("KART mkcam="+mkCamOn);
  TextWriter::toast(90,mkCamOn?"Mario Kart camera: ON\n":"Mario Kart camera: OFF\n");
 }
 uint64 agMask=uint64(ZL|ZR|DRIGHT);
 if((held&agMask)==0)autoGlideChordLatched=false;
 if(!autoGlideChordLatched && (held&agMask)==agMask){
  autoGlideChordLatched=true;autoGlideOn=!autoGlideOn;sys::debugLog("KART autoglide="+autoGlideOn);
  TextWriter::toast(90,autoGlideOn?"Auto glider: ON\n":"Auto glider: OFF\n");
 }
 uint64 offMask=uint64(ZL|ZR|DDOWN);
 if((held&offMask)==0)offroadChordLatched=false;
 if(!offroadChordLatched && (held&offMask)==offMask){
  offroadChordLatched=true;offroadOn=!offroadOn;sys::debugLog("KART offroad="+offroadOn);
  TextWriter::toast(90,offroadOn?"Off-road handling: ON\n":"Off-road handling: OFF\n");
 }
 // Pause menu / map: the game raises GamePause (Pre/Post while opening/closing) and pauses physics, but not the Actor
 // target. Hand every button and the camera back so the menus work (measured: runtime/diagnostics/menu_probe.as).
 if(!worldReady() || menuOpen()){camRelease();return;}
 if(spawnPending && (held&uint64(ZL|ZR|DUP))!=uint64(ZL|ZR|DUP)){if(++spawnDelay>=15){spawnPending=false;spawnDelay=0;spawnKart();}}else spawnDelay=0;
 updateDrive(lx,ly,held);
 animateWheels(getKart());
 sparkFrame(getKart());
 gliderFrame(getKart());handTargets(getKart());
 footIkFrame();
 groundFrame(getKart());
 soundFrame();
 cameraFrame(getKart(),rx,ry);
 uint64 driving=uint64(A|B|X|Y|R|ZR|L);
 if(wasRiding && (held&uint64(L))!=0 && !hornLatch){hornLatch=true;sndPlay(S_HORN,CH_SHOT);}   // L: horn (MK8: item button with no item)
 if((held&uint64(L))==0)hornLatch=false;
 if(wasRiding){
  overrideActive=true;outButtons=held&~driving;
  if(airborne || gliding){outLX=0;outLY=0;}   // in the air the vanilla stick tilts the contraption; on the ground the game
                                              // still gets it so Link plays his Turn_L/Turn_R lean clips
  if((held&uint64(X))!=0){outButtons|=uint64(B);exitLatch=true;}   // X gets out: TOTK's own dismount is B
 }else if(exitLatch){
  if((held&uint64(X))==0)exitLatch=false;
  else{overrideActive=true;outButtons=held&~uint64(X);}             // do not let the held X make Link jump
 }
}
void yieldFrame(){
 if(overrideActive)input(1,outButtons,outLX,outLY,outRX,outRY);
 else sleep(1);
}
void runResident(ptr_t pad){while(true){controllerFrame(pad);yieldFrame();}}
void main(){
 initKart();ptr_t pad=resolvePadInput();if(pad==0){TextWriter::toast(300,"KartLab: runtime input signature mismatch.\n");return;}
 TextWriter::toast(300,"KartLab: kart chests are just outside Lookout Landing (east). Place karts from Zonai Devices. A gas, B brake, R drift, X exit.\n");
 runResident(pad);
}
