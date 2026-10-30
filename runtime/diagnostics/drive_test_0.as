float _pf(ptr_t p){return ptr_deref_float(p);}
uint64 _pq(ptr_t p){return ptr_deref_u64(p);}
u32 _pu(ptr_t p){return ptr_deref_u32(p);}
int _ps(ptr_t p){return ptr_deref_s32(p);}
void _pw(ptr_t p,float v){ptr_write_float(p,v);}
ptr_t _pa(ActorBase@a){return ptr_from_ActorBase(a);}
void _L(const string&in s){sys::debugLog(s);}
ActorBase@_ag(uint64 i){return ActorWatcher::get(i);}
void _T(u32 t,const string&in s){TextWriter::toast(t,s);}
ptr_t _k16=0;
uint _k17=0xffffffff;
float _k18=0;
bool _k19=false;
bool _k20=false;float _d177=0,_w15=0;
float _d227=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d127=false;
const float _d36=7.775f;//[table]PRSL ground top speed,0 coins
const float _d28=0.011f;//[table]PRAC strength(G)
const float _d27=0.09f;//[table]PRAC limiter(M)
const float _d37=0.0118f;//[table]PRTL _d226,rad per MK frame
const float _d33=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d31=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d38=0.75f;//[table]PRON road traction
const float _d41=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d40=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d92)
const uint _d52=153;//[chosen]ultra _d154(not in the table):SMT+(SMT-MT)
const float _d9=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d39=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d35=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d30=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d32=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d34=0.993f;//[chosen]decay above _d232(after a boost)
const float _d29=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d20=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d11=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d228 0.001
const float _d12=0.8f;//[native]drift _d226 _d225 _w12,approached at 10%/frame,_d228<=0.07
const float _d8=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d140>=0.71 else 2
const float _d23=4.2f;//[chosen]drift _d131,m/s upward(~0.4 m,visible from the chase camera)
const int _d50=15;//[chosen]0.5 s
int _d238=0,trickRollDir=1;
const int _d3=24;const float _d2=5.0f;bool _d63=true,autoGlideBlocked=false,autoGlideChordLatched=true;
void _d224(float _d226){_d238=_d50;trickRollDir=_d226<-0.3f?-1:1;}//stick left spins the other way
const float _d1=0.3f,AIR_GAP=0.7f;const int _d51=8,TRICK_FRAMES=31;//trick:also R up to 6 _d92 before take-off
const float _d18=0.95f;//[measured]TOTK pulls the kart down~0.95 m/s per frame;added back so the glide _d202 settles at _d232
const float _d19=8.225f,GLIDE_SINK=1.6f,GLIDE_DIVE=4.5f,GLIDE_FLOAT=0.6f,GLIDE_STEER=0.6f,GLIDE_MIN_HEIGHT=2.5f;
const float _d0=9.0f,GLIDE_SIDE_DRAG=0.08f,AIR_SIDE_DRAG=0.01f;//[chosen]per half-frame _d228
const float _d17=0.55f,GLIDE_PITCH=0.35f,GLIDE_TILT_GAIN=4.0f,GLIDE_MAX_LEAN=0.65f;//[chosen]~29 deg _d64,~19 deg nose-down,~33 deg combined max
bool _d61=false,trickDone=false,gliding=false,gliderLatch=true;int _d60=0,groundFrames=0,trickWindow=0,rPressAge=99;
const bool _d42=false;
const float _d43=0.7f,OFFROAD_HEAVY=0.5f;//[table]PROF
bool _d170=_d42,offroadChordLatched=true;
float _d165=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d85=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d132=false,gasLatch=true,idleHold=false;
bool _d163(){return pause::isPauseRequest("GamePause")||pause::isPauseRequest("PreGamePause")||pause::isPauseRequest("PostGamePause")||pause::isPauseTarget("Custom_PhysicsUpdateWorld");}
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d130=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d130==0)return 0;
uint op=_pu(_d130);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d83=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d83-=0x04000000;
ptr_t _d232=ptr_t(int64(_d130)+_d83*4);
if(_pu(_d232)!=0xf0001382||_pu(_d232+4)!=0xa9be7bfd)return 0;
ptr_t _d65=_d232-0x65b80;if((_d65&0xfff)!=0)return 0;return _d65+0x3d90b8;
}
void _k13(){_d109=0;_d110=false;ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d192();_k19=false;_k20=false;_d177=0;_w15=0;_d127=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=_ag(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d225=_pu(_k16+0x24);if(_d225<2||_d225>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d134,uint _k27){
if(_d134 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d134);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d225=_pu(p+0x24);
return _d225>=2&&_d225<=6;
}
bool _k0(ActorBase@_d134,uint _k27){
if(Player is null||!_k1(_d134,_k27))return false;
ptr_t _d54=_pa(_d134),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d82=_pu(_d54+0x220);ptr_t _d155=_pq(_d54+0x228);
if(_d82<=129||_d82>512||!_k2(_d155))return false;
ptr_t _d81=_pq(_d155+0x408);
if(!_k2(_d81))return false;
uint _d196=_pu(_d81+0x20);ptr_t _k29=_pq(_d81+0x28);
if(_d196!=1||!_k2(_k29))return false;
ptr_t _d194=_pq(_k29);
if(!_k2(_d194))return false;
uint _d195=_pu(_d194+0x10),flags=_pu(_d194+0x18);
float _k33=_pf(_d194+0x74);
if(_d195!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d194+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d134,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d177=a.pos_x;_w15=a.pos_z;return;}
float dx=_d177-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d177=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
int _d149=0,spawnedType=0;bool _d144=true,capChordLatched=true,devChords=false;
string _d142(int t){return t==1?"SpObj_ControlStick_A_06":t==2?"SpObj_ControlStick_A_05":t==3?"SpObj_ControlStick_A_04":"SpObj_ControlStick_A_01";}//variants are new actors A_04..A_06
string _d146(int t){return t==1?"Pipe Frame":t==2?"B Dasher":t==3?"Standard Bike":"Standard Kart";}
const int _d25=4;bool _d141(int t){return t==3;}
string _d143(int t){return"SpObj_ControlStick_Capsule_A_0"+(t+1);}//inventory capsules(scripts/build_kart_capsules.py)
const string _d24="SpObj_ControlStick_A_0";
uint _d58=0;
int _d150(ptr_t a){
ptr_t s=_pq(a+0x218);if(s<0x1000000||s>0x8000000000)return-1;
for(uint i=0;i<_d24.length();i++)if(ptr_deref_u8(s+i)!=_d24[i])return-1;
uint d=ptr_deref_u8(s+22);if(ptr_deref_u8(s+23)!=0)return-1;
return d==49?0:d==54?1:d==53?2:d==52?3:-1;//A_01 Standard,A_06 Pipe Frame,A_05 B Dasher,A_04 Bike(A_02/A_03 vanilla)
}
void _d57(){
if(Player is null||(_d58++)%10!=0)return;
ptr_t p=_pa(Player);uint n=_pu(p+0x220);ptr_t _d155=_pq(p+0x228);
if(n<=130||n>600||!_d111(_d155))return;
ptr_t c=_pq(_d155+8*130);if(!_d111(c))return;
ptr_t ld=_pq(c+0x28);if(!_d111(ld))return;
ptr_t k=_pq(ld+0x40);if(!_d111(k)||k==_k16)return;
uint id=_pu(ld+0x48);if(_pu(k+0x10)!=id)return;
uint st=_pu(k+0x24);if(st<2||st>6)return;
int t=_d150(k);if(t<0)return;
_k13();ActorWatcher::assignSlot(2,k);_k16=k;_k17=id;spawnedType=t;_d149=t;
ActorBase@a=_ag(2);
if(a is null||_pa(a)!=k||!_k15(a)){_k13();return;}
_L("KART adopted "+_d146(t));
}
float _d147(int t){return t==1?1.0f:t==2?1.18f:t==3?1.275f:1.0f;}
float _d148(int t){return t==1?1.2f:t==2?1.42f:t==3?1.275f:1.3f;}
void _k8(){
if(!_k3())return;
ActorBase@_d171=_k7();
if(_k15(_d171)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d154=sqrt(fx*fx+fz*fz);if(_d154<0.1f)return;fx/=_d154;fz/=_d154;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d171!is null&&spawnedType!=_d149){_k13();@_d171=null;}//a different kart was chosen:spawn it(the _d171 one stays)
if(_d171!is null){_k10(_d171);_d171.setPos(x,y,z);@_d171=null;_d177=0;_w15=0;_d127=false;}
else{_k13();actor::createAndWatch(2,_d142(_d149),x,y,z);spawnedType=_d149;sleep(60);}//let creation get past its first _d92 before touching the _d54
for(uint f=0;f<600&&_k3();f++){//up to 20 s:a first load of a kart pack can take a while
ActorBase@a=_ag(2);
if(a!is null){
_k16=_pa(a);if(!_d111(_k16)){@a=null;sleep(1);continue;}_k17=_pu(_k16+0x10);
if(f%60==0)_L("KART spawn wait f="+f+" ptr="+formatInt(int64(_k16),"H")+" state="+_pu(_k16+0x24)+" ct="+_d111(_pq(_k16+0x228)));
ptr_t ct=_pq(_k16+0x228);bool _d179=_d111(ct)&&_d111(_pq(ct+0x50))&&_d111(_pq(_pq(ct+0x50)+0x20));
if(_d179&&a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();
if(a is null){ptr_t k=_k16;_L("KART spawn lost: watcher="+(_ag(2)!is null)+" state="+(_d111(k)?_pu(k+0x24):99)+" id="+(_d111(k)?_pu(k+0x10):0)+"/"+_k17);return;}a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d177=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
{ActorBase@a=_ag(2);ptr_t k=a is null?0:_pa(a);ptr_t ct=_d111(k)?_pq(k+0x228):0;
_L("KART spawn unavailable: world="+_k3()+" watcher="+(a!is null)+" ptr="+formatInt(int64(k),"H")+" state="+(_d111(k)?_pu(k+0x24):99)+" ct="+_d111(ct)+" phys="+(_d111(ct)&&_d111(_pq(ct+0x50))));}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d241(ActorBase@a){
ptr_t _d155=_pq(_pa(a)+0x228);if(!_k2(_d155))return 0;
ptr_t mc=_pq(_d155+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
float lf=_pf(b+120),rf=_pf(b+216),lb=_pf(b+312),rb=_pf(b+408);
if(abs(_pf(b+28)-0.3766f)>(_d141(spawnedType)?0.08f:0.002f)||abs(lf+rf)>0.002f||abs(lb+rb)>0.002f)return 0;//(a leaning bike moves its root)
if(_d141(spawnedType)){if(abs(lf)>0.01f||abs(lb)>0.01f)return 0;}//bike:both sockets of an axle on the centre line
else if(lf<0.5f||lf>1.2f||lb<0.5f||lb>1.2f)return 0;
return b;
}
void _d242(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
const float _d49=0.3927f;//2*pi/16 tread _d68
float _d239(float _d228){
float m=abs(_d228),half=_d49*0.5f;
if(m<=half*0.9f)return _d228;
float _d68=floor((m-half)/_d49);if(_d68>3)_d68=3;
float v=(_d68+0.5f)*_d49;return _d228<0?-v:v;
}
void _d62(ActorBase@a){
if(a is null){_d127=false;return;}
Matrix33f r=a.rot;float _d154=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d127&&_d154>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d154;}
_w4=x;_w5=z;_d127=true;
_w2+=_d239(ds/(0.28328f*_d147(spawnedType)));_w3+=_d239(ds/(0.28328f*_d148(spawnedType)));//tyre radius x body tyre scale
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d227*0.45f-_w1)*0.25f;
ptr_t b=_d241(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d242(b+72,sf,cf,sd,cd);_d242(b+168,sf,cf,sd,cd);
_d242(b+264,sr,cr,0,1);_d242(b+360,sr,cr,0,1);
if(_d141(spawnedType))_d66(b);
}
const float _d4=0.38f,BIKE_DRIFT_LEAN=0.5f,BIKE_PIVOT_Y=-0.30f;//[chosen]~22 deg turning,~29 deg drifting
float _d67=0;
void _d66(ptr_t b){
float sp=abs(_d165)/_d36;if(sp>1)sp=1;
float _d232=_d61||gliding?0:(_d85!=0?_d85*BIKE_DRIFT_LEAN*(0.7f+0.3f*abs(_d227)):_d227*_d4*sp);
_d67+=(_d232-_d67)*0.12f;
float c=cos(_d67),s=sin(_d67);ptr_t r=b-24;
_pw(r,c);_pw(r+4,s);_pw(r+8,0);
_pw(r+16,-s);_pw(r+20,c);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,1);
_pw(r+48,s*BIKE_PIVOT_Y);_pw(r+52,0.3766f+BIKE_PIVOT_Y-c*BIKE_PIVOT_Y);_pw(r+56,0);
}
void _d192(){_d238=0;_d61=false;trickDone=false;gliding=false;_d60=0;groundFrames=0;trickWindow=0;_d165=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d85=0;driftTier=0;boostLeft=0;hopWindow=0;_d132=false;gasLatch=true;idleHold=false;}
int _d121=-1;float _d115=99;//updated by _d118(ray cast under the kart)
float _d233(){
if(!_d170||_d115>=0.8f)return 1;
int m=_d121;
if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;//HeavySand,HeavySnow,Bog,Tar,Water,ContaminatedWater
if(m==1||m==2||m==3||m==5)return _d43;//Soil,Grass,Sand,Snow
return 1;
}
float _d222(float v,float _d234){
if(boostLeft>0){
boostLeft--;float t=_d36*_d41;
if(v<t){float _d137=(t-v)*_d29;if(_d137>MK_BOOST_CAP)_d137=MK_BOOST_CAP;return v+_d137;}
return t;
}
if(_d234>0){
if(v<0)return v+_d30>0?0:v+_d30;//stop reversing first
float t=_d36*_d234*_d233();
if(v<t){float _d137=(t-v)*_d28;if(_d137>_d27)_d137=_d27;return v+_d137;}//[native]form
float d=v*_d34;return d<t?t:d;
}
if(_d234<0){
if(v>0)return v-_d30<0?0:v-_d30;//brake,then reverse
float t=-_d35*(-_d234);
if(v>t){float _d137=(v-t)*_d28;if(_d137>_d27)_d137=_d27;return v-_d137;}
return v;
}
if(v>0)return v-_d32<0?0:v-_d32;
return v+_d32>0?0:v+_d32;
}
void _d86(int _d235){
_L("KART drift tier="+_d235+" charge="+driftCharge);
if(_d235==1)_T(30,"Mini-Turbo\n");else if(_d235==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d128){
_d227=0;
ActorBase@a=_k7();bool _d193=_k15(a);
if(!_d193&&Player!is null){_d57();@a=_k7();_d193=_k15(a);}
if(_d193!=_k19){_L("KART mounted="+_d193);_d192();_k19=_d193;_k20=!_d193;if(a!is null){_d177=a.pos_x;_w15=a.pos_z;}}
if(!_d193||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d192();return;}
float _d226=float(ix)/32768.0f,_d234=0;
if(abs(_d226)<0.15f)_d226=0;
bool _d105=(_d128&uint64(A))!=0,brake=(_d128&uint64(B))!=0;
if(!_d105)gasLatch=false;//the A press used to get in must be released first
if(brake)_d234=-1;else if(_d105&&!gasLatch)_d234=1;
_d227=_d226;
Matrix33f r=a.rot;float _d154=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d154<0.1f||r.a4<0.4f){_k10(a);_d192();return;}
float bx=r.a2/_d154,bz=r.a8/_d154,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
_d70=fx;camFz=fz;camBraking=brake&&_d165>0.5f;
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d55=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d56=_d55/_d39;
if(_d165>0&&_d165>_d56+0.6f)_d165=_d56+0.6f<0?0:_d56+0.6f;
if(_d165<0&&_d165<_d56-0.6f)_d165=_d56-0.6f>0?0:_d56-0.6f;
bool _d187=(_d128&uint64(R|ZR))!=0,fast=_d165>_d36*0.35f;
if(_d98())_d122(a.pos_x,a.pos_y+0.2f,a.pos_z);
bool _d174=_d115<AIR_GAP;
if(_d174){groundFrames++;_d60=0;}else{_d60++;groundFrames=0;}
bool _d240=_d61;
bool _d186=_d187&&!_d132;rPressAge=_d186?0:rPressAge+1;
if(!_d61&&_d60>=2){
_d61=true;trickWindow=_d51;trickDone=false;_L("KART airborne");
if(rPressAge<=6+_d60){trickDone=true;_d224(_d226);_d209(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick (buffered)");}
}
if(_d61&&groundFrames>=1){
_d61=false;
if(gliding){gliding=false;_L("KART glider landed");}
if(trickDone){if(boostLeft<TRICK_FRAMES)boostLeft=TRICK_FRAMES;_d209(_d48,CH_SHOT);_L("KART trick boost");}
trickDone=false;_L("KART landed");
}
float _d131=0;
bool _d185=_d187&&!_d132;
if(_d61){
if(trickWindow>0){trickWindow--;if(_d185&&!trickDone){trickDone=true;_d224(_d226);_d209(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick");}}
}else if(_d185){_d131=_d23;hopWindow=24;_d209(S_HOP,CH_SHOT);}//MK8 hops at any speed
_d132=_d187;
bool _d243=(_d128&uint64(Y))!=0;
if(!_d243)gliderLatch=false;
if(_d243&&!gliderLatch){
gliderLatch=true;
if(gliding){gliding=false;autoGlideBlocked=true;_L("KART glider folded");}
else if(_d61&&_d115>=GLIDE_MIN_HEIGHT){gliding=true;_d209(S_GOPEN,CH_SHOT);_d85=0;driftCharge=0;driftTier=0;_T(30,"Glider!\n");_L("KART glider open");}
}
if(!_d61)autoGlideBlocked=false;
if(_d63&&_d61&&!gliding&&!autoGlideBlocked&&_d238==0&&_d60>=_d3&&v.y<-_d2&&_d115>=GLIDE_MIN_HEIGHT){
gliding=true;autoGlideBlocked=true;_d209(S_GOPEN,CH_SHOT);_d85=0;driftCharge=0;driftTier=0;_L("KART glider auto");
}
if(_d85==0&&!_d61&&_d187&&hopWindow>0&&abs(_d226)>0.3f){_d85=_d226>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d85);}
if(_d85!=0&&(!_d187||!fast)){
int _d92=driftTier==3?int(_d52):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d40):0;
if(_d92>0&&_d187==false){boostLeft=_d92;_d209(driftTier==3?S_ULTRA:_d48,CH_SHOT);_L("KART boost tier="+driftTier+" frames="+_d92);}
_d85=0;driftCharge=0;driftTier=0;
}
if(!_d61&&_d234==0&&boostLeft==0&&_d85==0&&_d131==0&&abs(_d165)<_d32){
_d165=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d177=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d244=0,oldOff=bodyOff;
for(int _d228=0;_d228<2;_d228++){
if(hopWindow>0)hopWindow--;
if(gliding){float t=_d19*(iy>16000?1.06f:1.0f);_d165+=(t-_d165)*0.02f;}
else if(!_d61||boostLeft>0)_d165=_d222(_d165,_d234);
float _d69=0;
if(gliding){
driftTrack=0;_d244+=_d226*_d37*GLIDE_STEER;
}else if(_d85!=0){
float _d140=_d226*_d85;if(_d140>1)_d140=1;if(_d140<-1)_d140=-1;
float _d237=_d140>=0?_d12:-_d12,dt=(_d237-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d139=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d244+=_d85*_d33*_d139*_d139*(0.75f+0.25f*_d140);
if(!_d61)driftCharge+=_d140>=CHARGE_INWARD?_d8:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d235=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d9?1:0;
if(_d235>driftTier){driftTier=_d235;_d86(_d235);}
_d69=_d85*_d11;
}else{
driftTrack=0;
float _d220=abs(_d165)/(_d36*0.25f);if(_d220>1)_d220=1;
_d244+=_d226*_d37*_d220*(_d165<0?-1.0f:1.0f)*(_d61?_d1:1.0f);
}
if(_d238>0){bodyOff+=6.2832f/float(_d50*2)*float(trickRollDir);}
else{
float _d104=_d69-bodyOff,ds=_d104*0.07f;
if(abs(ds)<0.001f)ds=abs(_d104)<0.001f?_d104:(_d104>0?0.001f:-0.001f);
bodyOff+=ds;
}
if(!_d61)lateral*=1-_d20*_d38;
else lateral*=gliding?1-GLIDE_SIDE_DRAG:1-AIR_SIDE_DRAG;
}
if(_d238>0){_d238--;if(_d238==0||!_d61){_d238=0;while(bodyOff>3.1416f)bodyOff-=6.2832f;while(bodyOff<-3.1416f)bodyOff+=6.2832f;}}
_k18=_d165*_d39;
float _d221=_k18;
float vy=v.y+_d131;
if(gliding){
float _d202=iy>16000?GLIDE_DIVE:iy<-16000?GLIDE_FLOAT:GLIDE_SINK;//stick forward dives,back floats
vy+=(-_d202-vy)*0.3f+_d18;//ease into the glide descent(gravity compensated)
}
if(gliding&&vy<-_d0)vy=-_d0;//glider only(user:free fall must stay normal speed)
b.setVel(fx*_d221+lx*lateral,vy,fz*_d221+lz*lateral);
float tx=0,ty=1,tz=0,gain=2.0f;
if(gliding){
float _d180=float(iy)/32768.0f;if(_d180>1)_d180=1;if(_d180<-1)_d180=-1;
float _d64=_d226*_d17,nose=_d180*GLIDE_PITCH;//stick right:right _d198 down;stick forward:nose down
tx=-lx*_d64+fx*nose;tz=-lz*_d64+fz*nose;
float _d129=sqrt(tx*tx+tz*tz);if(_d129>GLIDE_MAX_LEAN){tx*=GLIDE_MAX_LEAN/_d129;tz*=GLIDE_MAX_LEAN/_d129;}
ty=1;float tl=sqrt(tx*tx+ty*ty+tz*tz);tx/=tl;ty/=tl;tz/=tl;gain=GLIDE_TILT_GAIN;
}
float ux=r.a1,uy=r.a4,uz=r.a7;
float wx=(uy*tz-uz*ty)*gain,wz=(ux*ty-uy*tx)*gain;//world axes(a body-axis version flipped the kart)
b.setAngularVel(wx,-(_d244+bodyOff-oldOff)*30.0f,wz);
}
const uint _d15=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float _d46=0.35f,FLAME_SCALE=0.15f;//[chosen]from screenshots
ptr_t _d95=0,fxSys=0,fxScr=0;int _d99=-2,fxFlame=-1;
bool _d96(ptr_t p,const string&in _d166){
uint n=_d166.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=_d166[i])return false;
return ptr_deref_u8(p+n)==0;
}
int _d93(const string&in _d166){
ptr_t _d191=_pq(_pq(fxSys+0x2ee8)+8);if(_d191==0||ptr_deref_u8(_d191+0x571)==0)return-1;//static effects=resource 1
int n=_ps(_d191+0x558);ptr_t _d197=_pq(_d191+0x430);
for(int i=0;i<n;i++)if(_d96(_pq(_d197+0x28*i)+0x10,_d166))return i;
return-1;
}
bool _d98(){
if(_d99>=0)return true;
if(_d99==-1)return false;//looked once and failed:stay off
_d99=-1;
ptr_t _d130=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d130==0)return false;
uint op=_pu(_d130);int64 _d83=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d83-=0x04000000;
ptr_t _d232=ptr_t(int64(_d130)+_d83*4),_d65=_d232-0x65b80;
if((_d65&0xfff)!=0||_pu(_d232)!=0xf0001382)return false;
fxScr=_d65+FX_SCRATCH;_d95=sys::mainOffset();
ptr_t _d138=_pq(_pq(_d95+_d15));if(_d138==0)return false;
fxSys=_pq(_d138+0x11b8);if(fxSys==0)return false;
int _d217=_d93("Ply_ShockWave_Spark");fxFlame=_d93("Chm_FlameThrower_ScraBuild");//Zonai _d89 emitter jet
_L("KART fx spark="+_d217+" flame="+fxFlame);
if(_d217<0)return false;
_d99=_d217;return true;
}
ptr_t _d94(int _d204){ptr_t h=fxScr+0x10*_d204,e=_pq(h);if(e==0)return 0;return _pu(e+0x234)==_pu(h+8)?e:0;}
ptr_t _d100(int _d204,int id){
ptr_t e=_d94(_d204);if(e!=0)return e;
ptr_t h=fxScr+0x10*_d204;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d95+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*_d204,0,0,0,0,0);
return _d94(_d204);
}
void _d102(int _d204){if(fxScr==0)return;ptr_t e=_d94(_d204);if(e!=0)ptr_call(_d95+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*_d204,0);}
void _d97(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
_pw(m,r.a0);_pw(m+4,r.a1);_pw(m+8,r.a2);_pw(m+12,px);
_pw(m+16,r.a3);_pw(m+20,r.a4);_pw(m+24,r.a5);_pw(m+28,py);
_pw(m+32,r.a6);_pw(m+36,r.a7);_pw(m+40,r.a8);_pw(m+44,pz);
_pw(fxScr+0x140,s);_pw(fxScr+0x144,s);_pw(fxScr+0x148,s);
ptr_call(_d95+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
void _d103(ptr_t e,float r,float g,float b){_pw(e+0x40,r);_pw(e+0x44,g);_pw(e+0x48,b);}
void _d218(ActorBase@a){
bool _d219=a!is null&&_k19&&_d85!=0&&driftTier>0;
bool _d89=a!is null&&_k19&&boostLeft>0;
if(!_d219&&!_d89&&fxScr==0)return;
if(!_d98()){return;}
if(!_d219)_d102(0);
if(!_d89||fxFlame<0)_d102(1);
if(_d219){
ptr_t e=_d100(0,_d99);
if(e!=0){
if(driftTier==1)_d103(e,0.25f,0.8f,6.0f);else if(driftTier==2)_d103(e,1.0f,1.0f,1.0f);else _d103(e,2.2f,0.4f,6.0f);
ptr_t b=_d241(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(_pf(b+312));wy=_pf(b+28)+_pf(b+316)-0.3683f;wz=_pf(b+32)+_pf(b+320);}
_d97(e,a,wx,wy,wz,_d46);_d97(e,a,-wx,wy,wz,_d46);
}
}
if(_d89&&fxFlame>=0){ptr_t e=_d100(1,fxFlame);if(e!=0){_d97(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);_d97(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
const uint _d14=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int _d123=-1,groundTick=0;
int _d107=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;//effect ids per class,looked up once(no arrays in this runtime)
bool _d122(float x,float y,float z){
ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d95+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);//flags:all false
_pw(v+4,2.0f);ptr_write_u64(q+0x38,v+4);//ray _d154(m)
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d95+_d14,q,0,0,0,0,0,0,0,0,0,0);
if(ptr_deref_u8(v+0x10)==0){_d121=-1;_d115=99;return false;}
_d121=_ps(v+0x40);_d115=_pf(v+0x14);return true;
}
int _d114(int m){
if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return-1;return 6;
}
string _d117="";//diagnostics only:overrides the grass effect _d166
string _d116(int c){
if(c==0&&_d117!="")return _d117;
if(c==0)return"ReFX_Grass_L";if(c==1||c==2)return"ReFX_Sand_L";if(c==3)return"ReFX_Snow_L";
if(c==4)return"Water_Splash01_Move";if(c==5)return"RctFld_Mud_Splash_S";return"Ply_SlipSmoke_Stone";
}
int _d119(int c){
if(c==0){if(_d107==-2)_d107=_d93(_d116(0));return _d107;}if(c==1){if(gid1==-2)gid1=_d93(_d116(1));return gid1;}
if(c==2){if(gid2==-2)gid2=_d93(_d116(2));return gid2;}if(c==3){if(gid3==-2)gid3=_d93(_d116(3));return gid3;}
if(c==4){if(gid4==-2)gid4=_d93(_d116(4));return gid4;}if(c==5){if(gid5==-2)gid5=_d93(_d116(5));return gid5;}
if(gid6==-2)gid6=_d93(_d116(6));return gid6;
}
const float _d22=1.2f,GROUND_MIN_SPEED=3.0f;//[chosen]
const int _d21=6;//[chosen]_d92 between bursts:TOTK's ground effects are one-shot(per footstep/hoof)
int _d113=0,groundBurstSlot=0;
void _d124(){if(fxScr==0)return;for(int k=3;k<7;k++)_d102(k);}
ptr_t _d101(int _d204,int id,ptr_t _d184){
ptr_t h=fxScr+0x10*_d204;_d102(_d204);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d95+FX_CREATE,fxSys,h,id,1,0,_d184,0,0,0,0,0);
return _d94(_d204);
}
void _d118(ActorBase@a){
bool _d53=a!is null&&_k19&&_d98();
if(!_d53){_d124();_d123=-1;return;}
int c=_d115<0.8f?_d114(_d121):-1;
bool _d169=c>=0&&c<6,show=c>=0&&abs(_k18)>GROUND_MIN_SPEED&&(_d169||_d85!=0);
_d123=show?c:-1;
if(!show){_d113=0;return;}
if(_d113-->0)return;
_d113=_d21;
int id=_d119(c);if(id<0)return;
int _d204=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
ptr_t e=_d101(_d204,id,fxScr+0x5000);if(e==0)return;
float wx=0.78f,wz=-0.75f;ptr_t b=_d241(a);if(b!=0){wx=abs(_pf(b+312));wz=_pf(b+32)+_pf(b+320);}
_d97(e,a,wx,0,wz,_d22);_d97(e,a,-wx,0,wz,_d22);
}
const float _d16=-0.15f,GLIDER_Z=-0.45f,GLIDER_STORE=1000.0f;//mesh stored 1/1000 size(scripts/build_glider.py)//[chosen]attach point in kart space(glider frame _d65)
float _d109=0;bool _d110=false;
ptr_t _d136=0,hostSklAt=0;
ptr_t _d135(ActorBase@a){
ptr_t _d155=_pq(_pa(a)+0x228);if(!_k2(_d155))return 0;
ptr_t mc=_pq(_d155+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
if(m==_d136&&hostSklAt!=0)return hostSklAt;
_d136=m;hostSklAt=0;_d110=false;//new kart(model instances are pooled:a reused one can keep an open glider)
for(uint o=0;o<0x4000;o+=4){
ptr_t r=m+o;
if(abs(_pf(r+52)-0.3766f)<0.003f&&abs(_pf(r+48))<0.003f&&abs(_pf(r+56))<0.003f
&&abs(_pf(r+96+52)-0.5966f)<0.003f&&abs(_pf(r+96+56)-0.4928f)<0.003f){hostSklAt=r;_L("KART host Skl_Root record at +"+o);break;}
}
return hostSklAt;
}
void _d112(ptr_t _d190,ptr_t j,float px,float py,float pz){
float dx=px-_pf(j+48),dy=py-_pf(j+52),dz=pz-_pf(j+56);
for(uint c=0;c<3;c++)_pw(_d190+48+4*c,_pf(j+16*c)*dx+_pf(j+16*c+4)*dy+_pf(j+16*c+8)*dz);
}
void _d126(ActorBase@a){
if(a is null)return;ptr_t _d203=_d135(a);if(_d203==0)return;
if(!_d141(spawnedType)){
_pw(_d203+192+48,0);_pw(_d203+192+52,-0.0001f);_pw(_d203+192+56,-0.2107f);
_pw(_d203+288+48,0);_pw(_d203+288+52,-0.0001f);_pw(_d203+288+56,0.2107f);
return;
}
float ax=0,ay=0.906f,az=-0.423f,c=cos(_w1),s=sin(_w1);
for(int _d198=-1;_d198<=1;_d198+=2){
float vx=0.62f*_d198,vy=0.96f-0.645f,vz=0.43f-0.752f,d=ax*vx+ay*vy+az*vz;
float cx=ay*vz-az*vy,cy=az*vx-ax*vz,cz=ax*vy-ay*vx;
float rx=vx*c+cx*s+ax*d*(1-c),ry=vy*c+cy*s+ay*d*(1-c),rz=vz*c+cz*s+az*d*(1-c);
float gx=rx,gy=0.645f+ry,lc=cos(_d67),ls=sin(_d67);
float lx=lc*gx-ls*gy+ls*BIKE_PIVOT_Y,ly=ls*gx+lc*gy+BIKE_PIVOT_Y-lc*BIKE_PIVOT_Y;
_d112(_d198>0?_d203+192:_d203+288,_d203+96,lx,ly,0.752f+rz);//+X is Link's left:Handle_L
}
}
void _d108(ActorBase@a){
float _d232=(a!is null&&_k19&&gliding)?1:0;
if(_d232==0&&_d109==0&&_d110)return;
if(a is null)return;
ptr_t _d203=_d135(a);if(_d203==0)return;
if(_d109<_d232){_d109+=0.17f;if(_d109>_d232)_d109=_d232;}
else if(_d109>_d232){_d109-=0.2f;if(_d109<_d232)_d109=_d232;}
ptr_t r=_d203-192;float sc=_d109*GLIDER_STORE;//Control=bone 1,two records before Skl_Root(bone 3)
_pw(r,sc);_pw(r+4,0);_pw(r+8,0);
_pw(r+16,0);_pw(r+20,sc);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,sc);
_pw(r+48,0);_pw(r+52,_d16);_pw(r+56,GLIDER_Z);
_d110=true;
}
const uint _d13=0x1085b5c;
bool _d91=false;
bool _d111(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d181(){
if(Player is null)return 0;ptr_t p=_pq(_pa(Player)+0x228);if(!_d111(p))return 0;
p=_pq(p+0x50);if(!_d111(p))return 0;p=_pq(p+0x20);return _d111(p)?p:0;
}
void _d90(){
if(!_k19&&!_d91)return;
ptr_t _d178=_d181();if(_d178==0)return;
ptr_call(sys::mainOffset()+_d13,_d178,_k19?0:1,0,0,0,0,0,0,0,0,0);
_d91=_k19;
}
const uint _d44=0x809ee0,SND_FADE=0xb226a4,PROP_SET=0x11acb98;
const int _d10=0,CH_SIZZLE=1,CH_DRIFT=2,CH_RUN=3,CH_SLIP=4,CH_FLUTTER=5,CH_SHOT=6;
const float _d45=1.0f/14.0f;//[chosen]top speed(14 m/s)=1=top of curve 213
const int _d47=1,S_DASH=2,S_IDLE=3,S_SIZZLE=4,S_DRIFT=7,S_FLUTTER=8,S_RUN=10,S_SLIP=20,S_LANDS=30;
const int _d48=40,S_ULTRA=41,S_HOP=42,S_LAND=43,S_TRICK=44,S_GOPEN=45,S_GCLOSE=46,S_HORN=47;
int _d207=0;int _d78=0,chKey1=0,chKey2=0,chKey3=0,chKey4=0,chKey5=0;
string _d230(int s){return s==0?"Grass":s==1?"Dirt":s==2?"Sand":s==3?"Snow":s==4?"Water":s==5?"Stone":"Wood";}
string _d152(int id){
if(id==_d47)return"Kart_Engine";if(id==S_DASH)return"Kart_EngineDash";if(id==S_IDLE)return"Kart_Idle";
if(id>=S_SIZZLE&&id<S_SIZZLE+3)return"Kart_Sizzle"+(id-S_SIZZLE+1);if(id==S_DRIFT)return"Kart_DriftSteer";
if(id==S_FLUTTER)return"Kart_GliderFlutter";if(id>=S_RUN&&id<S_RUN+7)return"Kart_Run_"+_d230(id-S_RUN);
if(id>=S_SLIP&&id<S_SLIP+7)return"Kart_Slip_"+_d230(id-S_SLIP);if(id>=S_LANDS&&id<S_LANDS+7)return"Kart_Land_"+_d230(id-S_LANDS);
if(id==_d48)return"Kart_MiniTurbo";if(id==S_ULTRA)return"Kart_UltraTurbo";if(id==S_HOP)return"Kart_Hop";if(id==S_LAND)return"Kart_Land";
if(id==S_TRICK)return"Kart_Trick";if(id==S_HORN)return"Kart_Horn";if(id==S_GOPEN)return"Kart_GliderOpen";if(id==S_GCLOSE)return"Kart_GliderClose";return"";
}
ptr_t _d214=0;int _d210=-1;bool _d215=false;
ptr_t _d212(){
ActorBase@a=_k7();if(a is null||!_d98())return 0;
ptr_t x=_pq(_pa(a)+0x228);if(!_d111(x))return 0;
x=_pq(x+0x68);if(!_d111(x))return 0;
ptr_t u=_pq(x+0x78);return _d111(u)?u:0;
}
void _d209(int id,int ch){
ptr_t u=_d212();if(u==0||id<=0)return;string _d151=_d152(id);
ptr_t k=fxScr+0x7800,h=fxScr+0x7880+8*ch;uint n=_d151.length();
for(uint w=0;w<4;w++){uint64 v=0;for(uint i=0;i<8;i++){uint c=w*8+i;if(c<n)v|=uint64(_d151[c])<<(8*i);}ptr_write_u64(k+8*w,v);}
ptr_write_u64(h,0xffff00ff);
ptr_call(_d95+_d44,u,k,h,0,0,0,0,0,0,0,0);
if(_d207<80){_d207++;_L("KART snd "+_d151+" h="+_pq(h));}
}
void _d205(int ch){if(fxScr==0)return;ptr_t h=fxScr+0x7880+8*ch;if(_pq(h)!=0xffff00ff)ptr_call(_d95+SND_FADE,h,0xffffffff,0,0,0,0,0,0,0,0,0);ptr_write_u64(h,0xffff00ff);}
int _d77(int ch){return ch==0?_d78:ch==1?chKey1:ch==2?chKey2:ch==3?chKey3:ch==4?chKey4:chKey5;}
void _d79(int ch,int k){if(ch==0)_d78=k;else if(ch==1)chKey1=k;else if(ch==2)chKey2=k;else if(ch==3)chKey3=k;else if(ch==4)chKey4=k;else chKey5=k;}
void _d208(int ch,int _d151){
if(_d77(ch)==_d151)return;
if(_d77(ch)!=0)_d205(ch);
if(_d151!=0)_d209(_d151,ch);
_d79(ch,_d151);
}
bool _d183(ptr_t x){
if(!_d111(x))return false;uint n=_pu(x+0x110);if(n==0||n>16)return false;
ptr_t _d167=_pq(x+0x118);if(!_d111(_d167))return false;
for(uint i=0;i<n;i++){ptr_t s=_pq(_d167+8*i);if(_d111(s)&&_d96(s,"ControlStick_StickSpeedXY")){_d210=int(i);return true;}}
return false;
}
void _d206(){
_d215=true;_d214=0;_d210=-1;
ActorBase@a=_k7();if(a is null)return;
ptr_t p=_pq(_pa(a)+0x228);if(!_d111(p))return;
p=_pq(p);if(!_d111(p))return;
p=_pq(p+0x10);if(!_d111(p))return;
if(_d183(p))_d214=p;
_L("KART snd prop X="+(_d214!=0)+" idx="+_d210+" n="+_pu(p+0x110));
}
void _d211(float ms){
if(_d214==0||_d210<0)return;
ptr_t f=fxScr+0x7a00;
_pw(f,abs(ms)*_d45);
ptr_call(_d95+PROP_SET,_d214,_d210,f,0,0,0,0,0,0,0,0);
}
int _d153=-2,lastSurface=-1;
bool _d161(int m,const string&in w){
ptr_t t=_pq(_d95+0x4637298);if(t==0||m<0||m>=54)return false;ptr_t s=_pq(t+0x250+8*m);if(!_d111(s))return false;
uint n=w.length();for(uint i=0;i<28;i++){if(ptr_deref_u8(s+i)==0)return false;bool ok=true;for(uint k=0;k<n&&ok;k++)if(ptr_deref_u8(s+i+k)!=w[k])ok=false;if(ok)return true;}
return false;
}
int _d231(){
if(_d121==_d153)return lastSurface;
_d153=_d121;int c=_d114(_d121);
lastSurface=c<0?-1:c==0?0:c==1?1:c==2?2:c==3?3:c==4?4:c==5?1:(_d161(_d121,"Wood")?6:5);
return lastSurface;
}
bool _d213=false,sndWasGlide=false;
void _d216(){
if(!_k19){
if(_d78!=0||chKey1!=0||chKey2!=0||chKey3!=0||chKey4!=0||chKey5!=0){for(int c=0;c<6;c++)_d208(c,0);}
_d215=false;_d213=false;sndWasGlide=false;return;
}
if(!_d215)_d206();
float sp=abs(_k18);_d211(sp);
_d208(_d10,gliding?0:boostLeft>0?S_DASH:sp<0.6f?S_IDLE:_d47);
_d208(CH_SIZZLE,(_d85!=0&&driftTier>0&&!gliding)?S_SIZZLE+driftTier-1:0);
int _d229=(_d61||gliding)?-1:_d231();
_d208(CH_DRIFT,(_d85!=0&&!_d61&&!gliding)?S_DRIFT:0);
_d208(CH_RUN,(_d229>=0&&sp>1.0f&&_d85==0)?S_RUN+_d229:0);
_d208(CH_SLIP,(_d229>=0&&_d85!=0)?S_SLIP+_d229:0);
_d208(CH_FLUTTER,gliding?S_FLUTTER:0);
if(sndWasGlide&&!gliding)_d209(S_GCLOSE,CH_SHOT);
if(_d213&&!_d61){_d209(S_LAND,CH_SHOT);int s2=_d231();if(s2>=0)_d209(S_LANDS+s2,CH_SHOT+1);}
_d213=_d61;sndWasGlide=gliding;
}
const bool _d26=true;
const float _d5=6.2f,CAM_HEIGHT=2.4f,CAM_LOOK_AHEAD=1.6f,CAM_LOOK_UP=1.2f,CAM_DRIFT_SWING=0.16f;
const float _d7=3.0f,CAM_LEAD=0.07f;//[chosen]seconds of fall to lead
const float _d6=7.6f,CAM_GLIDE_HEIGHT=4.4f,CAM_BOOST_BACK=0.8f,CAM_KICK=0.7f,CAM_BRAKE_IN=0.5f;
bool _d164=_d26,mkCamChordLatched=true,camFrozen=false,camInit=false,camBraking=false;
float _d70=0,camFz=1,camHx=0,camHz=1,camDist=_d5,camH=CAM_HEIGHT,camY=0,camKick=0,camLook=0;int _d71=0;
void _d73(){if(camFrozen){camera::toggleFreeze();camFrozen=false;}camInit=false;}
void _d74(ActorBase@a,int rx,int ry){
if(!_d164||a is null||!_k19){_d73();return;}
float sp=abs(_k18);
if(boostLeft>_d71+5)camKick=1;_d71=boostLeft;camKick*=0.88f;
float tx=_d70,tz=camFz;
if(_d85!=0){float c=cos(-_d85*CAM_DRIFT_SWING),s2=sin(-_d85*CAM_DRIFT_SWING);float nx=tx*c+tz*s2,nz=-tx*s2+tz*c;tx=nx;tz=nz;}
if(!camInit){camHx=tx;camHz=tz;camY=a.pos_y;camDist=_d5;camH=CAM_HEIGHT;}
float _d188=gliding?0.06f:_d61?0.05f:0.13f;
camHx+=(tx-camHx)*_d188;camHz+=(tz-camHz)*_d188;float hl=sqrt(camHx*camHx+camHz*camHz);if(hl<0.01f){camHx=tx;camHz=tz;hl=1;}camHx/=hl;camHz/=hl;
float _d156=float(rx)/32768.0f;if(abs(_d156)<0.2f)_d156=0;float _d157=_d156*1.8f;
if(float(ry)/32768.0f<-0.7f)_d157=3.1416f;//right stick down:_d156 behind(MK8 _d156-back)
camLook+=(_d157-camLook)*(_d157>3.0f?0.35f:0.15f);
float lc=cos(camLook),ls=sin(camLook),dx=camHx*lc+camHz*ls,dz=-camHx*ls+camHz*lc;
float _d84=gliding?_d6:_d5+sp*0.035f+(boostLeft>0?CAM_BOOST_BACK:0)-(camBraking?CAM_BRAKE_IN:0);
_d84+=camKick*CAM_KICK;
float h=gliding?CAM_GLIDE_HEIGHT:CAM_HEIGHT+sp*0.01f;
camDist+=(_d84-camDist)*(camKick>0.5f?0.3f:0.1f);camH+=(h-camH)*0.08f;
float ky=a.pos_y;if(_d61){RigidBody@cb=a.getMainRigidBody();if(cb!is null)ky+=cb.vel.y*CAM_LEAD;}
camY+=(ky-camY)*((_d61||gliding)?0.12f:0.35f);
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
bool _d133=false;
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool _d175=false,exitLatch=false;uint64 _d172=0;int _d173=0,outLY=0,outRX=0,outRY=0;
bool _d199=false;uint64 _d200=0;int _d201=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d176){
uint64 _d128=_d199?_d200:_pq(_d176);
int lx=_d199?_d201:_ps(_d176+8),ly=_d199?simLY:_ps(_d176+12);
int rx=_d199?simRX:_ps(_d176+16),ry=_d199?simRY:_ps(_d176+20);
_d175=false;_d172=_d128;_d173=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
_d73();
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;
if(devChords){
uint64 _d158=uint64(ZL|ZR|DUP);
if((_d128&_d158)==0)_k24=false;
if(!_k24&&(_d128&_d158)==_d158){_k24=true;_k25=true;_L("KART spawn queued");}
uint64 _d145=uint64(ZL|ZR|X);
if((_d128&_d145)==0)_d144=false;
if(!_k19&&!_d144&&(_d128&_d145)==_d145){
_d144=true;_d149=(_d149+1)%_d25;_L("KART type="+_d149);
_T(120,"Kart: "+_d146(_d149)+" (ZL+ZR+Up to spawn, ZL+ZR+Y for a capsule)\n");
}
uint64 _d76=uint64(ZL|ZR|Y);
if((_d128&_d76)==0)capChordLatched=false;
if(!_k19&&!capChordLatched&&(_d128&_d76)==_d76&&Player!is null){
capChordLatched=true;Matrix33f r=Player.rot;
actor::createSimple(_d143(_d149),Player.pos_x+1.5f*r.a2,Player.pos_y+0.8f,Player.pos_z+1.5f*r.a8);
_L("KART capsule "+_d149);_T(90,_d146(_d149)+" capsule\n");
}
}
uint64 _d72=uint64(ZL|ZR|DLEFT);
if((_d128&_d72)==0)mkCamChordLatched=false;
if(!mkCamChordLatched&&(_d128&_d72)==_d72){
mkCamChordLatched=true;_d164=!_d164;_L("KART mkcam="+_d164);
_T(90,_d164?"Mario Kart camera: ON\n":"Mario Kart camera: OFF\n");
}
uint64 _d59=uint64(ZL|ZR|DRIGHT);
if((_d128&_d59)==0)autoGlideChordLatched=false;
if(!autoGlideChordLatched&&(_d128&_d59)==_d59){
autoGlideChordLatched=true;_d63=!_d63;_L("KART autoglide="+_d63);
_T(90,_d63?"Auto glider: ON\n":"Auto glider: OFF\n");
}
uint64 _d168=uint64(ZL|ZR|DDOWN);
if((_d128&_d168)==0)offroadChordLatched=false;
if(!offroadChordLatched&&(_d128&_d168)==_d168){
offroadChordLatched=true;_d170=!_d170;_L("KART offroad="+_d170);
_T(90,_d170?"Off-road handling: ON\n":"Off-road handling: OFF\n");
}
if(!_k3()||_d163()){_d73();return;}
if(_k25&&(_d128&uint64(ZL|ZR|DUP))!=uint64(ZL|ZR|DUP)){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d128);
_d62(_k7());
_d218(_k7());
_d108(_k7());_d126(_k7());
_d90();
_d118(_k7());
_d216();
_d74(_k7(),rx,ry);
uint64 _d87=uint64(A|B|X|Y|R|ZR|L);
if(_k19&&(_d128&uint64(L))!=0&&!_d133){_d133=true;_d209(S_HORN,CH_SHOT);}//L:horn(MK8:item button with no item)
if((_d128&uint64(L))==0)_d133=false;
if(_k19){
_d175=true;_d172=_d128&~_d87;
if(_d61||gliding){_d173=0;outLY=0;}//in the air the vanilla stick tilts the contraption;on the ground the game
if((_d128&uint64(X))!=0){_d172|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d128&uint64(X))==0)exitLatch=false;
else{_d175=true;_d172=_d128&~uint64(X);}//do not let the _d128 X make Link jump
}
}
void _d245(){
if(_d175)input(1,_d172,_d173,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d176){while(true){_k5(_d176);_d245();}}
void _d106(uint f){
if(f%75!=0)return;uint k=f/75;
string n=k==0?"Ply_SlipSmoke_Grass_Green":k==1?"ReFX_Grass_M":k==2?"HorseStep_Grass_Tmp":k==3?"Ply_FootEffect_Grass_Green":"ReFX_Grass_L";
_d117=n;_d107=-2;_d124();_d123=-1;
_L("GRASS "+n);
}
void _d125(){ptr_t e=fxScr==0?0:_d94(3);if(e==0){_L("GSTATE none");return;}
_L("GSTATE e8="+ptr_deref_s16(e+0xe8)+" f38="+_pu(e+0x38)+" 4c="+_pf(e+0x4c)+" 5c="+_pf(e+0x5c)+" 24c="+_pf(e+0x24c)+" 250="+_pf(e+0x250)+" 254="+_pf(e+0x254)+" 25c="+_pf(e+0x25c)+" 260="+_pf(e+0x260));}
ptr_t tp=0;
void _d88(uint64 k,int x,int y,int rx,int ry=0){
_d199=true;_d200=k;_d201=x;simLY=y;simRX=rx;simRY=ry;_k5(tp);
if(_d175)input(1,_d172,_d173,outLY,outRX,outRY);else input(1,k,x,y,rx,ry);
}
string _d160(int i){if(i<0||i>=54)return"?";ptr_t t=_pq(sys::mainOffset()+0x4637298);if(t==0)return"?";ptr_t s=_pq(t+0x250+8*i);string r="";for(int k=0;k<32&&s!=0;k++){u8 c=ptr_deref_u8(s+k);if(c==0)break;r+=" ";r[r.length()-1]=c;}return r;}
bool _d182(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d120(ActorBase@a){if(a is null)return 0;ptr_t p=_pq(_pa(a)+0x228);if(!_d182(p))return 0;p=_pq(p+0x50);if(!_d182(p))return 0;
p=_pq(p+0x20);if(!_d182(p))return 0;p=_pq(p+0x10);if(!_d182(p))return 0;p=_pq(p+8);if(!_d182(p))return 0;p=_pq(p+0x20);if(!_d182(p))return 0;return p+0x20;}
string _d162(ActorBase@a){ptr_t g=_d120(a);if(g==0)return"none";int m=_ps(g+0x78);return""+m+":"+_d160(m)+" f="+ptr_deref_u8(g+0x110)+","+ptr_deref_u8(g+0x111);}
string _d80(ActorBase@a){if(a is null)return"null";string r="";ptr_t p=_pa(a);
for(uint i=0;i<6;i++){uint o=i==0?0x228:i==1?0x50:i==2?0x20:i==3?0x10:i==4?8:0x20;p=_pq(p+o);r+=" "+formatInt(int64(p),"H");if(!_d182(p))break;}return r;}
string _d189(float x,float y,float z){
if(!_d98())return"nofx";
ptr_t q=fxScr+0x5000,v=fxScr+0x5100,p1=fxScr+0x5200,p2=fxScr+0x5300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d95+0x4578958);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);
_pw(v+4,3.0f);ptr_write_u64(q+0x38,v+4);
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d95+0x20e4da4,q,0,0,0,0,0,0,0,0,0,0);
int m=_ps(v+0x40);
return"hit="+ptr_deref_u8(v+0x10)+" d="+_pf(v+0x14)+" f58="+_pf(v+0x18)+" n="+_pf(v+0x20)+","+_pf(v+0x24)+","+_pf(v+0x28)+" m="+m+":"+_d160(m)+" b="+ptr_deref_u8(v+0x44);
}
void _d159(const string&in l){ActorBase@k=_k7();
_L("MAT "+l+" player="+_d162(Player)+" rayP="+_d189(Player.pos_x,Player.pos_y+0.5f,Player.pos_z)+(k is null?"":" rayK="+_d189(k.pos_x,k.pos_y+0.2f,k.pos_z)));}
void _d223(const string&in l){_d125();ActorBase@a=_k7();_L("SPK "+l+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+_k18+" tier="+driftTier+" charge="+driftCharge+" boost="+boostLeft+" live0="+(fxScr!=0&&_d94(0)!=0)+" live1="+(fxScr!=0&&_d94(1)!=0)+" ground="+_d121+"/"+_d123+" d="+_d115+" cam="+camFrozen+" ch="+camHx+","+camHz+" f="+_d70+","+camFz+" d="+camDist+" wb="+(a!is null&&_d241(a)!=0)+" mounted="+_k15(a));}
void main(){
_k14();devChords=true;tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
_d159("start");input(30,0);_d159("start2");
Player.setPos(-118,127.8,-62);input(90,0);for(uint w=0;w<200&&!(_k3()&&abs(Player.pos_x+118)<20);w++)input(10,0);input(60,0);if(!_k3())return;
Player.setRot(0,0,1,0,1,0,-1,0,0);input(10,0);//face east,away from the kart chests at x-156
_d159("field");
_d149=0;_k5(tp);_d88(uint64(ZL|ZR|DUP),0,0,0);
for(uint f=0;f<25;f++)_d88(0,0,0,0);
for(uint t=0;t<10&&!_k15(_k7());t++){
ActorBase@k=_k7();if(k is null){input(10,0);continue;}
Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,k.pos_y+0.3f,pz);input(20,0);
_L("SPK try mount t="+t+" kart="+k.pos_x+","+k.pos_z+" player="+Player.pos_x+","+Player.pos_z);
input(1,1);input(30,0);
}
if(!_k15(_k7())){_L("SPK mount failed");return;}
_d88(0,0,0,0);
for(uint f=0;f<60&&_k3();f++){_d88(uint64(A),0,0,0);if(f%30==0)_d223("run"+f);}
_d223("drift-start");
for(uint k=0;k<3;k++){
bool _d236=false;
for(uint f=0;f<220&&_k3();f++){
_d88(uint64(A|R),32767,0,0);
float _d75=k==0?_d9+1:k==1?CHARGE_SMT+1:CHARGE_UMT+1;if(driftCharge>_d75)driftCharge=_d75;
if(!_d236&&driftTier==int(k)+1){_d236=true;_d223("hold"+(k+1));}
if(f%30==0)_d223("d"+k+"_"+f);
}
}
_d223("release");
for(uint f=0;f<20&&_k3();f++)_d88(uint64(A),32767,0,0);
_d223("boosting");
for(uint f=0;f<160&&_k3();f++)_d88(uint64(A),32767,0,0);
_d223("after");
_d88(uint64(X),0,0,0);for(uint f=0;f<30;f++)_d88(0,0,0,0);
_d223("exit");
_L("SPK finished");_d199=false;input(1,0);_k11(tp);
}
