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
bool _k20=false;float _d170=0,_w15=0;
float _d220=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d121=false;
const float _d35=7.775f;//[table]PRSL ground top speed,0 coins
const float _d27=0.011f;//[table]PRAC strength(G)
const float _d26=0.09f;//[table]PRAC limiter(M)
const float _d36=0.0118f;//[table]PRTL _d219,rad per MK frame
const float _d32=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d30=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d37=0.75f;//[table]PRON road traction
const float _d40=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d39=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d88)
const uint _d51=153;//[chosen]ultra _d147(not in the table):SMT+(SMT-MT)
const float _d9=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d38=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d34=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d29=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d31=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d33=0.993f;//[chosen]decay above _d226(after a boost)
const float _d28=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d20=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d11=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d221 0.001
const float _d12=0.8f;//[native]drift _d219 _d218 _w12,approached at 10%/frame,_d221<=0.07
const float _d8=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d134>=0.71 else 2
const float _d23=4.2f;//[chosen]drift _d125,m/s upward(~0.4 m,visible from the chase camera)
const int _d49=15;//[chosen]0.5 s
int _d232=0,trickRollDir=1;
const int _d3=24;const float _d2=5.0f;bool _d60=true,autoGlideBlocked=false,autoGlideChordLatched=true;
void _d217(float _d219){_d232=_d49;trickRollDir=_d219<-0.3f?-1:1;}//stick left spins the other way
const float _d1=0.3f,AIR_GAP=0.7f;const int _d50=8,TRICK_FRAMES=31;//trick:also R up to 6 _d88 before take-off
const float _d18=0.95f;//[measured]TOTK pulls the kart down~0.95 m/s per frame;added back so the glide _d195 settles at _d226
const float _d19=8.225f,GLIDE_SINK=1.6f,GLIDE_DIVE=4.5f,GLIDE_FLOAT=0.6f,GLIDE_STEER=0.6f,GLIDE_MIN_HEIGHT=2.5f;
const float _d0=9.0f,GLIDE_SIDE_DRAG=0.08f,AIR_SIDE_DRAG=0.01f;//[chosen]per half-frame _d221
const float _d17=0.55f,GLIDE_PITCH=0.35f,GLIDE_TILT_GAIN=4.0f,GLIDE_MAX_LEAN=0.65f;//[chosen]~29 deg _d61,~19 deg nose-down,~33 deg combined max
bool _d58=false,trickDone=false,gliding=false,gliderLatch=true;int _d57=0,groundFrames=0,trickWindow=0,rPressAge=99;
const bool _d41=false;
const float _d42=0.7f,OFFROAD_HEAVY=0.5f;//[table]PROF
bool _d163=_d41,offroadChordLatched=true;
float _d158=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d81=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d126=false,gasLatch=true,idleHold=false;
bool _d156(){return pause::isPauseRequest("GamePause")||pause::isPauseRequest("PreGamePause")||pause::isPauseRequest("PostGamePause")||pause::isPauseTarget("Custom_PhysicsUpdateWorld");}
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d124=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d124==0)return 0;
uint op=_pu(_d124);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d79=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d79-=0x04000000;
ptr_t _d226=ptr_t(int64(_d124)+_d79*4);
if(_pu(_d226)!=0xf0001382||_pu(_d226+4)!=0xa9be7bfd)return 0;
ptr_t _d62=_d226-0x65b80;if((_d62&0xfff)!=0)return 0;return _d62+0x3d90b8;
}
void _k13(){_d105=0;_d106=false;ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d184();_k19=false;_k20=false;_d170=0;_w15=0;_d121=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d218=_pu(_k16+0x24);if(_d218<2||_d218>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d128,uint _k27){
if(_d128 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d128);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d218=_pu(p+0x24);
return _d218>=2&&_d218<=6;
}
bool _k0(ActorBase@_d128,uint _k27){
if(Player is null||!_k1(_d128,_k27))return false;
ptr_t _d53=_pa(_d128),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d78=_pu(_d53+0x220);ptr_t _d148=_pq(_d53+0x228);
if(_d78<=129||_d78>512||!_k2(_d148))return false;
ptr_t _d77=_pq(_d148+0x408);
if(!_k2(_d77))return false;
uint _d190=_pu(_d77+0x20);ptr_t _k29=_pq(_d77+0x28);
if(_d190!=1||!_k2(_k29))return false;
ptr_t _d188=_pq(_k29);
if(!_k2(_d188))return false;
uint _d189=_pu(_d188+0x10),flags=_pu(_d188+0x18);
float _k33=_pf(_d188+0x74);
if(_d189!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d188+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d128,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d170=a.pos_x;_w15=a.pos_z;return;}
float dx=_d170-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d170=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
int _d142=0,spawnedType=0;bool _d137=true;
string _d136(int t){return t==1?"SpObj_ControlStick_A_02":t==2?"SpObj_ControlStick_A_03":t==3?"SpObj_ControlStick_A_04":"SpObj_ControlStick_A_01";}
string _d139(int t){return t==1?"Pipe Frame":t==2?"B Dasher":t==3?"Standard Bike":"Standard Kart";}
const int _d24=4;bool _d135(int t){return t==3;}
float _d140(int t){return t==1?1.0f:t==2?1.18f:t==3?1.275f:1.0f;}
float _d141(int t){return t==1?1.2f:t==2?1.42f:t==3?1.275f:1.3f;}
void _k8(){
if(!_k3())return;
ActorBase@_d164=_k7();
if(_k15(_d164)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d147=sqrt(fx*fx+fz*fz);if(_d147<0.1f)return;fx/=_d147;fz/=_d147;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d164!is null&&spawnedType!=_d142){_k13();@_d164=null;}//a different kart was chosen:spawn it(the _d164 one stays)
if(_d164!is null){_k10(_d164);_d164.setPos(x,y,z);@_d164=null;_d170=0;_w15=0;_d121=false;}
else{_k13();actor::createAndWatch(2,_d136(_d142),x,y,z);spawnedType=_d142;sleep(60);}//let creation get past its first _d88 before touching the _d53
for(uint f=0;f<600&&_k3();f++){//up to 20 s:a first load of a kart pack can take a while
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);if(!_d107(_k16)){@a=null;sleep(1);continue;}_k17=_pu(_k16+0x10);
ptr_t ct=_pq(_k16+0x228);bool _d172=_d107(ct)&&_d107(_pq(ct+0x50))&&_d107(_pq(_pq(ct+0x50)+0x20));
if(_d172&&a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d170=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d235(ActorBase@a){
ptr_t _d148=_pq(_pa(a)+0x228);if(!_k2(_d148))return 0;
ptr_t mc=_pq(_d148+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
float lf=_pf(b+120),rf=_pf(b+216),lb=_pf(b+312),rb=_pf(b+408);
if(abs(_pf(b+28)-0.3766f)>(_d135(spawnedType)?0.08f:0.002f)||abs(lf+rf)>0.002f||abs(lb+rb)>0.002f)return 0;//(a leaning bike moves its root)
if(_d135(spawnedType)){if(abs(lf)>0.01f||abs(lb)>0.01f)return 0;}//bike:both sockets of an axle on the centre line
else if(lf<0.5f||lf>1.2f||lb<0.5f||lb>1.2f)return 0;
return b;
}
void _d236(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
const float _d48=0.3927f;//2*pi/16 tread _d65
float _d233(float _d221){
float m=abs(_d221),half=_d48*0.5f;
if(m<=half*0.9f)return _d221;
float _d65=floor((m-half)/_d48);if(_d65>3)_d65=3;
float v=(_d65+0.5f)*_d48;return _d221<0?-v:v;
}
void _d59(ActorBase@a){
if(a is null){_d121=false;return;}
Matrix33f r=a.rot;float _d147=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d121&&_d147>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d147;}
_w4=x;_w5=z;_d121=true;
_w2+=_d233(ds/(0.28328f*_d140(spawnedType)));_w3+=_d233(ds/(0.28328f*_d141(spawnedType)));//tyre radius x body tyre scale
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d220*0.45f-_w1)*0.25f;
ptr_t b=_d235(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d236(b+72,sf,cf,sd,cd);_d236(b+168,sf,cf,sd,cd);
_d236(b+264,sr,cr,0,1);_d236(b+360,sr,cr,0,1);
if(_d135(spawnedType))_d63(b);
}
const float _d4=0.38f,BIKE_DRIFT_LEAN=0.5f,BIKE_PIVOT_Y=-0.30f;//[chosen]~22 deg turning,~29 deg drifting
float _d64=0;
void _d63(ptr_t b){
float sp=abs(_d158)/_d35;if(sp>1)sp=1;
float _d226=_d58||gliding?0:(_d81!=0?_d81*BIKE_DRIFT_LEAN*(0.7f+0.3f*abs(_d220)):_d220*_d4*sp);
_d64+=(_d226-_d64)*0.12f;
float c=cos(_d64),s=sin(_d64);ptr_t r=b-24;
_pw(r,c);_pw(r+4,s);_pw(r+8,0);
_pw(r+16,-s);_pw(r+20,c);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,1);
_pw(r+48,s*BIKE_PIVOT_Y);_pw(r+52,0.3766f+BIKE_PIVOT_Y-c*BIKE_PIVOT_Y);_pw(r+56,0);
}
void _d184(){_d232=0;_d58=false;trickDone=false;gliding=false;_d57=0;groundFrames=0;trickWindow=0;_d158=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d81=0;driftTier=0;boostLeft=0;hopWindow=0;_d126=false;gasLatch=true;idleHold=false;}
int _d116=-1;float _d110=99;//updated by _d113(ray cast under the kart)
float _d227(){
if(!_d163||_d110>=0.8f)return 1;
int m=_d116;
if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;//HeavySand,HeavySnow,Bog,Tar,Water,ContaminatedWater
if(m==1||m==2||m==3||m==5)return _d42;//Soil,Grass,Sand,Snow
return 1;
}
float _d215(float v,float _d228){
if(boostLeft>0){
boostLeft--;float t=_d35*_d40;
if(v<t){float _d131=(t-v)*_d28;if(_d131>MK_BOOST_CAP)_d131=MK_BOOST_CAP;return v+_d131;}
return t;
}
if(_d228>0){
if(v<0)return v+_d29>0?0:v+_d29;//stop reversing first
float t=_d35*_d228*_d227();
if(v<t){float _d131=(t-v)*_d27;if(_d131>_d26)_d131=_d26;return v+_d131;}//[native]form
float d=v*_d33;return d<t?t:d;
}
if(_d228<0){
if(v>0)return v-_d29<0?0:v-_d29;//brake,then reverse
float t=-_d34*(-_d228);
if(v>t){float _d131=(v-t)*_d27;if(_d131>_d26)_d131=_d26;return v-_d131;}
return v;
}
if(v>0)return v-_d31<0?0:v-_d31;
return v+_d31>0?0:v+_d31;
}
void _d82(int _d229){
_L("KART drift tier="+_d229+" charge="+driftCharge);
if(_d229==1)_T(30,"Mini-Turbo\n");else if(_d229==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d122){
_d220=0;
ActorBase@a=_k7();bool _d186=_k15(a);
if(_d186!=_k19){_L("KART mounted="+_d186);_d184();_k19=_d186;_k20=!_d186;if(a!is null){_d170=a.pos_x;_w15=a.pos_z;}}
if(!_d186||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d184();return;}
float _d219=float(ix)/32768.0f,_d228=0;
if(abs(_d219)<0.15f)_d219=0;
bool _d101=(_d122&uint64(A))!=0,brake=(_d122&uint64(B))!=0;
if(!_d101)gasLatch=false;//the A press used to get in must be released first
if(brake)_d228=-1;else if(_d101&&!gasLatch)_d228=1;
_d220=_d219;
Matrix33f r=a.rot;float _d147=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d147<0.1f||r.a4<0.4f){_k10(a);_d184();return;}
float bx=r.a2/_d147,bz=r.a8/_d147,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
_d67=fx;camFz=fz;camBraking=brake&&_d158>0.5f;
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d54=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d55=_d54/_d38;
if(_d158>0&&_d158>_d55+0.6f)_d158=_d55+0.6f<0?0:_d55+0.6f;
if(_d158<0&&_d158<_d55-0.6f)_d158=_d55-0.6f>0?0:_d55-0.6f;
bool _d180=(_d122&uint64(R|ZR))!=0,fast=_d158>_d35*0.35f;
if(_d94())_d117(a.pos_x,a.pos_y+0.2f,a.pos_z);
bool _d167=_d110<AIR_GAP;
if(_d167){groundFrames++;_d57=0;}else{_d57++;groundFrames=0;}
bool _d234=_d58;
bool _d179=_d180&&!_d126;rPressAge=_d179?0:rPressAge+1;
if(!_d58&&_d57>=2){
_d58=true;trickWindow=_d50;trickDone=false;_L("KART airborne");
if(rPressAge<=6+_d57){trickDone=true;_d217(_d219);_d202(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick (buffered)");}
}
if(_d58&&groundFrames>=1){
_d58=false;
if(gliding){gliding=false;_L("KART glider landed");}
if(trickDone){if(boostLeft<TRICK_FRAMES)boostLeft=TRICK_FRAMES;_d202(_d47,CH_SHOT);_L("KART trick boost");}
trickDone=false;_L("KART landed");
}
float _d125=0;
bool _d178=_d180&&!_d126;
if(_d58){
if(trickWindow>0){trickWindow--;if(_d178&&!trickDone){trickDone=true;_d217(_d219);_d202(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick");}}
}else if(_d178){_d125=_d23;hopWindow=24;_d202(S_HOP,CH_SHOT);}//MK8 hops at any speed
_d126=_d180;
bool _d237=(_d122&uint64(Y))!=0;
if(!_d237)gliderLatch=false;
if(_d237&&!gliderLatch){
gliderLatch=true;
if(gliding){gliding=false;autoGlideBlocked=true;_L("KART glider folded");}
else if(_d58&&_d110>=GLIDE_MIN_HEIGHT){gliding=true;_d202(S_GOPEN,CH_SHOT);_d81=0;driftCharge=0;driftTier=0;_T(30,"Glider!\n");_L("KART glider open");}
}
if(!_d58)autoGlideBlocked=false;
if(_d60&&_d58&&!gliding&&!autoGlideBlocked&&_d232==0&&_d57>=_d3&&v.y<-_d2&&_d110>=GLIDE_MIN_HEIGHT){
gliding=true;autoGlideBlocked=true;_d202(S_GOPEN,CH_SHOT);_d81=0;driftCharge=0;driftTier=0;_L("KART glider auto");
}
if(_d81==0&&!_d58&&_d180&&hopWindow>0&&abs(_d219)>0.3f){_d81=_d219>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d81);}
if(_d81!=0&&(!_d180||!fast)){
int _d88=driftTier==3?int(_d51):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d39):0;
if(_d88>0&&_d180==false){boostLeft=_d88;_d202(driftTier==3?S_ULTRA:_d47,CH_SHOT);_L("KART boost tier="+driftTier+" frames="+_d88);}
_d81=0;driftCharge=0;driftTier=0;
}
if(!_d58&&_d228==0&&boostLeft==0&&_d81==0&&_d125==0&&abs(_d158)<_d31){
_d158=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d170=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d238=0,oldOff=bodyOff;
for(int _d221=0;_d221<2;_d221++){
if(hopWindow>0)hopWindow--;
if(gliding){float t=_d19*(iy>16000?1.06f:1.0f);_d158+=(t-_d158)*0.02f;}
else if(!_d58||boostLeft>0)_d158=_d215(_d158,_d228);
float _d66=0;
if(gliding){
driftTrack=0;_d238+=_d219*_d36*GLIDE_STEER;
}else if(_d81!=0){
float _d134=_d219*_d81;if(_d134>1)_d134=1;if(_d134<-1)_d134=-1;
float _d231=_d134>=0?_d12:-_d12,dt=(_d231-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d133=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d238+=_d81*_d32*_d133*_d133*(0.75f+0.25f*_d134);
if(!_d58)driftCharge+=_d134>=CHARGE_INWARD?_d8:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d229=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d9?1:0;
if(_d229>driftTier){driftTier=_d229;_d82(_d229);}
_d66=_d81*_d11;
}else{
driftTrack=0;
float _d213=abs(_d158)/(_d35*0.25f);if(_d213>1)_d213=1;
_d238+=_d219*_d36*_d213*(_d158<0?-1.0f:1.0f)*(_d58?_d1:1.0f);
}
if(_d232>0){bodyOff+=6.2832f/float(_d49*2)*float(trickRollDir);}
else{
float _d100=_d66-bodyOff,ds=_d100*0.07f;
if(abs(ds)<0.001f)ds=abs(_d100)<0.001f?_d100:(_d100>0?0.001f:-0.001f);
bodyOff+=ds;
}
if(!_d58)lateral*=1-_d20*_d37;
else lateral*=gliding?1-GLIDE_SIDE_DRAG:1-AIR_SIDE_DRAG;
}
if(_d232>0){_d232--;if(_d232==0||!_d58){_d232=0;while(bodyOff>3.1416f)bodyOff-=6.2832f;while(bodyOff<-3.1416f)bodyOff+=6.2832f;}}
_k18=_d158*_d38;
float _d214=_k18;
float vy=v.y+_d125;
if(gliding){
float _d195=iy>16000?GLIDE_DIVE:iy<-16000?GLIDE_FLOAT:GLIDE_SINK;//stick forward dives,back floats
vy+=(-_d195-vy)*0.3f+_d18;//ease into the glide descent(gravity compensated)
}
if(gliding&&vy<-_d0)vy=-_d0;//glider only(user:free fall must stay normal speed)
b.setVel(fx*_d214+lx*lateral,vy,fz*_d214+lz*lateral);
float tx=0,ty=1,tz=0,gain=2.0f;
if(gliding){
float _d173=float(iy)/32768.0f;if(_d173>1)_d173=1;if(_d173<-1)_d173=-1;
float _d61=_d219*_d17,nose=_d173*GLIDE_PITCH;//stick right:right side down;stick forward:nose down
tx=-lx*_d61+fx*nose;tz=-lz*_d61+fz*nose;
float _d123=sqrt(tx*tx+tz*tz);if(_d123>GLIDE_MAX_LEAN){tx*=GLIDE_MAX_LEAN/_d123;tz*=GLIDE_MAX_LEAN/_d123;}
ty=1;float tl=sqrt(tx*tx+ty*ty+tz*tz);tx/=tl;ty/=tl;tz/=tl;gain=GLIDE_TILT_GAIN;
}
float ux=r.a1,uy=r.a4,uz=r.a7;
float wx=(uy*tz-uz*ty)*gain,wz=(ux*ty-uy*tx)*gain;//world axes(a body-axis version flipped the kart)
b.setAngularVel(wx,-(_d238+bodyOff-oldOff)*30.0f,wz);
}
const uint _d15=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float _d45=0.35f,FLAME_SCALE=0.15f;//[chosen]from screenshots
ptr_t _d91=0,fxSys=0,fxScr=0;int _d95=-2,fxFlame=-1;
bool _d92(ptr_t p,const string&in _d159){
uint n=_d159.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=_d159[i])return false;
return ptr_deref_u8(p+n)==0;
}
int _d89(const string&in _d159){
ptr_t _d183=_pq(_pq(fxSys+0x2ee8)+8);if(_d183==0||ptr_deref_u8(_d183+0x571)==0)return-1;//static effects=resource 1
int n=_ps(_d183+0x558);ptr_t _d191=_pq(_d183+0x430);
for(int i=0;i<n;i++)if(_d92(_pq(_d191+0x28*i)+0x10,_d159))return i;
return-1;
}
bool _d94(){
if(_d95>=0)return true;
if(_d95==-1)return false;//looked once and failed:stay off
_d95=-1;
ptr_t _d124=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d124==0)return false;
uint op=_pu(_d124);int64 _d79=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d79-=0x04000000;
ptr_t _d226=ptr_t(int64(_d124)+_d79*4),_d62=_d226-0x65b80;
if((_d62&0xfff)!=0||_pu(_d226)!=0xf0001382)return false;
fxScr=_d62+FX_SCRATCH;_d91=sys::mainOffset();
ptr_t _d132=_pq(_pq(_d91+_d15));if(_d132==0)return false;
fxSys=_pq(_d132+0x11b8);if(fxSys==0)return false;
int _d210=_d89("Ply_ShockWave_Spark");fxFlame=_d89("Chm_FlameThrower_ScraBuild");//Zonai _d85 emitter jet
_L("KART fx spark="+_d210+" flame="+fxFlame);
if(_d210<0)return false;
_d95=_d210;return true;
}
ptr_t _d90(int _d197){ptr_t h=fxScr+0x10*_d197,e=_pq(h);if(e==0)return 0;return _pu(e+0x234)==_pu(h+8)?e:0;}
ptr_t _d96(int _d197,int id){
ptr_t e=_d90(_d197);if(e!=0)return e;
ptr_t h=fxScr+0x10*_d197;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d91+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*_d197,0,0,0,0,0);
return _d90(_d197);
}
void _d98(int _d197){if(fxScr==0)return;ptr_t e=_d90(_d197);if(e!=0)ptr_call(_d91+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*_d197,0);}
void _d93(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
_pw(m,r.a0);_pw(m+4,r.a1);_pw(m+8,r.a2);_pw(m+12,px);
_pw(m+16,r.a3);_pw(m+20,r.a4);_pw(m+24,r.a5);_pw(m+28,py);
_pw(m+32,r.a6);_pw(m+36,r.a7);_pw(m+40,r.a8);_pw(m+44,pz);
_pw(fxScr+0x140,s);_pw(fxScr+0x144,s);_pw(fxScr+0x148,s);
ptr_call(_d91+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
void _d99(ptr_t e,float r,float g,float b){_pw(e+0x40,r);_pw(e+0x44,g);_pw(e+0x48,b);}
void _d211(ActorBase@a){
bool _d212=a!is null&&_k19&&_d81!=0&&driftTier>0;
bool _d85=a!is null&&_k19&&boostLeft>0;
if(!_d212&&!_d85&&fxScr==0)return;
if(!_d94()){return;}
if(!_d212)_d98(0);
if(!_d85||fxFlame<0)_d98(1);
if(_d212){
ptr_t e=_d96(0,_d95);
if(e!=0){
if(driftTier==1)_d99(e,0.25f,0.8f,6.0f);else if(driftTier==2)_d99(e,1.0f,1.0f,1.0f);else _d99(e,2.2f,0.4f,6.0f);
ptr_t b=_d235(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(_pf(b+312));wy=_pf(b+28)+_pf(b+316)-0.3683f;wz=_pf(b+32)+_pf(b+320);}
_d93(e,a,wx,wy,wz,_d45);_d93(e,a,-wx,wy,wz,_d45);
}
}
if(_d85&&fxFlame>=0){ptr_t e=_d96(1,fxFlame);if(e!=0){_d93(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);_d93(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
const uint _d14=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int _d118=-1,groundTick=0;
int _d103=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;//effect ids per class,looked up once(no arrays in this runtime)
bool _d117(float x,float y,float z){
ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d91+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);//flags:all false
_pw(v+4,2.0f);ptr_write_u64(q+0x38,v+4);//ray _d147(m)
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d91+_d14,q,0,0,0,0,0,0,0,0,0,0);
if(ptr_deref_u8(v+0x10)==0){_d116=-1;_d110=99;return false;}
_d116=_ps(v+0x40);_d110=_pf(v+0x14);return true;
}
int _d109(int m){
if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return-1;return 6;
}
string _d112="";//diagnostics only:overrides the grass effect _d159
string _d111(int c){
if(c==0&&_d112!="")return _d112;
if(c==0)return"ReFX_Grass_L";if(c==1||c==2)return"ReFX_Sand_L";if(c==3)return"ReFX_Snow_L";
if(c==4)return"Water_Splash01_Move";if(c==5)return"RctFld_Mud_Splash_S";return"Ply_SlipSmoke_Stone";
}
int _d114(int c){
if(c==0){if(_d103==-2)_d103=_d89(_d111(0));return _d103;}if(c==1){if(gid1==-2)gid1=_d89(_d111(1));return gid1;}
if(c==2){if(gid2==-2)gid2=_d89(_d111(2));return gid2;}if(c==3){if(gid3==-2)gid3=_d89(_d111(3));return gid3;}
if(c==4){if(gid4==-2)gid4=_d89(_d111(4));return gid4;}if(c==5){if(gid5==-2)gid5=_d89(_d111(5));return gid5;}
if(gid6==-2)gid6=_d89(_d111(6));return gid6;
}
const float _d22=1.2f,GROUND_MIN_SPEED=3.0f;//[chosen]
const int _d21=6;//[chosen]_d88 between bursts:TOTK's ground effects are one-shot(per footstep/hoof)
int _d108=0,groundBurstSlot=0;
void _d119(){if(fxScr==0)return;for(int k=3;k<7;k++)_d98(k);}
ptr_t _d97(int _d197,int id,ptr_t _d177){
ptr_t h=fxScr+0x10*_d197;_d98(_d197);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d91+FX_CREATE,fxSys,h,id,1,0,_d177,0,0,0,0,0);
return _d90(_d197);
}
void _d113(ActorBase@a){
bool _d52=a!is null&&_k19&&_d94();
if(!_d52){_d119();_d118=-1;return;}
int c=_d110<0.8f?_d109(_d116):-1;
bool _d162=c>=0&&c<6,show=c>=0&&abs(_k18)>GROUND_MIN_SPEED&&(_d162||_d81!=0);
_d118=show?c:-1;
if(!show){_d108=0;return;}
if(_d108-->0)return;
_d108=_d21;
int id=_d114(c);if(id<0)return;
int _d197=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
ptr_t e=_d97(_d197,id,fxScr+0x5000);if(e==0)return;
float wx=0.78f,wz=-0.75f;ptr_t b=_d235(a);if(b!=0){wx=abs(_pf(b+312));wz=_pf(b+32)+_pf(b+320);}
_d93(e,a,wx,0,wz,_d22);_d93(e,a,-wx,0,wz,_d22);
}
const float _d16=-0.15f,GLIDER_Z=-0.45f;//[chosen]attach point in kart space(glider frame _d62)
float _d105=0;bool _d106=false;
ptr_t _d130=0,hostSklAt=0;
ptr_t _d129(ActorBase@a){
ptr_t _d148=_pq(_pa(a)+0x228);if(!_k2(_d148))return 0;
ptr_t mc=_pq(_d148+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
if(m==_d130&&hostSklAt!=0)return hostSklAt;
_d130=m;hostSklAt=0;_d106=false;//new kart(model instances are pooled:a reused one can keep an open glider)
for(uint o=0;o<0x4000;o+=4){
ptr_t r=m+o;
if(abs(_pf(r+52)-0.3766f)<0.003f&&abs(_pf(r+48))<0.003f&&abs(_pf(r+56))<0.003f
&&abs(_pf(r+96+52)-0.5966f)<0.003f&&abs(_pf(r+96+56)-0.4928f)<0.003f){hostSklAt=r;_L("KART host Skl_Root record at +"+o);break;}
}
return hostSklAt;
}
void _d104(ActorBase@a){
float _d226=(a!is null&&_k19&&gliding)?1:0;
if(_d226==0&&_d105==0&&_d106)return;
if(a is null)return;
ptr_t _d196=_d129(a);if(_d196==0)return;
if(_d105<_d226){_d105+=0.17f;if(_d105>_d226)_d105=_d226;}
else if(_d105>_d226){_d105-=0.2f;if(_d105<_d226)_d105=_d226;}
ptr_t r=_d196-192;float sc=_d105;//Control=bone 1,two records before Skl_Root(bone 3)
_pw(r,sc);_pw(r+4,0);_pw(r+8,0);
_pw(r+16,0);_pw(r+20,sc);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,sc);
_pw(r+48,0);_pw(r+52,_d16);_pw(r+56,GLIDER_Z);
_d106=true;
}
const uint _d13=0x1085b5c;
bool _d87=false;
bool _d107(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d174(){
if(Player is null)return 0;ptr_t p=_pq(_pa(Player)+0x228);if(!_d107(p))return 0;
p=_pq(p+0x50);if(!_d107(p))return 0;p=_pq(p+0x20);return _d107(p)?p:0;
}
void _d86(){
if(!_k19&&!_d87)return;
ptr_t _d171=_d174();if(_d171==0)return;
ptr_call(sys::mainOffset()+_d13,_d171,_k19?0:1,0,0,0,0,0,0,0,0,0);
_d87=_k19;
}
const uint _d43=0x809ee0,SND_FADE=0xb226a4,PROP_SET=0x11acb98;
const int _d10=0,CH_SIZZLE=1,CH_DRIFT=2,CH_RUN=3,CH_SLIP=4,CH_FLUTTER=5,CH_SHOT=6;
const float _d44=1.0f/14.0f;//[chosen]top speed(14 m/s)=1=top of curve 213
const int _d46=1,S_DASH=2,S_IDLE=3,S_SIZZLE=4,S_DRIFT=7,S_FLUTTER=8,S_RUN=10,S_SLIP=20,S_LANDS=30;
const int _d47=40,S_ULTRA=41,S_HOP=42,S_LAND=43,S_TRICK=44,S_GOPEN=45,S_GCLOSE=46,S_HORN=47;
int _d200=0;int _d74=0,chKey1=0,chKey2=0,chKey3=0,chKey4=0,chKey5=0;
string _d223(int s){return s==0?"Grass":s==1?"Dirt":s==2?"Sand":s==3?"Snow":s==4?"Water":s==5?"Stone":"Wood";}
string _d144(int id){
if(id==_d46)return"Kart_Engine";if(id==S_DASH)return"Kart_EngineDash";if(id==S_IDLE)return"Kart_Idle";
if(id>=S_SIZZLE&&id<S_SIZZLE+3)return"Kart_Sizzle"+(id-S_SIZZLE+1);if(id==S_DRIFT)return"Kart_DriftSteer";
if(id==S_FLUTTER)return"Kart_GliderFlutter";if(id>=S_RUN&&id<S_RUN+7)return"Kart_Run_"+_d223(id-S_RUN);
if(id>=S_SLIP&&id<S_SLIP+7)return"Kart_Slip_"+_d223(id-S_SLIP);if(id>=S_LANDS&&id<S_LANDS+7)return"Kart_Land_"+_d223(id-S_LANDS);
if(id==_d47)return"Kart_MiniTurbo";if(id==S_ULTRA)return"Kart_UltraTurbo";if(id==S_HOP)return"Kart_Hop";if(id==S_LAND)return"Kart_Land";
if(id==S_TRICK)return"Kart_Trick";if(id==S_HORN)return"Kart_Horn";if(id==S_GOPEN)return"Kart_GliderOpen";if(id==S_GCLOSE)return"Kart_GliderClose";return"";
}
ptr_t _d207=0;int _d203=-1;bool _d208=false;
ptr_t _d205(){
ActorBase@a=_k7();if(a is null||!_d94())return 0;
ptr_t x=_pq(_pa(a)+0x228);if(!_d107(x))return 0;
x=_pq(x+0x68);if(!_d107(x))return 0;
ptr_t u=_pq(x+0x78);return _d107(u)?u:0;
}
void _d202(int id,int ch){
ptr_t u=_d205();if(u==0||id<=0)return;string _d143=_d144(id);
ptr_t k=fxScr+0x7800,h=fxScr+0x7880+8*ch;uint n=_d143.length();
for(uint w=0;w<4;w++){uint64 v=0;for(uint i=0;i<8;i++){uint c=w*8+i;if(c<n)v|=uint64(_d143[c])<<(8*i);}ptr_write_u64(k+8*w,v);}
ptr_write_u64(h,0xffff00ff);
ptr_call(_d91+_d43,u,k,h,0,0,0,0,0,0,0,0);
if(_d200<80){_d200++;_L("KART snd "+_d143+" h="+_pq(h));}
}
void _d198(int ch){if(fxScr==0)return;ptr_t h=fxScr+0x7880+8*ch;if(_pq(h)!=0xffff00ff)ptr_call(_d91+SND_FADE,h,0xffffffff,0,0,0,0,0,0,0,0,0);ptr_write_u64(h,0xffff00ff);}
int _d73(int ch){return ch==0?_d74:ch==1?chKey1:ch==2?chKey2:ch==3?chKey3:ch==4?chKey4:chKey5;}
void _d75(int ch,int k){if(ch==0)_d74=k;else if(ch==1)chKey1=k;else if(ch==2)chKey2=k;else if(ch==3)chKey3=k;else if(ch==4)chKey4=k;else chKey5=k;}
void _d201(int ch,int _d143){
if(_d73(ch)==_d143)return;
if(_d73(ch)!=0)_d198(ch);
if(_d143!=0)_d202(_d143,ch);
_d75(ch,_d143);
}
bool _d176(ptr_t x){
if(!_d107(x))return false;uint n=_pu(x+0x110);if(n==0||n>16)return false;
ptr_t _d160=_pq(x+0x118);if(!_d107(_d160))return false;
for(uint i=0;i<n;i++){ptr_t s=_pq(_d160+8*i);if(_d107(s)&&_d92(s,"ControlStick_StickSpeedXY")){_d203=int(i);return true;}}
return false;
}
void _d199(){
_d208=true;_d207=0;_d203=-1;
ActorBase@a=_k7();if(a is null)return;
ptr_t p=_pq(_pa(a)+0x228);if(!_d107(p))return;
p=_pq(p);if(!_d107(p))return;
p=_pq(p+0x10);if(!_d107(p))return;
if(_d176(p))_d207=p;
_L("KART snd prop X="+(_d207!=0)+" idx="+_d203+" n="+_pu(p+0x110));
}
void _d204(float ms){
if(_d207==0||_d203<0)return;
ptr_t f=fxScr+0x7a00;
_pw(f,abs(ms)*_d44);
ptr_call(_d91+PROP_SET,_d207,_d203,f,0,0,0,0,0,0,0,0);
}
int _d145=-2,lastSurface=-1;
bool _d154(int m,const string&in w){
ptr_t t=_pq(_d91+0x4637298);if(t==0||m<0||m>=54)return false;ptr_t s=_pq(t+0x250+8*m);if(!_d107(s))return false;
uint n=w.length();for(uint i=0;i<28;i++){if(ptr_deref_u8(s+i)==0)return false;bool ok=true;for(uint k=0;k<n&&ok;k++)if(ptr_deref_u8(s+i+k)!=w[k])ok=false;if(ok)return true;}
return false;
}
int _d224(){
if(_d116==_d145)return lastSurface;
_d145=_d116;int c=_d109(_d116);
lastSurface=c<0?-1:c==0?0:c==1?1:c==2?2:c==3?3:c==4?4:c==5?1:(_d154(_d116,"Wood")?6:5);
return lastSurface;
}
bool _d206=false,sndWasGlide=false;
void _d209(){
if(!_k19){
if(_d74!=0||chKey1!=0||chKey2!=0||chKey3!=0||chKey4!=0||chKey5!=0){for(int c=0;c<6;c++)_d201(c,0);}
_d208=false;_d206=false;sndWasGlide=false;return;
}
if(!_d208)_d199();
float sp=abs(_k18);_d204(sp);
_d201(_d10,gliding?0:boostLeft>0?S_DASH:sp<0.6f?S_IDLE:_d46);
_d201(CH_SIZZLE,(_d81!=0&&driftTier>0&&!gliding)?S_SIZZLE+driftTier-1:0);
int _d222=(_d58||gliding)?-1:_d224();
_d201(CH_DRIFT,(_d81!=0&&!_d58&&!gliding)?S_DRIFT:0);
_d201(CH_RUN,(_d222>=0&&sp>1.0f&&_d81==0)?S_RUN+_d222:0);
_d201(CH_SLIP,(_d222>=0&&_d81!=0)?S_SLIP+_d222:0);
_d201(CH_FLUTTER,gliding?S_FLUTTER:0);
if(sndWasGlide&&!gliding)_d202(S_GCLOSE,CH_SHOT);
if(_d206&&!_d58){_d202(S_LAND,CH_SHOT);int s2=_d224();if(s2>=0)_d202(S_LANDS+s2,CH_SHOT+1);}
_d206=_d58;sndWasGlide=gliding;
}
const bool _d25=true;
const float _d5=6.2f,CAM_HEIGHT=2.4f,CAM_LOOK_AHEAD=1.6f,CAM_LOOK_UP=1.2f,CAM_DRIFT_SWING=0.16f;
const float _d7=3.0f,CAM_LEAD=0.07f;//[chosen]seconds of fall to lead
const float _d6=7.6f,CAM_GLIDE_HEIGHT=4.4f,CAM_BOOST_BACK=0.8f,CAM_KICK=0.7f,CAM_BRAKE_IN=0.5f;
bool _d157=_d25,mkCamChordLatched=true,camFrozen=false,camInit=false,camBraking=false;
float _d67=0,camFz=1,camHx=0,camHz=1,camDist=_d5,camH=CAM_HEIGHT,camY=0,camKick=0,camLook=0;int _d68=0;
void _d70(){if(camFrozen){camera::toggleFreeze();camFrozen=false;}camInit=false;}
void _d71(ActorBase@a,int rx,int ry){
if(!_d157||a is null||!_k19){_d70();return;}
float sp=abs(_k18);
if(boostLeft>_d68+5)camKick=1;_d68=boostLeft;camKick*=0.88f;
float tx=_d67,tz=camFz;
if(_d81!=0){float c=cos(-_d81*CAM_DRIFT_SWING),s2=sin(-_d81*CAM_DRIFT_SWING);float nx=tx*c+tz*s2,nz=-tx*s2+tz*c;tx=nx;tz=nz;}
if(!camInit){camHx=tx;camHz=tz;camY=a.pos_y;camDist=_d5;camH=CAM_HEIGHT;}
float _d181=gliding?0.06f:_d58?0.05f:0.13f;
camHx+=(tx-camHx)*_d181;camHz+=(tz-camHz)*_d181;float hl=sqrt(camHx*camHx+camHz*camHz);if(hl<0.01f){camHx=tx;camHz=tz;hl=1;}camHx/=hl;camHz/=hl;
float _d149=float(rx)/32768.0f;if(abs(_d149)<0.2f)_d149=0;float _d150=_d149*1.8f;
if(float(ry)/32768.0f<-0.7f)_d150=3.1416f;//right stick down:_d149 behind(MK8 _d149-back)
camLook+=(_d150-camLook)*(_d150>3.0f?0.35f:0.15f);
float lc=cos(camLook),ls=sin(camLook),dx=camHx*lc+camHz*ls,dz=-camHx*ls+camHz*lc;
float _d80=gliding?_d6:_d5+sp*0.035f+(boostLeft>0?CAM_BOOST_BACK:0)-(camBraking?CAM_BRAKE_IN:0);
_d80+=camKick*CAM_KICK;
float h=gliding?CAM_GLIDE_HEIGHT:CAM_HEIGHT+sp*0.01f;
camDist+=(_d80-camDist)*(camKick>0.5f?0.3f:0.1f);camH+=(h-camH)*0.08f;
float ky=a.pos_y;if(_d58){RigidBody@cb=a.getMainRigidBody();if(cb!is null)ky+=cb.vel.y*CAM_LEAD;}
camY+=(ky-camY)*((_d58||gliding)?0.12f:0.35f);
if(camY-ky>_d7)camY=ky+_d7;if(ky-camY>_d7)camY=ky-_d7;
double px=a.pos_x-dx*camDist,py=camY+camH,pz=a.pos_z-dz*camDist;
double ax=a.pos_x+dx*CAM_LOOK_AHEAD,ay=ky+(gliding?0.4f:CAM_LOOK_UP),az=a.pos_z+dz*CAM_LOOK_AHEAD;
camera::freeze(0,1,0,px,py,pz,ax,ay,az);camFrozen=true;camInit=true;
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
_L("KART ready");
}
bool _d127=false;
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool _d168=false,exitLatch=false;uint64 _d165=0;int _d166=0,outLY=0,outRX=0,outRY=0;
bool _d192=false;uint64 _d193=0;int _d194=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d169){
uint64 _d122=_d192?_d193:_pq(_d169);
int lx=_d192?_d194:_ps(_d169+8),ly=_d192?simLY:_ps(_d169+12);
int rx=_d192?simRX:_ps(_d169+16),ry=_d192?simRY:_ps(_d169+20);
_d168=false;_d165=_d122;_d166=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
_d70();
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 _d151=uint64(ZL|ZR|DUP);
if((_d122&_d151)==0)_k24=false;
if(!_k24&&(_d122&_d151)==_d151){_k24=true;_k25=true;_L("KART spawn queued");}
uint64 _d138=uint64(ZL|ZR|X);
if((_d122&_d138)==0)_d137=false;
if(!_k19&&!_d137&&(_d122&_d138)==_d138){
_d137=true;_d142=(_d142+1)%_d24;_L("KART type="+_d142);
_T(120,"Kart: "+_d139(_d142)+" (ZL+ZR+Up to spawn)\n");
}
uint64 _d69=uint64(ZL|ZR|DLEFT);
if((_d122&_d69)==0)mkCamChordLatched=false;
if(!mkCamChordLatched&&(_d122&_d69)==_d69){
mkCamChordLatched=true;_d157=!_d157;_L("KART mkcam="+_d157);
_T(90,_d157?"Mario Kart camera: ON\n":"Mario Kart camera: OFF\n");
}
uint64 _d56=uint64(ZL|ZR|DRIGHT);
if((_d122&_d56)==0)autoGlideChordLatched=false;
if(!autoGlideChordLatched&&(_d122&_d56)==_d56){
autoGlideChordLatched=true;_d60=!_d60;_L("KART autoglide="+_d60);
_T(90,_d60?"Auto glider: ON\n":"Auto glider: OFF\n");
}
uint64 _d161=uint64(ZL|ZR|DDOWN);
if((_d122&_d161)==0)offroadChordLatched=false;
if(!offroadChordLatched&&(_d122&_d161)==_d161){
offroadChordLatched=true;_d163=!_d163;_L("KART offroad="+_d163);
_T(90,_d163?"Off-road handling: ON\n":"Off-road handling: OFF\n");
}
if(!_k3()||_d156()){_d70();return;}
if(_k25&&(_d122&_d151)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d122);
_d59(_k7());
_d211(_k7());
_d104(_k7());
_d86();
_d113(_k7());
_d209();
_d71(_k7(),rx,ry);
uint64 _d83=uint64(A|B|X|Y|R|ZR|L);
if(_k19&&(_d122&uint64(L))!=0&&!_d127){_d127=true;_d202(S_HORN,CH_SHOT);}//L:horn(MK8:item button with no item)
if((_d122&uint64(L))==0)_d127=false;
if(_k19){
_d168=true;_d165=_d122&~_d83;
if(_d58||gliding){_d166=0;outLY=0;}//in the air the vanilla stick tilts the contraption;on the ground the game
if((_d122&uint64(X))!=0){_d165|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d122&uint64(X))==0)exitLatch=false;
else{_d168=true;_d165=_d122&~uint64(X);}//do not let the _d122 X make Link jump
}
}
void _d239(){
if(_d168)input(1,_d165,_d166,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d169){while(true){_k5(_d169);_d239();}}
void _d102(uint f){
if(f%75!=0)return;uint k=f/75;
string n=k==0?"Ply_SlipSmoke_Grass_Green":k==1?"ReFX_Grass_M":k==2?"HorseStep_Grass_Tmp":k==3?"Ply_FootEffect_Grass_Green":"ReFX_Grass_L";
_d112=n;_d103=-2;_d119();_d118=-1;
_L("GRASS "+n);
}
void _d120(){ptr_t e=fxScr==0?0:_d90(3);if(e==0){_L("GSTATE none");return;}
_L("GSTATE e8="+ptr_deref_s16(e+0xe8)+" f38="+_pu(e+0x38)+" 4c="+_pf(e+0x4c)+" 5c="+_pf(e+0x5c)+" 24c="+_pf(e+0x24c)+" 250="+_pf(e+0x250)+" 254="+_pf(e+0x254)+" 25c="+_pf(e+0x25c)+" 260="+_pf(e+0x260));}
ptr_t tp=0;
void _d84(uint64 k,int x,int y,int rx,int ry=0){
_d192=true;_d193=k;_d194=x;simLY=y;simRX=rx;simRY=ry;_k5(tp);
if(_d168)input(1,_d165,_d166,outLY,outRX,outRY);else input(1,k,x,y,rx,ry);
}
void _d187(ptr_t _d62,uint _d146,ptr_t k,ptr_t kl,const string&in _d225){
for(uint o=0;o<_d146;o+=8){ptr_t v=_pq(_d62+o);if(v==k)_L("RSCAN "+_d225+" +"+formatInt(o,"H")+" = kart");else if(v==kl)_L("RSCAN "+_d225+" +"+formatInt(o,"H")+" = kartLink");}
}
void _d185(){
ActorBase@a=_k7();if(a is null||Player is null)return;ptr_t k=_pa(a),kl=_pq(k+0x1a8),p=_pa(Player);
_L("RSCAN start kart="+formatInt(int64(k),"H")+" link="+formatInt(int64(kl),"H")+" name="+a.getName()+" player="+formatInt(int64(p),"H"));
_d187(p,0x1800,k,kl,"player");
uint n=_pu(p+0x220);ptr_t _d148=_pq(p+0x228);if(n>600||!_d107(_d148))return;
for(uint i=0;i<n;i++){ptr_t c=_pq(_d148+8*i);if(!_d107(c))continue;_d187(c,0x200,k,kl,"comp"+i);}
_L("RSCAN done n="+n);
}
string _d153(int i){if(i<0||i>=54)return"?";ptr_t t=_pq(sys::mainOffset()+0x4637298);if(t==0)return"?";ptr_t s=_pq(t+0x250+8*i);string r="";for(int k=0;k<32&&s!=0;k++){u8 c=ptr_deref_u8(s+k);if(c==0)break;r+=" ";r[r.length()-1]=c;}return r;}
bool _d175(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d115(ActorBase@a){if(a is null)return 0;ptr_t p=_pq(_pa(a)+0x228);if(!_d175(p))return 0;p=_pq(p+0x50);if(!_d175(p))return 0;
p=_pq(p+0x20);if(!_d175(p))return 0;p=_pq(p+0x10);if(!_d175(p))return 0;p=_pq(p+8);if(!_d175(p))return 0;p=_pq(p+0x20);if(!_d175(p))return 0;return p+0x20;}
string _d155(ActorBase@a){ptr_t g=_d115(a);if(g==0)return"none";int m=_ps(g+0x78);return""+m+":"+_d153(m)+" f="+ptr_deref_u8(g+0x110)+","+ptr_deref_u8(g+0x111);}
string _d76(ActorBase@a){if(a is null)return"null";string r="";ptr_t p=_pa(a);
for(uint i=0;i<6;i++){uint o=i==0?0x228:i==1?0x50:i==2?0x20:i==3?0x10:i==4?8:0x20;p=_pq(p+o);r+=" "+formatInt(int64(p),"H");if(!_d175(p))break;}return r;}
string _d182(float x,float y,float z){
if(!_d94())return"nofx";
ptr_t q=fxScr+0x5000,v=fxScr+0x5100,p1=fxScr+0x5200,p2=fxScr+0x5300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d91+0x4578958);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);
_pw(v+4,3.0f);ptr_write_u64(q+0x38,v+4);
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d91+0x20e4da4,q,0,0,0,0,0,0,0,0,0,0);
int m=_ps(v+0x40);
return"hit="+ptr_deref_u8(v+0x10)+" d="+_pf(v+0x14)+" f58="+_pf(v+0x18)+" n="+_pf(v+0x20)+","+_pf(v+0x24)+","+_pf(v+0x28)+" m="+m+":"+_d153(m)+" b="+ptr_deref_u8(v+0x44);
}
void _d152(const string&in l){ActorBase@k=_k7();
_L("MAT "+l+" player="+_d155(Player)+" rayP="+_d182(Player.pos_x,Player.pos_y+0.5f,Player.pos_z)+(k is null?"":" rayK="+_d182(k.pos_x,k.pos_y+0.2f,k.pos_z)));}
void _d216(const string&in l){_d120();ActorBase@a=_k7();_L("SPK "+l+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+_k18+" tier="+driftTier+" charge="+driftCharge+" boost="+boostLeft+" live0="+(fxScr!=0&&_d90(0)!=0)+" live1="+(fxScr!=0&&_d90(1)!=0)+" ground="+_d116+"/"+_d118+" d="+_d110+" cam="+camFrozen+" ch="+camHx+","+camHz+" f="+_d67+","+camFz+" d="+camDist+" wb="+(a!is null&&_d235(a)!=0)+" mounted="+_k15(a));}
void main(){
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
_d152("start");input(30,0);_d152("start2");
Player.setPos(-150,127.8,-62);input(90,0);for(uint w=0;w<200&&!(_k3()&&abs(Player.pos_x+150)<20);w++)input(10,0);input(60,0);if(!_k3())return;
_d152("field");
_d142=3;_k5(tp);_d84(uint64(ZL|ZR|DUP),0,0,0);
for(uint f=0;f<25;f++)_d84(0,0,0,0);
for(uint t=0;t<10&&!_k15(_k7());t++){
ActorBase@k=_k7();if(k is null){input(10,0);continue;}
Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,k.pos_y+0.3f,pz);input(20,0);
_L("SPK try mount t="+t+" kart="+k.pos_x+","+k.pos_z+" player="+Player.pos_x+","+Player.pos_z);
input(1,1);input(30,0);
}
if(!_k15(_k7())){_L("SPK mount failed");return;}
_d84(0,0,0,0);
for(uint f=0;f<60&&_k3();f++){_d84(uint64(A),0,0,0);if(f%30==0)_d216("run"+f);}
_d185();_L("SPK finished");_d192=false;input(1,0);_k11(tp);return;
_d216("drift-start");
for(uint k=0;k<3;k++){
bool _d230=false;
for(uint f=0;f<220&&_k3();f++){
_d84(uint64(A|R),32767,0,0);
float _d72=k==0?_d9+1:k==1?CHARGE_SMT+1:CHARGE_UMT+1;if(driftCharge>_d72)driftCharge=_d72;
if(!_d230&&driftTier==int(k)+1){_d230=true;_d216("hold"+(k+1));}
if(f%30==0)_d216("d"+k+"_"+f);
}
}
_d216("release");
for(uint f=0;f<20&&_k3();f++)_d84(uint64(A),32767,0,0);
_d216("boosting");
for(uint f=0;f<160&&_k3();f++)_d84(uint64(A),32767,0,0);
_d216("after");
_d84(uint64(X),0,0,0);for(uint f=0;f<30;f++)_d84(0,0,0,0);
_d216("exit");
_L("SPK finished");_d192=false;input(1,0);_k11(tp);
}
