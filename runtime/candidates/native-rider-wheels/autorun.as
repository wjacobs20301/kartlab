ptr_t _k16=0;
uint _k17=0xffffffff;
float _k18=0;
bool _k19=false;
bool _k20=false;float _w14=0,_w15=0;
float _w0=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _w6=false;
const float MK_SPEED=7.775f;//[table]PRSL ground top speed,0 coins
const float MK_ACCEL_GAIN=0.011f;//[table]PRAC strength(G)
const float MK_ACCEL_CAP=0.09f;//[table]PRAC limiter(M)
const float MK_STEER=0.0118f;//[table]PRTL _w25,rad per MK frame
const float MK_DRIFT=0.0196f;//[table]PRTL drift,rad per MK frame
const float MK_CHARGE=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float MK_TRACTION=0.75f;//[table]PRON road traction
const float MT_SPEED=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint MT_FRAMES=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _w18)
const uint UMT_FRAMES=153;//[chosen]ultra _w13(not in the table):SMT+(SMT-MT)
const float CHARGE_MT=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float MS_PER_MK=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float MK_REVERSE=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float MK_BRAKE=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float MK_COAST=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float MK_OVERSPEED=0.993f;//[chosen]decay above _w23(after a boost)
const float MK_BOOST_GAIN=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float GRIP=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float DRIFT_BODY=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min step 0.001
const float DRIFT_TRACK=0.8f;//[native]drift _w25 _w24 _w12,approached at 10%/frame,step<=0.07
const float CHARGE_IN=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if inward>=0.71 else 2
const float HOP_SPEED=4.2f;//[chosen]drift hop,m/s upward(~0.4 m,visible from the chase camera)
const int TRICK_ROLL_FRAMES=15;//[chosen]0.5 s
int trickRoll=0,trickRollDir=1;
const int AUTO_GLIDE_FRAMES=24;const float AUTO_GLIDE_FALL=5.0f;bool autoGlideOn=true,autoGlideBlocked=false,autoGlideChordLatched=true;
void startTrick(float _w25){trickRoll=TRICK_ROLL_FRAMES;trickRollDir=_w25<-0.3f?-1:1;}//stick left spins the other way
const float AIR_STEER=0.3f,AIR_GAP=0.7f;const int TRICK_WINDOW=8,TRICK_FRAMES=31;//trick:also R up to 6 _w18 before take-off
const float GLIDE_GCOMP=0.95f;//[measured]TOTK pulls the kart down~0.95 m/s per frame;added back so the glide sink settles at _w23
const float GLIDE_SPEED=8.225f,GLIDE_SINK=1.6f,GLIDE_DIVE=4.5f,GLIDE_FLOAT=0.6f,GLIDE_STEER=0.6f,GLIDE_MIN_HEIGHT=2.5f;
const float AIR_MAX_FALL=9.0f,GLIDE_SIDE_DRAG=0.08f,AIR_SIDE_DRAG=0.01f;//[chosen]per half-frame step
const float GLIDE_BANK=0.55f,GLIDE_PITCH=0.35f,GLIDE_TILT_GAIN=4.0f,GLIDE_MAX_LEAN=0.65f;//[chosen]~29 deg bank,~19 deg nose-down,~33 deg combined max
bool airborne=false,trickDone=false,gliding=false,gliderLatch=true;int airFrames=0,groundFrames=0,trickWindow=0,rPressAge=99;
const bool OFFROAD_DEFAULT=false;
const float OFFROAD_LIGHT=0.7f,OFFROAD_HEAVY=0.5f;//[table]PROF
bool offroadOn=OFFROAD_DEFAULT,offroadChordLatched=true;
float mkSpeed=0,driftCharge=0,bodyOff=0,driftTrack=0;int driftDir=0,driftTier=0,boostLeft=0,hopWindow=0;bool hopHeld=false,gasLatch=true,idleHold=false;
bool menuOpen(){return pause::isPauseRequest("GamePause")||pause::isPauseRequest("PreGamePause")||pause::isPauseRequest("PostGamePause")||pause::isPauseTarget("Custom_PhysicsUpdateWorld");}
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(hook==0)return 0;
uint op=ptr_deref_u32(hook);if((op&0xfc000000)!=0x94000000)return 0;
int64 _w28=int64(op&0x03ffffff);if((op&0x02000000)!=0)_w28-=0x04000000;
ptr_t _w23=ptr_t(int64(hook)+_w28*4);
if(ptr_deref_u32(_w23)!=0xf0001382||ptr_deref_u32(_w23+4)!=0xa9be7bfd)return 0;
ptr_t base=_w23-0x65b80;if((base&0xfff)!=0)return 0;return base+0x3d90b8;
}
void _k13(){gliderScale=0;gliderWritten=false;ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;resetHandling();_k19=false;_k20=false;_w14=0;_w15=0;_w6=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||ptr_from_ActorBase(a)!=_k16)return null;
if(ptr_deref_u32(_k16+0x10)!=_k17)return null;
uint _w24=ptr_deref_u32(_k16+0x24);if(_w24<2||_w24>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@host,uint _k27){
if(host is null||_k27==0xffffffff)return false;
ptr_t p=ptr_from_ActorBase(host);
if(!_k2(p)||ptr_deref_u32(p+0x10)!=_k27)return false;
uint _w24=ptr_deref_u32(p+0x24);
return _w24>=2&&_w24<=6;
}
bool _k0(ActorBase@host,uint _k27){
if(Player is null||!_k1(host,_k27))return false;
ptr_t actor=ptr_from_ActorBase(host),_w22=ptr_from_ActorBase(Player);
if(!_k2(_w22))return false;
uint _k30=ptr_deref_u32(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=ptr_deref_u32(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _w29=ptr_deref_u32(actor+0x220);ptr_t list=ptr_deref_u64(actor+0x228);
if(_w29<=129||_w29>512||!_k2(list))return false;
ptr_t _w21=ptr_deref_u64(list+0x408);
if(!_k2(_w21))return false;
uint _w27=ptr_deref_u32(_w21+0x20);ptr_t _k29=ptr_deref_u64(_w21+0x28);
if(_w27!=1||!_k2(_k29))return false;
ptr_t seat=ptr_deref_u64(_k29);
if(!_k2(seat))return false;
uint _w26=ptr_deref_u32(seat+0x10),flags=ptr_deref_u32(seat+0x18);
float _k33=ptr_deref_float(seat+0x74);
if(_w26!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=ptr_deref_u64(seat+8),_k28=ptr_deref_u64(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(ptr_deref_u32(_k28+0x48)!=_k30||ptr_deref_u64(_k28+0x40)!=_w22)return false;
return _k1(host,_k27)&&ptr_deref_u32(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((ptr_deref_u64(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_w14=a.pos_x;_w15=a.pos_z;return;}
float dx=_w14-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_w14=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
int kartType=0,spawnedType=0;bool kartChordLatched=true,capChordLatched=true,devChords=false;
string kartActor(int t){return t==1?"SpObj_ControlStick_A_06":t==2?"SpObj_ControlStick_A_05":t==3?"SpObj_ControlStick_A_04":"SpObj_ControlStick_A_01";}//variants are new actors A_04..A_06
string kartName(int t){return t==1?"Pipe Frame":t==2?"B Dasher":t==3?"Standard Bike":"Standard Kart";}
const int KART_TYPES=4;bool isBike(int t){return t==3;}
string kartCapsule(int t){return"SpObj_ControlStick_Capsule_A_0"+(t+1);}//inventory capsules(scripts/build_kart_capsules.py)
const string KART_PREFIX="SpObj_ControlStick_A_0";
uint adoptTick=0;
int kartTypeOfActor(ptr_t a){
ptr_t s=ptr_deref_u64(a+0x218);if(s<0x1000000||s>0x8000000000)return-1;
for(uint i=0;i<KART_PREFIX.length();i++)if(ptr_deref_u8(s+i)!=KART_PREFIX[i])return-1;
uint d=ptr_deref_u8(s+22);if(ptr_deref_u8(s+23)!=0)return-1;
return d==49?0:d==54?1:d==53?2:d==52?3:-1;//A_01 Standard,A_06 Pipe Frame,A_05 B Dasher,A_04 Bike(A_02/A_03 vanilla)
}
void adoptRiddenKart(){
if(Player is null||(adoptTick++)%10!=0)return;
ptr_t p=ptr_from_ActorBase(Player);uint n=ptr_deref_u32(p+0x220);ptr_t list=ptr_deref_u64(p+0x228);
if(n<=130||n>600||!gptr(list))return;
ptr_t c=ptr_deref_u64(list+8*130);if(!gptr(c))return;
ptr_t ld=ptr_deref_u64(c+0x28);if(!gptr(ld))return;
ptr_t k=ptr_deref_u64(ld+0x40);if(!gptr(k)||k==_k16)return;
uint id=ptr_deref_u32(ld+0x48);if(ptr_deref_u32(k+0x10)!=id)return;
uint st=ptr_deref_u32(k+0x24);if(st<2||st>6)return;
int t=kartTypeOfActor(k);if(t<0)return;
_k13();ActorWatcher::assignSlot(2,k);_k16=k;_k17=id;spawnedType=t;kartType=t;
ActorBase@a=ActorWatcher::get(2);
if(a is null||ptr_from_ActorBase(a)!=k||!_k15(a)){_k13();return;}
sys::debugLog("KART adopted "+kartName(t));
}
float kartTireF(int t){return t==1?1.0f:t==2?1.18f:t==3?1.275f:1.0f;}
float kartTireR(int t){return t==1?1.2f:t==2?1.42f:t==3?1.275f:1.3f;}
void _k8(){
if(!_k3())return;
ActorBase@old=_k7();
if(_k15(old)){TextWriter::toast(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_w13=sqrt(fx*fx+fz*fz);if(_w13<0.1f)return;fx/=_w13;fz/=_w13;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(old!is null&&spawnedType!=kartType){_k13();@old=null;}//a different kart was chosen:spawn it(the old one stays)
if(old!is null){_k10(old);old.setPos(x,y,z);@old=null;_w14=0;_w15=0;_w6=false;}
else{_k13();actor::createAndWatch(2,kartActor(kartType),x,y,z);spawnedType=kartType;sleep(60);}//let creation get past its first _w18 before touching the actor
for(uint f=0;f<600&&_k3();f++){//up to 20 s:a first load of a kart pack can take a while
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=ptr_from_ActorBase(a);if(!gptr(_k16)){@a=null;sleep(1);continue;}_k17=ptr_deref_u32(_k16+0x10);
if(f%60==0)sys::debugLog("KART spawn wait f="+f+" ptr="+formatInt(int64(_k16),"H")+" state="+ptr_deref_u32(_k16+0x24)+" ct="+gptr(ptr_deref_u64(_k16+0x228)));
ptr_t ct=ptr_deref_u64(_k16+0x228);bool physReady=gptr(ct)&&gptr(ptr_deref_u64(ct+0x50))&&gptr(ptr_deref_u64(ptr_deref_u64(ct+0x50)+0x20));
if(physReady&&a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();
if(a is null){ptr_t k=_k16;sys::debugLog("KART spawn lost: watcher="+(ActorWatcher::get(2)!is null)+" state="+(gptr(k)?ptr_deref_u32(k+0x24):99)+" id="+(gptr(k)?ptr_deref_u32(k+0x10):0)+"/"+_k17);return;}a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_w14=a.pos_x;_w15=a.pos_z;
TextWriter::toast(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
sys::debugLog("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
{ActorBase@a=ActorWatcher::get(2);ptr_t k=a is null?0:ptr_from_ActorBase(a);ptr_t ct=gptr(k)?ptr_deref_u64(k+0x228):0;
sys::debugLog("KART spawn unavailable: world="+_k3()+" watcher="+(a!is null)+" ptr="+formatInt(int64(k),"H")+" state="+(gptr(k)?ptr_deref_u32(k+0x24):99)+" ct="+gptr(ct)+" phys="+(gptr(ct)&&gptr(ptr_deref_u64(ct+0x50))));}
_k13();TextWriter::toast(150,"KartLab: spawn unavailable.\n");
}
ptr_t _w7(ActorBase@a){
ptr_t list=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!_k2(list))return 0;
ptr_t mc=ptr_deref_u64(list+0x10);if(!_k2(mc))return 0;
ptr_t m=ptr_deref_u64(mc+0x28);if(!_k2(m))return 0;
ptr_t x=ptr_deref_u64(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=ptr_deref_u64(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
float lf=ptr_deref_float(b+120),rf=ptr_deref_float(b+216),lb=ptr_deref_float(b+312),rb=ptr_deref_float(b+408);
if(abs(ptr_deref_float(b+28)-0.3766f)>(isBike(spawnedType)?0.08f:0.002f)||abs(lf+rf)>0.002f||abs(lb+rb)>0.002f)return 0;//(a leaning bike moves its root)
if(isBike(spawnedType)){if(abs(lf)>0.01f||abs(lb)>0.01f)return 0;}//bike:both sockets of an axle on the centre line
else if(lf<0.5f||lf>1.2f||lb<0.5f||lb>1.2f)return 0;
return b;
}
void _w8(ptr_t t,float sp,float cp,float sd,float cd){
ptr_write_float(t,cd);ptr_write_float(t+4,0);ptr_write_float(t+8,-sd);
ptr_write_float(t+16,sd*sp);ptr_write_float(t+20,cp);ptr_write_float(t+24,cd*sp);
ptr_write_float(t+32,sd*cp);ptr_write_float(t+36,-sp);ptr_write_float(t+40,cd*cp);
}
const float TREAD_PERIOD=0.3927f;//2*pi/16 tread blocks
float visualSpinStep(float step){
float m=abs(step),half=TREAD_PERIOD*0.5f;
if(m<=half*0.9f)return step;
float blocks=floor((m-half)/TREAD_PERIOD);if(blocks>3)blocks=3;
float v=(blocks+0.5f)*TREAD_PERIOD;return step<0?-v:v;
}
void _w9(ActorBase@a){
if(a is null){_w6=false;return;}
Matrix33f r=a.rot;float _w13=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_w6&&_w13>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_w13;}
_w4=x;_w5=z;_w6=true;
_w2+=visualSpinStep(ds/(0.28328f*kartTireF(spawnedType)));_w3+=visualSpinStep(ds/(0.28328f*kartTireR(spawnedType)));//tyre radius x body tyre scale
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_w0*0.45f-_w1)*0.25f;
ptr_t b=_w7(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_w8(b+72,sf,cf,sd,cd);_w8(b+168,sf,cf,sd,cd);
_w8(b+264,sr,cr,0,1);_w8(b+360,sr,cr,0,1);
if(isBike(spawnedType))bikeLean(b);
}
const float BIKE_LEAN=0.38f,BIKE_DRIFT_LEAN=0.5f,BIKE_PIVOT_Y=-0.30f;//[chosen]~22 deg turning,~29 deg drifting
float bikeRoll=0;
void bikeLean(ptr_t b){
float sp=abs(mkSpeed)/MK_SPEED;if(sp>1)sp=1;
float _w23=airborne||gliding?0:(driftDir!=0?driftDir*BIKE_DRIFT_LEAN*(0.7f+0.3f*abs(_w0)):_w0*BIKE_LEAN*sp);
bikeRoll+=(_w23-bikeRoll)*0.12f;
float c=cos(bikeRoll),s=sin(bikeRoll);ptr_t r=b-24;
ptr_write_float(r,c);ptr_write_float(r+4,s);ptr_write_float(r+8,0);
ptr_write_float(r+16,-s);ptr_write_float(r+20,c);ptr_write_float(r+24,0);
ptr_write_float(r+32,0);ptr_write_float(r+36,0);ptr_write_float(r+40,1);
ptr_write_float(r+48,s*BIKE_PIVOT_Y);ptr_write_float(r+52,0.3766f+BIKE_PIVOT_Y-c*BIKE_PIVOT_Y);ptr_write_float(r+56,0);
}
void resetHandling(){trickRoll=0;airborne=false;trickDone=false;gliding=false;airFrames=0;groundFrames=0;trickWindow=0;mkSpeed=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;driftDir=0;driftTier=0;boostLeft=0;hopWindow=0;hopHeld=false;gasLatch=true;idleHold=false;}
int groundMat=-1;float groundDist=99;//updated by groundFrame(ray cast under the kart)
float terrainSpeedFactor(){
if(!offroadOn||groundDist>=0.8f)return 1;
int m=groundMat;
if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;//HeavySand,HeavySnow,Bog,Tar,Water,ContaminatedWater
if(m==1||m==2||m==3||m==5)return OFFROAD_LIGHT;//Soil,Grass,Sand,Snow
return 1;
}
float speedStep(float v,float _w10){
if(boostLeft>0){
boostLeft--;float t=MK_SPEED*MT_SPEED;
if(v<t){float inc=(t-v)*MK_BOOST_GAIN;if(inc>MK_BOOST_CAP)inc=MK_BOOST_CAP;return v+inc;}
return t;
}
if(_w10>0){
if(v<0)return v+MK_BRAKE>0?0:v+MK_BRAKE;//stop reversing first
float t=MK_SPEED*_w10*terrainSpeedFactor();
if(v<t){float inc=(t-v)*MK_ACCEL_GAIN;if(inc>MK_ACCEL_CAP)inc=MK_ACCEL_CAP;return v+inc;}//[native]form
float d=v*MK_OVERSPEED;return d<t?t:d;
}
if(_w10<0){
if(v>0)return v-MK_BRAKE<0?0:v-MK_BRAKE;//brake,then reverse
float t=-MK_REVERSE*(-_w10);
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
void _k12(int ix,int iy,uint64 held){
_w0=0;
ActorBase@a=_k7();bool _w20=_k15(a);
if(!_w20&&Player!is null){adoptRiddenKart();@a=_k7();_w20=_k15(a);}
if(_w20!=_k19){sys::debugLog("KART mounted="+_w20);resetHandling();_k19=_w20;_k20=!_w20;if(a!is null){_w14=a.pos_x;_w15=a.pos_z;}}
if(!_w20||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);resetHandling();return;}
float _w25=float(ix)/32768.0f,_w10=0;
if(abs(_w25)<0.15f)_w25=0;
bool gas=(held&uint64(A))!=0,brake=(held&uint64(B))!=0;
if(!gas)gasLatch=false;//the A press used to get in must be released first
if(brake)_w10=-1;else if(gas&&!gasLatch)_w10=1;
_w0=_w25;
Matrix33f r=a.rot;float _w13=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_w13<0.1f||r.a4<0.4f){_k10(a);resetHandling();return;}
float bx=r.a2/_w13,bz=r.a8/_w13,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
camFx=fx;camFz=fz;camBraking=brake&&mkSpeed>0.5f;
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float actualF=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float actualMk=actualF/MS_PER_MK;
if(mkSpeed>0&&mkSpeed>actualMk+0.6f)mkSpeed=actualMk+0.6f<0?0:actualMk+0.6f;
if(mkSpeed<0&&mkSpeed<actualMk-0.6f)mkSpeed=actualMk-0.6f>0?0:actualMk-0.6f;
bool r_held=(held&uint64(R|ZR))!=0,fast=mkSpeed>MK_SPEED*0.35f;
if(fxReady())groundRay(a.pos_x,a.pos_y+0.2f,a.pos_z);
bool overGround=groundDist<AIR_GAP;
if(overGround){groundFrames++;airFrames=0;}else{airFrames++;groundFrames=0;}
bool wasAir=airborne;
bool rPressNow=r_held&&!hopHeld;rPressAge=rPressNow?0:rPressAge+1;
if(!airborne&&airFrames>=2){
airborne=true;trickWindow=TRICK_WINDOW;trickDone=false;sys::debugLog("KART airborne");
if(rPressAge<=6+airFrames){trickDone=true;startTrick(_w25);sndPlay(S_TRICK,CH_SHOT);TextWriter::toast(30,"Trick!\n");sys::debugLog("KART trick (buffered)");}
}
if(airborne&&groundFrames>=1){
airborne=false;
if(gliding){gliding=false;sys::debugLog("KART glider landed");}
if(trickDone){if(boostLeft<TRICK_FRAMES)boostLeft=TRICK_FRAMES;sndPlay(S_MINI,CH_SHOT);sys::debugLog("KART trick boost");}
trickDone=false;sys::debugLog("KART landed");
}
float hop=0;
bool rPress=r_held&&!hopHeld;
if(airborne){
if(trickWindow>0){trickWindow--;if(rPress&&!trickDone){trickDone=true;startTrick(_w25);sndPlay(S_TRICK,CH_SHOT);TextWriter::toast(30,"Trick!\n");sys::debugLog("KART trick");}}
}else if(rPress){hop=HOP_SPEED;hopWindow=24;sndPlay(S_HOP,CH_SHOT);}//MK8 hops at any speed
hopHeld=r_held;
bool yHeld=(held&uint64(Y))!=0;
if(!yHeld)gliderLatch=false;
if(yHeld&&!gliderLatch){
gliderLatch=true;
if(gliding){gliding=false;autoGlideBlocked=true;sys::debugLog("KART glider folded");}
else if(airborne&&groundDist>=GLIDE_MIN_HEIGHT){gliding=true;sndPlay(S_GOPEN,CH_SHOT);driftDir=0;driftCharge=0;driftTier=0;TextWriter::toast(30,"Glider!\n");sys::debugLog("KART glider open");}
}
if(!airborne)autoGlideBlocked=false;
if(autoGlideOn&&airborne&&!gliding&&!autoGlideBlocked&&trickRoll==0&&airFrames>=AUTO_GLIDE_FRAMES&&v.y<-AUTO_GLIDE_FALL&&groundDist>=GLIDE_MIN_HEIGHT){
gliding=true;autoGlideBlocked=true;sndPlay(S_GOPEN,CH_SHOT);driftDir=0;driftCharge=0;driftTier=0;sys::debugLog("KART glider auto");
}
if(driftDir==0&&!airborne&&r_held&&hopWindow>0&&abs(_w25)>0.3f){driftDir=_w25>0?1:-1;driftCharge=0;driftTier=0;sys::debugLog("KART drift start dir="+driftDir);}
if(driftDir!=0&&(!r_held||!fast)){
int _w18=driftTier==3?int(UMT_FRAMES):driftTier==2?int(SMT_FRAMES):driftTier==1?int(MT_FRAMES):0;
if(_w18>0&&r_held==false){boostLeft=_w18;sndPlay(driftTier==3?S_ULTRA:S_MINI,CH_SHOT);sys::debugLog("KART boost tier="+driftTier+" frames="+_w18);}
driftDir=0;driftCharge=0;driftTier=0;
}
if(!airborne&&_w10==0&&boostLeft==0&&driftDir==0&&hop==0&&abs(mkSpeed)<MK_COAST){
mkSpeed=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_w14=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float yaw=0,oldOff=bodyOff;
for(int step=0;step<2;step++){
if(hopWindow>0)hopWindow--;
if(gliding){float t=GLIDE_SPEED*(iy>16000?1.06f:1.0f);mkSpeed+=(t-mkSpeed)*0.02f;}
else if(!airborne||boostLeft>0)mkSpeed=speedStep(mkSpeed,_w10);
float bodyTarget=0;
if(gliding){
driftTrack=0;yaw+=_w25*MK_STEER*GLIDE_STEER;
}else if(driftDir!=0){
float inward=_w25*driftDir;if(inward>1)inward=1;if(inward<-1)inward=-1;
float trackTarget=inward>=0?DRIFT_TRACK:-DRIFT_TRACK,dt=(trackTarget-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float intensity=driftTrack<0?0:driftTrack>1?1:driftTrack;
yaw+=driftDir*MK_DRIFT*intensity*intensity*(0.75f+0.25f*inward);
if(!airborne)driftCharge+=inward>=CHARGE_INWARD?CHARGE_IN:CHARGE_OUT;//[native]exact MK8DX charge rule
int tier=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>CHARGE_MT?1:0;
if(tier>driftTier){driftTier=tier;driftTierToast(tier);}
bodyTarget=driftDir*DRIFT_BODY;
}else{
driftTrack=0;
float speedFactor=abs(mkSpeed)/(MK_SPEED*0.25f);if(speedFactor>1)speedFactor=1;
yaw+=_w25*MK_STEER*speedFactor*(mkSpeed<0?-1.0f:1.0f)*(airborne?AIR_STEER:1.0f);
}
if(trickRoll>0){bodyOff+=6.2832f/float(TRICK_ROLL_FRAMES*2)*float(trickRollDir);}
else{
float gap=bodyTarget-bodyOff,ds=gap*0.07f;
if(abs(ds)<0.001f)ds=abs(gap)<0.001f?gap:(gap>0?0.001f:-0.001f);
bodyOff+=ds;
}
if(!airborne)lateral*=1-GRIP*MK_TRACTION;
else lateral*=gliding?1-GLIDE_SIDE_DRAG:1-AIR_SIDE_DRAG;
}
if(trickRoll>0){trickRoll--;if(trickRoll==0||!airborne){trickRoll=0;while(bodyOff>3.1416f)bodyOff-=6.2832f;while(bodyOff<-3.1416f)bodyOff+=6.2832f;}}
_k18=mkSpeed*MS_PER_MK;
float speedMs=_k18;
float vy=v.y+hop;
if(gliding){
float sink=iy>16000?GLIDE_DIVE:iy<-16000?GLIDE_FLOAT:GLIDE_SINK;//stick forward dives,back floats
vy+=(-sink-vy)*0.3f+GLIDE_GCOMP;//ease into the glide descent(gravity compensated)
}
if(gliding&&vy<-AIR_MAX_FALL)vy=-AIR_MAX_FALL;//glider only(user:free fall must stay normal speed)
b.setVel(fx*speedMs+lx*lateral,vy,fz*speedMs+lz*lateral);
float tx=0,ty=1,tz=0,gain=2.0f;
if(gliding){
float pitch=float(iy)/32768.0f;if(pitch>1)pitch=1;if(pitch<-1)pitch=-1;
float bank=_w25*GLIDE_BANK,nose=pitch*GLIDE_PITCH;//stick right:right side down;stick forward:nose down
tx=-lx*bank+fx*nose;tz=-lz*bank+fz*nose;
float hl2=sqrt(tx*tx+tz*tz);if(hl2>GLIDE_MAX_LEAN){tx*=GLIDE_MAX_LEAN/hl2;tz*=GLIDE_MAX_LEAN/hl2;}
ty=1;float tl=sqrt(tx*tx+ty*ty+tz*tz);tx/=tl;ty/=tl;tz/=tl;gain=GLIDE_TILT_GAIN;
}
float ux=r.a1,uy=r.a4,uz=r.a7;
float wx=(uy*tz-uz*ty)*gain,wz=(ux*ty-uy*tx)*gain;//world axes(a body-axis version flipped the kart)
b.setAngularVel(wx,-(yaw+bodyOff-oldOff)*30.0f,wz);
}
const uint FX_ROOT=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float SPARK_SCALE=0.35f,FLAME_SCALE=0.15f;//[chosen]from screenshots
ptr_t fxM=0,fxSys=0,fxScr=0;int fxSpark=-2,fxFlame=-1;
bool fxNameIs(ptr_t p,const string&in name){
uint n=name.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=name[i])return false;
return ptr_deref_u8(p+n)==0;
}
int fxFind(const string&in name){
ptr_t res=ptr_deref_u64(ptr_deref_u64(fxSys+0x2ee8)+8);if(res==0||ptr_deref_u8(res+0x571)==0)return-1;//static effects=resource 1
int n=ptr_deref_s32(res+0x558);ptr_t sets=ptr_deref_u64(res+0x430);
for(int i=0;i<n;i++)if(fxNameIs(ptr_deref_u64(sets+0x28*i)+0x10,name))return i;
return-1;
}
bool fxReady(){
if(fxSpark>=0)return true;
if(fxSpark==-1)return false;//looked once and failed:stay off
fxSpark=-1;
ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(hook==0)return false;
uint op=ptr_deref_u32(hook);int64 _w28=int64(op&0x03ffffff);if((op&0x02000000)!=0)_w28-=0x04000000;
ptr_t _w23=ptr_t(int64(hook)+_w28*4),base=_w23-0x65b80;
if((base&0xfff)!=0||ptr_deref_u32(_w23)!=0xf0001382)return false;
fxScr=base+FX_SCRATCH;fxM=sys::mainOffset();
ptr_t inst=ptr_deref_u64(ptr_deref_u64(fxM+FX_ROOT));if(inst==0)return false;
fxSys=ptr_deref_u64(inst+0x11b8);if(fxSys==0)return false;
int spark=fxFind("Ply_ShockWave_Spark");fxFlame=fxFind("Chm_FlameThrower_ScraBuild");//Zonai flame emitter jet
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
void fxPlace(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
ptr_write_float(m,r.a0);ptr_write_float(m+4,r.a1);ptr_write_float(m+8,r.a2);ptr_write_float(m+12,px);
ptr_write_float(m+16,r.a3);ptr_write_float(m+20,r.a4);ptr_write_float(m+24,r.a5);ptr_write_float(m+28,py);
ptr_write_float(m+32,r.a6);ptr_write_float(m+36,r.a7);ptr_write_float(m+40,r.a8);ptr_write_float(m+44,pz);
ptr_write_float(fxScr+0x140,s);ptr_write_float(fxScr+0x144,s);ptr_write_float(fxScr+0x148,s);
ptr_call(fxM+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
void fxTint(ptr_t e,float r,float g,float b){ptr_write_float(e+0x40,r);ptr_write_float(e+0x44,g);ptr_write_float(e+0x48,b);}
void sparkFrame(ActorBase@a){
bool sparks=a!is null&&_k19&&driftDir!=0&&driftTier>0;
bool flame=a!is null&&_k19&&boostLeft>0;
if(!sparks&&!flame&&fxScr==0)return;
if(!fxReady()){return;}
if(!sparks)fxStop(0);
if(!flame||fxFlame<0)fxStop(1);
if(sparks){
ptr_t e=fxStart(0,fxSpark);
if(e!=0){
if(driftTier==1)fxTint(e,0.25f,0.8f,6.0f);else if(driftTier==2)fxTint(e,1.0f,1.0f,1.0f);else fxTint(e,2.2f,0.4f,6.0f);
ptr_t b=_w7(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(ptr_deref_float(b+312));wy=ptr_deref_float(b+28)+ptr_deref_float(b+316)-0.3683f;wz=ptr_deref_float(b+32)+ptr_deref_float(b+320);}
fxPlace(e,a,wx,wy,wz,SPARK_SCALE);fxPlace(e,a,-wx,wy,wz,SPARK_SCALE);
}
}
if(flame&&fxFlame>=0){ptr_t e=fxStart(1,fxFlame);if(e!=0){fxPlace(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);fxPlace(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
const uint FX_RAY_EVAL=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int groundSlot=-1,groundTick=0;
int gid0=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;//effect ids per class,looked up once(no arrays in this runtime)
bool groundRay(float x,float y,float z){
ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,ptr_from_ActorBase(Player));
ptr_write_u64(q,fxM+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);//flags:all false
ptr_write_float(v+4,2.0f);ptr_write_u64(q+0x38,v+4);//ray _w13(m)
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
ptr_write_float(v+0x50,x);ptr_write_float(v+0x54,y);ptr_write_float(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(fxM+FX_RAY_EVAL,q,0,0,0,0,0,0,0,0,0,0);
if(ptr_deref_u8(v+0x10)==0){groundMat=-1;groundDist=99;return false;}
groundMat=ptr_deref_s32(v+0x40);groundDist=ptr_deref_float(v+0x14);return true;
}
int groundClass(int m){
if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return-1;return 6;
}
string groundEffectTest="";//diagnostics only:overrides the grass effect name
string groundEffect(int c){
if(c==0&&groundEffectTest!="")return groundEffectTest;
if(c==0)return"ReFX_Grass_L";if(c==1||c==2)return"ReFX_Sand_L";if(c==3)return"ReFX_Snow_L";
if(c==4)return"Water_Splash01_Move";if(c==5)return"RctFld_Mud_Splash_S";return"Ply_SlipSmoke_Stone";
}
int groundId(int c){
if(c==0){if(gid0==-2)gid0=fxFind(groundEffect(0));return gid0;}if(c==1){if(gid1==-2)gid1=fxFind(groundEffect(1));return gid1;}
if(c==2){if(gid2==-2)gid2=fxFind(groundEffect(2));return gid2;}if(c==3){if(gid3==-2)gid3=fxFind(groundEffect(3));return gid3;}
if(c==4){if(gid4==-2)gid4=fxFind(groundEffect(4));return gid4;}if(c==5){if(gid5==-2)gid5=fxFind(groundEffect(5));return gid5;}
if(gid6==-2)gid6=fxFind(groundEffect(6));return gid6;
}
const float GROUND_SCALE=1.2f,GROUND_MIN_SPEED=3.0f;//[chosen]
const int GROUND_BURST=6;//[chosen]_w18 between bursts:TOTK's ground effects are one-shot(per footstep/hoof)
int groundBurstTick=0,groundBurstSlot=0;
void groundStopAll(){if(fxScr==0)return;for(int k=3;k<7;k++)fxStop(k);}
ptr_t fxStartShared(int slot,int id,ptr_t queue){
ptr_t h=fxScr+0x10*slot;fxStop(slot);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(fxM+FX_CREATE,fxSys,h,id,1,0,queue,0,0,0,0,0);
return fxLive(slot);
}
void groundFrame(ActorBase@a){
bool active=a!is null&&_k19&&fxReady();
if(!active){groundStopAll();groundSlot=-1;return;}
int c=groundDist<0.8f?groundClass(groundMat):-1;
bool offroad=c>=0&&c<6,show=c>=0&&abs(_k18)>GROUND_MIN_SPEED&&(offroad||driftDir!=0);
groundSlot=show?c:-1;
if(!show){groundBurstTick=0;return;}
if(groundBurstTick-->0)return;
groundBurstTick=GROUND_BURST;
int id=groundId(c);if(id<0)return;
int slot=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
ptr_t e=fxStartShared(slot,id,fxScr+0x5000);if(e==0)return;
float wx=0.78f,wz=-0.75f;ptr_t b=_w7(a);if(b!=0){wx=abs(ptr_deref_float(b+312));wz=ptr_deref_float(b+32)+ptr_deref_float(b+320);}
fxPlace(e,a,wx,0,wz,GROUND_SCALE);fxPlace(e,a,-wx,0,wz,GROUND_SCALE);
}
const float GLIDER_Y=-0.15f,GLIDER_Z=-0.45f,GLIDER_STORE=1000.0f;//mesh stored 1/1000 size(scripts/build_glider.py)//[chosen]attach point in kart space(glider frame base)
float gliderScale=0;bool gliderWritten=false;
ptr_t hostModelAt=0,hostSklAt=0;
ptr_t hostBones(ActorBase@a){
ptr_t list=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!_k2(list))return 0;
ptr_t mc=ptr_deref_u64(list+0x10);if(!_k2(mc))return 0;
ptr_t m=ptr_deref_u64(mc+0x28);if(!_k2(m))return 0;
if(m==hostModelAt&&hostSklAt!=0)return hostSklAt;
hostModelAt=m;hostSklAt=0;gliderWritten=false;//new kart(model instances are pooled:a reused one can keep an open glider)
for(uint o=0;o<0x4000;o+=4){
ptr_t r=m+o;
if(abs(ptr_deref_float(r+52)-0.3766f)<0.003f&&abs(ptr_deref_float(r+48))<0.003f&&abs(ptr_deref_float(r+56))<0.003f
&&abs(ptr_deref_float(r+96+52)-0.5966f)<0.003f&&abs(ptr_deref_float(r+96+56)-0.4928f)<0.003f){hostSklAt=r;sys::debugLog("KART host Skl_Root record at +"+o);break;}
}
return hostSklAt;
}
void gripTarget(ptr_t rec,ptr_t j,float px,float py,float pz){
float dx=px-ptr_deref_float(j+48),dy=py-ptr_deref_float(j+52),dz=pz-ptr_deref_float(j+56);
for(uint c=0;c<3;c++)ptr_write_float(rec+48+4*c,ptr_deref_float(j+16*c)*dx+ptr_deref_float(j+16*c+4)*dy+ptr_deref_float(j+16*c+8)*dz);
}
void handTargets(ActorBase@a){
if(a is null)return;ptr_t skl=hostBones(a);if(skl==0)return;
if(!isBike(spawnedType)){
ptr_write_float(skl+192+48,0);ptr_write_float(skl+192+52,-0.0001f);ptr_write_float(skl+192+56,-0.2107f);
ptr_write_float(skl+288+48,0);ptr_write_float(skl+288+52,-0.0001f);ptr_write_float(skl+288+56,0.2107f);
return;
}
float ax=0,ay=0.906f,az=-0.423f,c=cos(_w1),s=sin(_w1);
for(int side=-1;side<=1;side+=2){
float vx=0.62f*side,vy=0.96f-0.645f,vz=0.43f-0.752f,d=ax*vx+ay*vy+az*vz;
float cx=ay*vz-az*vy,cy=az*vx-ax*vz,cz=ax*vy-ay*vx;
float rx=vx*c+cx*s+ax*d*(1-c),ry=vy*c+cy*s+ay*d*(1-c),rz=vz*c+cz*s+az*d*(1-c);
float gx=rx,gy=0.645f+ry,lc=cos(bikeRoll),ls=sin(bikeRoll);
float lx=lc*gx-ls*gy+ls*BIKE_PIVOT_Y,ly=ls*gx+lc*gy+BIKE_PIVOT_Y-lc*BIKE_PIVOT_Y;
gripTarget(side>0?skl+192:skl+288,skl+96,lx,ly,0.752f+rz);//+X is Link's left:Handle_L
}
}
void gliderFrame(ActorBase@a){
float _w23=(a!is null&&_k19&&gliding)?1:0;
if(_w23==0&&gliderScale==0&&gliderWritten)return;
if(a is null)return;
ptr_t skl=hostBones(a);if(skl==0)return;
if(gliderScale<_w23){gliderScale+=0.17f;if(gliderScale>_w23)gliderScale=_w23;}
else if(gliderScale>_w23){gliderScale-=0.2f;if(gliderScale<_w23)gliderScale=_w23;}
ptr_t r=skl-192;float sc=gliderScale*GLIDER_STORE;//Control=bone 1,two records before Skl_Root(bone 3)
ptr_write_float(r,sc);ptr_write_float(r+4,0);ptr_write_float(r+8,0);
ptr_write_float(r+16,0);ptr_write_float(r+20,sc);ptr_write_float(r+24,0);
ptr_write_float(r+32,0);ptr_write_float(r+36,0);ptr_write_float(r+40,sc);
ptr_write_float(r+48,0);ptr_write_float(r+52,GLIDER_Y);ptr_write_float(r+56,GLIDER_Z);
gliderWritten=true;
}
const uint FOOTIK_SET=0x1085b5c;
bool footIkOff=false;
bool gptr(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t playerPhysics(){
if(Player is null)return 0;ptr_t p=ptr_deref_u64(ptr_from_ActorBase(Player)+0x228);if(!gptr(p))return 0;
p=ptr_deref_u64(p+0x50);if(!gptr(p))return 0;p=ptr_deref_u64(p+0x20);return gptr(p)?p:0;
}
void footIkFrame(){
if(!_k19&&!footIkOff)return;
ptr_t phys=playerPhysics();if(phys==0)return;
ptr_call(sys::mainOffset()+FOOTIK_SET,phys,_k19?0:1,0,0,0,0,0,0,0,0,0);
footIkOff=_k19;
}
const uint SND_PLAY=0x809ee0,SND_FADE=0xb226a4,PROP_SET=0x11acb98;
const int CH_ENGINE=0,CH_SIZZLE=1,CH_DRIFT=2,CH_RUN=3,CH_SLIP=4,CH_FLUTTER=5,CH_SHOT=6;
const float SND_ROT_PER_MS=1.0f/14.0f;//[chosen]top speed(14 m/s)=1=top of curve 213
const int S_ENGINE=1,S_DASH=2,S_IDLE=3,S_SIZZLE=4,S_DRIFT=7,S_FLUTTER=8,S_RUN=10,S_SLIP=20,S_LANDS=30;
const int S_MINI=40,S_ULTRA=41,S_HOP=42,S_LAND=43,S_TRICK=44,S_GOPEN=45,S_GCLOSE=46,S_HORN=47;
int sndLogs=0;int chKey0=0,chKey1=0,chKey2=0,chKey3=0,chKey4=0,chKey5=0;
string surfaceName(int s){return s==0?"Grass":s==1?"Dirt":s==2?"Sand":s==3?"Snow":s==4?"Water":s==5?"Stone":"Wood";}
string keyName(int id){
if(id==S_ENGINE)return"Kart_Engine";if(id==S_DASH)return"Kart_EngineDash";if(id==S_IDLE)return"Kart_Idle";
if(id>=S_SIZZLE&&id<S_SIZZLE+3)return"Kart_Sizzle"+(id-S_SIZZLE+1);if(id==S_DRIFT)return"Kart_DriftSteer";
if(id==S_FLUTTER)return"Kart_GliderFlutter";if(id>=S_RUN&&id<S_RUN+7)return"Kart_Run_"+surfaceName(id-S_RUN);
if(id>=S_SLIP&&id<S_SLIP+7)return"Kart_Slip_"+surfaceName(id-S_SLIP);if(id>=S_LANDS&&id<S_LANDS+7)return"Kart_Land_"+surfaceName(id-S_LANDS);
if(id==S_MINI)return"Kart_MiniTurbo";if(id==S_ULTRA)return"Kart_UltraTurbo";if(id==S_HOP)return"Kart_Hop";if(id==S_LAND)return"Kart_Land";
if(id==S_TRICK)return"Kart_Trick";if(id==S_HORN)return"Kart_Horn";if(id==S_GOPEN)return"Kart_GliderOpen";if(id==S_GCLOSE)return"Kart_GliderClose";return"";
}
ptr_t sndX=0;int sndProp=-1;bool sndXTried=false;
ptr_t sndUser(){
ActorBase@a=_k7();if(a is null||!fxReady())return 0;
ptr_t x=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!gptr(x))return 0;
x=ptr_deref_u64(x+0x68);if(!gptr(x))return 0;
ptr_t u=ptr_deref_u64(x+0x78);return gptr(u)?u:0;
}
void sndPlay(int id,int ch){
ptr_t u=sndUser();if(u==0||id<=0)return;string key=keyName(id);
ptr_t k=fxScr+0x7800,h=fxScr+0x7880+8*ch;uint n=key.length();
for(uint w=0;w<4;w++){uint64 v=0;for(uint i=0;i<8;i++){uint c=w*8+i;if(c<n)v|=uint64(key[c])<<(8*i);}ptr_write_u64(k+8*w,v);}
ptr_write_u64(h,0xffff00ff);
ptr_call(fxM+SND_PLAY,u,k,h,0,0,0,0,0,0,0,0);
if(sndLogs<80){sndLogs++;sys::debugLog("KART snd "+key+" h="+ptr_deref_u64(h));}
}
void sndFade(int ch){if(fxScr==0)return;ptr_t h=fxScr+0x7880+8*ch;if(ptr_deref_u64(h)!=0xffff00ff)ptr_call(fxM+SND_FADE,h,0xffffffff,0,0,0,0,0,0,0,0,0);ptr_write_u64(h,0xffff00ff);}
int chKey(int ch){return ch==0?chKey0:ch==1?chKey1:ch==2?chKey2:ch==3?chKey3:ch==4?chKey4:chKey5;}
void chSetKey(int ch,int k){if(ch==0)chKey0=k;else if(ch==1)chKey1=k;else if(ch==2)chKey2=k;else if(ch==3)chKey3=k;else if(ch==4)chKey4=k;else chKey5=k;}
void sndLoop(int ch,int key){
if(chKey(ch)==key)return;
if(chKey(ch)!=0)sndFade(ch);
if(key!=0)sndPlay(key,ch);
chSetKey(ch,key);
}
bool propNames(ptr_t x){
if(!gptr(x))return false;uint n=ptr_deref_u32(x+0x110);if(n==0||n>16)return false;
ptr_t names=ptr_deref_u64(x+0x118);if(!gptr(names))return false;
for(uint i=0;i<n;i++){ptr_t s=ptr_deref_u64(names+8*i);if(gptr(s)&&fxNameIs(s,"ControlStick_StickSpeedXY")){sndProp=int(i);return true;}}
return false;
}
void sndFindX(){
sndXTried=true;sndX=0;sndProp=-1;
ActorBase@a=_k7();if(a is null)return;
ptr_t p=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!gptr(p))return;
p=ptr_deref_u64(p);if(!gptr(p))return;
p=ptr_deref_u64(p+0x10);if(!gptr(p))return;
if(propNames(p))sndX=p;
sys::debugLog("KART snd prop X="+(sndX!=0)+" idx="+sndProp+" n="+ptr_deref_u32(p+0x110));
}
void sndSpeed(float ms){
if(sndX==0||sndProp<0)return;
ptr_t f=fxScr+0x7a00;
ptr_write_float(f,abs(ms)*SND_ROT_PER_MS);
ptr_call(fxM+PROP_SET,sndX,sndProp,f,0,0,0,0,0,0,0,0);
}
int lastMatName=-2,lastSurface=-1;
bool matNameHas(int m,const string&in w){
ptr_t t=ptr_deref_u64(fxM+0x4637298);if(t==0||m<0||m>=54)return false;ptr_t s=ptr_deref_u64(t+0x250+8*m);if(!gptr(s))return false;
uint n=w.length();for(uint i=0;i<28;i++){if(ptr_deref_u8(s+i)==0)return false;bool ok=true;for(uint k=0;k<n&&ok;k++)if(ptr_deref_u8(s+i+k)!=w[k])ok=false;if(ok)return true;}
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
if(!_k19){
if(chKey0!=0||chKey1!=0||chKey2!=0||chKey3!=0||chKey4!=0||chKey5!=0){for(int c=0;c<6;c++)sndLoop(c,0);}
sndXTried=false;sndWasAir=false;sndWasGlide=false;return;
}
if(!sndXTried)sndFindX();
float sp=abs(_k18);sndSpeed(sp);
sndLoop(CH_ENGINE,gliding?0:boostLeft>0?S_DASH:sp<0.6f?S_IDLE:S_ENGINE);
sndLoop(CH_SIZZLE,(driftDir!=0&&driftTier>0&&!gliding)?S_SIZZLE+driftTier-1:0);
int surf=(airborne||gliding)?-1:surfaceSound();
sndLoop(CH_DRIFT,(driftDir!=0&&!airborne&&!gliding)?S_DRIFT:0);
sndLoop(CH_RUN,(surf>=0&&sp>1.0f&&driftDir==0)?S_RUN+surf:0);
sndLoop(CH_SLIP,(surf>=0&&driftDir!=0)?S_SLIP+surf:0);
sndLoop(CH_FLUTTER,gliding?S_FLUTTER:0);
if(sndWasGlide&&!gliding)sndPlay(S_GCLOSE,CH_SHOT);
if(sndWasAir&&!airborne){sndPlay(S_LAND,CH_SHOT);int s2=surfaceSound();if(s2>=0)sndPlay(S_LANDS+s2,CH_SHOT+1);}
sndWasAir=airborne;sndWasGlide=gliding;
}
const bool MKCAM_DEFAULT=true;
const float CAM_DIST=6.2f,CAM_HEIGHT=2.4f,CAM_LOOK_AHEAD=1.6f,CAM_LOOK_UP=1.2f,CAM_DRIFT_SWING=0.16f;
const float CAM_MAX_LAG=3.0f,CAM_LEAD=0.07f;//[chosen]seconds of fall to lead
const float CAM_GLIDE_DIST=7.6f,CAM_GLIDE_HEIGHT=4.4f,CAM_BOOST_BACK=0.8f,CAM_KICK=0.7f,CAM_BRAKE_IN=0.5f;
bool mkCamOn=MKCAM_DEFAULT,mkCamChordLatched=true,camFrozen=false,camInit=false,camBraking=false;
float camFx=0,camFz=1,camHx=0,camHz=1,camDist=CAM_DIST,camH=CAM_HEIGHT,camY=0,camKick=0,camLook=0;int camLastBoost=0;
void camRelease(){if(camFrozen){camera::toggleFreeze();camFrozen=false;}camInit=false;}
void cameraFrame(ActorBase@a,int rx,int ry){
if(!mkCamOn||a is null||!_k19){camRelease();return;}
float sp=abs(_k18);
if(boostLeft>camLastBoost+5)camKick=1;camLastBoost=boostLeft;camKick*=0.88f;
float tx=camFx,tz=camFz;
if(driftDir!=0){float c=cos(-driftDir*CAM_DRIFT_SWING),s2=sin(-driftDir*CAM_DRIFT_SWING);float nx=tx*c+tz*s2,nz=-tx*s2+tz*c;tx=nx;tz=nz;}
if(!camInit){camHx=tx;camHz=tz;camY=a.pos_y;camDist=CAM_DIST;camH=CAM_HEIGHT;}
float rate=gliding?0.06f:airborne?0.05f:0.13f;
camHx+=(tx-camHx)*rate;camHz+=(tz-camHz)*rate;float hl=sqrt(camHx*camHx+camHz*camHz);if(hl<0.01f){camHx=tx;camHz=tz;hl=1;}camHx/=hl;camHz/=hl;
float look=float(rx)/32768.0f;if(abs(look)<0.2f)look=0;float lookT=look*1.8f;
if(float(ry)/32768.0f<-0.7f)lookT=3.1416f;//right stick down:look behind(MK8 look-back)
camLook+=(lookT-camLook)*(lookT>3.0f?0.35f:0.15f);
float lc=cos(camLook),ls=sin(camLook),dx=camHx*lc+camHz*ls,dz=-camHx*ls+camHz*lc;
float dist=gliding?CAM_GLIDE_DIST:CAM_DIST+sp*0.035f+(boostLeft>0?CAM_BOOST_BACK:0)-(camBraking?CAM_BRAKE_IN:0);
dist+=camKick*CAM_KICK;
float h=gliding?CAM_GLIDE_HEIGHT:CAM_HEIGHT+sp*0.01f;
camDist+=(dist-camDist)*(camKick>0.5f?0.3f:0.1f);camH+=(h-camH)*0.08f;
float ky=a.pos_y;if(airborne){RigidBody@cb=a.getMainRigidBody();if(cb!is null)ky+=cb.vel.y*CAM_LEAD;}
camY+=(ky-camY)*((airborne||gliding)?0.12f:0.35f);
if(camY-ky>CAM_MAX_LAG)camY=ky+CAM_MAX_LAG;if(ky-camY>CAM_MAX_LAG)camY=ky-CAM_MAX_LAG;
double px=a.pos_x-dx*camDist,py=camY+camH,pz=a.pos_z-dz*camDist;
double ax=a.pos_x+dx*CAM_LOOK_AHEAD,ay=ky+(gliding?0.4f:CAM_LOOK_UP),az=a.pos_z+dz*CAM_LOOK_AHEAD;
camera::freeze(0,1,0,px,py,pz,ax,ay,az);camFrozen=true;camInit=true;
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
sys::debugLog("KART ready");
}
bool hornLatch=false;
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool overrideActive=false,exitLatch=false;uint64 outButtons=0;int outLX=0,outLY=0,outRX=0,outRY=0;
bool simActive=false;uint64 simHeld=0;int simLX=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t pad){
uint64 held=simActive?simHeld:ptr_deref_u64(pad);
int lx=simActive?simLX:ptr_deref_s32(pad+8),ly=simActive?simLY:ptr_deref_s32(pad+12);
int rx=simActive?simRX:ptr_deref_s32(pad+16),ry=simActive?simRY:ptr_deref_s32(pad+20);
overrideActive=false;outButtons=held;outLX=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
camRelease();
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;
if(devChords){
uint64 mask=uint64(ZL|ZR|DUP);
if((held&mask)==0)_k24=false;
if(!_k24&&(held&mask)==mask){_k24=true;_k25=true;sys::debugLog("KART spawn queued");}
uint64 kartMask=uint64(ZL|ZR|X);
if((held&kartMask)==0)kartChordLatched=false;
if(!_k19&&!kartChordLatched&&(held&kartMask)==kartMask){
kartChordLatched=true;kartType=(kartType+1)%KART_TYPES;sys::debugLog("KART type="+kartType);
TextWriter::toast(120,"Kart: "+kartName(kartType)+" (ZL+ZR+Up to spawn, ZL+ZR+Y for a capsule)\n");
}
uint64 capMask=uint64(ZL|ZR|Y);
if((held&capMask)==0)capChordLatched=false;
if(!_k19&&!capChordLatched&&(held&capMask)==capMask&&Player!is null){
capChordLatched=true;Matrix33f r=Player.rot;
actor::createSimple(kartCapsule(kartType),Player.pos_x+1.5f*r.a2,Player.pos_y+0.8f,Player.pos_z+1.5f*r.a8);
sys::debugLog("KART capsule "+kartType);TextWriter::toast(90,kartName(kartType)+" capsule\n");
}
}
uint64 camMask=uint64(ZL|ZR|DLEFT);
if((held&camMask)==0)mkCamChordLatched=false;
if(!mkCamChordLatched&&(held&camMask)==camMask){
mkCamChordLatched=true;mkCamOn=!mkCamOn;sys::debugLog("KART mkcam="+mkCamOn);
TextWriter::toast(90,mkCamOn?"Mario Kart camera: ON\n":"Mario Kart camera: OFF\n");
}
uint64 agMask=uint64(ZL|ZR|DRIGHT);
if((held&agMask)==0)autoGlideChordLatched=false;
if(!autoGlideChordLatched&&(held&agMask)==agMask){
autoGlideChordLatched=true;autoGlideOn=!autoGlideOn;sys::debugLog("KART autoglide="+autoGlideOn);
TextWriter::toast(90,autoGlideOn?"Auto glider: ON\n":"Auto glider: OFF\n");
}
uint64 offMask=uint64(ZL|ZR|DDOWN);
if((held&offMask)==0)offroadChordLatched=false;
if(!offroadChordLatched&&(held&offMask)==offMask){
offroadChordLatched=true;offroadOn=!offroadOn;sys::debugLog("KART offroad="+offroadOn);
TextWriter::toast(90,offroadOn?"Off-road handling: ON\n":"Off-road handling: OFF\n");
}
if(!_k3()||menuOpen()){camRelease();return;}
if(_k25&&(held&uint64(ZL|ZR|DUP))!=uint64(ZL|ZR|DUP)){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,held);
_w9(_k7());
sparkFrame(_k7());
gliderFrame(_k7());handTargets(_k7());
footIkFrame();
groundFrame(_k7());
soundFrame();
cameraFrame(_k7(),rx,ry);
uint64 driving=uint64(A|B|X|Y|R|ZR|L);
if(_k19&&(held&uint64(L))!=0&&!hornLatch){hornLatch=true;sndPlay(S_HORN,CH_SHOT);}//L:horn(MK8:item button with no item)
if((held&uint64(L))==0)hornLatch=false;
if(_k19){
overrideActive=true;outButtons=held&~driving;
if(airborne||gliding){outLX=0;outLY=0;}//in the air the vanilla stick tilts the contraption;on the ground the game
if((held&uint64(X))!=0){outButtons|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((held&uint64(X))==0)exitLatch=false;
else{overrideActive=true;outButtons=held&~uint64(X);}//do not let the held X make Link jump
}
}
void yieldFrame(){
if(overrideActive)input(1,outButtons,outLX,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t pad){while(true){_k5(pad);yieldFrame();}}
void main(){
_k14();ptr_t pad=_k6();if(pad==0){TextWriter::toast(300,"KartLab: runtime input signature mismatch.\n");return;}
TextWriter::toast(300,"KartLab: kart chests are just outside Lookout Landing (east). Place karts from Zonai Devices. A gas, B brake, R drift, X exit.\n");
_k11(pad);
}
