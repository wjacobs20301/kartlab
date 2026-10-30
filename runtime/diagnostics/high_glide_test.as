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
bool _k20=false;float _d146=0,_w15=0;
float _d192=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d109=false;
const float _d29=7.775f;//[table]PRSL ground top speed,0 coins
const float _d21=0.011f;//[table]PRAC strength(G)
const float _d20=0.09f;//[table]PRAC limiter(M)
const float _d30=0.0118f;//[table]PRTL _d191,rad per MK frame
const float _d26=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d24=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d31=0.75f;//[table]PRON road traction
const float _d34=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d33=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d76)
const uint _d44=153;//[chosen]ultra _d124(not in the table):SMT+(SMT-MT)
const float _d4=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d32=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d28=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d23=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d25=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d27=0.993f;//[chosen]decay above _d197(after a boost)
const float _d22=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d15=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d6=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d193 0.001
const float _d7=0.8f;//[native]drift _d191 _d190 _w12,approached at 10%/frame,_d193<=0.07
const float _d3=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d120>=0.71 else 2
const float _d18=3.0f;//[chosen]drift _d112,m/s upward
const float _d0=0.3f,AIR_GAP=0.7f;const int _d43=8,TRICK_FRAMES=31;//trick:also R up to 6 _d76 before take-off
const float _d13=0.95f;//[measured]TOTK pulls the kart down~0.95 m/s per frame;added back so the glide _d168 settles at _d197
const float _d14=8.225f,GLIDE_SINK=1.6f,GLIDE_DIVE=4.5f,GLIDE_FLOAT=0.6f,GLIDE_STEER=0.6f,GLIDE_MIN_HEIGHT=2.5f;
const float _d12=0.55f,GLIDE_PITCH=0.35f,GLIDE_TILT_GAIN=4.0f;//[chosen]~29 deg _d52,~19 deg _d148
bool _d50=false,trickDone=false,gliding=false,gliderLatch=true;int _d49=0,groundFrames=0,trickWindow=0,rPressAge=99;
const bool _d35=false;
const float _d36=0.7f,OFFROAD_HEAVY=0.5f;//[table]PROF
bool _d139=_d35,offroadChordLatched=true;
float _d134=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d69=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d113=false,gasLatch=true,idleHold=false;
bool _d132(){return pause::isPauseRequest("GamePause")||pause::isPauseRequest("PreGamePause")||pause::isPauseRequest("PostGamePause")||pause::isPauseTarget("Custom_PhysicsUpdateWorld");}
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d111=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d111==0)return 0;
uint op=_pu(_d111);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d67=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d67-=0x04000000;
ptr_t _d197=ptr_t(int64(_d111)+_d67*4);
if(_pu(_d197)!=0xf0001382||_pu(_d197+4)!=0xa9be7bfd)return 0;
ptr_t _d53=_d197-0x65b80;if((_d53&0xfff)!=0)return 0;return _d53+0x3d90b8;
}
void _k13(){_d93=0;_d94=false;ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d159();_k19=false;_k20=false;_d146=0;_w15=0;_d109=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d190=_pu(_k16+0x24);if(_d190<2||_d190>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d114,uint _k27){
if(_d114 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d114);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d190=_pu(p+0x24);
return _d190>=2&&_d190<=6;
}
bool _k0(ActorBase@_d114,uint _k27){
if(Player is null||!_k1(_d114,_k27))return false;
ptr_t _d46=_pa(_d114),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d66=_pu(_d46+0x220);ptr_t _d125=_pq(_d46+0x228);
if(_d66<=129||_d66>512||!_k2(_d125))return false;
ptr_t _d65=_pq(_d125+0x408);
if(!_k2(_d65))return false;
uint _d163=_pu(_d65+0x20);ptr_t _k29=_pq(_d65+0x28);
if(_d163!=1||!_k2(_k29))return false;
ptr_t _d161=_pq(_k29);
if(!_k2(_d161))return false;
uint _d162=_pu(_d161+0x10),flags=_pu(_d161+0x18);
float _k33=_pf(_d161+0x74);
if(_d162!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d161+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d114,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d146=a.pos_x;_w15=a.pos_z;return;}
float dx=_d146-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d146=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@_d140=_k7();
if(_k15(_d140)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d124=sqrt(fx*fx+fz*fz);if(_d124<0.1f)return;fx/=_d124;fz/=_d124;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d140!is null){_k10(_d140);_d140.setPos(x,y,z);@_d140=null;_d146=0;_w15=0;_d109=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);_k17=_pu(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d146=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d204(ActorBase@a){
ptr_t _d125=_pq(_pa(a)+0x228);if(!_k2(_d125))return 0;
ptr_t mc=_pq(_d125+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(_pf(b+120)-0.728f)>0.002f||abs(_pf(b+216)+0.728f)>0.002f||abs(_pf(b+312)-0.7776f)>0.002f||abs(_pf(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _d205(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
const float _d42=0.3927f;//2*pi/16 tread _d54
float _d202(float _d193){
float m=abs(_d193),half=_d42*0.5f;
if(m<=half*0.9f)return _d193;
float _d54=floor((m-half)/_d42);if(_d54>3)_d54=3;
float v=(_d54+0.5f)*_d42;return _d193<0?-v:v;
}
void _d51(ActorBase@a){
if(a is null){_d109=false;return;}
Matrix33f r=a.rot;float _d124=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d109&&_d124>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d124;}
_w4=x;_w5=z;_d109=true;
_w2+=_d202(ds/0.28328f);_w3+=_d202(ds/0.3683f);
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d192*0.45f-_w1)*0.25f;
ptr_t b=_d204(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d205(b+72,sf,cf,sd,cd);_d205(b+168,sf,cf,sd,cd);
_d205(b+264,sr,cr,0,1);_d205(b+360,sr,cr,0,1);
}
void _d159(){_d50=false;trickDone=false;gliding=false;_d49=0;groundFrames=0;trickWindow=0;_d134=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d69=0;driftTier=0;boostLeft=0;hopWindow=0;_d113=false;gasLatch=true;idleHold=false;}
int _d104=-1;float _d98=99;//updated by _d101(ray cast under the kart)
float _d198(){
if(!_d139||_d98>=0.8f)return 1;
int m=_d104;
if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;//HeavySand,HeavySnow,Bog,Tar,Water,ContaminatedWater
if(m==1||m==2||m==3||m==5)return _d36;//Soil,Grass,Sand,Snow
return 1;
}
float _d188(float v,float _d199){
if(boostLeft>0){
boostLeft--;float t=_d29*_d34;
if(v<t){float _d117=(t-v)*_d22;if(_d117>MK_BOOST_CAP)_d117=MK_BOOST_CAP;return v+_d117;}
return t;
}
if(_d199>0){
if(v<0)return v+_d23>0?0:v+_d23;//stop reversing first
float t=_d29*_d199*_d198();
if(v<t){float _d117=(t-v)*_d21;if(_d117>_d20)_d117=_d20;return v+_d117;}//[native]form
float d=v*_d27;return d<t?t:d;
}
if(_d199<0){
if(v>0)return v-_d23<0?0:v-_d23;//brake,then reverse
float t=-_d28*(-_d199);
if(v>t){float _d117=(v-t)*_d21;if(_d117>_d20)_d117=_d20;return v-_d117;}
return v;
}
if(v>0)return v-_d25<0?0:v-_d25;
return v+_d25>0?0:v+_d25;
}
void _d70(int _d200){
_L("KART drift tier="+_d200+" charge="+driftCharge);
if(_d200==1)_T(30,"Mini-Turbo\n");else if(_d200==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d110){
_d192=0;
ActorBase@a=_k7();bool _d160=_k15(a);
if(_d160!=_k19){_L("KART mounted="+_d160);_d159();_k19=_d160;_k20=!_d160;if(a!is null){_d146=a.pos_x;_w15=a.pos_z;}}
if(!_d160||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d159();return;}
float _d191=float(ix)/32768.0f,_d199=0;
if(abs(_d191)<0.15f)_d191=0;
bool _d89=(_d110&uint64(A))!=0,brake=(_d110&uint64(B))!=0;
if(!_d89)gasLatch=false;//the A press used to get in must be released first
if(brake)_d199=-1;else if(_d89&&!gasLatch)_d199=1;
_d192=_d191;
Matrix33f r=a.rot;float _d124=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d124<0.1f||r.a4<0.4f){_k10(a);_d159();return;}
float bx=r.a2/_d124,bz=r.a8/_d124,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
_d56=fx;camFz=fz;camBraking=brake&&_d134>0.5f;
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d47=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d48=_d47/_d32;
if(_d134>0&&_d134>_d48+0.6f)_d134=_d48+0.6f<0?0:_d48+0.6f;
if(_d134<0&&_d134<_d48-0.6f)_d134=_d48-0.6f>0?0:_d48-0.6f;
bool _d155=(_d110&uint64(R|ZR))!=0,fast=_d134>_d29*0.35f;
if(_d82())_d105(a.pos_x,a.pos_y+0.2f,a.pos_z);
bool _d143=_d98<AIR_GAP;
if(_d143){groundFrames++;_d49=0;}else{_d49++;groundFrames=0;}
bool _d203=_d50;
bool _d154=_d155&&!_d113;rPressAge=_d154?0:rPressAge+1;
if(!_d50&&_d49>=2){
_d50=true;trickWindow=_d43;trickDone=false;_L("KART airborne");
if(rPressAge<=6+_d49){trickDone=true;_d175(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick (buffered)");}
}
if(_d50&&groundFrames>=1){
_d50=false;
if(gliding){gliding=false;_L("KART glider landed");}
if(trickDone){if(boostLeft<TRICK_FRAMES)boostLeft=TRICK_FRAMES;_d175(_d41,CH_SHOT);_L("KART trick boost");}
trickDone=false;_L("KART landed");
}
float _d112=0;
bool _d153=_d155&&!_d113;
if(_d50){
if(trickWindow>0){trickWindow--;if(_d153&&!trickDone){trickDone=true;_d175(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick");}}
}else if(_d153&&fast){_d112=_d18;hopWindow=24;_d175(S_HOP,CH_SHOT);}
_d113=_d155;
bool _d206=(_d110&uint64(Y))!=0;
if(!_d206)gliderLatch=false;
if(_d206&&!gliderLatch){
gliderLatch=true;
if(gliding){gliding=false;_L("KART glider folded");}
else if(_d50&&_d98>=GLIDE_MIN_HEIGHT){gliding=true;_d175(S_GOPEN,CH_SHOT);_d69=0;driftCharge=0;driftTier=0;_T(30,"Glider!\n");_L("KART glider open");}
}
if(_d69==0&&!_d50&&_d155&&hopWindow>0&&abs(_d191)>0.3f){_d69=_d191>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d69);}
if(_d69!=0&&(!_d155||!fast)){
int _d76=driftTier==3?int(_d44):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d33):0;
if(_d76>0&&_d155==false){boostLeft=_d76;_d175(driftTier==3?S_ULTRA:_d41,CH_SHOT);_L("KART boost tier="+driftTier+" frames="+_d76);}
_d69=0;driftCharge=0;driftTier=0;
}
if(!_d50&&_d199==0&&boostLeft==0&&_d69==0&&_d112==0&&abs(_d134)<_d25){
_d134=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d146=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d207=0,oldOff=bodyOff;
for(int _d193=0;_d193<2;_d193++){
if(hopWindow>0)hopWindow--;
if(gliding){float t=_d14*(iy>16000?1.06f:1.0f);_d134+=(t-_d134)*0.02f;}
else if(!_d50||boostLeft>0)_d134=_d188(_d134,_d199);
float _d55=0;
if(gliding){
driftTrack=0;_d207+=_d191*_d30*GLIDE_STEER;
}else if(_d69!=0){
float _d120=_d191*_d69;if(_d120>1)_d120=1;if(_d120<-1)_d120=-1;
float _d201=_d120>=0?_d7:-_d7,dt=(_d201-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d119=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d207+=_d69*_d26*_d119*_d119*(0.75f+0.25f*_d120);
if(!_d50)driftCharge+=_d120>=CHARGE_INWARD?_d3:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d200=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d4?1:0;
if(_d200>driftTier){driftTier=_d200;_d70(_d200);}
_d55=_d69*_d6;
}else{
driftTrack=0;
float _d186=abs(_d134)/(_d29*0.25f);if(_d186>1)_d186=1;
_d207+=_d191*_d30*_d186*(_d134<0?-1.0f:1.0f)*(_d50?_d0:1.0f);
}
float _d88=_d55-bodyOff,ds=_d88*0.07f;
if(abs(ds)<0.001f)ds=abs(_d88)<0.001f?_d88:(_d88>0?0.001f:-0.001f);
bodyOff+=ds;
if(!_d50)lateral*=1-_d15*_d31;
}
_k18=_d134*_d32;
float _d187=_k18;
float vy=v.y+_d112;
if(gliding){
float _d168=iy>16000?GLIDE_DIVE:iy<-16000?GLIDE_FLOAT:GLIDE_SINK;//stick forward dives,back floats
vy+=(-_d168-vy)*0.3f+_d13;//ease into the glide descent(gravity compensated)
}
b.setVel(fx*_d187+lx*lateral,vy,fz*_d187+lz*lateral);
float tx=0,ty=1,tz=0,gain=2.0f;
if(gliding){
float _d148=float(iy)/32768.0f;if(_d148>1)_d148=1;if(_d148<-1)_d148=-1;
float _d52=_d191*_d12,nose=_d148*GLIDE_PITCH;//stick right:right side down;stick forward:nose down
tx=-lx*_d52+fx*nose;tz=-lz*_d52+fz*nose;ty=1;float tl=sqrt(tx*tx+ty*ty+tz*tz);tx/=tl;ty/=tl;tz/=tl;gain=GLIDE_TILT_GAIN;
}
float ux=r.a1,uy=r.a4,uz=r.a7;
float wx=(uy*tz-uz*ty)*gain,wz=(ux*ty-uy*tx)*gain;//world axes(a body-axis version flipped the kart)
b.setAngularVel(wx,-(_d207+bodyOff-oldOff)*30.0f,wz);
}
const uint _d10=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float _d39=0.35f,FLAME_SCALE=0.15f;//[chosen]from screenshots
ptr_t _d79=0,fxSys=0,fxScr=0;int _d83=-2,fxFlame=-1;
bool _d80(ptr_t p,const string&in _d135){
uint n=_d135.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=_d135[i])return false;
return ptr_deref_u8(p+n)==0;
}
int _d77(const string&in _d135){
ptr_t _d158=_pq(_pq(fxSys+0x2ee8)+8);if(_d158==0||ptr_deref_u8(_d158+0x571)==0)return-1;//static effects=resource 1
int n=_ps(_d158+0x558);ptr_t _d164=_pq(_d158+0x430);
for(int i=0;i<n;i++)if(_d80(_pq(_d164+0x28*i)+0x10,_d135))return i;
return-1;
}
bool _d82(){
if(_d83>=0)return true;
if(_d83==-1)return false;//looked once and failed:stay off
_d83=-1;
ptr_t _d111=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d111==0)return false;
uint op=_pu(_d111);int64 _d67=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d67-=0x04000000;
ptr_t _d197=ptr_t(int64(_d111)+_d67*4),_d53=_d197-0x65b80;
if((_d53&0xfff)!=0||_pu(_d197)!=0xf0001382)return false;
fxScr=_d53+FX_SCRATCH;_d79=sys::mainOffset();
ptr_t _d118=_pq(_pq(_d79+_d10));if(_d118==0)return false;
fxSys=_pq(_d118+0x11b8);if(fxSys==0)return false;
int _d183=_d77("Ply_ShockWave_Spark");fxFlame=_d77("Chm_FlameThrower_ScraBuild");//Zonai _d73 emitter jet
_L("KART fx spark="+_d183+" flame="+fxFlame);
if(_d183<0)return false;
_d83=_d183;return true;
}
ptr_t _d78(int _d170){ptr_t h=fxScr+0x10*_d170,e=_pq(h);if(e==0)return 0;return _pu(e+0x234)==_pu(h+8)?e:0;}
ptr_t _d84(int _d170,int id){
ptr_t e=_d78(_d170);if(e!=0)return e;
ptr_t h=fxScr+0x10*_d170;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d79+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*_d170,0,0,0,0,0);
return _d78(_d170);
}
void _d86(int _d170){if(fxScr==0)return;ptr_t e=_d78(_d170);if(e!=0)ptr_call(_d79+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*_d170,0);}
void _d81(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
_pw(m,r.a0);_pw(m+4,r.a1);_pw(m+8,r.a2);_pw(m+12,px);
_pw(m+16,r.a3);_pw(m+20,r.a4);_pw(m+24,r.a5);_pw(m+28,py);
_pw(m+32,r.a6);_pw(m+36,r.a7);_pw(m+40,r.a8);_pw(m+44,pz);
_pw(fxScr+0x140,s);_pw(fxScr+0x144,s);_pw(fxScr+0x148,s);
ptr_call(_d79+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
void _d87(ptr_t e,float r,float g,float b){_pw(e+0x40,r);_pw(e+0x44,g);_pw(e+0x48,b);}
void _d184(ActorBase@a){
bool _d185=a!is null&&_k19&&_d69!=0&&driftTier>0;
bool _d73=a!is null&&_k19&&boostLeft>0;
if(!_d185&&!_d73&&fxScr==0)return;
if(!_d82()){return;}
if(!_d185)_d86(0);
if(!_d73||fxFlame<0)_d86(1);
if(_d185){
ptr_t e=_d84(0,_d83);
if(e!=0){
if(driftTier==1)_d87(e,0.25f,0.8f,6.0f);else if(driftTier==2)_d87(e,1.0f,1.0f,1.0f);else _d87(e,2.2f,0.4f,6.0f);
ptr_t b=_d204(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(_pf(b+312));wy=_pf(b+28)+_pf(b+316)-0.3683f;wz=_pf(b+32)+_pf(b+320);}
_d81(e,a,wx,wy,wz,_d39);_d81(e,a,-wx,wy,wz,_d39);
}
}
if(_d73&&fxFlame>=0){ptr_t e=_d84(1,fxFlame);if(e!=0){_d81(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);_d81(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
const uint _d9=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int _d106=-1,groundTick=0;
int _d91=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;//effect ids per class,looked up once(no arrays in this runtime)
bool _d105(float x,float y,float z){
ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d79+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);//flags:all false
_pw(v+4,2.0f);ptr_write_u64(q+0x38,v+4);//ray _d124(m)
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d79+_d9,q,0,0,0,0,0,0,0,0,0,0);
if(ptr_deref_u8(v+0x10)==0){_d104=-1;_d98=99;return false;}
_d104=_ps(v+0x40);_d98=_pf(v+0x14);return true;
}
int _d97(int m){
if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return-1;return 6;
}
string _d100="";//diagnostics only:overrides the grass effect _d135
string _d99(int c){
if(c==0&&_d100!="")return _d100;
if(c==0)return"ReFX_Grass_L";if(c==1||c==2)return"ReFX_Sand_L";if(c==3)return"ReFX_Snow_L";
if(c==4)return"Water_Splash01_Move";if(c==5)return"RctFld_Mud_Splash_S";return"Ply_SlipSmoke_Stone";
}
int _d102(int c){
if(c==0){if(_d91==-2)_d91=_d77(_d99(0));return _d91;}if(c==1){if(gid1==-2)gid1=_d77(_d99(1));return gid1;}
if(c==2){if(gid2==-2)gid2=_d77(_d99(2));return gid2;}if(c==3){if(gid3==-2)gid3=_d77(_d99(3));return gid3;}
if(c==4){if(gid4==-2)gid4=_d77(_d99(4));return gid4;}if(c==5){if(gid5==-2)gid5=_d77(_d99(5));return gid5;}
if(gid6==-2)gid6=_d77(_d99(6));return gid6;
}
const float _d17=1.2f,GROUND_MIN_SPEED=3.0f;//[chosen]
const int _d16=6;//[chosen]_d76 between bursts:TOTK's ground effects are one-shot(per footstep/hoof)
int _d96=0,groundBurstSlot=0;
void _d107(){if(fxScr==0)return;for(int k=3;k<7;k++)_d86(k);}
ptr_t _d85(int _d170,int id,ptr_t _d152){
ptr_t h=fxScr+0x10*_d170;_d86(_d170);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d79+FX_CREATE,fxSys,h,id,1,0,_d152,0,0,0,0,0);
return _d78(_d170);
}
void _d101(ActorBase@a){
bool _d45=a!is null&&_k19&&_d82();
if(!_d45){_d107();_d106=-1;return;}
int c=_d98<0.8f?_d97(_d104):-1;
bool _d138=c>=0&&c<6,show=c>=0&&abs(_k18)>GROUND_MIN_SPEED&&(_d138||_d69!=0);
_d106=show?c:-1;
if(!show){_d96=0;return;}
if(_d96-->0)return;
_d96=_d16;
int id=_d102(c);if(id<0)return;
int _d170=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
ptr_t e=_d85(_d170,id,fxScr+0x5000);if(e==0)return;
float wx=0.78f,wz=-0.75f;ptr_t b=_d204(a);if(b!=0){wx=abs(_pf(b+312));wz=_pf(b+32)+_pf(b+320);}
_d81(e,a,wx,0,wz,_d17);_d81(e,a,-wx,0,wz,_d17);
}
const float _d11=-0.15f,GLIDER_Z=-0.45f;//[chosen]attach point in kart space(glider frame _d53)
float _d93=0;bool _d94=false;
ptr_t _d116=0,hostSklAt=0;
ptr_t _d115(ActorBase@a){
ptr_t _d125=_pq(_pa(a)+0x228);if(!_k2(_d125))return 0;
ptr_t mc=_pq(_d125+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
if(m==_d116&&hostSklAt!=0)return hostSklAt;
_d116=m;hostSklAt=0;_d94=false;//new kart(model instances are pooled:a reused one can keep an open glider)
for(uint o=0;o<0x4000;o+=4){
ptr_t r=m+o;
if(abs(_pf(r+52)-0.3766f)<0.003f&&abs(_pf(r+48))<0.003f&&abs(_pf(r+56))<0.003f
&&abs(_pf(r+96+52)-0.5966f)<0.003f&&abs(_pf(r+96+56)-0.4928f)<0.003f){hostSklAt=r;_L("KART host Skl_Root record at +"+o);break;}
}
return hostSklAt;
}
void _d92(ActorBase@a){
float _d197=(a!is null&&_k19&&gliding)?1:0;
if(_d197==0&&_d93==0&&_d94)return;
if(a is null)return;
ptr_t _d169=_d115(a);if(_d169==0)return;
if(_d93<_d197){_d93+=0.17f;if(_d93>_d197)_d93=_d197;}
else if(_d93>_d197){_d93-=0.2f;if(_d93<_d197)_d93=_d197;}
ptr_t r=_d169-192;float sc=_d93;//Control=bone 1,two records before Skl_Root(bone 3)
_pw(r,sc);_pw(r+4,0);_pw(r+8,0);
_pw(r+16,0);_pw(r+20,sc);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,sc);
_pw(r+48,0);_pw(r+52,_d11);_pw(r+56,GLIDER_Z);
_d94=true;
}
const uint _d8=0x1085b5c;
bool _d75=false;
bool _d95(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d149(){
if(Player is null)return 0;ptr_t p=_pq(_pa(Player)+0x228);if(!_d95(p))return 0;
p=_pq(p+0x50);if(!_d95(p))return 0;p=_pq(p+0x20);return _d95(p)?p:0;
}
void _d74(){
if(!_k19&&!_d75)return;
ptr_t _d147=_d149();if(_d147==0)return;
ptr_call(sys::mainOffset()+_d8,_d147,_k19?0:1,0,0,0,0,0,0,0,0,0);
_d75=_k19;
}
const uint _d37=0x809ee0,SND_FADE=0xb226a4,PROP_SET=0x11acb98;
const int _d5=0,CH_SIZZLE=1,CH_DRIFT=2,CH_RUN=3,CH_SLIP=4,CH_FLUTTER=5,CH_SHOT=6;
const float _d38=1.0f/14.0f;//[chosen]top speed(14 m/s)=1=top of curve 213
const int _d40=1,S_DASH=2,S_IDLE=3,S_SIZZLE=4,S_DRIFT=7,S_FLUTTER=8,S_RUN=10,S_SLIP=20,S_LANDS=30;
const int _d41=40,S_ULTRA=41,S_HOP=42,S_LAND=43,S_TRICK=44,S_GOPEN=45,S_GCLOSE=46;
int _d173=0;int _d62=0,chKey1=0,chKey2=0,chKey3=0,chKey4=0,chKey5=0;
string _d195(int s){return s==0?"Grass":s==1?"Dirt":s==2?"Sand":s==3?"Snow":s==4?"Water":s==5?"Stone":"Wood";}
string _d122(int id){
if(id==_d40)return"Kart_Engine";if(id==S_DASH)return"Kart_EngineDash";if(id==S_IDLE)return"Kart_Idle";
if(id>=S_SIZZLE&&id<S_SIZZLE+3)return"Kart_Sizzle"+(id-S_SIZZLE+1);if(id==S_DRIFT)return"Kart_DriftSteer";
if(id==S_FLUTTER)return"Kart_GliderFlutter";if(id>=S_RUN&&id<S_RUN+7)return"Kart_Run_"+_d195(id-S_RUN);
if(id>=S_SLIP&&id<S_SLIP+7)return"Kart_Slip_"+_d195(id-S_SLIP);if(id>=S_LANDS&&id<S_LANDS+7)return"Kart_Land_"+_d195(id-S_LANDS);
if(id==_d41)return"Kart_MiniTurbo";if(id==S_ULTRA)return"Kart_UltraTurbo";if(id==S_HOP)return"Kart_Hop";if(id==S_LAND)return"Kart_Land";
if(id==S_TRICK)return"Kart_Trick";if(id==S_GOPEN)return"Kart_GliderOpen";if(id==S_GCLOSE)return"Kart_GliderClose";return"";
}
ptr_t _d180=0;int _d176=-1;bool _d181=false;
ptr_t _d178(){
ActorBase@a=_k7();if(a is null||!_d82())return 0;
ptr_t x=_pq(_pa(a)+0x228);if(!_d95(x))return 0;
x=_pq(x+0x68);if(!_d95(x))return 0;
ptr_t u=_pq(x+0x78);return _d95(u)?u:0;
}
void _d175(int id,int ch){
ptr_t u=_d178();if(u==0||id<=0)return;string _d121=_d122(id);
ptr_t k=fxScr+0x7800,h=fxScr+0x7880+8*ch;uint n=_d121.length();
for(uint w=0;w<4;w++){uint64 v=0;for(uint i=0;i<8;i++){uint c=w*8+i;if(c<n)v|=uint64(_d121[c])<<(8*i);}ptr_write_u64(k+8*w,v);}
ptr_write_u64(h,0xffff00ff);
ptr_call(_d79+_d37,u,k,h,0,0,0,0,0,0,0,0);
if(_d173<80){_d173++;_L("KART snd "+_d121+" h="+_pq(h));}
}
void _d171(int ch){if(fxScr==0)return;ptr_t h=fxScr+0x7880+8*ch;if(_pq(h)!=0xffff00ff)ptr_call(_d79+SND_FADE,h,0xffffffff,0,0,0,0,0,0,0,0,0);ptr_write_u64(h,0xffff00ff);}
int _d61(int ch){return ch==0?_d62:ch==1?chKey1:ch==2?chKey2:ch==3?chKey3:ch==4?chKey4:chKey5;}
void _d63(int ch,int k){if(ch==0)_d62=k;else if(ch==1)chKey1=k;else if(ch==2)chKey2=k;else if(ch==3)chKey3=k;else if(ch==4)chKey4=k;else chKey5=k;}
void _d174(int ch,int _d121){
if(_d61(ch)==_d121)return;
if(_d61(ch)!=0)_d171(ch);
if(_d121!=0)_d175(_d121,ch);
_d63(ch,_d121);
}
bool _d151(ptr_t x){
if(!_d95(x))return false;uint n=_pu(x+0x110);if(n==0||n>16)return false;
ptr_t _d136=_pq(x+0x118);if(!_d95(_d136))return false;
for(uint i=0;i<n;i++){ptr_t s=_pq(_d136+8*i);if(_d95(s)&&_d80(s,"ControlStick_StickSpeedXY")){_d176=int(i);return true;}}
return false;
}
void _d172(){
_d181=true;_d180=0;_d176=-1;
ActorBase@a=_k7();if(a is null)return;
ptr_t p=_pq(_pa(a)+0x228);if(!_d95(p))return;
p=_pq(p);if(!_d95(p))return;
p=_pq(p+0x10);if(!_d95(p))return;
if(_d151(p))_d180=p;
_L("KART snd prop X="+(_d180!=0)+" idx="+_d176+" n="+_pu(p+0x110));
}
void _d177(float ms){
if(_d180==0||_d176<0)return;
ptr_t f=fxScr+0x7a00;
_pw(f,abs(ms)*_d38);
ptr_call(_d79+PROP_SET,_d180,_d176,f,0,0,0,0,0,0,0,0);
}
int _d123=-2,lastSurface=-1;
bool _d130(int m,const string&in w){
ptr_t t=_pq(_d79+0x4637298);if(t==0||m<0||m>=54)return false;ptr_t s=_pq(t+0x250+8*m);if(!_d95(s))return false;
uint n=w.length();for(uint i=0;i<28;i++){if(ptr_deref_u8(s+i)==0)return false;bool ok=true;for(uint k=0;k<n&&ok;k++)if(ptr_deref_u8(s+i+k)!=w[k])ok=false;if(ok)return true;}
return false;
}
int _d196(){
if(_d104==_d123)return lastSurface;
_d123=_d104;int c=_d97(_d104);
lastSurface=c<0?-1:c==0?0:c==1?1:c==2?2:c==3?3:c==4?4:c==5?1:(_d130(_d104,"Wood")?6:5);
return lastSurface;
}
bool _d179=false,sndWasGlide=false;
void _d182(){
if(!_k19){
if(_d62!=0||chKey1!=0||chKey2!=0||chKey3!=0||chKey4!=0||chKey5!=0){for(int c=0;c<6;c++)_d174(c,0);}
_d181=false;_d179=false;sndWasGlide=false;return;
}
if(!_d181)_d172();
float sp=abs(_k18);_d177(sp);
_d174(_d5,gliding?0:boostLeft>0?S_DASH:sp<0.6f?S_IDLE:_d40);
_d174(CH_SIZZLE,(_d69!=0&&driftTier>0&&!gliding)?S_SIZZLE+driftTier-1:0);
int _d194=(_d50||gliding)?-1:_d196();
_d174(CH_DRIFT,(_d69!=0&&!_d50&&!gliding)?S_DRIFT:0);
_d174(CH_RUN,(_d194>=0&&sp>1.0f&&_d69==0)?S_RUN+_d194:0);
_d174(CH_SLIP,(_d194>=0&&_d69!=0)?S_SLIP+_d194:0);
_d174(CH_FLUTTER,gliding?S_FLUTTER:0);
if(sndWasGlide&&!gliding)_d175(S_GCLOSE,CH_SHOT);
if(_d179&&!_d50){_d175(S_LAND,CH_SHOT);int s2=_d196();if(s2>=0)_d175(S_LANDS+s2,CH_SHOT+1);}
_d179=_d50;sndWasGlide=gliding;
}
const bool _d19=true;
const float _d1=6.2f,CAM_HEIGHT=2.4f,CAM_LOOK_AHEAD=1.6f,CAM_LOOK_UP=1.2f,CAM_DRIFT_SWING=0.16f;
const float _d2=7.6f,CAM_GLIDE_HEIGHT=4.4f,CAM_BOOST_BACK=0.8f,CAM_KICK=0.7f,CAM_BRAKE_IN=0.5f;
bool _d133=_d19,mkCamChordLatched=true,camFrozen=false,camInit=false,camBraking=false;
float _d56=0,camFz=1,camHx=0,camHz=1,camDist=_d1,camH=CAM_HEIGHT,camY=0,camKick=0,camLook=0;int _d57=0;
void _d59(){if(camFrozen){camera::toggleFreeze();camFrozen=false;}camInit=false;}
void _d60(ActorBase@a,int rx){
if(!_d133||a is null||!_k19){_d59();return;}
float sp=abs(_k18);
if(boostLeft>_d57+5)camKick=1;_d57=boostLeft;camKick*=0.88f;
float tx=_d56,tz=camFz;
if(_d69!=0){float c=cos(-_d69*CAM_DRIFT_SWING),s2=sin(-_d69*CAM_DRIFT_SWING);float nx=tx*c+tz*s2,nz=-tx*s2+tz*c;tx=nx;tz=nz;}
if(!camInit){camHx=tx;camHz=tz;camY=a.pos_y;camDist=_d1;camH=CAM_HEIGHT;}
float _d156=gliding?0.06f:_d50?0.05f:0.13f;
camHx+=(tx-camHx)*_d156;camHz+=(tz-camHz)*_d156;float hl=sqrt(camHx*camHx+camHz*camHz);if(hl<0.01f){camHx=tx;camHz=tz;hl=1;}camHx/=hl;camHz/=hl;
float _d126=float(rx)/32768.0f;if(abs(_d126)<0.2f)_d126=0;camLook+=(_d126*1.8f-camLook)*0.15f;
float lc=cos(camLook),ls=sin(camLook),dx=camHx*lc+camHz*ls,dz=-camHx*ls+camHz*lc;
float _d68=gliding?_d2:_d1+sp*0.035f+(boostLeft>0?CAM_BOOST_BACK:0)-(camBraking?CAM_BRAKE_IN:0);
_d68+=camKick*CAM_KICK;
float h=gliding?CAM_GLIDE_HEIGHT:CAM_HEIGHT+sp*0.01f;
camDist+=(_d68-camDist)*(camKick>0.5f?0.3f:0.1f);camH+=(h-camH)*0.08f;
camY+=(a.pos_y-camY)*((_d50||gliding)?0.12f:0.35f);
double px=a.pos_x-dx*camDist,py=camY+camH,pz=a.pos_z-dz*camDist;
double ax=a.pos_x+dx*CAM_LOOK_AHEAD,ay=camY+(gliding?0.4f:CAM_LOOK_UP),az=a.pos_z+dz*CAM_LOOK_AHEAD;
camera::freeze(0,1,0,px,py,pz,ax,ay,az);camFrozen=true;camInit=true;
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
_L("KART ready");
}
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool _d144=false,exitLatch=false;uint64 _d141=0;int _d142=0,outLY=0,outRX=0,outRY=0;
bool _d165=false;uint64 _d166=0;int _d167=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d145){
uint64 _d110=_d165?_d166:_pq(_d145);
int lx=_d165?_d167:_ps(_d145+8),ly=_d165?simLY:_ps(_d145+12);
int rx=_d165?simRX:_ps(_d145+16),ry=_d165?simRY:_ps(_d145+20);
_d144=false;_d141=_d110;_d142=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
_d59();
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 _d127=uint64(ZL|ZR|DUP);
if((_d110&_d127)==0)_k24=false;
if(!_k24&&(_d110&_d127)==_d127){_k24=true;_k25=true;_L("KART spawn queued");}
uint64 _d58=uint64(ZL|ZR|DLEFT);
if((_d110&_d58)==0)mkCamChordLatched=false;
if(!mkCamChordLatched&&(_d110&_d58)==_d58){
mkCamChordLatched=true;_d133=!_d133;_L("KART mkcam="+_d133);
_T(90,_d133?"Mario Kart camera: ON\n":"Mario Kart camera: OFF\n");
}
uint64 _d137=uint64(ZL|ZR|DDOWN);
if((_d110&_d137)==0)offroadChordLatched=false;
if(!offroadChordLatched&&(_d110&_d137)==_d137){
offroadChordLatched=true;_d139=!_d139;_L("KART offroad="+_d139);
_T(90,_d139?"Off-road handling: ON\n":"Off-road handling: OFF\n");
}
if(!_k3()||_d132()){_d59();return;}
if(_k25&&(_d110&_d127)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d110);
_d51(_k7());
_d184(_k7());
_d92(_k7());
_d74();
_d101(_k7());
_d182();
_d60(_k7(),rx);
uint64 _d71=uint64(A|B|X|Y|R|ZR);
if(_k19){
_d144=true;_d141=_d110&~_d71;
_d142=0;outLY=0;//the vanilla control stick tilts the contraption with the left stick in the air;this controller steers
if((_d110&uint64(X))!=0){_d141|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d110&uint64(X))==0)exitLatch=false;
else{_d144=true;_d141=_d110&~uint64(X);}//do not let the _d110 X make Link jump
}
}
void _d208(){
if(_d144)input(1,_d141,_d142,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d145){while(true){_k5(_d145);_d208();}}
void _d90(uint f){
if(f%75!=0)return;uint k=f/75;
string n=k==0?"Ply_SlipSmoke_Grass_Green":k==1?"ReFX_Grass_M":k==2?"HorseStep_Grass_Tmp":k==3?"Ply_FootEffect_Grass_Green":"ReFX_Grass_L";
_d100=n;_d91=-2;_d107();_d106=-1;
_L("GRASS "+n);
}
void _d108(){ptr_t e=fxScr==0?0:_d78(3);if(e==0){_L("GSTATE none");return;}
_L("GSTATE e8="+ptr_deref_s16(e+0xe8)+" f38="+_pu(e+0x38)+" 4c="+_pf(e+0x4c)+" 5c="+_pf(e+0x5c)+" 24c="+_pf(e+0x24c)+" 250="+_pf(e+0x250)+" 254="+_pf(e+0x254)+" 25c="+_pf(e+0x25c)+" 260="+_pf(e+0x260));}
ptr_t tp=0;
void _d72(uint64 k,int x,int y,int rx){
_d165=true;_d166=k;_d167=x;simLY=y;simRX=rx;simRY=0;_k5(tp);
if(_d144)input(1,_d141,_d142,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
string _d129(int i){if(i<0||i>=54)return"?";ptr_t t=_pq(sys::mainOffset()+0x4637298);if(t==0)return"?";ptr_t s=_pq(t+0x250+8*i);string r="";for(int k=0;k<32&&s!=0;k++){u8 c=ptr_deref_u8(s+k);if(c==0)break;r+=" ";r[r.length()-1]=c;}return r;}
bool _d150(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d103(ActorBase@a){if(a is null)return 0;ptr_t p=_pq(_pa(a)+0x228);if(!_d150(p))return 0;p=_pq(p+0x50);if(!_d150(p))return 0;
p=_pq(p+0x20);if(!_d150(p))return 0;p=_pq(p+0x10);if(!_d150(p))return 0;p=_pq(p+8);if(!_d150(p))return 0;p=_pq(p+0x20);if(!_d150(p))return 0;return p+0x20;}
string _d131(ActorBase@a){ptr_t g=_d103(a);if(g==0)return"none";int m=_ps(g+0x78);return""+m+":"+_d129(m)+" f="+ptr_deref_u8(g+0x110)+","+ptr_deref_u8(g+0x111);}
string _d64(ActorBase@a){if(a is null)return"null";string r="";ptr_t p=_pa(a);
for(uint i=0;i<6;i++){uint o=i==0?0x228:i==1?0x50:i==2?0x20:i==3?0x10:i==4?8:0x20;p=_pq(p+o);r+=" "+formatInt(int64(p),"H");if(!_d150(p))break;}return r;}
string _d157(float x,float y,float z){
if(!_d82())return"nofx";
ptr_t q=fxScr+0x5000,v=fxScr+0x5100,p1=fxScr+0x5200,p2=fxScr+0x5300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d79+0x4578958);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);
_pw(v+4,3.0f);ptr_write_u64(q+0x38,v+4);
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d79+0x20e4da4,q,0,0,0,0,0,0,0,0,0,0);
int m=_ps(v+0x40);
return"hit="+ptr_deref_u8(v+0x10)+" d="+_pf(v+0x14)+" f58="+_pf(v+0x18)+" n="+_pf(v+0x20)+","+_pf(v+0x24)+","+_pf(v+0x28)+" m="+m+":"+_d129(m)+" b="+ptr_deref_u8(v+0x44);
}
void _d128(const string&in l){ActorBase@k=_k7();
_L("MAT "+l+" player="+_d131(Player)+" rayP="+_d157(Player.pos_x,Player.pos_y+0.5f,Player.pos_z)+(k is null?"":" rayK="+_d157(k.pos_x,k.pos_y+0.2f,k.pos_z)));}
void _d189(const string&in l){_d108();ActorBase@a=_k7();_L("SPK "+l+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+_k18+" tier="+driftTier+" charge="+driftCharge+" boost="+boostLeft+" live0="+(fxScr!=0&&_d78(0)!=0)+" live1="+(fxScr!=0&&_d78(1)!=0)+" ground="+_d104+"/"+_d106+" d="+_d98+" cam="+camFrozen+" ch="+camHx+","+camHz+" f="+_d56+","+camFz+" d="+camDist+" mounted="+_k15(a));}
void main(){
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
_d128("start");input(30,0);_d128("start2");
Player.setPos(-150,127.8,-62);input(90,0);for(uint w=0;w<200&&!(_k3()&&abs(Player.pos_x+150)<20);w++)input(10,0);input(60,0);if(!_k3())return;
_d128("field");
_k5(tp);_d72(uint64(ZL|ZR|DUP),0,0,0);
for(uint f=0;f<25;f++)_d72(0,0,0,0);
for(uint t=0;t<10&&!_k15(_k7());t++){
ActorBase@k=_k7();if(k is null){input(10,0);continue;}
Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,k.pos_y+0.3f,pz);input(20,0);
_L("SPK try mount t="+t+" kart="+k.pos_x+","+k.pos_z+" player="+Player.pos_x+","+Player.pos_z);
input(1,1);input(30,0);
}
if(!_k15(_k7())){_L("SPK mount failed");return;}
_d72(0,0,0,0);
for(uint f=0;f<60&&_k3();f++){_d72(uint64(A),0,0,0);if(f%30==0)_d189("run"+f);}
ActorBase@k=_k7();float y0=k.pos_y;
for(uint f=0;f<90&&_k3();f++){@k=_k7();Vector3f lv=k.getMainRigidBody().vel;k.getMainRigidBody().setVel(lv.x,60.0f,lv.z);_d72(uint64(A),0,0,0);}
for(uint f=0;f<150&&_k3();f++){_d72(uint64(A),0,0,0);@k=_k7();if(k.getMainRigidBody().vel.y<2)break;}
_d72(uint64(A|Y),0,0,0);_d72(uint64(A),0,0,0);
for(uint f=0;f<1800&&_k3();f++){
_d72(uint64(A),0,0,0);@k=_k7();
if(f%15==0||!_k15(k))_L("HI f="+f+" h="+(k.pos_y-y0)+" vy="+k.getMainRigidBody().vel.y+" pvy="+Player.getMainRigidBody().vel.y+" py="+(Player.pos_y-y0)+" glide="+gliding+" air="+_d50+" ride="+_k15(k));
if(!_k15(k)||(!_d50&&f>30))break;
}
_L("SPK finished");_d165=false;input(1,0);_k11(tp);
}
