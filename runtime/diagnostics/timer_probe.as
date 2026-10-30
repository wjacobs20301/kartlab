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
bool _k20=false;float _d149=0,_w15=0;
float _d195=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d110=false;
const float _d30=7.775f;//[table]PRSL ground top speed,0 coins
const float _d22=0.011f;//[table]PRAC strength(G)
const float _d21=0.09f;//[table]PRAC limiter(M)
const float _d31=0.0118f;//[table]PRTL _d194,rad per MK frame
const float _d27=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d25=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d32=0.75f;//[table]PRON road traction
const float _d35=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d34=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d77)
const uint _d45=153;//[chosen]ultra _d127(not in the table):SMT+(SMT-MT)
const float _d5=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d33=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d29=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d24=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d26=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d28=0.993f;//[chosen]decay above _d200(after a boost)
const float _d23=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d16=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d7=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d196 0.001
const float _d8=0.8f;//[native]drift _d194 _d193 _w12,approached at 10%/frame,_d196<=0.07
const float _d4=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d121>=0.71 else 2
const float _d19=3.0f;//[chosen]drift _d113,m/s upward
const float _d1=0.3f,AIR_GAP=0.7f;const int _d44=8,TRICK_FRAMES=31;//trick:also R up to 6 _d77 before take-off
const float _d14=0.95f;//[measured]TOTK pulls the kart down~0.95 m/s per frame;added back so the glide _d171 settles at _d200
const float _d15=8.225f,GLIDE_SINK=1.6f,GLIDE_DIVE=4.5f,GLIDE_FLOAT=0.6f,GLIDE_STEER=0.6f,GLIDE_MIN_HEIGHT=2.5f;
const float _d0=9.0f;
const float _d13=0.55f,GLIDE_PITCH=0.35f,GLIDE_TILT_GAIN=4.0f;//[chosen]~29 deg _d53,~19 deg _d151
bool _d51=false,trickDone=false,gliding=false,gliderLatch=true;int _d50=0,groundFrames=0,trickWindow=0,rPressAge=99;
const bool _d36=false;
const float _d37=0.7f,OFFROAD_HEAVY=0.5f;//[table]PROF
bool _d142=_d36,offroadChordLatched=true;
float _d137=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d70=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d114=false,gasLatch=true,idleHold=false;
bool _d135(){return pause::isPauseRequest("GamePause")||pause::isPauseRequest("PreGamePause")||pause::isPauseRequest("PostGamePause")||pause::isPauseTarget("Custom_PhysicsUpdateWorld");}
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d112=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d112==0)return 0;
uint op=_pu(_d112);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d68=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d68-=0x04000000;
ptr_t _d200=ptr_t(int64(_d112)+_d68*4);
if(_pu(_d200)!=0xf0001382||_pu(_d200+4)!=0xa9be7bfd)return 0;
ptr_t _d54=_d200-0x65b80;if((_d54&0xfff)!=0)return 0;return _d54+0x3d90b8;
}
void _k13(){_d94=0;_d95=false;ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d162();_k19=false;_k20=false;_d149=0;_w15=0;_d110=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d193=_pu(_k16+0x24);if(_d193<2||_d193>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d115,uint _k27){
if(_d115 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d115);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d193=_pu(p+0x24);
return _d193>=2&&_d193<=6;
}
bool _k0(ActorBase@_d115,uint _k27){
if(Player is null||!_k1(_d115,_k27))return false;
ptr_t _d47=_pa(_d115),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d67=_pu(_d47+0x220);ptr_t _d128=_pq(_d47+0x228);
if(_d67<=129||_d67>512||!_k2(_d128))return false;
ptr_t _d66=_pq(_d128+0x408);
if(!_k2(_d66))return false;
uint _d166=_pu(_d66+0x20);ptr_t _k29=_pq(_d66+0x28);
if(_d166!=1||!_k2(_k29))return false;
ptr_t _d164=_pq(_k29);
if(!_k2(_d164))return false;
uint _d165=_pu(_d164+0x10),flags=_pu(_d164+0x18);
float _k33=_pf(_d164+0x74);
if(_d165!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d164+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d115,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d149=a.pos_x;_w15=a.pos_z;return;}
float dx=_d149-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d149=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@_d143=_k7();
if(_k15(_d143)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d127=sqrt(fx*fx+fz*fz);if(_d127<0.1f)return;fx/=_d127;fz/=_d127;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d143!is null){_k10(_d143);_d143.setPos(x,y,z);@_d143=null;_d149=0;_w15=0;_d110=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);_k17=_pu(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d149=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d212(ActorBase@a){
ptr_t _d128=_pq(_pa(a)+0x228);if(!_k2(_d128))return 0;
ptr_t mc=_pq(_d128+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(_pf(b+120)-0.728f)>0.002f||abs(_pf(b+216)+0.728f)>0.002f||abs(_pf(b+312)-0.7776f)>0.002f||abs(_pf(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _d213(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
const float _d43=0.3927f;//2*pi/16 tread _d55
float _d210(float _d196){
float m=abs(_d196),half=_d43*0.5f;
if(m<=half*0.9f)return _d196;
float _d55=floor((m-half)/_d43);if(_d55>3)_d55=3;
float v=(_d55+0.5f)*_d43;return _d196<0?-v:v;
}
void _d52(ActorBase@a){
if(a is null){_d110=false;return;}
Matrix33f r=a.rot;float _d127=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d110&&_d127>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d127;}
_w4=x;_w5=z;_d110=true;
_w2+=_d210(ds/0.28328f);_w3+=_d210(ds/0.3683f);
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d195*0.45f-_w1)*0.25f;
ptr_t b=_d212(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d213(b+72,sf,cf,sd,cd);_d213(b+168,sf,cf,sd,cd);
_d213(b+264,sr,cr,0,1);_d213(b+360,sr,cr,0,1);
}
void _d162(){_d51=false;trickDone=false;gliding=false;_d50=0;groundFrames=0;trickWindow=0;_d137=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d70=0;driftTier=0;boostLeft=0;hopWindow=0;_d114=false;gasLatch=true;idleHold=false;}
int _d105=-1;float _d99=99;//updated by _d102(ray cast under the kart)
float _d202(){
if(!_d142||_d99>=0.8f)return 1;
int m=_d105;
if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;//HeavySand,HeavySnow,Bog,Tar,Water,ContaminatedWater
if(m==1||m==2||m==3||m==5)return _d37;//Soil,Grass,Sand,Snow
return 1;
}
float _d191(float v,float _d203){
if(boostLeft>0){
boostLeft--;float t=_d30*_d35;
if(v<t){float _d118=(t-v)*_d23;if(_d118>MK_BOOST_CAP)_d118=MK_BOOST_CAP;return v+_d118;}
return t;
}
if(_d203>0){
if(v<0)return v+_d24>0?0:v+_d24;//stop reversing first
float t=_d30*_d203*_d202();
if(v<t){float _d118=(t-v)*_d22;if(_d118>_d21)_d118=_d21;return v+_d118;}//[native]form
float d=v*_d28;return d<t?t:d;
}
if(_d203<0){
if(v>0)return v-_d24<0?0:v-_d24;//brake,then reverse
float t=-_d29*(-_d203);
if(v>t){float _d118=(v-t)*_d22;if(_d118>_d21)_d118=_d21;return v-_d118;}
return v;
}
if(v>0)return v-_d26<0?0:v-_d26;
return v+_d26>0?0:v+_d26;
}
void _d71(int _d204){
_L("KART drift tier="+_d204+" charge="+driftCharge);
if(_d204==1)_T(30,"Mini-Turbo\n");else if(_d204==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d111){
_d195=0;
ActorBase@a=_k7();bool _d163=_k15(a);
if(_d163!=_k19){_L("KART mounted="+_d163);_d162();_k19=_d163;_k20=!_d163;if(a!is null){_d149=a.pos_x;_w15=a.pos_z;}}
if(!_d163||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d162();return;}
float _d194=float(ix)/32768.0f,_d203=0;
if(abs(_d194)<0.15f)_d194=0;
bool _d90=(_d111&uint64(A))!=0,brake=(_d111&uint64(B))!=0;
if(!_d90)gasLatch=false;//the A press used to get in must be released first
if(brake)_d203=-1;else if(_d90&&!gasLatch)_d203=1;
_d195=_d194;
Matrix33f r=a.rot;float _d127=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d127<0.1f||r.a4<0.4f){_k10(a);_d162();return;}
float bx=r.a2/_d127,bz=r.a8/_d127,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
_d57=fx;camFz=fz;camBraking=brake&&_d137>0.5f;
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d48=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d49=_d48/_d33;
if(_d137>0&&_d137>_d49+0.6f)_d137=_d49+0.6f<0?0:_d49+0.6f;
if(_d137<0&&_d137<_d49-0.6f)_d137=_d49-0.6f>0?0:_d49-0.6f;
bool _d158=(_d111&uint64(R|ZR))!=0,fast=_d137>_d30*0.35f;
if(_d83())_d106(a.pos_x,a.pos_y+0.2f,a.pos_z);
bool _d146=_d99<AIR_GAP;
if(_d146){groundFrames++;_d50=0;}else{_d50++;groundFrames=0;}
bool _d211=_d51;
bool _d157=_d158&&!_d114;rPressAge=_d157?0:rPressAge+1;
if(!_d51&&_d50>=2){
_d51=true;trickWindow=_d44;trickDone=false;_L("KART airborne");
if(rPressAge<=6+_d50){trickDone=true;_d178(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick (buffered)");}
}
if(_d51&&groundFrames>=1){
_d51=false;
if(gliding){gliding=false;_L("KART glider landed");}
if(trickDone){if(boostLeft<TRICK_FRAMES)boostLeft=TRICK_FRAMES;_d178(_d42,CH_SHOT);_L("KART trick boost");}
trickDone=false;_L("KART landed");
}
float _d113=0;
bool _d156=_d158&&!_d114;
if(_d51){
if(trickWindow>0){trickWindow--;if(_d156&&!trickDone){trickDone=true;_d178(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick");}}
}else if(_d156&&fast){_d113=_d19;hopWindow=24;_d178(S_HOP,CH_SHOT);}
_d114=_d158;
bool _d215=(_d111&uint64(Y))!=0;
if(!_d215)gliderLatch=false;
if(_d215&&!gliderLatch){
gliderLatch=true;
if(gliding){gliding=false;_L("KART glider folded");}
else if(_d51&&_d99>=GLIDE_MIN_HEIGHT){gliding=true;_d178(S_GOPEN,CH_SHOT);_d70=0;driftCharge=0;driftTier=0;_T(30,"Glider!\n");_L("KART glider open");}
}
if(_d70==0&&!_d51&&_d158&&hopWindow>0&&abs(_d194)>0.3f){_d70=_d194>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d70);}
if(_d70!=0&&(!_d158||!fast)){
int _d77=driftTier==3?int(_d45):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d34):0;
if(_d77>0&&_d158==false){boostLeft=_d77;_d178(driftTier==3?S_ULTRA:_d42,CH_SHOT);_L("KART boost tier="+driftTier+" frames="+_d77);}
_d70=0;driftCharge=0;driftTier=0;
}
if(!_d51&&_d203==0&&boostLeft==0&&_d70==0&&_d113==0&&abs(_d137)<_d26){
_d137=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d149=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d216=0,oldOff=bodyOff;
for(int _d196=0;_d196<2;_d196++){
if(hopWindow>0)hopWindow--;
if(gliding){float t=_d15*(iy>16000?1.06f:1.0f);_d137+=(t-_d137)*0.02f;}
else if(!_d51||boostLeft>0)_d137=_d191(_d137,_d203);
float _d56=0;
if(gliding){
driftTrack=0;_d216+=_d194*_d31*GLIDE_STEER;
}else if(_d70!=0){
float _d121=_d194*_d70;if(_d121>1)_d121=1;if(_d121<-1)_d121=-1;
float _d209=_d121>=0?_d8:-_d8,dt=(_d209-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d120=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d216+=_d70*_d27*_d120*_d120*(0.75f+0.25f*_d121);
if(!_d51)driftCharge+=_d121>=CHARGE_INWARD?_d4:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d204=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d5?1:0;
if(_d204>driftTier){driftTier=_d204;_d71(_d204);}
_d56=_d70*_d7;
}else{
driftTrack=0;
float _d189=abs(_d137)/(_d30*0.25f);if(_d189>1)_d189=1;
_d216+=_d194*_d31*_d189*(_d137<0?-1.0f:1.0f)*(_d51?_d1:1.0f);
}
float _d89=_d56-bodyOff,ds=_d89*0.07f;
if(abs(ds)<0.001f)ds=abs(_d89)<0.001f?_d89:(_d89>0?0.001f:-0.001f);
bodyOff+=ds;
if(!_d51)lateral*=1-_d16*_d32;
}
_k18=_d137*_d33;
float _d190=_k18;
float vy=v.y+_d113;
if(gliding){
float _d171=iy>16000?GLIDE_DIVE:iy<-16000?GLIDE_FLOAT:GLIDE_SINK;//stick forward dives,back floats
vy+=(-_d171-vy)*0.3f+_d14;//ease into the glide descent(gravity compensated)
}
if(gliding&&vy<-_d0)vy=-_d0;//glider only(user:free fall must stay normal speed)
b.setVel(fx*_d190+lx*lateral,vy,fz*_d190+lz*lateral);
float tx=0,ty=1,tz=0,gain=2.0f;
if(gliding){
float _d151=float(iy)/32768.0f;if(_d151>1)_d151=1;if(_d151<-1)_d151=-1;
float _d53=_d194*_d13,nose=_d151*GLIDE_PITCH;//stick right:right side down;stick forward:nose down
tx=-lx*_d53+fx*nose;tz=-lz*_d53+fz*nose;ty=1;float tl=sqrt(tx*tx+ty*ty+tz*tz);tx/=tl;ty/=tl;tz/=tl;gain=GLIDE_TILT_GAIN;
}
float ux=r.a1,uy=r.a4,uz=r.a7;
float wx=(uy*tz-uz*ty)*gain,wz=(ux*ty-uy*tx)*gain;//world axes(a body-axis version flipped the kart)
b.setAngularVel(wx,-(_d216+bodyOff-oldOff)*30.0f,wz);
}
const uint _d11=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float _d40=0.35f,FLAME_SCALE=0.15f;//[chosen]from screenshots
ptr_t _d80=0,fxSys=0,fxScr=0;int _d84=-2,fxFlame=-1;
bool _d81(ptr_t p,const string&in _d138){
uint n=_d138.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=_d138[i])return false;
return ptr_deref_u8(p+n)==0;
}
int _d78(const string&in _d138){
ptr_t _d161=_pq(_pq(fxSys+0x2ee8)+8);if(_d161==0||ptr_deref_u8(_d161+0x571)==0)return-1;//static effects=resource 1
int n=_ps(_d161+0x558);ptr_t _d167=_pq(_d161+0x430);
for(int i=0;i<n;i++)if(_d81(_pq(_d167+0x28*i)+0x10,_d138))return i;
return-1;
}
bool _d83(){
if(_d84>=0)return true;
if(_d84==-1)return false;//looked once and failed:stay off
_d84=-1;
ptr_t _d112=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d112==0)return false;
uint op=_pu(_d112);int64 _d68=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d68-=0x04000000;
ptr_t _d200=ptr_t(int64(_d112)+_d68*4),_d54=_d200-0x65b80;
if((_d54&0xfff)!=0||_pu(_d200)!=0xf0001382)return false;
fxScr=_d54+FX_SCRATCH;_d80=sys::mainOffset();
ptr_t _d119=_pq(_pq(_d80+_d11));if(_d119==0)return false;
fxSys=_pq(_d119+0x11b8);if(fxSys==0)return false;
int _d186=_d78("Ply_ShockWave_Spark");fxFlame=_d78("Chm_FlameThrower_ScraBuild");//Zonai _d74 emitter jet
_L("KART fx spark="+_d186+" flame="+fxFlame);
if(_d186<0)return false;
_d84=_d186;return true;
}
ptr_t _d79(int _d173){ptr_t h=fxScr+0x10*_d173,e=_pq(h);if(e==0)return 0;return _pu(e+0x234)==_pu(h+8)?e:0;}
ptr_t _d85(int _d173,int id){
ptr_t e=_d79(_d173);if(e!=0)return e;
ptr_t h=fxScr+0x10*_d173;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d80+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*_d173,0,0,0,0,0);
return _d79(_d173);
}
void _d87(int _d173){if(fxScr==0)return;ptr_t e=_d79(_d173);if(e!=0)ptr_call(_d80+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*_d173,0);}
void _d82(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
_pw(m,r.a0);_pw(m+4,r.a1);_pw(m+8,r.a2);_pw(m+12,px);
_pw(m+16,r.a3);_pw(m+20,r.a4);_pw(m+24,r.a5);_pw(m+28,py);
_pw(m+32,r.a6);_pw(m+36,r.a7);_pw(m+40,r.a8);_pw(m+44,pz);
_pw(fxScr+0x140,s);_pw(fxScr+0x144,s);_pw(fxScr+0x148,s);
ptr_call(_d80+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
void _d88(ptr_t e,float r,float g,float b){_pw(e+0x40,r);_pw(e+0x44,g);_pw(e+0x48,b);}
void _d187(ActorBase@a){
bool _d188=a!is null&&_k19&&_d70!=0&&driftTier>0;
bool _d74=a!is null&&_k19&&boostLeft>0;
if(!_d188&&!_d74&&fxScr==0)return;
if(!_d83()){return;}
if(!_d188)_d87(0);
if(!_d74||fxFlame<0)_d87(1);
if(_d188){
ptr_t e=_d85(0,_d84);
if(e!=0){
if(driftTier==1)_d88(e,0.25f,0.8f,6.0f);else if(driftTier==2)_d88(e,1.0f,1.0f,1.0f);else _d88(e,2.2f,0.4f,6.0f);
ptr_t b=_d212(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(_pf(b+312));wy=_pf(b+28)+_pf(b+316)-0.3683f;wz=_pf(b+32)+_pf(b+320);}
_d82(e,a,wx,wy,wz,_d40);_d82(e,a,-wx,wy,wz,_d40);
}
}
if(_d74&&fxFlame>=0){ptr_t e=_d85(1,fxFlame);if(e!=0){_d82(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);_d82(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
const uint _d10=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int _d107=-1,groundTick=0;
int _d92=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;//effect ids per class,looked up once(no arrays in this runtime)
bool _d106(float x,float y,float z){
ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d80+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);//flags:all false
_pw(v+4,2.0f);ptr_write_u64(q+0x38,v+4);//ray _d127(m)
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d80+_d10,q,0,0,0,0,0,0,0,0,0,0);
if(ptr_deref_u8(v+0x10)==0){_d105=-1;_d99=99;return false;}
_d105=_ps(v+0x40);_d99=_pf(v+0x14);return true;
}
int _d98(int m){
if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return-1;return 6;
}
string _d101="";//diagnostics only:overrides the grass effect _d138
string _d100(int c){
if(c==0&&_d101!="")return _d101;
if(c==0)return"ReFX_Grass_L";if(c==1||c==2)return"ReFX_Sand_L";if(c==3)return"ReFX_Snow_L";
if(c==4)return"Water_Splash01_Move";if(c==5)return"RctFld_Mud_Splash_S";return"Ply_SlipSmoke_Stone";
}
int _d103(int c){
if(c==0){if(_d92==-2)_d92=_d78(_d100(0));return _d92;}if(c==1){if(gid1==-2)gid1=_d78(_d100(1));return gid1;}
if(c==2){if(gid2==-2)gid2=_d78(_d100(2));return gid2;}if(c==3){if(gid3==-2)gid3=_d78(_d100(3));return gid3;}
if(c==4){if(gid4==-2)gid4=_d78(_d100(4));return gid4;}if(c==5){if(gid5==-2)gid5=_d78(_d100(5));return gid5;}
if(gid6==-2)gid6=_d78(_d100(6));return gid6;
}
const float _d18=1.2f,GROUND_MIN_SPEED=3.0f;//[chosen]
const int _d17=6;//[chosen]_d77 between bursts:TOTK's ground effects are one-shot(per footstep/hoof)
int _d97=0,groundBurstSlot=0;
void _d108(){if(fxScr==0)return;for(int k=3;k<7;k++)_d87(k);}
ptr_t _d86(int _d173,int id,ptr_t _d155){
ptr_t h=fxScr+0x10*_d173;_d87(_d173);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d80+FX_CREATE,fxSys,h,id,1,0,_d155,0,0,0,0,0);
return _d79(_d173);
}
void _d102(ActorBase@a){
bool _d46=a!is null&&_k19&&_d83();
if(!_d46){_d108();_d107=-1;return;}
int c=_d99<0.8f?_d98(_d105):-1;
bool _d141=c>=0&&c<6,show=c>=0&&abs(_k18)>GROUND_MIN_SPEED&&(_d141||_d70!=0);
_d107=show?c:-1;
if(!show){_d97=0;return;}
if(_d97-->0)return;
_d97=_d17;
int id=_d103(c);if(id<0)return;
int _d173=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
ptr_t e=_d86(_d173,id,fxScr+0x5000);if(e==0)return;
float wx=0.78f,wz=-0.75f;ptr_t b=_d212(a);if(b!=0){wx=abs(_pf(b+312));wz=_pf(b+32)+_pf(b+320);}
_d82(e,a,wx,0,wz,_d18);_d82(e,a,-wx,0,wz,_d18);
}
const float _d12=-0.15f,GLIDER_Z=-0.45f;//[chosen]attach point in kart space(glider frame _d54)
float _d94=0;bool _d95=false;
ptr_t _d117=0,hostSklAt=0;
ptr_t _d116(ActorBase@a){
ptr_t _d128=_pq(_pa(a)+0x228);if(!_k2(_d128))return 0;
ptr_t mc=_pq(_d128+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
if(m==_d117&&hostSklAt!=0)return hostSklAt;
_d117=m;hostSklAt=0;_d95=false;//new kart(model instances are pooled:a reused one can _d122 an open glider)
for(uint o=0;o<0x4000;o+=4){
ptr_t r=m+o;
if(abs(_pf(r+52)-0.3766f)<0.003f&&abs(_pf(r+48))<0.003f&&abs(_pf(r+56))<0.003f
&&abs(_pf(r+96+52)-0.5966f)<0.003f&&abs(_pf(r+96+56)-0.4928f)<0.003f){hostSklAt=r;_L("KART host Skl_Root record at +"+o);break;}
}
return hostSklAt;
}
void _d93(ActorBase@a){
float _d200=(a!is null&&_k19&&gliding)?1:0;
if(_d200==0&&_d94==0&&_d95)return;
if(a is null)return;
ptr_t _d172=_d116(a);if(_d172==0)return;
if(_d94<_d200){_d94+=0.17f;if(_d94>_d200)_d94=_d200;}
else if(_d94>_d200){_d94-=0.2f;if(_d94<_d200)_d94=_d200;}
ptr_t r=_d172-192;float sc=_d94;//Control=bone 1,two records before Skl_Root(bone 3)
_pw(r,sc);_pw(r+4,0);_pw(r+8,0);
_pw(r+16,0);_pw(r+20,sc);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,sc);
_pw(r+48,0);_pw(r+52,_d12);_pw(r+56,GLIDER_Z);
_d95=true;
}
const uint _d9=0x1085b5c;
bool _d76=false;
bool _d96(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d152(){
if(Player is null)return 0;ptr_t p=_pq(_pa(Player)+0x228);if(!_d96(p))return 0;
p=_pq(p+0x50);if(!_d96(p))return 0;p=_pq(p+0x20);return _d96(p)?p:0;
}
void _d75(){
if(!_k19&&!_d76)return;
ptr_t _d150=_d152();if(_d150==0)return;
ptr_call(sys::mainOffset()+_d9,_d150,_k19?0:1,0,0,0,0,0,0,0,0,0);
_d76=_k19;
}
const uint _d38=0x809ee0,SND_FADE=0xb226a4,PROP_SET=0x11acb98;
const int _d6=0,CH_SIZZLE=1,CH_DRIFT=2,CH_RUN=3,CH_SLIP=4,CH_FLUTTER=5,CH_SHOT=6;
const float _d39=1.0f/14.0f;//[chosen]top speed(14 m/s)=1=top of curve 213
const int _d41=1,S_DASH=2,S_IDLE=3,S_SIZZLE=4,S_DRIFT=7,S_FLUTTER=8,S_RUN=10,S_SLIP=20,S_LANDS=30;
const int _d42=40,S_ULTRA=41,S_HOP=42,S_LAND=43,S_TRICK=44,S_GOPEN=45,S_GCLOSE=46;
int _d176=0;int _d63=0,chKey1=0,chKey2=0,chKey3=0,chKey4=0,chKey5=0;
string _d198(int s){return s==0?"Grass":s==1?"Dirt":s==2?"Sand":s==3?"Snow":s==4?"Water":s==5?"Stone":"Wood";}
string _d124(int id){
if(id==_d41)return"Kart_Engine";if(id==S_DASH)return"Kart_EngineDash";if(id==S_IDLE)return"Kart_Idle";
if(id>=S_SIZZLE&&id<S_SIZZLE+3)return"Kart_Sizzle"+(id-S_SIZZLE+1);if(id==S_DRIFT)return"Kart_DriftSteer";
if(id==S_FLUTTER)return"Kart_GliderFlutter";if(id>=S_RUN&&id<S_RUN+7)return"Kart_Run_"+_d198(id-S_RUN);
if(id>=S_SLIP&&id<S_SLIP+7)return"Kart_Slip_"+_d198(id-S_SLIP);if(id>=S_LANDS&&id<S_LANDS+7)return"Kart_Land_"+_d198(id-S_LANDS);
if(id==_d42)return"Kart_MiniTurbo";if(id==S_ULTRA)return"Kart_UltraTurbo";if(id==S_HOP)return"Kart_Hop";if(id==S_LAND)return"Kart_Land";
if(id==S_TRICK)return"Kart_Trick";if(id==S_GOPEN)return"Kart_GliderOpen";if(id==S_GCLOSE)return"Kart_GliderClose";return"";
}
ptr_t _d183=0;int _d179=-1;bool _d184=false;
ptr_t _d181(){
ActorBase@a=_k7();if(a is null||!_d83())return 0;
ptr_t x=_pq(_pa(a)+0x228);if(!_d96(x))return 0;
x=_pq(x+0x68);if(!_d96(x))return 0;
ptr_t u=_pq(x+0x78);return _d96(u)?u:0;
}
void _d178(int id,int ch){
ptr_t u=_d181();if(u==0||id<=0)return;string _d123=_d124(id);
ptr_t k=fxScr+0x7800,h=fxScr+0x7880+8*ch;uint n=_d123.length();
for(uint w=0;w<4;w++){uint64 v=0;for(uint i=0;i<8;i++){uint c=w*8+i;if(c<n)v|=uint64(_d123[c])<<(8*i);}ptr_write_u64(k+8*w,v);}
ptr_write_u64(h,0xffff00ff);
ptr_call(_d80+_d38,u,k,h,0,0,0,0,0,0,0,0);
if(_d176<80){_d176++;_L("KART snd "+_d123+" h="+_pq(h));}
}
void _d174(int ch){if(fxScr==0)return;ptr_t h=fxScr+0x7880+8*ch;if(_pq(h)!=0xffff00ff)ptr_call(_d80+SND_FADE,h,0xffffffff,0,0,0,0,0,0,0,0,0);ptr_write_u64(h,0xffff00ff);}
int _d62(int ch){return ch==0?_d63:ch==1?chKey1:ch==2?chKey2:ch==3?chKey3:ch==4?chKey4:chKey5;}
void _d64(int ch,int k){if(ch==0)_d63=k;else if(ch==1)chKey1=k;else if(ch==2)chKey2=k;else if(ch==3)chKey3=k;else if(ch==4)chKey4=k;else chKey5=k;}
void _d177(int ch,int _d123){
if(_d62(ch)==_d123)return;
if(_d62(ch)!=0)_d174(ch);
if(_d123!=0)_d178(_d123,ch);
_d64(ch,_d123);
}
bool _d154(ptr_t x){
if(!_d96(x))return false;uint n=_pu(x+0x110);if(n==0||n>16)return false;
ptr_t _d139=_pq(x+0x118);if(!_d96(_d139))return false;
for(uint i=0;i<n;i++){ptr_t s=_pq(_d139+8*i);if(_d96(s)&&_d81(s,"ControlStick_StickSpeedXY")){_d179=int(i);return true;}}
return false;
}
void _d175(){
_d184=true;_d183=0;_d179=-1;
ActorBase@a=_k7();if(a is null)return;
ptr_t p=_pq(_pa(a)+0x228);if(!_d96(p))return;
p=_pq(p);if(!_d96(p))return;
p=_pq(p+0x10);if(!_d96(p))return;
if(_d154(p))_d183=p;
_L("KART snd prop X="+(_d183!=0)+" idx="+_d179+" n="+_pu(p+0x110));
}
void _d180(float ms){
if(_d183==0||_d179<0)return;
ptr_t f=fxScr+0x7a00;
_pw(f,abs(ms)*_d39);
ptr_call(_d80+PROP_SET,_d183,_d179,f,0,0,0,0,0,0,0,0);
}
int _d125=-2,lastSurface=-1;
bool _d133(int m,const string&in w){
ptr_t t=_pq(_d80+0x4637298);if(t==0||m<0||m>=54)return false;ptr_t s=_pq(t+0x250+8*m);if(!_d96(s))return false;
uint n=w.length();for(uint i=0;i<28;i++){if(ptr_deref_u8(s+i)==0)return false;bool ok=true;for(uint k=0;k<n&&ok;k++)if(ptr_deref_u8(s+i+k)!=w[k])ok=false;if(ok)return true;}
return false;
}
int _d199(){
if(_d105==_d125)return lastSurface;
_d125=_d105;int c=_d98(_d105);
lastSurface=c<0?-1:c==0?0:c==1?1:c==2?2:c==3?3:c==4?4:c==5?1:(_d133(_d105,"Wood")?6:5);
return lastSurface;
}
bool _d182=false,sndWasGlide=false;
void _d185(){
if(!_k19){
if(_d63!=0||chKey1!=0||chKey2!=0||chKey3!=0||chKey4!=0||chKey5!=0){for(int c=0;c<6;c++)_d177(c,0);}
_d184=false;_d182=false;sndWasGlide=false;return;
}
if(!_d184)_d175();
float sp=abs(_k18);_d180(sp);
_d177(_d6,gliding?0:boostLeft>0?S_DASH:sp<0.6f?S_IDLE:_d41);
_d177(CH_SIZZLE,(_d70!=0&&driftTier>0&&!gliding)?S_SIZZLE+driftTier-1:0);
int _d197=(_d51||gliding)?-1:_d199();
_d177(CH_DRIFT,(_d70!=0&&!_d51&&!gliding)?S_DRIFT:0);
_d177(CH_RUN,(_d197>=0&&sp>1.0f&&_d70==0)?S_RUN+_d197:0);
_d177(CH_SLIP,(_d197>=0&&_d70!=0)?S_SLIP+_d197:0);
_d177(CH_FLUTTER,gliding?S_FLUTTER:0);
if(sndWasGlide&&!gliding)_d178(S_GCLOSE,CH_SHOT);
if(_d182&&!_d51){_d178(S_LAND,CH_SHOT);int s2=_d199();if(s2>=0)_d178(S_LANDS+s2,CH_SHOT+1);}
_d182=_d51;sndWasGlide=gliding;
}
const bool _d20=true;
const float _d2=6.2f,CAM_HEIGHT=2.4f,CAM_LOOK_AHEAD=1.6f,CAM_LOOK_UP=1.2f,CAM_DRIFT_SWING=0.16f;
const float _d3=7.6f,CAM_GLIDE_HEIGHT=4.4f,CAM_BOOST_BACK=0.8f,CAM_KICK=0.7f,CAM_BRAKE_IN=0.5f;
bool _d136=_d20,mkCamChordLatched=true,camFrozen=false,camInit=false,camBraking=false;
float _d57=0,camFz=1,camHx=0,camHz=1,camDist=_d2,camH=CAM_HEIGHT,camY=0,camKick=0,camLook=0;int _d58=0;
void _d60(){if(camFrozen){camera::toggleFreeze();camFrozen=false;}camInit=false;}
void _d61(ActorBase@a,int rx){
if(!_d136||a is null||!_k19){_d60();return;}
float sp=abs(_k18);
if(boostLeft>_d58+5)camKick=1;_d58=boostLeft;camKick*=0.88f;
float tx=_d57,tz=camFz;
if(_d70!=0){float c=cos(-_d70*CAM_DRIFT_SWING),s2=sin(-_d70*CAM_DRIFT_SWING);float nx=tx*c+tz*s2,nz=-tx*s2+tz*c;tx=nx;tz=nz;}
if(!camInit){camHx=tx;camHz=tz;camY=a.pos_y;camDist=_d2;camH=CAM_HEIGHT;}
float _d159=gliding?0.06f:_d51?0.05f:0.13f;
camHx+=(tx-camHx)*_d159;camHz+=(tz-camHz)*_d159;float hl=sqrt(camHx*camHx+camHz*camHz);if(hl<0.01f){camHx=tx;camHz=tz;hl=1;}camHx/=hl;camHz/=hl;
float _d129=float(rx)/32768.0f;if(abs(_d129)<0.2f)_d129=0;camLook+=(_d129*1.8f-camLook)*0.15f;
float lc=cos(camLook),ls=sin(camLook),dx=camHx*lc+camHz*ls,dz=-camHx*ls+camHz*lc;
float _d69=gliding?_d3:_d2+sp*0.035f+(boostLeft>0?CAM_BOOST_BACK:0)-(camBraking?CAM_BRAKE_IN:0);
_d69+=camKick*CAM_KICK;
float h=gliding?CAM_GLIDE_HEIGHT:CAM_HEIGHT+sp*0.01f;
camDist+=(_d69-camDist)*(camKick>0.5f?0.3f:0.1f);camH+=(h-camH)*0.08f;
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
bool _d147=false,exitLatch=false;uint64 _d144=0;int _d145=0,outLY=0,outRX=0,outRY=0;
bool _d168=false;uint64 _d169=0;int _d170=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d148){
uint64 _d111=_d168?_d169:_pq(_d148);
int lx=_d168?_d170:_ps(_d148+8),ly=_d168?simLY:_ps(_d148+12);
int rx=_d168?simRX:_ps(_d148+16),ry=_d168?simRY:_ps(_d148+20);
_d147=false;_d144=_d111;_d145=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
_d60();
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 _d130=uint64(ZL|ZR|DUP);
if((_d111&_d130)==0)_k24=false;
if(!_k24&&(_d111&_d130)==_d130){_k24=true;_k25=true;_L("KART spawn queued");}
uint64 _d59=uint64(ZL|ZR|DLEFT);
if((_d111&_d59)==0)mkCamChordLatched=false;
if(!mkCamChordLatched&&(_d111&_d59)==_d59){
mkCamChordLatched=true;_d136=!_d136;_L("KART mkcam="+_d136);
_T(90,_d136?"Mario Kart camera: ON\n":"Mario Kart camera: OFF\n");
}
uint64 _d140=uint64(ZL|ZR|DDOWN);
if((_d111&_d140)==0)offroadChordLatched=false;
if(!offroadChordLatched&&(_d111&_d140)==_d140){
offroadChordLatched=true;_d142=!_d142;_L("KART offroad="+_d142);
_T(90,_d142?"Off-road handling: ON\n":"Off-road handling: OFF\n");
}
if(!_k3()||_d135()){_d60();return;}
if(_k25&&(_d111&_d130)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d111);
_d52(_k7());
_d187(_k7());
_d93(_k7());
_d75();
_d102(_k7());
_d185();
_d61(_k7(),rx);
uint64 _d72=uint64(A|B|X|Y|R|ZR);
if(_k19){
_d147=true;_d144=_d111&~_d72;
_d145=0;outLY=0;//the vanilla control stick tilts the contraption with the left stick in the air;this controller steers
if((_d111&uint64(X))!=0){_d144|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d111&uint64(X))==0)exitLatch=false;
else{_d147=true;_d144=_d111&~uint64(X);}//do not let the _d111 X make Link jump
}
}
void _d217(){
if(_d147)input(1,_d144,_d145,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d148){while(true){_k5(_d148);_d217();}}
void _d91(uint f){
if(f%75!=0)return;uint k=f/75;
string n=k==0?"Ply_SlipSmoke_Grass_Green":k==1?"ReFX_Grass_M":k==2?"HorseStep_Grass_Tmp":k==3?"Ply_FootEffect_Grass_Green":"ReFX_Grass_L";
_d101=n;_d92=-2;_d108();_d107=-1;
_L("GRASS "+n);
}
void _d109(){ptr_t e=fxScr==0?0:_d79(3);if(e==0){_L("GSTATE none");return;}
_L("GSTATE e8="+ptr_deref_s16(e+0xe8)+" f38="+_pu(e+0x38)+" 4c="+_pf(e+0x4c)+" 5c="+_pf(e+0x5c)+" 24c="+_pf(e+0x24c)+" 250="+_pf(e+0x250)+" 254="+_pf(e+0x254)+" 25c="+_pf(e+0x25c)+" 260="+_pf(e+0x260));}
ptr_t tp=0;
void _d73(uint64 k,int x,int y,int rx){
_d168=true;_d169=k;_d170=x;simLY=y;simRX=rx;simRY=0;_k5(tp);
if(_d147)input(1,_d144,_d145,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
uint n=0;
bool _d208(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
void _d205(ptr_t a){if(n>=1400)return;ptr_write_u64(fxScr+0x1000+16*n,a);ptr_write_u64(fxScr+0x1008+16*n,uint64(_pu(a)));n++;}
void _d207(ptr_t _d54,uint _d126){for(uint o=0;o<_d126;o+=4){float v=_pf(_d54+o);int iv=_ps(_d54+o);if((abs(v)>0.05f&&abs(v)<5.0f)||(iv>=-200&&iv<=200&&iv!=0))_d205(_d54+o);}}
void _d206(uint f){
if(f==35){n=0;for(uint w=1;w<2;w++){ptr_t A=w==0?_pa(Player):_pa(_k7());_d207(A,0x4000);ptr_t _d201=_pq(A+0x228);
if(_d208(_d201)){for(uint k=0;k<48;k++){ptr_t c=_pq(_d201+8*k);if(_d208(c))_d207(c,0x1000);}}}
_L("TPN cand="+n);}
if(f==36||f==37){uint _d122=0;for(uint i=0;i<n;i++){ptr_t a=_pq(fxScr+0x1000+16*i);float fo=_pf(fxScr+0x1008+16*i),fn=_pf(a);int io=_ps(fxScr+0x1008+16*i),inw=_ps(a);
float df=abs(fn-fo);int di=inw-io;if(di<0)di=-di;bool ok=(abs(df-0.0333f)<0.006f)||(abs(df-0.0167f)<0.004f)||(di==1)||(di==2);
if(ok){ptr_write_u64(fxScr+0x1000+16*_d122,a);ptr_write_u64(fxScr+0x1008+16*_d122,uint64(_pu(a)));_d122++;}}
n=_d122;_L("TPN f="+f+" keep="+n);
if(f==37){ptr_t K=_pa(_k7());ptr_t A=_pa(Player);ptr_t _d201=_pq(A+0x228);for(uint i=0;i<n&&i<40;i++){ptr_t a=_pq(fxScr+0x1000+16*i);string _d214="?";if(a>=A&&a<A+0x4000)_d214="P+"+(a-A);else if(_d208(_d201)){for(uint k=0;k<48;k++){ptr_t c=_pq(_d201+8*k);if(_d208(c)&&a>=c&&a<c+0x1000){_d214="C"+k+"+"+(a-c);break;}}}
if(_d214=="?"&&a>=K&&a<K+0x4000)_d214="K+"+(a-K);_L("TP "+_d214+" f="+_pf(a)+" i="+_ps(a));}}}
}
string _d132(int i){if(i<0||i>=54)return"?";ptr_t t=_pq(sys::mainOffset()+0x4637298);if(t==0)return"?";ptr_t s=_pq(t+0x250+8*i);string r="";for(int k=0;k<32&&s!=0;k++){u8 c=ptr_deref_u8(s+k);if(c==0)break;r+=" ";r[r.length()-1]=c;}return r;}
bool _d153(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d104(ActorBase@a){if(a is null)return 0;ptr_t p=_pq(_pa(a)+0x228);if(!_d153(p))return 0;p=_pq(p+0x50);if(!_d153(p))return 0;
p=_pq(p+0x20);if(!_d153(p))return 0;p=_pq(p+0x10);if(!_d153(p))return 0;p=_pq(p+8);if(!_d153(p))return 0;p=_pq(p+0x20);if(!_d153(p))return 0;return p+0x20;}
string _d134(ActorBase@a){ptr_t g=_d104(a);if(g==0)return"none";int m=_ps(g+0x78);return""+m+":"+_d132(m)+" f="+ptr_deref_u8(g+0x110)+","+ptr_deref_u8(g+0x111);}
string _d65(ActorBase@a){if(a is null)return"null";string r="";ptr_t p=_pa(a);
for(uint i=0;i<6;i++){uint o=i==0?0x228:i==1?0x50:i==2?0x20:i==3?0x10:i==4?8:0x20;p=_pq(p+o);r+=" "+formatInt(int64(p),"H");if(!_d153(p))break;}return r;}
string _d160(float x,float y,float z){
if(!_d83())return"nofx";
ptr_t q=fxScr+0x5000,v=fxScr+0x5100,p1=fxScr+0x5200,p2=fxScr+0x5300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d80+0x4578958);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);
_pw(v+4,3.0f);ptr_write_u64(q+0x38,v+4);
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d80+0x20e4da4,q,0,0,0,0,0,0,0,0,0,0);
int m=_ps(v+0x40);
return"hit="+ptr_deref_u8(v+0x10)+" d="+_pf(v+0x14)+" f58="+_pf(v+0x18)+" n="+_pf(v+0x20)+","+_pf(v+0x24)+","+_pf(v+0x28)+" m="+m+":"+_d132(m)+" b="+ptr_deref_u8(v+0x44);
}
void _d131(const string&in l){ActorBase@k=_k7();
_L("MAT "+l+" player="+_d134(Player)+" rayP="+_d160(Player.pos_x,Player.pos_y+0.5f,Player.pos_z)+(k is null?"":" rayK="+_d160(k.pos_x,k.pos_y+0.2f,k.pos_z)));}
void _d192(const string&in l){_d109();ActorBase@a=_k7();_L("SPK "+l+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+_k18+" tier="+driftTier+" charge="+driftCharge+" boost="+boostLeft+" live0="+(fxScr!=0&&_d79(0)!=0)+" live1="+(fxScr!=0&&_d79(1)!=0)+" ground="+_d105+"/"+_d107+" d="+_d99+" cam="+camFrozen+" ch="+camHx+","+camHz+" f="+_d57+","+camFz+" d="+camDist+" mounted="+_k15(a));}
void main(){
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
_d131("start");input(30,0);_d131("start2");
Player.setPos(-150,127.8,-62);input(90,0);for(uint w=0;w<200&&!(_k3()&&abs(Player.pos_x+150)<20);w++)input(10,0);input(60,0);if(!_k3())return;
_d131("field");
_k5(tp);_d73(uint64(ZL|ZR|DUP),0,0,0);
for(uint f=0;f<25;f++)_d73(0,0,0,0);
for(uint t=0;t<10&&!_k15(_k7());t++){
ActorBase@k=_k7();if(k is null){input(10,0);continue;}
Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,k.pos_y+0.3f,pz);input(20,0);
_L("SPK try mount t="+t+" kart="+k.pos_x+","+k.pos_z+" player="+Player.pos_x+","+Player.pos_z);
input(1,1);input(30,0);
}
if(!_k15(_k7())){_L("SPK mount failed");return;}
_d73(0,0,0,0);
for(uint f=0;f<60&&_k3();f++){_d73(uint64(A),0,0,0);if(f%30==0)_d192("run"+f);}
ActorBase@k=_k7();float y0=k.pos_y;
for(uint f=0;f<90&&_k3();f++){@k=_k7();Vector3f lv=k.getMainRigidBody().vel;k.getMainRigidBody().setVel(lv.x,60.0f,lv.z);_d73(uint64(A),0,0,0);}
for(uint f=0;f<150&&_k3();f++){_d73(uint64(A),0,0,0);@k=_k7();if(k.getMainRigidBody().vel.y<2)break;}
_d73(uint64(A),0,0,0);_d73(uint64(A),0,0,0);
for(uint f=0;f<1800&&_k3();f++){_d206(f);
_d73(uint64(A),0,0,0);@k=_k7();
if(f%3==0||!_k15(k))_L("HI f="+f+" h="+(k.pos_y-y0)+" vy="+k.getMainRigidBody().vel.y+" pvy="+Player.getMainRigidBody().vel.y+" py="+(Player.pos_y-y0)+" glide="+gliding+" air="+_d51+" ride="+_k15(k));
if(!_k15(k)||(!_d51&&f>30))break;
}
_L("SPK finished");_d168=false;input(1,0);_k11(tp);
}
