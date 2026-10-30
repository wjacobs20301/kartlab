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
const float HOP_SPEED=3.0f;//[chosen]drift hop,m/s upward
float mkSpeed=0,driftCharge=0,bodyOff=0,driftTrack=0;int driftDir=0,driftTier=0,boostLeft=0,hopWindow=0;bool hopHeld=false,gasLatch=true,idleHold=false;
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
void _k13(){ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;resetHandling();_k19=false;_k20=false;_w14=0;_w15=0;_w6=false;}
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
void _k8(){
if(!_k3())return;
ActorBase@old=_k7();
if(_k15(old)){TextWriter::toast(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_w13=sqrt(fx*fx+fz*fz);if(_w13<0.1f)return;fx/=_w13;fz/=_w13;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(old!is null){_k10(old);old.setPos(x,y,z);@old=null;_w14=0;_w15=0;_w6=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=ptr_from_ActorBase(a);_k17=ptr_deref_u32(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_w14=a.pos_x;_w15=a.pos_z;
TextWriter::toast(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
sys::debugLog("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
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
if(abs(ptr_deref_float(b+28)-0.3766f)>0.002f||abs(ptr_deref_float(b+120)-0.728f)>0.002f||abs(ptr_deref_float(b+216)+0.728f)>0.002f||abs(ptr_deref_float(b+312)-0.7776f)>0.002f||abs(ptr_deref_float(b+408)+0.7776f)>0.002f)return 0;
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
_w2+=visualSpinStep(ds/0.28328f);_w3+=visualSpinStep(ds/0.3683f);
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_w0*0.45f-_w1)*0.25f;
ptr_t b=_w7(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_w8(b+72,sf,cf,sd,cd);_w8(b+168,sf,cf,sd,cd);
_w8(b+264,sr,cr,0,1);_w8(b+360,sr,cr,0,1);
}
void resetHandling(){mkSpeed=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;driftDir=0;driftTier=0;boostLeft=0;hopWindow=0;hopHeld=false;gasLatch=true;idleHold=false;}
float speedStep(float v,float _w10){
if(boostLeft>0){
boostLeft--;float t=MK_SPEED*MT_SPEED;
if(v<t){float inc=(t-v)*MK_BOOST_GAIN;if(inc>MK_BOOST_CAP)inc=MK_BOOST_CAP;return v+inc;}
return t;
}
if(_w10>0){
if(v<0)return v+MK_BRAKE>0?0:v+MK_BRAKE;//stop reversing first
float t=MK_SPEED*_w10;
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
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float actualF=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float actualMk=actualF/MS_PER_MK;
if(mkSpeed>0&&mkSpeed>actualMk+0.6f)mkSpeed=actualMk+0.6f<0?0:actualMk+0.6f;
if(mkSpeed<0&&mkSpeed<actualMk-0.6f)mkSpeed=actualMk-0.6f>0?0:actualMk-0.6f;
bool r_held=(held&uint64(R|ZR))!=0,fast=mkSpeed>MK_SPEED*0.35f;
float hop=0;
if(r_held&&!hopHeld&&fast){hop=HOP_SPEED;hopWindow=24;}
hopHeld=r_held;
if(driftDir==0&&r_held&&hopWindow>0&&abs(_w25)>0.3f){driftDir=_w25>0?1:-1;driftCharge=0;driftTier=0;sys::debugLog("KART drift start dir="+driftDir);}
if(driftDir!=0&&(!r_held||!fast)){
int _w18=driftTier==3?int(UMT_FRAMES):driftTier==2?int(SMT_FRAMES):driftTier==1?int(MT_FRAMES):0;
if(_w18>0&&r_held==false){boostLeft=_w18;sys::debugLog("KART boost tier="+driftTier+" frames="+_w18);}
driftDir=0;driftCharge=0;driftTier=0;
}
if(_w10==0&&boostLeft==0&&driftDir==0&&hop==0&&abs(mkSpeed)<MK_COAST){
mkSpeed=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_w14=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float yaw=0,oldOff=bodyOff;
for(int step=0;step<2;step++){
if(hopWindow>0)hopWindow--;
mkSpeed=speedStep(mkSpeed,_w10);
float bodyTarget=0;
if(driftDir!=0){
float inward=_w25*driftDir;if(inward>1)inward=1;if(inward<-1)inward=-1;
float trackTarget=inward>=0?DRIFT_TRACK:-DRIFT_TRACK,dt=(trackTarget-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float intensity=driftTrack<0?0:driftTrack>1?1:driftTrack;
yaw+=driftDir*MK_DRIFT*intensity*intensity*(0.75f+0.25f*inward);
driftCharge+=inward>=CHARGE_INWARD?CHARGE_IN:CHARGE_OUT;//[native]exact MK8DX charge rule
int tier=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>CHARGE_MT?1:0;
if(tier>driftTier){driftTier=tier;driftTierToast(tier);}
bodyTarget=driftDir*DRIFT_BODY;
}else{
driftTrack=0;
float speedFactor=abs(mkSpeed)/(MK_SPEED*0.25f);if(speedFactor>1)speedFactor=1;
yaw+=_w25*MK_STEER*speedFactor*(mkSpeed<0?-1.0f:1.0f);
}
float gap=bodyTarget-bodyOff,ds=gap*0.07f;
if(abs(ds)<0.001f)ds=abs(gap)<0.001f?gap:(gap>0?0.001f:-0.001f);
bodyOff+=ds;
lateral*=1-GRIP*MK_TRACTION;
}
_k18=mkSpeed*MS_PER_MK;
float speedMs=_k18;
b.setVel(fx*speedMs+lx*lateral,v.y+hop,fz*speedMs+lz*lateral);
b.setAngularVel(-r.a7*2.0f,-(yaw+bodyOff-oldOff)*30.0f,r.a1*2.0f);
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
sys::debugLog("KART ready");
}
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
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 mask=uint64(ZL|ZR|DUP);
if((held&mask)==0)_k24=false;
if(!_k24&&(held&mask)==mask){_k24=true;_k25=true;sys::debugLog("KART spawn queued");}
if(!_k3())return;
if(_k25&&(held&mask)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,held);
_w9(_k7());
uint64 driving=uint64(A|B|X|R|ZR);
if(_k19){
overrideActive=true;outButtons=held&~driving;
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
TextWriter::toast(300,"KartLab: ZL+ZR+Up spawns a kart. A to get in. A gas, B brake, R drift, X exit.\n");
_k11(pad);
}
