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
bool _k20=false;float _d171=0,_w15=0;
float _d221=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d123=false;
const float _d36=7.775f;//[table]PRSL ground top speed,0 coins
const float _d28=0.011f;//[table]PRAC strength(G)
const float _d27=0.09f;//[table]PRAC limiter(M)
const float _d37=0.0118f;//[table]PRTL _d220,rad per MK frame
const float _d33=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d31=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d38=0.75f;//[table]PRON road traction
const float _d41=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d40=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d91)
const uint _d52=153;//[chosen]ultra _d151(not in the table):SMT+(SMT-MT)
const float _d9=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d39=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d35=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d30=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d32=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d34=0.993f;//[chosen]decay above _d227(after a boost)
const float _d29=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d20=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d11=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d222 0.001
const float _d12=0.8f;//[native]drift _d220 _d219 _w12,approached at 10%/frame,_d222<=0.07
const float _d8=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d137>=0.71 else 2
const float _d23=4.2f;//[chosen]drift _d127,m/s upward(~0.4 m,visible from the chase camera)
const int _d50=15;//[chosen]0.5 s
int _d232=0,trickRollDir=1;
const int _d3=24;const float _d2=5.0f;bool _d63=true,autoGlideBlocked=false,autoGlideChordLatched=true;
void _d218(float _d220){_d232=_d50;trickRollDir=_d220<-0.3f?-1:1;}//stick left spins the other way
const float _d1=0.3f,AIR_GAP=0.7f;const int _d51=8,TRICK_FRAMES=31;//trick:also R up to 6 _d91 before take-off
const float _d18=0.95f;//[measured]TOTK pulls the kart down~0.95 m/s per frame;added back so the glide _d197 settles at _d227
const float _d19=8.225f,GLIDE_SINK=1.6f,GLIDE_DIVE=4.5f,GLIDE_FLOAT=0.6f,GLIDE_STEER=0.6f,GLIDE_MIN_HEIGHT=2.5f;
const float _d0=9.0f,GLIDE_SIDE_DRAG=0.08f,AIR_SIDE_DRAG=0.01f;//[chosen]per half-frame _d222
const float _d17=0.55f,GLIDE_PITCH=0.35f,GLIDE_TILT_GAIN=4.0f,GLIDE_MAX_LEAN=0.65f;//[chosen]~29 deg _d64,~19 deg nose-down,~33 deg combined max
bool _d61=false,trickDone=false,gliding=false,gliderLatch=true;int _d60=0,groundFrames=0,trickWindow=0,rPressAge=99;
const bool _d42=false;
const float _d43=0.7f,OFFROAD_HEAVY=0.5f;//[table]PROF
bool _d164=_d42,offroadChordLatched=true;
float _d159=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d84=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d128=false,gasLatch=true,idleHold=false;
bool _d157(){return pause::isPauseRequest("GamePause")||pause::isPauseRequest("PreGamePause")||pause::isPauseRequest("PostGamePause")||pause::isPauseTarget("Custom_PhysicsUpdateWorld");}
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d126=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d126==0)return 0;
uint op=_pu(_d126);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d82=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d82-=0x04000000;
ptr_t _d227=ptr_t(int64(_d126)+_d82*4);
if(_pu(_d227)!=0xf0001382||_pu(_d227+4)!=0xa9be7bfd)return 0;
ptr_t _d65=_d227-0x65b80;if((_d65&0xfff)!=0)return 0;return _d65+0x3d90b8;
}
void _k13(){_d107=0;_d108=false;ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d185();_k19=false;_k20=false;_d171=0;_w15=0;_d123=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=_ag(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d219=_pu(_k16+0x24);if(_d219<2||_d219>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d130,uint _k27){
if(_d130 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d130);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d219=_pu(p+0x24);
return _d219>=2&&_d219<=6;
}
bool _k0(ActorBase@_d130,uint _k27){
if(Player is null||!_k1(_d130,_k27))return false;
ptr_t _d54=_pa(_d130),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d81=_pu(_d54+0x220);ptr_t _d152=_pq(_d54+0x228);
if(_d81<=129||_d81>512||!_k2(_d152))return false;
ptr_t _d80=_pq(_d152+0x408);
if(!_k2(_d80))return false;
uint _d190=_pu(_d80+0x20);ptr_t _k29=_pq(_d80+0x28);
if(_d190!=1||!_k2(_k29))return false;
ptr_t _d188=_pq(_k29);
if(!_k2(_d188))return false;
uint _d189=_pu(_d188+0x10),flags=_pu(_d188+0x18);
float _k33=_pf(_d188+0x74);
if(_d189!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d188+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d130,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d171=a.pos_x;_w15=a.pos_z;return;}
float dx=_d171-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d171=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
int _d146=0,spawnedType=0;bool _d141=true,capChordLatched=true,devChords=false;
string _d139(int t){return t==1?"SpObj_ControlStick_A_06":t==2?"SpObj_ControlStick_A_05":t==3?"SpObj_ControlStick_A_04":"SpObj_ControlStick_A_01";}//variants are new actors A_04..A_06
string _d143(int t){return t==1?"Pipe Frame":t==2?"B Dasher":t==3?"Standard Bike":"Standard Kart";}
const int _d25=4;bool _d138(int t){return t==3;}
string _d140(int t){return"SpObj_ControlStick_Capsule_A_0"+(t+1);}//inventory capsules(scripts/build_kart_capsules.py)
const string _d24="SpObj_ControlStick_A_0";
uint _d58=0;
int _d147(ptr_t a){
ptr_t s=_pq(a+0x218);if(s<0x1000000||s>0x8000000000)return-1;
for(uint i=0;i<_d24.length();i++)if(ptr_deref_u8(s+i)!=_d24[i])return-1;
uint d=ptr_deref_u8(s+22);if(ptr_deref_u8(s+23)!=0)return-1;
return d==49?0:d==54?1:d==53?2:d==52?3:-1;//A_01 Standard,A_06 Pipe Frame,A_05 B Dasher,A_04 Bike(A_02/A_03 vanilla)
}
void _d57(){
if(Player is null||(_d58++)%10!=0)return;
ptr_t p=_pa(Player);uint n=_pu(p+0x220);ptr_t _d152=_pq(p+0x228);
if(n<=130||n>600||!_d109(_d152))return;
ptr_t c=_pq(_d152+8*130);if(!_d109(c))return;
ptr_t ld=_pq(c+0x28);if(!_d109(ld))return;
ptr_t k=_pq(ld+0x40);if(!_d109(k)||k==_k16)return;
uint id=_pu(ld+0x48);if(_pu(k+0x10)!=id)return;
uint st=_pu(k+0x24);if(st<2||st>6)return;
int t=_d147(k);if(t<0)return;
_k13();ActorWatcher::assignSlot(2,k);_k16=k;_k17=id;spawnedType=t;_d146=t;
ActorBase@a=_ag(2);
if(a is null||_pa(a)!=k||!_k15(a)){_k13();return;}
_L("KART adopted "+_d143(t));
}
float _d144(int t){return t==1?1.0f:t==2?1.18f:t==3?1.275f:1.0f;}
float _d145(int t){return t==1?1.2f:t==2?1.42f:t==3?1.275f:1.3f;}
void _k8(){
if(!_k3())return;
ActorBase@_d165=_k7();
if(_k15(_d165)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d151=sqrt(fx*fx+fz*fz);if(_d151<0.1f)return;fx/=_d151;fz/=_d151;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d165!is null&&spawnedType!=_d146){_k13();@_d165=null;}//a different kart was chosen:spawn it(the _d165 one stays)
if(_d165!is null){_k10(_d165);_d165.setPos(x,y,z);@_d165=null;_d171=0;_w15=0;_d123=false;}
else{_k13();actor::createAndWatch(2,_d139(_d146),x,y,z);spawnedType=_d146;sleep(60);}//let creation get past its first _d91 before touching the _d54
for(uint f=0;f<600&&_k3();f++){//up to 20 s:a first load of a kart pack can take a while
ActorBase@a=_ag(2);
if(a!is null){
_k16=_pa(a);if(!_d109(_k16)){@a=null;sleep(1);continue;}_k17=_pu(_k16+0x10);
if(f%60==0)_L("KART spawn wait f="+f+" ptr="+formatInt(int64(_k16),"H")+" state="+_pu(_k16+0x24)+" ct="+_d109(_pq(_k16+0x228)));
ptr_t ct=_pq(_k16+0x228);bool _d173=_d109(ct)&&_d109(_pq(ct+0x50))&&_d109(_pq(_pq(ct+0x50)+0x20));
if(_d173&&a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();
if(a is null){ptr_t k=_k16;_L("KART spawn lost: watcher="+(_ag(2)!is null)+" state="+(_d109(k)?_pu(k+0x24):99)+" id="+(_d109(k)?_pu(k+0x10):0)+"/"+_k17);return;}a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d171=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
{ActorBase@a=_ag(2);ptr_t k=a is null?0:_pa(a);ptr_t ct=_d109(k)?_pq(k+0x228):0;
_L("KART spawn unavailable: world="+_k3()+" watcher="+(a!is null)+" ptr="+formatInt(int64(k),"H")+" state="+(_d109(k)?_pu(k+0x24):99)+" ct="+_d109(ct)+" phys="+(_d109(ct)&&_d109(_pq(ct+0x50))));}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d235(ActorBase@a){
ptr_t _d152=_pq(_pa(a)+0x228);if(!_k2(_d152))return 0;
ptr_t mc=_pq(_d152+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
float lf=_pf(b+120),rf=_pf(b+216),lb=_pf(b+312),rb=_pf(b+408);
if(abs(_pf(b+28)-0.3766f)>(_d138(spawnedType)?0.08f:0.002f)||abs(lf+rf)>0.002f||abs(lb+rb)>0.002f)return 0;//(a leaning bike moves its root)
if(_d138(spawnedType)){if(abs(lf)>0.01f||abs(lb)>0.01f)return 0;}//bike:both sockets of an axle on the centre line
else if(lf<0.5f||lf>1.2f||lb<0.5f||lb>1.2f)return 0;
return b;
}
void _d236(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
const float _d49=0.3927f;//2*pi/16 tread _d68
float _d233(float _d222){
float m=abs(_d222),half=_d49*0.5f;
if(m<=half*0.9f)return _d222;
float _d68=floor((m-half)/_d49);if(_d68>3)_d68=3;
float v=(_d68+0.5f)*_d49;return _d222<0?-v:v;
}
void _d62(ActorBase@a){
if(a is null){_d123=false;return;}
Matrix33f r=a.rot;float _d151=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d123&&_d151>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d151;}
_w4=x;_w5=z;_d123=true;
_w2+=_d233(ds/(0.28328f*_d144(spawnedType)));_w3+=_d233(ds/(0.28328f*_d145(spawnedType)));//tyre radius x body tyre scale
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d221*0.45f-_w1)*0.25f;
ptr_t b=_d235(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d236(b+72,sf,cf,sd,cd);_d236(b+168,sf,cf,sd,cd);
_d236(b+264,sr,cr,0,1);_d236(b+360,sr,cr,0,1);
if(_d138(spawnedType))_d66(b);
}
const float _d4=0.38f,BIKE_DRIFT_LEAN=0.5f,BIKE_PIVOT_Y=-0.30f;//[chosen]~22 deg turning,~29 deg drifting
float _d67=0;
void _d66(ptr_t b){
float sp=abs(_d159)/_d36;if(sp>1)sp=1;
float _d227=_d61||gliding?0:(_d84!=0?_d84*BIKE_DRIFT_LEAN*(0.7f+0.3f*abs(_d221)):_d221*_d4*sp);
_d67+=(_d227-_d67)*0.12f;
float c=cos(_d67),s=sin(_d67);ptr_t r=b-24;
_pw(r,c);_pw(r+4,s);_pw(r+8,0);
_pw(r+16,-s);_pw(r+20,c);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,1);
_pw(r+48,s*BIKE_PIVOT_Y);_pw(r+52,0.3766f+BIKE_PIVOT_Y-c*BIKE_PIVOT_Y);_pw(r+56,0);
}
void _d185(){_d232=0;_d61=false;trickDone=false;gliding=false;_d60=0;groundFrames=0;trickWindow=0;_d159=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d84=0;driftTier=0;boostLeft=0;hopWindow=0;_d128=false;gasLatch=true;idleHold=false;}
int _d118=-1;float _d113=99;//updated by _d116(ray cast under the kart)
float _d228(){
if(!_d164||_d113>=0.8f)return 1;
int m=_d118;
if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;//HeavySand,HeavySnow,Bog,Tar,Water,ContaminatedWater
if(m==1||m==2||m==3||m==5)return _d43;//Soil,Grass,Sand,Snow
return 1;
}
float _d217(float v,float _d229){
if(boostLeft>0){
boostLeft--;float t=_d36*_d41;
if(v<t){float _d134=(t-v)*_d29;if(_d134>MK_BOOST_CAP)_d134=MK_BOOST_CAP;return v+_d134;}
return t;
}
if(_d229>0){
if(v<0)return v+_d30>0?0:v+_d30;//stop reversing first
float t=_d36*_d229*_d228();
if(v<t){float _d134=(t-v)*_d28;if(_d134>_d27)_d134=_d27;return v+_d134;}//[native]form
float d=v*_d34;return d<t?t:d;
}
if(_d229<0){
if(v>0)return v-_d30<0?0:v-_d30;//brake,then reverse
float t=-_d35*(-_d229);
if(v>t){float _d134=(v-t)*_d28;if(_d134>_d27)_d134=_d27;return v-_d134;}
return v;
}
if(v>0)return v-_d32<0?0:v-_d32;
return v+_d32>0?0:v+_d32;
}
void _d85(int _d230){
_L("KART drift tier="+_d230+" charge="+driftCharge);
if(_d230==1)_T(30,"Mini-Turbo\n");else if(_d230==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d124){
_d221=0;
ActorBase@a=_k7();bool _d186=_k15(a);
if(!_d186&&Player!is null){_d57();@a=_k7();_d186=_k15(a);}
if(_d186!=_k19){_L("KART mounted="+_d186);_d185();_k19=_d186;_k20=!_d186;if(a!is null){_d171=a.pos_x;_w15=a.pos_z;}}
if(!_d186||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d185();return;}
float _d220=float(ix)/32768.0f,_d229=0;
if(abs(_d220)<0.15f)_d220=0;
bool _d104=(_d124&uint64(A))!=0,brake=(_d124&uint64(B))!=0;
if(!_d104)gasLatch=false;//the A press used to get in must be released first
if(brake)_d229=-1;else if(_d104&&!gasLatch)_d229=1;
_d221=_d220;
Matrix33f r=a.rot;float _d151=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d151<0.1f||r.a4<0.4f){_k10(a);_d185();return;}
float bx=r.a2/_d151,bz=r.a8/_d151,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
_d70=fx;camFz=fz;camBraking=brake&&_d159>0.5f;
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d55=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d56=_d55/_d39;
if(_d159>0&&_d159>_d56+0.6f)_d159=_d56+0.6f<0?0:_d56+0.6f;
if(_d159<0&&_d159<_d56-0.6f)_d159=_d56-0.6f>0?0:_d56-0.6f;
bool _d181=(_d124&uint64(R|ZR))!=0,fast=_d159>_d36*0.35f;
if(_d97())_d119(a.pos_x,a.pos_y+0.2f,a.pos_z);
bool _d168=_d113<AIR_GAP;
if(_d168){groundFrames++;_d60=0;}else{_d60++;groundFrames=0;}
bool _d234=_d61;
bool _d180=_d181&&!_d128;rPressAge=_d180?0:rPressAge+1;
if(!_d61&&_d60>=2){
_d61=true;trickWindow=_d51;trickDone=false;_L("KART airborne");
if(rPressAge<=6+_d60){trickDone=true;_d218(_d220);_d204(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick (buffered)");}
}
if(_d61&&groundFrames>=1){
_d61=false;
if(gliding){gliding=false;_L("KART glider landed");}
if(trickDone){if(boostLeft<TRICK_FRAMES)boostLeft=TRICK_FRAMES;_d204(_d48,CH_SHOT);_L("KART trick boost");}
trickDone=false;_L("KART landed");
}
float _d127=0;
bool _d179=_d181&&!_d128;
if(_d61){
if(trickWindow>0){trickWindow--;if(_d179&&!trickDone){trickDone=true;_d218(_d220);_d204(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick");}}
}else if(_d179){_d127=_d23;hopWindow=24;_d204(S_HOP,CH_SHOT);}//MK8 hops at any speed
_d128=_d181;
bool _d237=(_d124&uint64(Y))!=0;
if(!_d237)gliderLatch=false;
if(_d237&&!gliderLatch){
gliderLatch=true;
if(gliding){gliding=false;autoGlideBlocked=true;_L("KART glider folded");}
else if(_d61&&_d113>=GLIDE_MIN_HEIGHT){gliding=true;_d204(S_GOPEN,CH_SHOT);_d84=0;driftCharge=0;driftTier=0;_T(30,"Glider!\n");_L("KART glider open");}
}
if(!_d61)autoGlideBlocked=false;
if(_d63&&_d61&&!gliding&&!autoGlideBlocked&&_d232==0&&_d60>=_d3&&v.y<-_d2&&_d113>=GLIDE_MIN_HEIGHT){
gliding=true;autoGlideBlocked=true;_d204(S_GOPEN,CH_SHOT);_d84=0;driftCharge=0;driftTier=0;_L("KART glider auto");
}
if(_d84==0&&!_d61&&_d181&&hopWindow>0&&abs(_d220)>0.3f){_d84=_d220>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d84);}
if(_d84!=0&&(!_d181||!fast)){
int _d91=driftTier==3?int(_d52):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d40):0;
if(_d91>0&&_d181==false){boostLeft=_d91;_d204(driftTier==3?S_ULTRA:_d48,CH_SHOT);_L("KART boost tier="+driftTier+" frames="+_d91);}
_d84=0;driftCharge=0;driftTier=0;
}
if(!_d61&&_d229==0&&boostLeft==0&&_d84==0&&_d127==0&&abs(_d159)<_d32){
_d159=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d171=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d238=0,oldOff=bodyOff;
for(int _d222=0;_d222<2;_d222++){
if(hopWindow>0)hopWindow--;
if(gliding){float t=_d19*(iy>16000?1.06f:1.0f);_d159+=(t-_d159)*0.02f;}
else if(!_d61||boostLeft>0)_d159=_d217(_d159,_d229);
float _d69=0;
if(gliding){
driftTrack=0;_d238+=_d220*_d37*GLIDE_STEER;
}else if(_d84!=0){
float _d137=_d220*_d84;if(_d137>1)_d137=1;if(_d137<-1)_d137=-1;
float _d231=_d137>=0?_d12:-_d12,dt=(_d231-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d136=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d238+=_d84*_d33*_d136*_d136*(0.75f+0.25f*_d137);
if(!_d61)driftCharge+=_d137>=CHARGE_INWARD?_d8:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d230=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d9?1:0;
if(_d230>driftTier){driftTier=_d230;_d85(_d230);}
_d69=_d84*_d11;
}else{
driftTrack=0;
float _d215=abs(_d159)/(_d36*0.25f);if(_d215>1)_d215=1;
_d238+=_d220*_d37*_d215*(_d159<0?-1.0f:1.0f)*(_d61?_d1:1.0f);
}
if(_d232>0){bodyOff+=6.2832f/float(_d50*2)*float(trickRollDir);}
else{
float _d103=_d69-bodyOff,ds=_d103*0.07f;
if(abs(ds)<0.001f)ds=abs(_d103)<0.001f?_d103:(_d103>0?0.001f:-0.001f);
bodyOff+=ds;
}
if(!_d61)lateral*=1-_d20*_d38;
else lateral*=gliding?1-GLIDE_SIDE_DRAG:1-AIR_SIDE_DRAG;
}
if(_d232>0){_d232--;if(_d232==0||!_d61){_d232=0;while(bodyOff>3.1416f)bodyOff-=6.2832f;while(bodyOff<-3.1416f)bodyOff+=6.2832f;}}
_k18=_d159*_d39;
float _d216=_k18;
float vy=v.y+_d127;
if(gliding){
float _d197=iy>16000?GLIDE_DIVE:iy<-16000?GLIDE_FLOAT:GLIDE_SINK;//stick forward dives,back floats
vy+=(-_d197-vy)*0.3f+_d18;//ease into the glide descent(gravity compensated)
}
if(gliding&&vy<-_d0)vy=-_d0;//glider only(user:free fall must stay normal speed)
b.setVel(fx*_d216+lx*lateral,vy,fz*_d216+lz*lateral);
float tx=0,ty=1,tz=0,gain=2.0f;
if(gliding){
float _d174=float(iy)/32768.0f;if(_d174>1)_d174=1;if(_d174<-1)_d174=-1;
float _d64=_d220*_d17,nose=_d174*GLIDE_PITCH;//stick right:right _d193 down;stick forward:nose down
tx=-lx*_d64+fx*nose;tz=-lz*_d64+fz*nose;
float _d125=sqrt(tx*tx+tz*tz);if(_d125>GLIDE_MAX_LEAN){tx*=GLIDE_MAX_LEAN/_d125;tz*=GLIDE_MAX_LEAN/_d125;}
ty=1;float tl=sqrt(tx*tx+ty*ty+tz*tz);tx/=tl;ty/=tl;tz/=tl;gain=GLIDE_TILT_GAIN;
}
float ux=r.a1,uy=r.a4,uz=r.a7;
float wx=(uy*tz-uz*ty)*gain,wz=(ux*ty-uy*tx)*gain;//world axes(a body-axis version flipped the kart)
b.setAngularVel(wx,-(_d238+bodyOff-oldOff)*30.0f,wz);
}
const uint _d15=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float _d46=0.35f,FLAME_SCALE=0.15f;//[chosen]from screenshots
ptr_t _d94=0,fxSys=0,fxScr=0;int _d98=-2,fxFlame=-1;
bool _d95(ptr_t p,const string&in _d160){
uint n=_d160.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=_d160[i])return false;
return ptr_deref_u8(p+n)==0;
}
int _d92(const string&in _d160){
ptr_t _d184=_pq(_pq(fxSys+0x2ee8)+8);if(_d184==0||ptr_deref_u8(_d184+0x571)==0)return-1;//static effects=resource 1
int n=_ps(_d184+0x558);ptr_t _d192=_pq(_d184+0x430);
for(int i=0;i<n;i++)if(_d95(_pq(_d192+0x28*i)+0x10,_d160))return i;
return-1;
}
bool _d97(){
if(_d98>=0)return true;
if(_d98==-1)return false;//looked once and failed:stay off
_d98=-1;
ptr_t _d126=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d126==0)return false;
uint op=_pu(_d126);int64 _d82=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d82-=0x04000000;
ptr_t _d227=ptr_t(int64(_d126)+_d82*4),_d65=_d227-0x65b80;
if((_d65&0xfff)!=0||_pu(_d227)!=0xf0001382)return false;
fxScr=_d65+FX_SCRATCH;_d94=sys::mainOffset();
ptr_t _d135=_pq(_pq(_d94+_d15));if(_d135==0)return false;
fxSys=_pq(_d135+0x11b8);if(fxSys==0)return false;
int _d212=_d92("Ply_ShockWave_Spark");fxFlame=_d92("Chm_FlameThrower_ScraBuild");//Zonai _d88 emitter jet
_L("KART fx spark="+_d212+" flame="+fxFlame);
if(_d212<0)return false;
_d98=_d212;return true;
}
ptr_t _d93(int _d199){ptr_t h=fxScr+0x10*_d199,e=_pq(h);if(e==0)return 0;return _pu(e+0x234)==_pu(h+8)?e:0;}
ptr_t _d99(int _d199,int id){
ptr_t e=_d93(_d199);if(e!=0)return e;
ptr_t h=fxScr+0x10*_d199;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d94+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*_d199,0,0,0,0,0);
return _d93(_d199);
}
void _d101(int _d199){if(fxScr==0)return;ptr_t e=_d93(_d199);if(e!=0)ptr_call(_d94+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*_d199,0);}
void _d96(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
_pw(m,r.a0);_pw(m+4,r.a1);_pw(m+8,r.a2);_pw(m+12,px);
_pw(m+16,r.a3);_pw(m+20,r.a4);_pw(m+24,r.a5);_pw(m+28,py);
_pw(m+32,r.a6);_pw(m+36,r.a7);_pw(m+40,r.a8);_pw(m+44,pz);
_pw(fxScr+0x140,s);_pw(fxScr+0x144,s);_pw(fxScr+0x148,s);
ptr_call(_d94+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
void _d102(ptr_t e,float r,float g,float b){_pw(e+0x40,r);_pw(e+0x44,g);_pw(e+0x48,b);}
void _d213(ActorBase@a){
bool _d214=a!is null&&_k19&&_d84!=0&&driftTier>0;
bool _d88=a!is null&&_k19&&boostLeft>0;
if(!_d214&&!_d88&&fxScr==0)return;
if(!_d97()){return;}
if(!_d214)_d101(0);
if(!_d88||fxFlame<0)_d101(1);
if(_d214){
ptr_t e=_d99(0,_d98);
if(e!=0){
if(driftTier==1)_d102(e,0.25f,0.8f,6.0f);else if(driftTier==2)_d102(e,1.0f,1.0f,1.0f);else _d102(e,2.2f,0.4f,6.0f);
ptr_t b=_d235(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(_pf(b+312));wy=_pf(b+28)+_pf(b+316)-0.3683f;wz=_pf(b+32)+_pf(b+320);}
_d96(e,a,wx,wy,wz,_d46);_d96(e,a,-wx,wy,wz,_d46);
}
}
if(_d88&&fxFlame>=0){ptr_t e=_d99(1,fxFlame);if(e!=0){_d96(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);_d96(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
const uint _d14=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int _d120=-1,groundTick=0;
int _d105=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;//effect ids per class,looked up once(no arrays in this runtime)
bool _d119(float x,float y,float z){
ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d94+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);//flags:all false
_pw(v+4,2.0f);ptr_write_u64(q+0x38,v+4);//ray _d151(m)
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d94+_d14,q,0,0,0,0,0,0,0,0,0,0);
if(ptr_deref_u8(v+0x10)==0){_d118=-1;_d113=99;return false;}
_d118=_ps(v+0x40);_d113=_pf(v+0x14);return true;
}
int _d112(int m){
if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return-1;return 6;
}
string _d115="";//diagnostics only:overrides the grass effect _d160
string _d114(int c){
if(c==0&&_d115!="")return _d115;
if(c==0)return"ReFX_Grass_L";if(c==1||c==2)return"ReFX_Sand_L";if(c==3)return"ReFX_Snow_L";
if(c==4)return"Water_Splash01_Move";if(c==5)return"RctFld_Mud_Splash_S";return"Ply_SlipSmoke_Stone";
}
int _d117(int c){
if(c==0){if(_d105==-2)_d105=_d92(_d114(0));return _d105;}if(c==1){if(gid1==-2)gid1=_d92(_d114(1));return gid1;}
if(c==2){if(gid2==-2)gid2=_d92(_d114(2));return gid2;}if(c==3){if(gid3==-2)gid3=_d92(_d114(3));return gid3;}
if(c==4){if(gid4==-2)gid4=_d92(_d114(4));return gid4;}if(c==5){if(gid5==-2)gid5=_d92(_d114(5));return gid5;}
if(gid6==-2)gid6=_d92(_d114(6));return gid6;
}
const float _d22=1.2f,GROUND_MIN_SPEED=3.0f;//[chosen]
const int _d21=6;//[chosen]_d91 between bursts:TOTK's ground effects are one-shot(per footstep/hoof)
int _d111=0,groundBurstSlot=0;
void _d121(){if(fxScr==0)return;for(int k=3;k<7;k++)_d101(k);}
ptr_t _d100(int _d199,int id,ptr_t _d178){
ptr_t h=fxScr+0x10*_d199;_d101(_d199);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d94+FX_CREATE,fxSys,h,id,1,0,_d178,0,0,0,0,0);
return _d93(_d199);
}
void _d116(ActorBase@a){
bool _d53=a!is null&&_k19&&_d97();
if(!_d53){_d121();_d120=-1;return;}
int c=_d113<0.8f?_d112(_d118):-1;
bool _d163=c>=0&&c<6,show=c>=0&&abs(_k18)>GROUND_MIN_SPEED&&(_d163||_d84!=0);
_d120=show?c:-1;
if(!show){_d111=0;return;}
if(_d111-->0)return;
_d111=_d21;
int id=_d117(c);if(id<0)return;
int _d199=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
ptr_t e=_d100(_d199,id,fxScr+0x5000);if(e==0)return;
float wx=0.78f,wz=-0.75f;ptr_t b=_d235(a);if(b!=0){wx=abs(_pf(b+312));wz=_pf(b+32)+_pf(b+320);}
_d96(e,a,wx,0,wz,_d22);_d96(e,a,-wx,0,wz,_d22);
}
const float _d16=-0.15f,GLIDER_Z=-0.45f,GLIDER_STORE=1000.0f;//mesh stored 1/1000 size(scripts/build_glider.py)//[chosen]attach point in kart space(glider frame _d65)
float _d107=0;bool _d108=false;
ptr_t _d132=0,hostSklAt=0;
ptr_t _d131(ActorBase@a){
ptr_t _d152=_pq(_pa(a)+0x228);if(!_k2(_d152))return 0;
ptr_t mc=_pq(_d152+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
if(m==_d132&&hostSklAt!=0)return hostSklAt;
_d132=m;hostSklAt=0;_d108=false;//new kart(model instances are pooled:a reused one can keep an open glider)
for(uint o=0;o<0x4000;o+=4){
ptr_t r=m+o;
if(abs(_pf(r+52)-0.3766f)<0.003f&&abs(_pf(r+48))<0.003f&&abs(_pf(r+56))<0.003f
&&abs(_pf(r+96+52)-0.5966f)<0.003f&&abs(_pf(r+96+56)-0.4928f)<0.003f){hostSklAt=r;_L("KART host Skl_Root record at +"+o);break;}
}
return hostSklAt;
}
void _d110(ptr_t _d183,ptr_t j,float px,float py,float pz){
float dx=px-_pf(j+48),dy=py-_pf(j+52),dz=pz-_pf(j+56);
for(uint c=0;c<3;c++)_pw(_d183+48+4*c,_pf(j+16*c)*dx+_pf(j+16*c+4)*dy+_pf(j+16*c+8)*dz);
}
void _d122(ActorBase@a){
if(a is null)return;ptr_t _d198=_d131(a);if(_d198==0)return;
if(!_d138(spawnedType)){
_pw(_d198+192+48,0);_pw(_d198+192+52,-0.0001f);_pw(_d198+192+56,-0.2107f);
_pw(_d198+288+48,0);_pw(_d198+288+52,-0.0001f);_pw(_d198+288+56,0.2107f);
return;
}
float ax=0,ay=0.906f,az=-0.423f,c=cos(_w1),s=sin(_w1);
for(int _d193=-1;_d193<=1;_d193+=2){
float vx=0.62f*_d193,vy=0.96f-0.645f,vz=0.43f-0.752f,d=ax*vx+ay*vy+az*vz;
float cx=ay*vz-az*vy,cy=az*vx-ax*vz,cz=ax*vy-ay*vx;
float rx=vx*c+cx*s+ax*d*(1-c),ry=vy*c+cy*s+ay*d*(1-c),rz=vz*c+cz*s+az*d*(1-c);
float gx=rx,gy=0.645f+ry,lc=cos(_d67),ls=sin(_d67);
float lx=lc*gx-ls*gy+ls*BIKE_PIVOT_Y,ly=ls*gx+lc*gy+BIKE_PIVOT_Y-lc*BIKE_PIVOT_Y;
_d110(_d193>0?_d198+192:_d198+288,_d198+96,lx,ly,0.752f+rz);//+X is Link's left:Handle_L
}
}
void _d106(ActorBase@a){
float _d227=(a!is null&&_k19&&gliding)?1:0;
if(_d227==0&&_d107==0&&_d108)return;
if(a is null)return;
ptr_t _d198=_d131(a);if(_d198==0)return;
if(_d107<_d227){_d107+=0.17f;if(_d107>_d227)_d107=_d227;}
else if(_d107>_d227){_d107-=0.2f;if(_d107<_d227)_d107=_d227;}
ptr_t r=_d198-192;float sc=_d107*GLIDER_STORE;//Control=bone 1,two records before Skl_Root(bone 3)
_pw(r,sc);_pw(r+4,0);_pw(r+8,0);
_pw(r+16,0);_pw(r+20,sc);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,sc);
_pw(r+48,0);_pw(r+52,_d16);_pw(r+56,GLIDER_Z);
_d108=true;
}
const uint _d13=0x1085b5c;
bool _d90=false;
bool _d109(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d176(){
if(Player is null)return 0;ptr_t p=_pq(_pa(Player)+0x228);if(!_d109(p))return 0;
p=_pq(p+0x50);if(!_d109(p))return 0;p=_pq(p+0x20);return _d109(p)?p:0;
}
void _d89(){
if(!_k19&&!_d90)return;
ptr_t _d172=_d176();if(_d172==0)return;
ptr_call(sys::mainOffset()+_d13,_d172,_k19?0:1,0,0,0,0,0,0,0,0,0);
_d90=_k19;
}
const uint _d44=0x809ee0,SND_FADE=0xb226a4,PROP_SET=0x11acb98;
const int _d10=0,CH_SIZZLE=1,CH_DRIFT=2,CH_RUN=3,CH_SLIP=4,CH_FLUTTER=5,CH_SHOT=6;
const float _d45=1.0f/14.0f;//[chosen]top speed(14 m/s)=1=top of curve 213
const int _d47=1,S_DASH=2,S_IDLE=3,S_SIZZLE=4,S_DRIFT=7,S_FLUTTER=8,S_RUN=10,S_SLIP=20,S_LANDS=30;
const int _d48=40,S_ULTRA=41,S_HOP=42,S_LAND=43,S_TRICK=44,S_GOPEN=45,S_GCLOSE=46,S_HORN=47;
int _d202=0;int _d77=0,chKey1=0,chKey2=0,chKey3=0,chKey4=0,chKey5=0;
string _d224(int s){return s==0?"Grass":s==1?"Dirt":s==2?"Sand":s==3?"Snow":s==4?"Water":s==5?"Stone":"Wood";}
string _d149(int id){
if(id==_d47)return"Kart_Engine";if(id==S_DASH)return"Kart_EngineDash";if(id==S_IDLE)return"Kart_Idle";
if(id>=S_SIZZLE&&id<S_SIZZLE+3)return"Kart_Sizzle"+(id-S_SIZZLE+1);if(id==S_DRIFT)return"Kart_DriftSteer";
if(id==S_FLUTTER)return"Kart_GliderFlutter";if(id>=S_RUN&&id<S_RUN+7)return"Kart_Run_"+_d224(id-S_RUN);
if(id>=S_SLIP&&id<S_SLIP+7)return"Kart_Slip_"+_d224(id-S_SLIP);if(id>=S_LANDS&&id<S_LANDS+7)return"Kart_Land_"+_d224(id-S_LANDS);
if(id==_d48)return"Kart_MiniTurbo";if(id==S_ULTRA)return"Kart_UltraTurbo";if(id==S_HOP)return"Kart_Hop";if(id==S_LAND)return"Kart_Land";
if(id==S_TRICK)return"Kart_Trick";if(id==S_HORN)return"Kart_Horn";if(id==S_GOPEN)return"Kart_GliderOpen";if(id==S_GCLOSE)return"Kart_GliderClose";return"";
}
ptr_t _d209=0;int _d205=-1;bool _d210=false;
ptr_t _d207(){
ActorBase@a=_k7();if(a is null||!_d97())return 0;
ptr_t x=_pq(_pa(a)+0x228);if(!_d109(x))return 0;
x=_pq(x+0x68);if(!_d109(x))return 0;
ptr_t u=_pq(x+0x78);return _d109(u)?u:0;
}
void _d204(int id,int ch){
ptr_t u=_d207();if(u==0||id<=0)return;string _d148=_d149(id);
ptr_t k=fxScr+0x7800,h=fxScr+0x7880+8*ch;uint n=_d148.length();
for(uint w=0;w<4;w++){uint64 v=0;for(uint i=0;i<8;i++){uint c=w*8+i;if(c<n)v|=uint64(_d148[c])<<(8*i);}ptr_write_u64(k+8*w,v);}
ptr_write_u64(h,0xffff00ff);
ptr_call(_d94+_d44,u,k,h,0,0,0,0,0,0,0,0);
if(_d202<80){_d202++;_L("KART snd "+_d148+" h="+_pq(h));}
}
void _d200(int ch){if(fxScr==0)return;ptr_t h=fxScr+0x7880+8*ch;if(_pq(h)!=0xffff00ff)ptr_call(_d94+SND_FADE,h,0xffffffff,0,0,0,0,0,0,0,0,0);ptr_write_u64(h,0xffff00ff);}
int _d76(int ch){return ch==0?_d77:ch==1?chKey1:ch==2?chKey2:ch==3?chKey3:ch==4?chKey4:chKey5;}
void _d78(int ch,int k){if(ch==0)_d77=k;else if(ch==1)chKey1=k;else if(ch==2)chKey2=k;else if(ch==3)chKey3=k;else if(ch==4)chKey4=k;else chKey5=k;}
void _d203(int ch,int _d148){
if(_d76(ch)==_d148)return;
if(_d76(ch)!=0)_d200(ch);
if(_d148!=0)_d204(_d148,ch);
_d78(ch,_d148);
}
bool _d177(ptr_t x){
if(!_d109(x))return false;uint n=_pu(x+0x110);if(n==0||n>16)return false;
ptr_t _d161=_pq(x+0x118);if(!_d109(_d161))return false;
for(uint i=0;i<n;i++){ptr_t s=_pq(_d161+8*i);if(_d109(s)&&_d95(s,"ControlStick_StickSpeedXY")){_d205=int(i);return true;}}
return false;
}
void _d201(){
_d210=true;_d209=0;_d205=-1;
ActorBase@a=_k7();if(a is null)return;
ptr_t p=_pq(_pa(a)+0x228);if(!_d109(p))return;
p=_pq(p);if(!_d109(p))return;
p=_pq(p+0x10);if(!_d109(p))return;
if(_d177(p))_d209=p;
_L("KART snd prop X="+(_d209!=0)+" idx="+_d205+" n="+_pu(p+0x110));
}
void _d206(float ms){
if(_d209==0||_d205<0)return;
ptr_t f=fxScr+0x7a00;
_pw(f,abs(ms)*_d45);
ptr_call(_d94+PROP_SET,_d209,_d205,f,0,0,0,0,0,0,0,0);
}
int _d150=-2,lastSurface=-1;
bool _d156(int m,const string&in w){
ptr_t t=_pq(_d94+0x4637298);if(t==0||m<0||m>=54)return false;ptr_t s=_pq(t+0x250+8*m);if(!_d109(s))return false;
uint n=w.length();for(uint i=0;i<28;i++){if(ptr_deref_u8(s+i)==0)return false;bool ok=true;for(uint k=0;k<n&&ok;k++)if(ptr_deref_u8(s+i+k)!=w[k])ok=false;if(ok)return true;}
return false;
}
int _d225(){
if(_d118==_d150)return lastSurface;
_d150=_d118;int c=_d112(_d118);
lastSurface=c<0?-1:c==0?0:c==1?1:c==2?2:c==3?3:c==4?4:c==5?1:(_d156(_d118,"Wood")?6:5);
return lastSurface;
}
bool _d208=false,sndWasGlide=false;
void _d211(){
if(!_k19){
if(_d77!=0||chKey1!=0||chKey2!=0||chKey3!=0||chKey4!=0||chKey5!=0){for(int c=0;c<6;c++)_d203(c,0);}
_d210=false;_d208=false;sndWasGlide=false;return;
}
if(!_d210)_d201();
float sp=abs(_k18);_d206(sp);
_d203(_d10,gliding?0:boostLeft>0?S_DASH:sp<0.6f?S_IDLE:_d47);
_d203(CH_SIZZLE,(_d84!=0&&driftTier>0&&!gliding)?S_SIZZLE+driftTier-1:0);
int _d223=(_d61||gliding)?-1:_d225();
_d203(CH_DRIFT,(_d84!=0&&!_d61&&!gliding)?S_DRIFT:0);
_d203(CH_RUN,(_d223>=0&&sp>1.0f&&_d84==0)?S_RUN+_d223:0);
_d203(CH_SLIP,(_d223>=0&&_d84!=0)?S_SLIP+_d223:0);
_d203(CH_FLUTTER,gliding?S_FLUTTER:0);
if(sndWasGlide&&!gliding)_d204(S_GCLOSE,CH_SHOT);
if(_d208&&!_d61){_d204(S_LAND,CH_SHOT);int s2=_d225();if(s2>=0)_d204(S_LANDS+s2,CH_SHOT+1);}
_d208=_d61;sndWasGlide=gliding;
}
const bool _d26=true;
const float _d5=6.2f,CAM_HEIGHT=2.4f,CAM_LOOK_AHEAD=1.6f,CAM_LOOK_UP=1.2f,CAM_DRIFT_SWING=0.16f;
const float _d7=3.0f,CAM_LEAD=0.07f;//[chosen]seconds of fall to lead
const float _d6=7.6f,CAM_GLIDE_HEIGHT=4.4f,CAM_BOOST_BACK=0.8f,CAM_KICK=0.7f,CAM_BRAKE_IN=0.5f;
bool _d158=_d26,mkCamChordLatched=true,camFrozen=false,camInit=false,camBraking=false;
float _d70=0,camFz=1,camHx=0,camHz=1,camDist=_d5,camH=CAM_HEIGHT,camY=0,camKick=0,camLook=0;int _d71=0;
void _d73(){if(camFrozen){camera::toggleFreeze();camFrozen=false;}camInit=false;}
void _d74(ActorBase@a,int rx,int ry){
if(!_d158||a is null||!_k19){_d73();return;}
float sp=abs(_k18);
if(boostLeft>_d71+5)camKick=1;_d71=boostLeft;camKick*=0.88f;
float tx=_d70,tz=camFz;
if(_d84!=0){float c=cos(-_d84*CAM_DRIFT_SWING),s2=sin(-_d84*CAM_DRIFT_SWING);float nx=tx*c+tz*s2,nz=-tx*s2+tz*c;tx=nx;tz=nz;}
if(!camInit){camHx=tx;camHz=tz;camY=a.pos_y;camDist=_d5;camH=CAM_HEIGHT;}
float _d182=gliding?0.06f:_d61?0.05f:0.13f;
camHx+=(tx-camHx)*_d182;camHz+=(tz-camHz)*_d182;float hl=sqrt(camHx*camHx+camHz*camHz);if(hl<0.01f){camHx=tx;camHz=tz;hl=1;}camHx/=hl;camHz/=hl;
float _d153=float(rx)/32768.0f;if(abs(_d153)<0.2f)_d153=0;float _d154=_d153*1.8f;
if(float(ry)/32768.0f<-0.7f)_d154=3.1416f;//right stick down:_d153 behind(MK8 _d153-back)
camLook+=(_d154-camLook)*(_d154>3.0f?0.35f:0.15f);
float lc=cos(camLook),ls=sin(camLook),dx=camHx*lc+camHz*ls,dz=-camHx*ls+camHz*lc;
float _d83=gliding?_d6:_d5+sp*0.035f+(boostLeft>0?CAM_BOOST_BACK:0)-(camBraking?CAM_BRAKE_IN:0);
_d83+=camKick*CAM_KICK;
float h=gliding?CAM_GLIDE_HEIGHT:CAM_HEIGHT+sp*0.01f;
camDist+=(_d83-camDist)*(camKick>0.5f?0.3f:0.1f);camH+=(h-camH)*0.08f;
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
bool _d129=false;
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool _d169=false,exitLatch=false;uint64 _d166=0;int _d167=0,outLY=0,outRX=0,outRY=0;
bool _d194=false;uint64 _d195=0;int _d196=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d170){
uint64 _d124=_d194?_d195:_pq(_d170);
int lx=_d194?_d196:_ps(_d170+8),ly=_d194?simLY:_ps(_d170+12);
int rx=_d194?simRX:_ps(_d170+16),ry=_d194?simRY:_ps(_d170+20);
_d169=false;_d166=_d124;_d167=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
_d73();
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;
if(devChords){
uint64 _d155=uint64(ZL|ZR|DUP);
if((_d124&_d155)==0)_k24=false;
if(!_k24&&(_d124&_d155)==_d155){_k24=true;_k25=true;_L("KART spawn queued");}
uint64 _d142=uint64(ZL|ZR|X);
if((_d124&_d142)==0)_d141=false;
if(!_k19&&!_d141&&(_d124&_d142)==_d142){
_d141=true;_d146=(_d146+1)%_d25;_L("KART type="+_d146);
_T(120,"Kart: "+_d143(_d146)+" (ZL+ZR+Up to spawn, ZL+ZR+Y for a capsule)\n");
}
uint64 _d75=uint64(ZL|ZR|Y);
if((_d124&_d75)==0)capChordLatched=false;
if(!_k19&&!capChordLatched&&(_d124&_d75)==_d75&&Player!is null){
capChordLatched=true;Matrix33f r=Player.rot;
actor::createSimple(_d140(_d146),Player.pos_x+1.5f*r.a2,Player.pos_y+0.8f,Player.pos_z+1.5f*r.a8);
_L("KART capsule "+_d146);_T(90,_d143(_d146)+" capsule\n");
}
}
uint64 _d72=uint64(ZL|ZR|DLEFT);
if((_d124&_d72)==0)mkCamChordLatched=false;
if(!mkCamChordLatched&&(_d124&_d72)==_d72){
mkCamChordLatched=true;_d158=!_d158;_L("KART mkcam="+_d158);
_T(90,_d158?"Mario Kart camera: ON\n":"Mario Kart camera: OFF\n");
}
uint64 _d59=uint64(ZL|ZR|DRIGHT);
if((_d124&_d59)==0)autoGlideChordLatched=false;
if(!autoGlideChordLatched&&(_d124&_d59)==_d59){
autoGlideChordLatched=true;_d63=!_d63;_L("KART autoglide="+_d63);
_T(90,_d63?"Auto glider: ON\n":"Auto glider: OFF\n");
}
uint64 _d162=uint64(ZL|ZR|DDOWN);
if((_d124&_d162)==0)offroadChordLatched=false;
if(!offroadChordLatched&&(_d124&_d162)==_d162){
offroadChordLatched=true;_d164=!_d164;_L("KART offroad="+_d164);
_T(90,_d164?"Off-road handling: ON\n":"Off-road handling: OFF\n");
}
if(!_k3()||_d157()){_d73();return;}
if(_k25&&(_d124&uint64(ZL|ZR|DUP))!=uint64(ZL|ZR|DUP)){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d124);
_d62(_k7());
_d213(_k7());
_d106(_k7());_d122(_k7());
_d89();
_d116(_k7());
_d211();
_d74(_k7(),rx,ry);
uint64 _d86=uint64(A|B|X|Y|R|ZR|L);
if(_k19&&(_d124&uint64(L))!=0&&!_d129){_d129=true;_d204(S_HORN,CH_SHOT);}//L:horn(MK8:item button with no item)
if((_d124&uint64(L))==0)_d129=false;
if(_k19){
_d169=true;_d166=_d124&~_d86;
if(_d61||gliding){_d167=0;outLY=0;}//in the air the vanilla stick tilts the contraption;on the ground the game
if((_d124&uint64(X))!=0){_d166|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d124&uint64(X))==0)exitLatch=false;
else{_d169=true;_d166=_d124&~uint64(X);}//do not let the _d124 X make Link jump
}
}
void _d239(){
if(_d169)input(1,_d166,_d167,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d170){while(true){_k5(_d170);_d239();}}
ptr_t tp=0;
void _d87(uint64 k,int x,int y,int rx,int ry=0){
_d194=true;_d195=k;_d196=x;simLY=y;simRX=rx;simRY=ry;_k5(tp);
if(_d169)input(1,_d166,_d167,outLY,outRX,outRY);else input(1,k,x,y,rx,ry);
}
void _d133(uint n){for(uint f=0;f<n;f++)_d87(0,0,0,0);}
void _d226(uint64 k,int x=0,int y=0){for(uint f=0;f<3;f++)_d87(k,x,y,0);_d133(12);}
void _d175(uint i,uint _d187,uint _d79,const string&in _d160){
ActorWatcher::clearSlot(3);
_d226(uint64(PLUS));_d133(50);
for(uint t=0;t<10;t++)_d226(uint64(R));
for(uint t=0;t<2;t++){_d226(uint64(L));_d133(15);}
for(uint t=0;t<4;t++)_d226(uint64(DUP));
for(uint t=0;t<6;t++)_d226(uint64(DLEFT));
for(uint t=0;t<_d187;t++)_d226(uint64(DDOWN));
for(uint t=0;t<_d79;t++)_d226(uint64(DRIGHT));
_d133(20);_L("PLC sel"+i+" "+_d160);_d133(10);
ActorWatcher::assignSlotAwaitSpawn(3,"");
_d226(uint64(A));_d133(20);_d226(uint64(A));_d133(30);
_d226(uint64(B));_d133(50);_d226(uint64(B));_d133(30);
for(uint f=0;f<240;f++){
_d133(1);ActorBase@c=_ag(3);
if(c!is null){string nm=c.getName();if(nm.findFirst("SpObj_ControlStick_A_0")==0)break;_L("PLC skip "+nm);ActorWatcher::clearSlot(3);ActorWatcher::assignSlotAwaitSpawn(3,"");}
}
float x0=0,z0=0,y0=0;bool _d191=false;
for(uint s=0;s<12;s++){
_d133(30);ActorBase@w=_ag(3);
if(w is null){_L("PLC pos"+i+" t="+s+" none");continue;}
if(!_d191){_d191=true;x0=w.pos_x;y0=w.pos_y;z0=w.pos_z;}
float dx=w.pos_x-x0,dz=w.pos_z-z0;
_L("PLC pos"+i+" t="+s+" "+w.getName()+" "+w.pos_x+","+w.pos_y+","+w.pos_z+" moved="+sqrt(dx*dx+dz*dz)+" up="+w.rot.a4);
}
_L("PLC done"+i+" created="+_d191);
}
void main(){
_k14();devChords=true;tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
Player.setPos(-146,127.8,-58.5);input(90,0);for(uint w=0;w<200&&!(_k3()&&abs(Player.pos_x+146)<20);w++)input(10,0);input(60,0);if(!_k3())return;
for(uint c=0;c<4;c++){
Player.setRot(0,0,-1,0,1,0,1,0,0);input(2,0);Player.setPos(-154.4f,Player.pos_y+0.3f,-54.0f-3.0f*c);input(30,0);
for(uint f=0;f<30;f++)_d87(f%10<5?uint64(A):0,0,0,0);
_d133(90);_d226(uint64(A));_d133(50);_d226(uint64(A));_d133(30);
}
_L("PLC chests");
for(uint i=0;i<4;i++){
Player.setRot(0,0,1,0,1,0,-1,0,0);input(2,0);Player.setPos(-138.0f+0.0f*i,Player.pos_y+0.3f,-48.0f-7.0f*i);input(40,0);
_d175(i,(i==0?0:i==1?1:i==2?1:i==3?0:0),(i==0?4:i==1?1:i==2?0:i==3?3:0),"kart");
}
_L("PLC finished");_d194=false;input(1,0);_k11(tp);
}
