float _pf(ptr_t p){return ptr_deref_float(p);}
uint64 _pq(ptr_t p){return ptr_deref_u64(p);}
u32 _pu(ptr_t p){return ptr_deref_u32(p);}
int _ps(ptr_t p){return ptr_deref_s32(p);}
void _pw(ptr_t p,float v){ptr_write_float(p,v);}
ptr_t _pa(ActorBase@a){return ptr_from_ActorBase(a);}
void _L(const string&in s){sys::debugLog(s);}
void _T(u32 t,const string&in s){TextWriter::toast(t,s);}
ptr_t _k16=0;
uint _k17=0xffffffff;
float _k18=0;
bool _k19=false;
bool _k20=false;float _d119=0,_w15=0;
float _d150=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d90=false;
const float _d24=7.775f;//[table]PRSL ground top speed,0 coins
const float _d16=0.011f;//[table]PRAC strength(G)
const float _d15=0.09f;//[table]PRAC limiter(M)
const float _d25=0.0118f;//[table]PRTL _d149,rad per MK frame
const float _d21=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d19=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d26=0.75f;//[table]PRON road traction
const float _d29=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d28=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d57)
const uint _d35=153;//[chosen]ultra _d102(not in the table):SMT+(SMT-MT)
const float _d2=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d27=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d23=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d18=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d20=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d22=0.993f;//[chosen]decay above _d152(after a boost)
const float _d17=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d11=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d3=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d151 0.001
const float _d4=0.8f;//[native]drift _d149 _d148 _w12,approached at 10%/frame,_d151<=0.07
const float _d1=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d101>=0.71 else 2
const float _d14=3.0f;//[chosen]drift _d93,m/s upward
const float _d0=0.3f,AIR_GAP=0.7f;const int _d34=8,TRICK_FRAMES=31;//trick:also R up to 6 _d57 before take-off
const float _d9=0.95f;//[measured]TOTK pulls the kart down~0.95 m/s per frame;added back so the glide _d138 settles at _d152
const float _d10=8.225f,GLIDE_SINK=1.6f,GLIDE_DIVE=4.5f,GLIDE_FLOAT=0.6f,GLIDE_STEER=0.6f,GLIDE_MIN_HEIGHT=2.5f;
bool _d41=false,trickDone=false,gliding=false,gliderLatch=true;int _d40=0,groundFrames=0,trickWindow=0,rPressAge=99;
const bool _d30=false;
const float _d31=0.7f,OFFROAD_HEAVY=0.5f;//[table]PROF
bool _d112=_d30,offroadChordLatched=true;
float _d108=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d50=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d94=false,gasLatch=true,idleHold=false;
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d92=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d92==0)return 0;
uint op=_pu(_d92);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d49=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d49-=0x04000000;
ptr_t _d152=ptr_t(int64(_d92)+_d49*4);
if(_pu(_d152)!=0xf0001382||_pu(_d152+4)!=0xa9be7bfd)return 0;
ptr_t _d43=_d152-0x65b80;if((_d43&0xfff)!=0)return 0;return _d43+0x3d90b8;
}
void _k13(){ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d129();_k19=false;_k20=false;_d119=0;_w15=0;_d90=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d148=_pu(_k16+0x24);if(_d148<2||_d148>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d95,uint _k27){
if(_d95 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d95);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d148=_pu(p+0x24);
return _d148>=2&&_d148<=6;
}
bool _k0(ActorBase@_d95,uint _k27){
if(Player is null||!_k1(_d95,_k27))return false;
ptr_t _d37=_pa(_d95),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d48=_pu(_d37+0x220);ptr_t _d103=_pq(_d37+0x228);
if(_d48<=129||_d48>512||!_k2(_d103))return false;
ptr_t _d47=_pq(_d103+0x408);
if(!_k2(_d47))return false;
uint _d133=_pu(_d47+0x20);ptr_t _k29=_pq(_d47+0x28);
if(_d133!=1||!_k2(_k29))return false;
ptr_t _d131=_pq(_k29);
if(!_k2(_d131))return false;
uint _d132=_pu(_d131+0x10),flags=_pu(_d131+0x18);
float _k33=_pf(_d131+0x74);
if(_d132!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d131+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d95,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d119=a.pos_x;_w15=a.pos_z;return;}
float dx=_d119-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d119=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@_d113=_k7();
if(_k15(_d113)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d102=sqrt(fx*fx+fz*fz);if(_d102<0.1f)return;fx/=_d102;fz/=_d102;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d113!is null){_k10(_d113);_d113.setPos(x,y,z);@_d113=null;_d119=0;_w15=0;_d90=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);_k17=_pu(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d119=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d159(ActorBase@a){
ptr_t _d103=_pq(_pa(a)+0x228);if(!_k2(_d103))return 0;
ptr_t mc=_pq(_d103+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(_pf(b+120)-0.728f)>0.002f||abs(_pf(b+216)+0.728f)>0.002f||abs(_pf(b+312)-0.7776f)>0.002f||abs(_pf(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _d160(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
const float _d33=0.3927f;//2*pi/16 tread _d44
float _d157(float _d151){
float m=abs(_d151),half=_d33*0.5f;
if(m<=half*0.9f)return _d151;
float _d44=floor((m-half)/_d33);if(_d44>3)_d44=3;
float v=(_d44+0.5f)*_d33;return _d151<0?-v:v;
}
void _d42(ActorBase@a){
if(a is null){_d90=false;return;}
Matrix33f r=a.rot;float _d102=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d90&&_d102>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d102;}
_w4=x;_w5=z;_d90=true;
_w2+=_d157(ds/0.28328f);_w3+=_d157(ds/0.3683f);
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d150*0.45f-_w1)*0.25f;
ptr_t b=_d159(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d160(b+72,sf,cf,sd,cd);_d160(b+168,sf,cf,sd,cd);
_d160(b+264,sr,cr,0,1);_d160(b+360,sr,cr,0,1);
}
void _d129(){_d41=false;trickDone=false;gliding=false;_d40=0;groundFrames=0;trickWindow=0;_d108=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d50=0;driftTier=0;boostLeft=0;hopWindow=0;_d94=false;gasLatch=true;idleHold=false;}
int _d85=-1;float _d79=99;//updated by _d82(ray cast under the kart)
float _d153(){
if(!_d112||_d79>=0.8f)return 1;
int m=_d85;
if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;//HeavySand,HeavySnow,Bog,Tar,Water,ContaminatedWater
if(m==1||m==2||m==3||m==5)return _d31;//Soil,Grass,Sand,Snow
return 1;
}
float _d146(float v,float _d154){
if(boostLeft>0){
boostLeft--;float t=_d24*_d29;
if(v<t){float _d98=(t-v)*_d17;if(_d98>MK_BOOST_CAP)_d98=MK_BOOST_CAP;return v+_d98;}
return t;
}
if(_d154>0){
if(v<0)return v+_d18>0?0:v+_d18;//stop reversing first
float t=_d24*_d154*_d153();
if(v<t){float _d98=(t-v)*_d16;if(_d98>_d15)_d98=_d15;return v+_d98;}//[native]form
float d=v*_d22;return d<t?t:d;
}
if(_d154<0){
if(v>0)return v-_d18<0?0:v-_d18;//brake,then reverse
float t=-_d23*(-_d154);
if(v>t){float _d98=(v-t)*_d16;if(_d98>_d15)_d98=_d15;return v-_d98;}
return v;
}
if(v>0)return v-_d20<0?0:v-_d20;
return v+_d20>0?0:v+_d20;
}
void _d51(int _d155){
_L("KART drift tier="+_d155+" charge="+driftCharge);
if(_d155==1)_T(30,"Mini-Turbo\n");else if(_d155==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d91){
_d150=0;
ActorBase@a=_k7();bool _d130=_k15(a);
if(_d130!=_k19){_L("KART mounted="+_d130);_d129();_k19=_d130;_k20=!_d130;if(a!is null){_d119=a.pos_x;_w15=a.pos_z;}}
if(!_d130||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d129();return;}
float _d149=float(ix)/32768.0f,_d154=0;
if(abs(_d149)<0.15f)_d149=0;
bool _d70=(_d91&uint64(A))!=0,brake=(_d91&uint64(B))!=0;
if(!_d70)gasLatch=false;//the A press used to get in must be released first
if(brake)_d154=-1;else if(_d70&&!gasLatch)_d154=1;
_d150=_d149;
Matrix33f r=a.rot;float _d102=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d102<0.1f||r.a4<0.4f){_k10(a);_d129();return;}
float bx=r.a2/_d102,bz=r.a8/_d102,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d38=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d39=_d38/_d27;
if(_d108>0&&_d108>_d39+0.6f)_d108=_d39+0.6f<0?0:_d39+0.6f;
if(_d108<0&&_d108<_d39-0.6f)_d108=_d39-0.6f>0?0:_d39-0.6f;
bool _d126=(_d91&uint64(R|ZR))!=0,fast=_d108>_d24*0.35f;
if(_d63())_d86(a.pos_x,a.pos_y+0.2f,a.pos_z);
bool _d116=_d79<AIR_GAP;
if(_d116){groundFrames++;_d40=0;}else{_d40++;groundFrames=0;}
bool _d158=_d41;
bool _d125=_d126&&!_d94;rPressAge=_d125?0:rPressAge+1;
if(!_d41&&_d40>=2){
_d41=true;trickWindow=_d34;trickDone=false;_L("KART airborne");
if(rPressAge<=6+_d40){trickDone=true;_T(30,"Trick!\n");_L("KART trick (buffered)");}
}
if(_d41&&groundFrames>=1){
_d41=false;
if(gliding){gliding=false;_L("KART glider landed");}
if(trickDone){if(boostLeft<TRICK_FRAMES)boostLeft=TRICK_FRAMES;_L("KART trick boost");}
trickDone=false;_L("KART landed");
}
float _d93=0;
bool _d124=_d126&&!_d94;
if(_d41){
if(trickWindow>0){trickWindow--;if(_d124&&!trickDone){trickDone=true;_T(30,"Trick!\n");_L("KART trick");}}
}else if(_d124&&fast){_d93=_d14;hopWindow=24;}
_d94=_d126;
bool _d161=(_d91&uint64(Y))!=0;
if(!_d161)gliderLatch=false;
if(_d161&&!gliderLatch){
gliderLatch=true;
if(gliding){gliding=false;_L("KART glider folded");}
else if(_d41&&_d79>=GLIDE_MIN_HEIGHT){gliding=true;_d50=0;driftCharge=0;driftTier=0;_T(30,"Glider!\n");_L("KART glider open");}
}
if(_d50==0&&!_d41&&_d126&&hopWindow>0&&abs(_d149)>0.3f){_d50=_d149>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d50);}
if(_d50!=0&&(!_d126||!fast)){
int _d57=driftTier==3?int(_d35):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d28):0;
if(_d57>0&&_d126==false){boostLeft=_d57;_L("KART boost tier="+driftTier+" frames="+_d57);}
_d50=0;driftCharge=0;driftTier=0;
}
if(!_d41&&_d154==0&&boostLeft==0&&_d50==0&&_d93==0&&abs(_d108)<_d20){
_d108=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d119=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d162=0,oldOff=bodyOff;
for(int _d151=0;_d151<2;_d151++){
if(hopWindow>0)hopWindow--;
if(gliding){float t=_d10*(iy>16000?1.06f:1.0f);_d108+=(t-_d108)*0.02f;}
else if(!_d41||boostLeft>0)_d108=_d146(_d108,_d154);
float _d45=0;
if(gliding){
driftTrack=0;_d162+=_d149*_d25*GLIDE_STEER;
}else if(_d50!=0){
float _d101=_d149*_d50;if(_d101>1)_d101=1;if(_d101<-1)_d101=-1;
float _d156=_d101>=0?_d4:-_d4,dt=(_d156-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d100=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d162+=_d50*_d21*_d100*_d100*(0.75f+0.25f*_d101);
if(!_d41)driftCharge+=_d101>=CHARGE_INWARD?_d1:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d155=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d2?1:0;
if(_d155>driftTier){driftTier=_d155;_d51(_d155);}
_d45=_d50*_d3;
}else{
driftTrack=0;
float _d144=abs(_d108)/(_d24*0.25f);if(_d144>1)_d144=1;
_d162+=_d149*_d25*_d144*(_d108<0?-1.0f:1.0f)*(_d41?_d0:1.0f);
}
float _d69=_d45-bodyOff,ds=_d69*0.07f;
if(abs(ds)<0.001f)ds=abs(_d69)<0.001f?_d69:(_d69>0?0.001f:-0.001f);
bodyOff+=ds;
if(!_d41)lateral*=1-_d11*_d26;
}
_k18=_d108*_d27;
float _d145=_k18;
float vy=v.y+_d93;
if(gliding){
float _d138=iy>16000?GLIDE_DIVE:iy<-16000?GLIDE_FLOAT:GLIDE_SINK;//stick forward dives,back floats
vy+=(-_d138-vy)*0.3f+_d9;//ease into the glide descent(gravity compensated)
}
b.setVel(fx*_d145+lx*lateral,vy,fz*_d145+lz*lateral);
b.setAngularVel(-r.a7*2.0f,-(_d162+bodyOff-oldOff)*30.0f,r.a1*2.0f);
}
const uint _d7=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float _d32=0.35f,FLAME_SCALE=0.15f;//[chosen]from screenshots
ptr_t _d60=0,fxSys=0,fxScr=0;int _d64=-2,fxFlame=-1;
bool _d61(ptr_t p,const string&in _d109){
uint n=_d109.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=_d109[i])return false;
return ptr_deref_u8(p+n)==0;
}
int _d58(const string&in _d109){
ptr_t _d128=_pq(_pq(fxSys+0x2ee8)+8);if(_d128==0||ptr_deref_u8(_d128+0x571)==0)return-1;//static effects=resource 1
int n=_ps(_d128+0x558);ptr_t _d134=_pq(_d128+0x430);
for(int i=0;i<n;i++)if(_d61(_pq(_d134+0x28*i)+0x10,_d109))return i;
return-1;
}
bool _d63(){
if(_d64>=0)return true;
if(_d64==-1)return false;//looked once and failed:stay off
_d64=-1;
ptr_t _d92=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d92==0)return false;
uint op=_pu(_d92);int64 _d49=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d49-=0x04000000;
ptr_t _d152=ptr_t(int64(_d92)+_d49*4),_d43=_d152-0x65b80;
if((_d43&0xfff)!=0||_pu(_d152)!=0xf0001382)return false;
fxScr=_d43+FX_SCRATCH;_d60=sys::mainOffset();
ptr_t _d99=_pq(_pq(_d60+_d7));if(_d99==0)return false;
fxSys=_pq(_d99+0x11b8);if(fxSys==0)return false;
int _d141=_d58("Ply_ShockWave_Spark");fxFlame=_d58("Chm_FlameThrower_ScraBuild");//Zonai _d54 emitter jet
_L("KART fx spark="+_d141+" flame="+fxFlame);
if(_d141<0)return false;
_d64=_d141;return true;
}
ptr_t _d59(int _d140){ptr_t h=fxScr+0x10*_d140,e=_pq(h);if(e==0)return 0;return _pu(e+0x234)==_pu(h+8)?e:0;}
ptr_t _d65(int _d140,int id){
ptr_t e=_d59(_d140);if(e!=0)return e;
ptr_t h=fxScr+0x10*_d140;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d60+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*_d140,0,0,0,0,0);
return _d59(_d140);
}
void _d67(int _d140){if(fxScr==0)return;ptr_t e=_d59(_d140);if(e!=0)ptr_call(_d60+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*_d140,0);}
void _d62(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
_pw(m,r.a0);_pw(m+4,r.a1);_pw(m+8,r.a2);_pw(m+12,px);
_pw(m+16,r.a3);_pw(m+20,r.a4);_pw(m+24,r.a5);_pw(m+28,py);
_pw(m+32,r.a6);_pw(m+36,r.a7);_pw(m+40,r.a8);_pw(m+44,pz);
_pw(fxScr+0x140,s);_pw(fxScr+0x144,s);_pw(fxScr+0x148,s);
ptr_call(_d60+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
void _d68(ptr_t e,float r,float g,float b){_pw(e+0x40,r);_pw(e+0x44,g);_pw(e+0x48,b);}
void _d142(ActorBase@a){
bool _d143=a!is null&&_k19&&_d50!=0&&driftTier>0;
bool _d54=a!is null&&_k19&&boostLeft>0;
if(!_d143&&!_d54&&fxScr==0)return;
if(!_d63()){return;}
if(!_d143)_d67(0);
if(!_d54||fxFlame<0)_d67(1);
if(_d143){
ptr_t e=_d65(0,_d64);
if(e!=0){
if(driftTier==1)_d68(e,0.25f,0.8f,6.0f);else if(driftTier==2)_d68(e,1.0f,1.0f,1.0f);else _d68(e,2.2f,0.4f,6.0f);
ptr_t b=_d159(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(_pf(b+312));wy=_pf(b+28)+_pf(b+316)-0.3683f;wz=_pf(b+32)+_pf(b+320);}
_d62(e,a,wx,wy,wz,_d32);_d62(e,a,-wx,wy,wz,_d32);
}
}
if(_d54&&fxFlame>=0){ptr_t e=_d65(1,fxFlame);if(e!=0){_d62(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);_d62(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
const uint _d6=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int _d87=-1,groundTick=0;
int _d72=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;//effect ids per class,looked up once(no arrays in this runtime)
bool _d86(float x,float y,float z){
ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d60+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);//flags:all false
_pw(v+4,2.0f);ptr_write_u64(q+0x38,v+4);//ray _d102(m)
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d60+_d6,q,0,0,0,0,0,0,0,0,0,0);
if(ptr_deref_u8(v+0x10)==0){_d85=-1;_d79=99;return false;}
_d85=_ps(v+0x40);_d79=_pf(v+0x14);return true;
}
int _d78(int m){
if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return-1;return 6;
}
string _d81="";//diagnostics only:overrides the grass effect _d109
string _d80(int c){
if(c==0&&_d81!="")return _d81;
if(c==0)return"ReFX_Grass_L";if(c==1||c==2)return"ReFX_Sand_L";if(c==3)return"ReFX_Snow_L";
if(c==4)return"Water_Splash01_Move";if(c==5)return"RctFld_Mud_Splash_S";return"Ply_SlipSmoke_Stone";
}
int _d83(int c){
if(c==0){if(_d72==-2)_d72=_d58(_d80(0));return _d72;}if(c==1){if(gid1==-2)gid1=_d58(_d80(1));return gid1;}
if(c==2){if(gid2==-2)gid2=_d58(_d80(2));return gid2;}if(c==3){if(gid3==-2)gid3=_d58(_d80(3));return gid3;}
if(c==4){if(gid4==-2)gid4=_d58(_d80(4));return gid4;}if(c==5){if(gid5==-2)gid5=_d58(_d80(5));return gid5;}
if(gid6==-2)gid6=_d58(_d80(6));return gid6;
}
const float _d13=1.2f,GROUND_MIN_SPEED=3.0f;//[chosen]
const int _d12=6;//[chosen]_d57 between bursts:TOTK's ground effects are one-shot(per footstep/hoof)
int _d77=0,groundBurstSlot=0;
void _d88(){if(fxScr==0)return;for(int k=3;k<7;k++)_d67(k);}
ptr_t _d66(int _d140,int id,ptr_t _d123){
ptr_t h=fxScr+0x10*_d140;_d67(_d140);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d60+FX_CREATE,fxSys,h,id,1,0,_d123,0,0,0,0,0);
return _d59(_d140);
}
void _d82(ActorBase@a){
bool _d36=a!is null&&_k19&&_d63();
if(!_d36){_d88();_d87=-1;return;}
int c=_d79<0.8f?_d78(_d85):-1;
bool _d111=c>=0&&c<6,show=c>=0&&abs(_k18)>GROUND_MIN_SPEED&&(_d111||_d50!=0);
_d87=show?c:-1;
if(!show){_d77=0;return;}
if(_d77-->0)return;
_d77=_d12;
int id=_d83(c);if(id<0)return;
int _d140=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
ptr_t e=_d66(_d140,id,fxScr+0x5000);if(e==0)return;
float wx=0.78f,wz=-0.75f;ptr_t b=_d159(a);if(b!=0){wx=abs(_pf(b+312));wz=_pf(b+32)+_pf(b+320);}
_d62(e,a,wx,0,wz,_d13);_d62(e,a,-wx,0,wz,_d13);
}
const float _d8=-0.15f,GLIDER_Z=-0.45f;//[chosen]attach point in kart space(glider frame _d43)
float _d74=0;bool _d75=false;
ptr_t _d97=0,hostSklAt=0;
ptr_t _d96(ActorBase@a){
ptr_t _d103=_pq(_pa(a)+0x228);if(!_k2(_d103))return 0;
ptr_t mc=_pq(_d103+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
if(m==_d97&&hostSklAt!=0)return hostSklAt;
_d97=m;hostSklAt=0;
for(uint o=0;o<0x4000;o+=4){
ptr_t r=m+o;
if(abs(_pf(r+52)-0.3766f)<0.003f&&abs(_pf(r+48))<0.003f&&abs(_pf(r+56))<0.003f
&&abs(_pf(r+96+52)-0.5966f)<0.003f&&abs(_pf(r+96+56)-0.4928f)<0.003f){hostSklAt=r;_L("KART host Skl_Root record at +"+o);break;}
}
return hostSklAt;
}
void _d73(ActorBase@a){
float _d152=(a!is null&&_k19&&gliding)?1:0;
if(_d152==0&&_d74==0&&_d75)return;
if(a is null)return;
ptr_t _d139=_d96(a);if(_d139==0)return;
if(_d74<_d152){_d74+=0.17f;if(_d74>_d152)_d74=_d152;}
else if(_d74>_d152){_d74-=0.2f;if(_d74<_d152)_d74=_d152;}
ptr_t r=_d139-192;float sc=_d74;//Control=bone 1,two records before Skl_Root(bone 3)
_pw(r,sc);_pw(r+4,0);_pw(r+8,0);
_pw(r+16,0);_pw(r+20,sc);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,sc);
_pw(r+48,0);_pw(r+52,_d8);_pw(r+56,GLIDER_Z);
_d75=true;
}
const uint _d5=0x1085b5c;
bool _d56=false;
bool _d76(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d121(){
if(Player is null)return 0;ptr_t p=_pq(_pa(Player)+0x228);if(!_d76(p))return 0;
p=_pq(p+0x50);if(!_d76(p))return 0;p=_pq(p+0x20);return _d76(p)?p:0;
}
void _d55(){
if(!_k19&&!_d56)return;
ptr_t _d120=_d121();if(_d120==0)return;
ptr_call(sys::mainOffset()+_d5,_d120,_k19?0:1,0,0,0,0,0,0,0,0,0);
_d56=_k19;
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
_L("KART ready");
}
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool _d117=false,exitLatch=false;uint64 _d114=0;int _d115=0,outLY=0,outRX=0,outRY=0;
bool _d135=false;uint64 _d136=0;int _d137=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d118){
uint64 _d91=_d135?_d136:_pq(_d118);
int lx=_d135?_d137:_ps(_d118+8),ly=_d135?simLY:_ps(_d118+12);
int rx=_d135?simRX:_ps(_d118+16),ry=_d135?simRY:_ps(_d118+20);
_d117=false;_d114=_d91;_d115=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 _d104=uint64(ZL|ZR|DUP);
if((_d91&_d104)==0)_k24=false;
if(!_k24&&(_d91&_d104)==_d104){_k24=true;_k25=true;_L("KART spawn queued");}
uint64 _d110=uint64(ZL|ZR|DDOWN);
if((_d91&_d110)==0)offroadChordLatched=false;
if(!offroadChordLatched&&(_d91&_d110)==_d110){
offroadChordLatched=true;_d112=!_d112;_L("KART offroad="+_d112);
_T(90,_d112?"Off-road handling: ON\n":"Off-road handling: OFF\n");
}
if(!_k3())return;
if(_k25&&(_d91&_d104)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d91);
_d42(_k7());
_d142(_k7());
_d73(_k7());
_d55();
_d82(_k7());
uint64 _d52=uint64(A|B|X|Y|R|ZR);
if(_k19){
_d117=true;_d114=_d91&~_d52;
if((_d91&uint64(X))!=0){_d114|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d91&uint64(X))==0)exitLatch=false;
else{_d117=true;_d114=_d91&~uint64(X);}//do not let the _d91 X make Link jump
}
}
void _d163(){
if(_d117)input(1,_d114,_d115,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d118){while(true){_k5(_d118);_d163();}}
void _d71(uint f){
if(f%75!=0)return;uint k=f/75;
string n=k==0?"Ply_SlipSmoke_Grass_Green":k==1?"ReFX_Grass_M":k==2?"HorseStep_Grass_Tmp":k==3?"Ply_FootEffect_Grass_Green":"ReFX_Grass_L";
_d81=n;_d72=-2;_d88();_d87=-1;
_L("GRASS "+n);
}
void _d89(){ptr_t e=fxScr==0?0:_d59(3);if(e==0){_L("GSTATE none");return;}
_L("GSTATE e8="+ptr_deref_s16(e+0xe8)+" f38="+_pu(e+0x38)+" 4c="+_pf(e+0x4c)+" 5c="+_pf(e+0x5c)+" 24c="+_pf(e+0x24c)+" 250="+_pf(e+0x250)+" 254="+_pf(e+0x254)+" 25c="+_pf(e+0x25c)+" 260="+_pf(e+0x260));}
ptr_t tp=0;
void _d53(uint64 k,int x,int y,int rx){
_d135=true;_d136=k;_d137=x;simLY=y;simRX=rx;simRY=0;_k5(tp);
if(_d117)input(1,_d114,_d115,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
string _d106(int i){if(i<0||i>=54)return"?";ptr_t t=_pq(sys::mainOffset()+0x4637298);if(t==0)return"?";ptr_t s=_pq(t+0x250+8*i);string r="";for(int k=0;k<32&&s!=0;k++){u8 c=ptr_deref_u8(s+k);if(c==0)break;r+=" ";r[r.length()-1]=c;}return r;}
bool _d122(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d84(ActorBase@a){if(a is null)return 0;ptr_t p=_pq(_pa(a)+0x228);if(!_d122(p))return 0;p=_pq(p+0x50);if(!_d122(p))return 0;
p=_pq(p+0x20);if(!_d122(p))return 0;p=_pq(p+0x10);if(!_d122(p))return 0;p=_pq(p+8);if(!_d122(p))return 0;p=_pq(p+0x20);if(!_d122(p))return 0;return p+0x20;}
string _d107(ActorBase@a){ptr_t g=_d84(a);if(g==0)return"none";int m=_ps(g+0x78);return""+m+":"+_d106(m)+" f="+ptr_deref_u8(g+0x110)+","+ptr_deref_u8(g+0x111);}
string _d46(ActorBase@a){if(a is null)return"null";string r="";ptr_t p=_pa(a);
for(uint i=0;i<6;i++){uint o=i==0?0x228:i==1?0x50:i==2?0x20:i==3?0x10:i==4?8:0x20;p=_pq(p+o);r+=" "+formatInt(int64(p),"H");if(!_d122(p))break;}return r;}
string _d127(float x,float y,float z){
if(!_d63())return"nofx";
ptr_t q=fxScr+0x5000,v=fxScr+0x5100,p1=fxScr+0x5200,p2=fxScr+0x5300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d60+0x4578958);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);
_pw(v+4,3.0f);ptr_write_u64(q+0x38,v+4);
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d60+0x20e4da4,q,0,0,0,0,0,0,0,0,0,0);
int m=_ps(v+0x40);
return"hit="+ptr_deref_u8(v+0x10)+" d="+_pf(v+0x14)+" f58="+_pf(v+0x18)+" n="+_pf(v+0x20)+","+_pf(v+0x24)+","+_pf(v+0x28)+" m="+m+":"+_d106(m)+" b="+ptr_deref_u8(v+0x44);
}
void _d105(const string&in l){ActorBase@k=_k7();
_L("MAT "+l+" player="+_d107(Player)+" rayP="+_d127(Player.pos_x,Player.pos_y+0.5f,Player.pos_z)+(k is null?"":" rayK="+_d127(k.pos_x,k.pos_y+0.2f,k.pos_z)));}
void _d147(const string&in l){_d89();ActorBase@a=_k7();_L("SPK "+l+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+_k18+" tier="+driftTier+" charge="+driftCharge+" boost="+boostLeft+" live0="+(fxScr!=0&&_d59(0)!=0)+" live1="+(fxScr!=0&&_d59(1)!=0)+" ground="+_d85+"/"+_d87+" d="+_d79+" air="+_d41+" glide="+gliding+" gscale="+_d74+" crec="+((a is null||_d96(a)==0)?-1:_pf(_d96(a)-192))+","+((a is null||_d96(a)==0)?-1:_pf(_d96(a)-192+52))+" trick="+trickDone+" vy="+(a is null?0:a.getMainRigidBody().vel.y)+" gd="+_d79+" mounted="+_k15(a));}
void main(){
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
_d105("start");input(30,0);_d105("start2");
Player.setPos(-150,127.8,-62);input(90,0);if(!_k3())return;
_d105("field");
_k5(tp);_d53(uint64(ZL|ZR|DUP),0,0,0);
for(uint f=0;f<25;f++)_d53(0,0,0,0);
for(uint t=0;t<10&&!_k15(_k7());t++){
ActorBase@k=_k7();if(k is null){input(10,0);continue;}
Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,k.pos_y+0.3f,pz);input(20,0);
_L("SPK try mount t="+t+" kart="+k.pos_x+","+k.pos_z+" player="+Player.pos_x+","+Player.pos_z);
input(1,1);input(30,0);
}
if(!_k15(_k7())){_L("SPK mount failed");return;}
_d53(0,0,0,0);
for(uint f=0;f<60&&_k3();f++){_d53(uint64(A),0,0,0);if(f%30==0)_d147("run"+f);}
ActorBase@k=_k7();Vector3f lv=k.getMainRigidBody().vel;k.getMainRigidBody().setVel(lv.x,12.0f,lv.z);
for(uint f=0;f<60&&_k3();f++){_d53(uint64(A)|(f==0?uint64(R):0),0,0,0);if(f%3==0)_d147("jump"+f);}
for(uint f=0;f<40&&_k3();f++){_d53(uint64(A),0,0,0);if(f%10==0)_d147("afterjump"+f);}
for(uint f=0;f<180&&_k3();f++){_d53(uint64(A),0,0,0);if(f%30==0)_d147("preglide"+f);}
@k=_k7();lv=k.getMainRigidBody().vel;k.getMainRigidBody().setVel(lv.x,24.0f,lv.z);
for(uint f=0;f<12&&_k3();f++){_d53(uint64(A),0,0,0);if(f%3==0)_d147("launch"+f);}
_d53(uint64(A|Y),0,0,0);_d53(uint64(A),0,0,0);_d147("glider-pressed");
for(uint f=0;f<240&&_k3()&&(f<5||_d41);f++){_d53(uint64(A),0,(f>90?32767:0),0);if(f%10==0)_d147("glide"+f);}
for(uint f=0;f<150&&_k3();f++){_d53(0,0,0,0);if(f%30==0)_d147("afterglide"+f);}
_L("SPK finished");_d135=false;input(1,0);_k11(tp);
}
