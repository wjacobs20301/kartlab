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
bool _k20=false;float _d144=0,_w15=0;
float _d187=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d108=false;
const float _d30=7.775f;//[table]PRSL ground top speed,0 coins
const float _d22=0.011f;//[table]PRAC strength(G)
const float _d21=0.09f;//[table]PRAC limiter(M)
const float _d31=0.0118f;//[table]PRTL _d186,rad per MK frame
const float _d27=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d25=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d32=0.75f;//[table]PRON road traction
const float _d35=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d34=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d78)
const uint _d45=153;//[chosen]ultra _d125(not in the table):SMT+(SMT-MT)
const float _d5=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d33=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d29=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d24=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d26=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d28=0.993f;//[chosen]decay above _d192(after a boost)
const float _d23=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d16=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d7=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d188 0.001
const float _d8=0.8f;//[native]drift _d186 _d185 _w12,approached at 10%/frame,_d188<=0.07
const float _d4=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d120>=0.71 else 2
const float _d19=3.0f;//[chosen]drift _d112,m/s upward
const float _d1=0.3f,AIR_GAP=0.7f;const int _d44=8,TRICK_FRAMES=31;//trick:also R up to 6 _d78 before take-off
const float _d14=0.95f;//[measured]TOTK pulls the kart down~0.95 m/s per frame;added back so the glide _d164 settles at _d192
const float _d15=8.225f,GLIDE_SINK=1.6f,GLIDE_DIVE=4.5f,GLIDE_FLOAT=0.6f,GLIDE_STEER=0.6f,GLIDE_MIN_HEIGHT=2.5f;
const float _d0=9.0f;
const float _d13=0.55f,GLIDE_PITCH=0.35f,GLIDE_TILT_GAIN=4.0f,GLIDE_MAX_LEAN=0.65f;//[chosen]~29 deg _d53,~19 deg nose-down,~33 deg combined max
bool _d51=false,trickDone=false,gliding=false,gliderLatch=true;int _d50=0,groundFrames=0,trickWindow=0,rPressAge=99;
const bool _d36=false;
const float _d37=0.7f,OFFROAD_HEAVY=0.5f;//[table]PROF
bool _d137=_d36,offroadChordLatched=true;
float _d132=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d71=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d113=false,gasLatch=true,idleHold=false;
bool _d130(){return pause::isPauseRequest("GamePause")||pause::isPauseRequest("PreGamePause")||pause::isPauseRequest("PostGamePause")||pause::isPauseTarget("Custom_PhysicsUpdateWorld");}
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d111=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d111==0)return 0;
uint op=_pu(_d111);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d69=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d69-=0x04000000;
ptr_t _d192=ptr_t(int64(_d111)+_d69*4);
if(_pu(_d192)!=0xf0001382||_pu(_d192+4)!=0xa9be7bfd)return 0;
ptr_t _d54=_d192-0x65b80;if((_d54&0xfff)!=0)return 0;return _d54+0x3d90b8;
}
void _k13(){_d94=0;_d95=false;ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d155();_k19=false;_k20=false;_d144=0;_w15=0;_d108=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d185=_pu(_k16+0x24);if(_d185<2||_d185>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d114,uint _k27){
if(_d114 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d114);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d185=_pu(p+0x24);
return _d185>=2&&_d185<=6;
}
bool _k0(ActorBase@_d114,uint _k27){
if(Player is null||!_k1(_d114,_k27))return false;
ptr_t _d47=_pa(_d114),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d68=_pu(_d47+0x220);ptr_t _d126=_pq(_d47+0x228);
if(_d68<=129||_d68>512||!_k2(_d126))return false;
ptr_t _d67=_pq(_d126+0x408);
if(!_k2(_d67))return false;
uint _d159=_pu(_d67+0x20);ptr_t _k29=_pq(_d67+0x28);
if(_d159!=1||!_k2(_k29))return false;
ptr_t _d157=_pq(_k29);
if(!_k2(_d157))return false;
uint _d158=_pu(_d157+0x10),flags=_pu(_d157+0x18);
float _k33=_pf(_d157+0x74);
if(_d158!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d157+8),_k28=_pq(_w22+0x1a8);
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
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d144=a.pos_x;_w15=a.pos_z;return;}
float dx=_d144-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d144=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@_d138=_k7();
if(_k15(_d138)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d125=sqrt(fx*fx+fz*fz);if(_d125<0.1f)return;fx/=_d125;fz/=_d125;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d138!is null){_k10(_d138);_d138.setPos(x,y,z);@_d138=null;_d144=0;_w15=0;_d108=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);_k17=_pu(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d144=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d199(ActorBase@a){
ptr_t _d126=_pq(_pa(a)+0x228);if(!_k2(_d126))return 0;
ptr_t mc=_pq(_d126+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(_pf(b+120)-0.728f)>0.002f||abs(_pf(b+216)+0.728f)>0.002f||abs(_pf(b+312)-0.7776f)>0.002f||abs(_pf(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _d200(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
const float _d43=0.3927f;//2*pi/16 tread _d55
float _d197(float _d188){
float m=abs(_d188),half=_d43*0.5f;
if(m<=half*0.9f)return _d188;
float _d55=floor((m-half)/_d43);if(_d55>3)_d55=3;
float v=(_d55+0.5f)*_d43;return _d188<0?-v:v;
}
void _d52(ActorBase@a){
if(a is null){_d108=false;return;}
Matrix33f r=a.rot;float _d125=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d108&&_d125>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d125;}
_w4=x;_w5=z;_d108=true;
_w2+=_d197(ds/0.28328f);_w3+=_d197(ds/0.3683f);
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d187*0.45f-_w1)*0.25f;
ptr_t b=_d199(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d200(b+72,sf,cf,sd,cd);_d200(b+168,sf,cf,sd,cd);
_d200(b+264,sr,cr,0,1);_d200(b+360,sr,cr,0,1);
}
void _d155(){_d51=false;trickDone=false;gliding=false;_d50=0;groundFrames=0;trickWindow=0;_d132=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d71=0;driftTier=0;boostLeft=0;hopWindow=0;_d113=false;gasLatch=true;idleHold=false;}
int _d104=-1;float _d99=99;//updated by _d102(ray cast under the kart)
float _d193(){
if(!_d137||_d99>=0.8f)return 1;
int m=_d104;
if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;//HeavySand,HeavySnow,Bog,Tar,Water,ContaminatedWater
if(m==1||m==2||m==3||m==5)return _d37;//Soil,Grass,Sand,Snow
return 1;
}
float _d184(float v,float _d194){
if(boostLeft>0){
boostLeft--;float t=_d30*_d35;
if(v<t){float _d117=(t-v)*_d23;if(_d117>MK_BOOST_CAP)_d117=MK_BOOST_CAP;return v+_d117;}
return t;
}
if(_d194>0){
if(v<0)return v+_d24>0?0:v+_d24;//stop reversing first
float t=_d30*_d194*_d193();
if(v<t){float _d117=(t-v)*_d22;if(_d117>_d21)_d117=_d21;return v+_d117;}//[native]form
float d=v*_d28;return d<t?t:d;
}
if(_d194<0){
if(v>0)return v-_d24<0?0:v-_d24;//brake,then reverse
float t=-_d29*(-_d194);
if(v>t){float _d117=(v-t)*_d22;if(_d117>_d21)_d117=_d21;return v-_d117;}
return v;
}
if(v>0)return v-_d26<0?0:v-_d26;
return v+_d26>0?0:v+_d26;
}
void _d72(int _d195){
_L("KART drift tier="+_d195+" charge="+driftCharge);
if(_d195==1)_T(30,"Mini-Turbo\n");else if(_d195==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d109){
_d187=0;
ActorBase@a=_k7();bool _d156=_k15(a);
if(_d156!=_k19){_L("KART mounted="+_d156);_d155();_k19=_d156;_k20=!_d156;if(a!is null){_d144=a.pos_x;_w15=a.pos_z;}}
if(!_d156||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d155();return;}
float _d186=float(ix)/32768.0f,_d194=0;
if(abs(_d186)<0.15f)_d186=0;
bool _d91=(_d109&uint64(A))!=0,brake=(_d109&uint64(B))!=0;
if(!_d91)gasLatch=false;//the A press used to get in must be released first
if(brake)_d194=-1;else if(_d91&&!gasLatch)_d194=1;
_d187=_d186;
Matrix33f r=a.rot;float _d125=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d125<0.1f||r.a4<0.4f){_k10(a);_d155();return;}
float bx=r.a2/_d125,bz=r.a8/_d125,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
_d57=fx;camFz=fz;camBraking=brake&&_d132>0.5f;
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d48=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d49=_d48/_d33;
if(_d132>0&&_d132>_d49+0.6f)_d132=_d49+0.6f<0?0:_d49+0.6f;
if(_d132<0&&_d132<_d49-0.6f)_d132=_d49-0.6f>0?0:_d49-0.6f;
bool _d152=(_d109&uint64(R|ZR))!=0,fast=_d132>_d30*0.35f;
if(_d84())_d105(a.pos_x,a.pos_y+0.2f,a.pos_z);
bool _d141=_d99<AIR_GAP;
if(_d141){groundFrames++;_d50=0;}else{_d50++;groundFrames=0;}
bool _d198=_d51;
bool _d151=_d152&&!_d113;rPressAge=_d151?0:rPressAge+1;
if(!_d51&&_d50>=2){
_d51=true;trickWindow=_d44;trickDone=false;_L("KART airborne");
if(rPressAge<=6+_d50){trickDone=true;_d171(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick (buffered)");}
}
if(_d51&&groundFrames>=1){
_d51=false;
if(gliding){gliding=false;_L("KART glider landed");}
if(trickDone){if(boostLeft<TRICK_FRAMES)boostLeft=TRICK_FRAMES;_d171(_d42,CH_SHOT);_L("KART trick boost");}
trickDone=false;_L("KART landed");
}
float _d112=0;
bool _d150=_d152&&!_d113;
if(_d51){
if(trickWindow>0){trickWindow--;if(_d150&&!trickDone){trickDone=true;_d171(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick");}}
}else if(_d150&&fast){_d112=_d19;hopWindow=24;_d171(S_HOP,CH_SHOT);}
_d113=_d152;
bool _d201=(_d109&uint64(Y))!=0;
if(!_d201)gliderLatch=false;
if(_d201&&!gliderLatch){
gliderLatch=true;
if(gliding){gliding=false;_L("KART glider folded");}
else if(_d51&&_d99>=GLIDE_MIN_HEIGHT){gliding=true;_d171(S_GOPEN,CH_SHOT);_d71=0;driftCharge=0;driftTier=0;_T(30,"Glider!\n");_L("KART glider open");}
}
if(_d71==0&&!_d51&&_d152&&hopWindow>0&&abs(_d186)>0.3f){_d71=_d186>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d71);}
if(_d71!=0&&(!_d152||!fast)){
int _d78=driftTier==3?int(_d45):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d34):0;
if(_d78>0&&_d152==false){boostLeft=_d78;_d171(driftTier==3?S_ULTRA:_d42,CH_SHOT);_L("KART boost tier="+driftTier+" frames="+_d78);}
_d71=0;driftCharge=0;driftTier=0;
}
if(!_d51&&_d194==0&&boostLeft==0&&_d71==0&&_d112==0&&abs(_d132)<_d26){
_d132=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d144=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d202=0,oldOff=bodyOff;
for(int _d188=0;_d188<2;_d188++){
if(hopWindow>0)hopWindow--;
if(gliding){float t=_d15*(iy>16000?1.06f:1.0f);_d132+=(t-_d132)*0.02f;}
else if(!_d51||boostLeft>0)_d132=_d184(_d132,_d194);
float _d56=0;
if(gliding){
driftTrack=0;_d202+=_d186*_d31*GLIDE_STEER;
}else if(_d71!=0){
float _d120=_d186*_d71;if(_d120>1)_d120=1;if(_d120<-1)_d120=-1;
float _d196=_d120>=0?_d8:-_d8,dt=(_d196-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d119=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d202+=_d71*_d27*_d119*_d119*(0.75f+0.25f*_d120);
if(!_d51)driftCharge+=_d120>=CHARGE_INWARD?_d4:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d195=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d5?1:0;
if(_d195>driftTier){driftTier=_d195;_d72(_d195);}
_d56=_d71*_d7;
}else{
driftTrack=0;
float _d182=abs(_d132)/(_d30*0.25f);if(_d182>1)_d182=1;
_d202+=_d186*_d31*_d182*(_d132<0?-1.0f:1.0f)*(_d51?_d1:1.0f);
}
float _d90=_d56-bodyOff,ds=_d90*0.07f;
if(abs(ds)<0.001f)ds=abs(_d90)<0.001f?_d90:(_d90>0?0.001f:-0.001f);
bodyOff+=ds;
if(!_d51)lateral*=1-_d16*_d32;
}
_k18=_d132*_d33;
float _d183=_k18;
float vy=v.y+_d112;
if(gliding){
float _d164=iy>16000?GLIDE_DIVE:iy<-16000?GLIDE_FLOAT:GLIDE_SINK;//stick forward dives,back floats
vy+=(-_d164-vy)*0.3f+_d14;//ease into the glide descent(gravity compensated)
}
if(gliding&&vy<-_d0)vy=-_d0;//glider only(user:free fall must stay normal speed)
b.setVel(fx*_d183+lx*lateral,vy,fz*_d183+lz*lateral);
float tx=0,ty=1,tz=0,gain=2.0f;
if(gliding){
float _d146=float(iy)/32768.0f;if(_d146>1)_d146=1;if(_d146<-1)_d146=-1;
float _d53=_d186*_d13,nose=_d146*GLIDE_PITCH;//stick right:right side down;stick forward:nose down
tx=-lx*_d53+fx*nose;tz=-lz*_d53+fz*nose;
float _d110=sqrt(tx*tx+tz*tz);if(_d110>GLIDE_MAX_LEAN){tx*=GLIDE_MAX_LEAN/_d110;tz*=GLIDE_MAX_LEAN/_d110;}
ty=1;float tl=sqrt(tx*tx+ty*ty+tz*tz);tx/=tl;ty/=tl;tz/=tl;gain=GLIDE_TILT_GAIN;
}
float ux=r.a1,uy=r.a4,uz=r.a7;
float wx=(uy*tz-uz*ty)*gain,wz=(ux*ty-uy*tx)*gain;//world axes(a body-axis version flipped the kart)
b.setAngularVel(wx,-(_d202+bodyOff-oldOff)*30.0f,wz);
}
const uint _d11=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float _d40=0.35f,FLAME_SCALE=0.15f;//[chosen]from screenshots
ptr_t _d81=0,fxSys=0,fxScr=0;int _d85=-2,fxFlame=-1;
bool _d82(ptr_t p,const string&in _d133){
uint n=_d133.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=_d133[i])return false;
return ptr_deref_u8(p+n)==0;
}
int _d79(const string&in _d133){
ptr_t _d154=_pq(_pq(fxSys+0x2ee8)+8);if(_d154==0||ptr_deref_u8(_d154+0x571)==0)return-1;//static effects=resource 1
int n=_ps(_d154+0x558);ptr_t _d160=_pq(_d154+0x430);
for(int i=0;i<n;i++)if(_d82(_pq(_d160+0x28*i)+0x10,_d133))return i;
return-1;
}
bool _d84(){
if(_d85>=0)return true;
if(_d85==-1)return false;//looked once and failed:stay off
_d85=-1;
ptr_t _d111=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d111==0)return false;
uint op=_pu(_d111);int64 _d69=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d69-=0x04000000;
ptr_t _d192=ptr_t(int64(_d111)+_d69*4),_d54=_d192-0x65b80;
if((_d54&0xfff)!=0||_pu(_d192)!=0xf0001382)return false;
fxScr=_d54+FX_SCRATCH;_d81=sys::mainOffset();
ptr_t _d118=_pq(_pq(_d81+_d11));if(_d118==0)return false;
fxSys=_pq(_d118+0x11b8);if(fxSys==0)return false;
int _d179=_d79("Ply_ShockWave_Spark");fxFlame=_d79("Chm_FlameThrower_ScraBuild");//Zonai _d75 emitter jet
_L("KART fx spark="+_d179+" flame="+fxFlame);
if(_d179<0)return false;
_d85=_d179;return true;
}
ptr_t _d80(int _d166){ptr_t h=fxScr+0x10*_d166,e=_pq(h);if(e==0)return 0;return _pu(e+0x234)==_pu(h+8)?e:0;}
ptr_t _d86(int _d166,int id){
ptr_t e=_d80(_d166);if(e!=0)return e;
ptr_t h=fxScr+0x10*_d166;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d81+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*_d166,0,0,0,0,0);
return _d80(_d166);
}
void _d88(int _d166){if(fxScr==0)return;ptr_t e=_d80(_d166);if(e!=0)ptr_call(_d81+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*_d166,0);}
void _d83(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
_pw(m,r.a0);_pw(m+4,r.a1);_pw(m+8,r.a2);_pw(m+12,px);
_pw(m+16,r.a3);_pw(m+20,r.a4);_pw(m+24,r.a5);_pw(m+28,py);
_pw(m+32,r.a6);_pw(m+36,r.a7);_pw(m+40,r.a8);_pw(m+44,pz);
_pw(fxScr+0x140,s);_pw(fxScr+0x144,s);_pw(fxScr+0x148,s);
ptr_call(_d81+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
void _d89(ptr_t e,float r,float g,float b){_pw(e+0x40,r);_pw(e+0x44,g);_pw(e+0x48,b);}
void _d180(ActorBase@a){
bool _d181=a!is null&&_k19&&_d71!=0&&driftTier>0;
bool _d75=a!is null&&_k19&&boostLeft>0;
if(!_d181&&!_d75&&fxScr==0)return;
if(!_d84()){return;}
if(!_d181)_d88(0);
if(!_d75||fxFlame<0)_d88(1);
if(_d181){
ptr_t e=_d86(0,_d85);
if(e!=0){
if(driftTier==1)_d89(e,0.25f,0.8f,6.0f);else if(driftTier==2)_d89(e,1.0f,1.0f,1.0f);else _d89(e,2.2f,0.4f,6.0f);
ptr_t b=_d199(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(_pf(b+312));wy=_pf(b+28)+_pf(b+316)-0.3683f;wz=_pf(b+32)+_pf(b+320);}
_d83(e,a,wx,wy,wz,_d40);_d83(e,a,-wx,wy,wz,_d40);
}
}
if(_d75&&fxFlame>=0){ptr_t e=_d86(1,fxFlame);if(e!=0){_d83(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);_d83(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
const uint _d10=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int _d106=-1,groundTick=0;
int _d92=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;//effect ids per class,looked up once(no arrays in this runtime)
bool _d105(float x,float y,float z){
ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d81+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);//flags:all false
_pw(v+4,2.0f);ptr_write_u64(q+0x38,v+4);//ray _d125(m)
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d81+_d10,q,0,0,0,0,0,0,0,0,0,0);
if(ptr_deref_u8(v+0x10)==0){_d104=-1;_d99=99;return false;}
_d104=_ps(v+0x40);_d99=_pf(v+0x14);return true;
}
int _d98(int m){
if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return-1;return 6;
}
string _d101="";//diagnostics only:overrides the grass effect _d133
string _d100(int c){
if(c==0&&_d101!="")return _d101;
if(c==0)return"ReFX_Grass_L";if(c==1||c==2)return"ReFX_Sand_L";if(c==3)return"ReFX_Snow_L";
if(c==4)return"Water_Splash01_Move";if(c==5)return"RctFld_Mud_Splash_S";return"Ply_SlipSmoke_Stone";
}
int _d103(int c){
if(c==0){if(_d92==-2)_d92=_d79(_d100(0));return _d92;}if(c==1){if(gid1==-2)gid1=_d79(_d100(1));return gid1;}
if(c==2){if(gid2==-2)gid2=_d79(_d100(2));return gid2;}if(c==3){if(gid3==-2)gid3=_d79(_d100(3));return gid3;}
if(c==4){if(gid4==-2)gid4=_d79(_d100(4));return gid4;}if(c==5){if(gid5==-2)gid5=_d79(_d100(5));return gid5;}
if(gid6==-2)gid6=_d79(_d100(6));return gid6;
}
const float _d18=1.2f,GROUND_MIN_SPEED=3.0f;//[chosen]
const int _d17=6;//[chosen]_d78 between bursts:TOTK's ground effects are one-shot(per footstep/hoof)
int _d97=0,groundBurstSlot=0;
void _d107(){if(fxScr==0)return;for(int k=3;k<7;k++)_d88(k);}
ptr_t _d87(int _d166,int id,ptr_t _d149){
ptr_t h=fxScr+0x10*_d166;_d88(_d166);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d81+FX_CREATE,fxSys,h,id,1,0,_d149,0,0,0,0,0);
return _d80(_d166);
}
void _d102(ActorBase@a){
bool _d46=a!is null&&_k19&&_d84();
if(!_d46){_d107();_d106=-1;return;}
int c=_d99<0.8f?_d98(_d104):-1;
bool _d136=c>=0&&c<6,show=c>=0&&abs(_k18)>GROUND_MIN_SPEED&&(_d136||_d71!=0);
_d106=show?c:-1;
if(!show){_d97=0;return;}
if(_d97-->0)return;
_d97=_d17;
int id=_d103(c);if(id<0)return;
int _d166=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
ptr_t e=_d87(_d166,id,fxScr+0x5000);if(e==0)return;
float wx=0.78f,wz=-0.75f;ptr_t b=_d199(a);if(b!=0){wx=abs(_pf(b+312));wz=_pf(b+32)+_pf(b+320);}
_d83(e,a,wx,0,wz,_d18);_d83(e,a,-wx,0,wz,_d18);
}
const float _d12=-0.15f,GLIDER_Z=-0.45f;//[chosen]attach point in kart space(glider frame _d54)
float _d94=0;bool _d95=false;
ptr_t _d116=0,hostSklAt=0;
ptr_t _d115(ActorBase@a){
ptr_t _d126=_pq(_pa(a)+0x228);if(!_k2(_d126))return 0;
ptr_t mc=_pq(_d126+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
if(m==_d116&&hostSklAt!=0)return hostSklAt;
_d116=m;hostSklAt=0;_d95=false;//new kart(model instances are pooled:a reused one can _d121 an open glider)
for(uint o=0;o<0x4000;o+=4){
ptr_t r=m+o;
if(abs(_pf(r+52)-0.3766f)<0.003f&&abs(_pf(r+48))<0.003f&&abs(_pf(r+56))<0.003f
&&abs(_pf(r+96+52)-0.5966f)<0.003f&&abs(_pf(r+96+56)-0.4928f)<0.003f){hostSklAt=r;_L("KART host Skl_Root record at +"+o);break;}
}
return hostSklAt;
}
void _d93(ActorBase@a){
float _d192=(a!is null&&_k19&&gliding)?1:0;
if(_d192==0&&_d94==0&&_d95)return;
if(a is null)return;
ptr_t _d165=_d115(a);if(_d165==0)return;
if(_d94<_d192){_d94+=0.17f;if(_d94>_d192)_d94=_d192;}
else if(_d94>_d192){_d94-=0.2f;if(_d94<_d192)_d94=_d192;}
ptr_t r=_d165-192;float sc=_d94;//Control=bone 1,two records before Skl_Root(bone 3)
_pw(r,sc);_pw(r+4,0);_pw(r+8,0);
_pw(r+16,0);_pw(r+20,sc);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,sc);
_pw(r+48,0);_pw(r+52,_d12);_pw(r+56,GLIDER_Z);
_d95=true;
}
const uint _d9=0x1085b5c;
bool _d77=false;
bool _d96(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d147(){
if(Player is null)return 0;ptr_t p=_pq(_pa(Player)+0x228);if(!_d96(p))return 0;
p=_pq(p+0x50);if(!_d96(p))return 0;p=_pq(p+0x20);return _d96(p)?p:0;
}
void _d76(){
if(!_k19&&!_d77)return;
ptr_t _d145=_d147();if(_d145==0)return;
ptr_call(sys::mainOffset()+_d9,_d145,_k19?0:1,0,0,0,0,0,0,0,0,0);
_d77=_k19;
}
const uint _d38=0x809ee0,SND_FADE=0xb226a4,PROP_SET=0x11acb98;
const int _d6=0,CH_SIZZLE=1,CH_DRIFT=2,CH_RUN=3,CH_SLIP=4,CH_FLUTTER=5,CH_SHOT=6;
const float _d39=1.0f/14.0f;//[chosen]top speed(14 m/s)=1=top of curve 213
const int _d41=1,S_DASH=2,S_IDLE=3,S_SIZZLE=4,S_DRIFT=7,S_FLUTTER=8,S_RUN=10,S_SLIP=20,S_LANDS=30;
const int _d42=40,S_ULTRA=41,S_HOP=42,S_LAND=43,S_TRICK=44,S_GOPEN=45,S_GCLOSE=46;
int _d169=0;int _d63=0,chKey1=0,chKey2=0,chKey3=0,chKey4=0,chKey5=0;
string _d190(int s){return s==0?"Grass":s==1?"Dirt":s==2?"Sand":s==3?"Snow":s==4?"Water":s==5?"Stone":"Wood";}
string _d123(int id){
if(id==_d41)return"Kart_Engine";if(id==S_DASH)return"Kart_EngineDash";if(id==S_IDLE)return"Kart_Idle";
if(id>=S_SIZZLE&&id<S_SIZZLE+3)return"Kart_Sizzle"+(id-S_SIZZLE+1);if(id==S_DRIFT)return"Kart_DriftSteer";
if(id==S_FLUTTER)return"Kart_GliderFlutter";if(id>=S_RUN&&id<S_RUN+7)return"Kart_Run_"+_d190(id-S_RUN);
if(id>=S_SLIP&&id<S_SLIP+7)return"Kart_Slip_"+_d190(id-S_SLIP);if(id>=S_LANDS&&id<S_LANDS+7)return"Kart_Land_"+_d190(id-S_LANDS);
if(id==_d42)return"Kart_MiniTurbo";if(id==S_ULTRA)return"Kart_UltraTurbo";if(id==S_HOP)return"Kart_Hop";if(id==S_LAND)return"Kart_Land";
if(id==S_TRICK)return"Kart_Trick";if(id==S_GOPEN)return"Kart_GliderOpen";if(id==S_GCLOSE)return"Kart_GliderClose";return"";
}
ptr_t _d176=0;int _d172=-1;bool _d177=false;
ptr_t _d174(){
ActorBase@a=_k7();if(a is null||!_d84())return 0;
ptr_t x=_pq(_pa(a)+0x228);if(!_d96(x))return 0;
x=_pq(x+0x68);if(!_d96(x))return 0;
ptr_t u=_pq(x+0x78);return _d96(u)?u:0;
}
void _d171(int id,int ch){
ptr_t u=_d174();if(u==0||id<=0)return;string _d122=_d123(id);
ptr_t k=fxScr+0x7800,h=fxScr+0x7880+8*ch;uint n=_d122.length();
for(uint w=0;w<4;w++){uint64 v=0;for(uint i=0;i<8;i++){uint c=w*8+i;if(c<n)v|=uint64(_d122[c])<<(8*i);}ptr_write_u64(k+8*w,v);}
ptr_write_u64(h,0xffff00ff);
ptr_call(_d81+_d38,u,k,h,0,0,0,0,0,0,0,0);
if(_d169<80){_d169++;_L("KART snd "+_d122+" h="+_pq(h));}
}
void _d167(int ch){if(fxScr==0)return;ptr_t h=fxScr+0x7880+8*ch;if(_pq(h)!=0xffff00ff)ptr_call(_d81+SND_FADE,h,0xffffffff,0,0,0,0,0,0,0,0,0);ptr_write_u64(h,0xffff00ff);}
int _d62(int ch){return ch==0?_d63:ch==1?chKey1:ch==2?chKey2:ch==3?chKey3:ch==4?chKey4:chKey5;}
void _d64(int ch,int k){if(ch==0)_d63=k;else if(ch==1)chKey1=k;else if(ch==2)chKey2=k;else if(ch==3)chKey3=k;else if(ch==4)chKey4=k;else chKey5=k;}
void _d170(int ch,int _d122){
if(_d62(ch)==_d122)return;
if(_d62(ch)!=0)_d167(ch);
if(_d122!=0)_d171(_d122,ch);
_d64(ch,_d122);
}
bool _d148(ptr_t x){
if(!_d96(x))return false;uint n=_pu(x+0x110);if(n==0||n>16)return false;
ptr_t _d134=_pq(x+0x118);if(!_d96(_d134))return false;
for(uint i=0;i<n;i++){ptr_t s=_pq(_d134+8*i);if(_d96(s)&&_d82(s,"ControlStick_StickSpeedXY")){_d172=int(i);return true;}}
return false;
}
void _d168(){
_d177=true;_d176=0;_d172=-1;
ActorBase@a=_k7();if(a is null)return;
ptr_t p=_pq(_pa(a)+0x228);if(!_d96(p))return;
p=_pq(p);if(!_d96(p))return;
p=_pq(p+0x10);if(!_d96(p))return;
if(_d148(p))_d176=p;
_L("KART snd prop X="+(_d176!=0)+" idx="+_d172+" n="+_pu(p+0x110));
}
void _d173(float ms){
if(_d176==0||_d172<0)return;
ptr_t f=fxScr+0x7a00;
_pw(f,abs(ms)*_d39);
ptr_call(_d81+PROP_SET,_d176,_d172,f,0,0,0,0,0,0,0,0);
}
int _d124=-2,lastSurface=-1;
bool _d129(int m,const string&in w){
ptr_t t=_pq(_d81+0x4637298);if(t==0||m<0||m>=54)return false;ptr_t s=_pq(t+0x250+8*m);if(!_d96(s))return false;
uint n=w.length();for(uint i=0;i<28;i++){if(ptr_deref_u8(s+i)==0)return false;bool ok=true;for(uint k=0;k<n&&ok;k++)if(ptr_deref_u8(s+i+k)!=w[k])ok=false;if(ok)return true;}
return false;
}
int _d191(){
if(_d104==_d124)return lastSurface;
_d124=_d104;int c=_d98(_d104);
lastSurface=c<0?-1:c==0?0:c==1?1:c==2?2:c==3?3:c==4?4:c==5?1:(_d129(_d104,"Wood")?6:5);
return lastSurface;
}
bool _d175=false,sndWasGlide=false;
void _d178(){
if(!_k19){
if(_d63!=0||chKey1!=0||chKey2!=0||chKey3!=0||chKey4!=0||chKey5!=0){for(int c=0;c<6;c++)_d170(c,0);}
_d177=false;_d175=false;sndWasGlide=false;return;
}
if(!_d177)_d168();
float sp=abs(_k18);_d173(sp);
_d170(_d6,gliding?0:boostLeft>0?S_DASH:sp<0.6f?S_IDLE:_d41);
_d170(CH_SIZZLE,(_d71!=0&&driftTier>0&&!gliding)?S_SIZZLE+driftTier-1:0);
int _d189=(_d51||gliding)?-1:_d191();
_d170(CH_DRIFT,(_d71!=0&&!_d51&&!gliding)?S_DRIFT:0);
_d170(CH_RUN,(_d189>=0&&sp>1.0f&&_d71==0)?S_RUN+_d189:0);
_d170(CH_SLIP,(_d189>=0&&_d71!=0)?S_SLIP+_d189:0);
_d170(CH_FLUTTER,gliding?S_FLUTTER:0);
if(sndWasGlide&&!gliding)_d171(S_GCLOSE,CH_SHOT);
if(_d175&&!_d51){_d171(S_LAND,CH_SHOT);int s2=_d191();if(s2>=0)_d171(S_LANDS+s2,CH_SHOT+1);}
_d175=_d51;sndWasGlide=gliding;
}
const bool _d20=true;
const float _d2=6.2f,CAM_HEIGHT=2.4f,CAM_LOOK_AHEAD=1.6f,CAM_LOOK_UP=1.2f,CAM_DRIFT_SWING=0.16f;
const float _d3=7.6f,CAM_GLIDE_HEIGHT=4.4f,CAM_BOOST_BACK=0.8f,CAM_KICK=0.7f,CAM_BRAKE_IN=0.5f;
bool _d131=_d20,mkCamChordLatched=true,camFrozen=false,camInit=false,camBraking=false;
float _d57=0,camFz=1,camHx=0,camHz=1,camDist=_d2,camH=CAM_HEIGHT,camY=0,camKick=0,camLook=0;int _d58=0;
void _d60(){if(camFrozen){camera::toggleFreeze();camFrozen=false;}camInit=false;}
void _d61(ActorBase@a,int rx){
if(!_d131||a is null||!_k19){_d60();return;}
float sp=abs(_k18);
if(boostLeft>_d58+5)camKick=1;_d58=boostLeft;camKick*=0.88f;
float tx=_d57,tz=camFz;
if(_d71!=0){float c=cos(-_d71*CAM_DRIFT_SWING),s2=sin(-_d71*CAM_DRIFT_SWING);float nx=tx*c+tz*s2,nz=-tx*s2+tz*c;tx=nx;tz=nz;}
if(!camInit){camHx=tx;camHz=tz;camY=a.pos_y;camDist=_d2;camH=CAM_HEIGHT;}
float _d153=gliding?0.06f:_d51?0.05f:0.13f;
camHx+=(tx-camHx)*_d153;camHz+=(tz-camHz)*_d153;float hl=sqrt(camHx*camHx+camHz*camHz);if(hl<0.01f){camHx=tx;camHz=tz;hl=1;}camHx/=hl;camHz/=hl;
float _d127=float(rx)/32768.0f;if(abs(_d127)<0.2f)_d127=0;camLook+=(_d127*1.8f-camLook)*0.15f;
float lc=cos(camLook),ls=sin(camLook),dx=camHx*lc+camHz*ls,dz=-camHx*ls+camHz*lc;
float _d70=gliding?_d3:_d2+sp*0.035f+(boostLeft>0?CAM_BOOST_BACK:0)-(camBraking?CAM_BRAKE_IN:0);
_d70+=camKick*CAM_KICK;
float h=gliding?CAM_GLIDE_HEIGHT:CAM_HEIGHT+sp*0.01f;
camDist+=(_d70-camDist)*(camKick>0.5f?0.3f:0.1f);camH+=(h-camH)*0.08f;
camY+=(a.pos_y-camY)*((_d51||gliding)?0.12f:0.35f);
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
bool _d142=false,exitLatch=false;uint64 _d139=0;int _d140=0,outLY=0,outRX=0,outRY=0;
bool _d161=false;uint64 _d162=0;int _d163=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d143){
uint64 _d109=_d161?_d162:_pq(_d143);
int lx=_d161?_d163:_ps(_d143+8),ly=_d161?simLY:_ps(_d143+12);
int rx=_d161?simRX:_ps(_d143+16),ry=_d161?simRY:_ps(_d143+20);
_d142=false;_d139=_d109;_d140=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
_d60();
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 _d128=uint64(ZL|ZR|DUP);
if((_d109&_d128)==0)_k24=false;
if(!_k24&&(_d109&_d128)==_d128){_k24=true;_k25=true;_L("KART spawn queued");}
uint64 _d59=uint64(ZL|ZR|DLEFT);
if((_d109&_d59)==0)mkCamChordLatched=false;
if(!mkCamChordLatched&&(_d109&_d59)==_d59){
mkCamChordLatched=true;_d131=!_d131;_L("KART mkcam="+_d131);
_T(90,_d131?"Mario Kart camera: ON\n":"Mario Kart camera: OFF\n");
}
uint64 _d135=uint64(ZL|ZR|DDOWN);
if((_d109&_d135)==0)offroadChordLatched=false;
if(!offroadChordLatched&&(_d109&_d135)==_d135){
offroadChordLatched=true;_d137=!_d137;_L("KART offroad="+_d137);
_T(90,_d137?"Off-road handling: ON\n":"Off-road handling: OFF\n");
}
if(!_k3()||_d130()){_d60();return;}
if(_k25&&(_d109&_d128)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d109);
_d52(_k7());
_d180(_k7());
_d93(_k7());
_d76();
_d102(_k7());
_d178();
_d61(_k7(),rx);
uint64 _d73=uint64(A|B|X|Y|R|ZR);
if(_k19){
_d142=true;_d139=_d109&~_d73;
_d140=0;outLY=0;//the vanilla control stick tilts the contraption with the left stick in the air;this controller steers
if((_d109&uint64(X))!=0){_d139|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d109&uint64(X))==0)exitLatch=false;
else{_d142=true;_d139=_d109&~uint64(X);}//do not let the _d109 X make Link jump
}
}
void _d203(){
if(_d142)input(1,_d139,_d140,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d143){while(true){_k5(_d143);_d203();}}
ptr_t tp=0;uint _d66=0;
void _d65(){string _d121="";for(uint i=0;i<1500;i++){string t="Weapon_Sword_heapstress_"+i+"_"+_d121.length();_d121=t.substr(0,24)+_d121.substr(0,8);}_d66+=1500;}
void wf(uint n){for(uint i=0;i<n;i++){_d65();input(1,0);}}
void _d74(uint64 k,int x,int y,int rx){
_d65();_d161=true;_d162=k;_d163=x;simLY=y;simRX=rx;simRY=0;_k5(tp);
if(_d142)input(1,_d139,_d140,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
void hs(const string&in l){ActorBase@a=_k7();_L("HS "+l+" churned="+_d66+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+_k18+" mounted="+_k15(a));}
void main(){
_k14();tp=_k6();if(tp==0)return;
hs("boot");wf(180);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){_d65();input(1,1);wf(90);}
wf(60);if(!_k3())return;
hs("world");
Player.setPos(-150,127.8,-62);wf(90);for(uint w=0;w<200&&!(_k3()&&abs(Player.pos_x+150)<20);w++)wf(10);wf(60);if(!_k3())return;
hs("field");
_k5(tp);_d74(uint64(ZL|ZR|DUP),0,0,0);
for(uint f=0;f<25;f++)_d74(0,0,0,0);
for(uint t=0;t<10&&!_k15(_k7());t++){
ActorBase@k=_k7();if(k is null){wf(10);continue;}
Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);wf(2);Player.setPos(px,k.pos_y+0.3f,pz);wf(20);
hs("try mount t="+t);
_d65();input(1,1);wf(30);
}
if(!_k15(_k7())){hs("mount failed");return;}
_d74(0,0,0,0);hs("mounted");
for(uint f=0;f<1800&&_k3();f++){int sx=(f/300)%2==0?32767:0;_d74(uint64(A),sx,0,0);if(f%150==0)hs("drive"+f);}
_d74(uint64(X),0,0,0);for(uint f=0;f<30;f++)_d74(0,0,0,0);
hs("finished");_d161=false;input(1,0);_k11(tp);
}
