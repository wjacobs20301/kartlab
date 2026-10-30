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
bool _k20=false;float _d165=0,_w15=0;
float _d213=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d117=false;
const float _d34=7.775f;//[table]PRSL ground top speed,0 coins
const float _d26=0.011f;//[table]PRAC strength(G)
const float _d25=0.09f;//[table]PRAC limiter(M)
const float _d35=0.0118f;//[table]PRTL _d212,rad per MK frame
const float _d31=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d29=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d36=0.75f;//[table]PRON road traction
const float _d39=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d38=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d84)
const uint _d50=153;//[chosen]ultra _d142(not in the table):SMT+(SMT-MT)
const float _d8=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d37=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d33=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d28=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d30=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d32=0.993f;//[chosen]decay above _d218(after a boost)
const float _d27=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d19=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d10=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d214 0.001
const float _d11=0.8f;//[native]drift _d212 _d211 _w12,approached at 10%/frame,_d214<=0.07
const float _d7=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d130>=0.71 else 2
const float _d22=4.2f;//[chosen]drift _d121,m/s upward(~0.4 m,visible from the chase camera)
const int _d48=15;//[chosen]0.5 s
int _d223=0,trickRollDir=1;
const int _d3=24;const float _d2=5.0f;bool _d59=true,autoGlideBlocked=false,autoGlideChordLatched=true;
void _d210(float _d212){_d223=_d48;trickRollDir=_d212<-0.3f?-1:1;}//stick left spins the other way
const float _d1=0.3f,AIR_GAP=0.7f;const int _d49=8,TRICK_FRAMES=31;//trick:also R up to 6 _d84 before take-off
const float _d17=0.95f;//[measured]TOTK pulls the kart down~0.95 m/s per frame;added back so the glide _d188 settles at _d218
const float _d18=8.225f,GLIDE_SINK=1.6f,GLIDE_DIVE=4.5f,GLIDE_FLOAT=0.6f,GLIDE_STEER=0.6f,GLIDE_MIN_HEIGHT=2.5f;
const float _d0=9.0f,GLIDE_SIDE_DRAG=0.08f,AIR_SIDE_DRAG=0.01f;//[chosen]per half-frame _d214
const float _d16=0.55f,GLIDE_PITCH=0.35f,GLIDE_TILT_GAIN=4.0f,GLIDE_MAX_LEAN=0.65f;//[chosen]~29 deg _d60,~19 deg nose-down,~33 deg combined max
bool _d57=false,trickDone=false,gliding=false,gliderLatch=true;int _d56=0,groundFrames=0,trickWindow=0,rPressAge=99;
const bool _d40=false;
const float _d41=0.7f,OFFROAD_HEAVY=0.5f;//[table]PROF
bool _d158=_d40,offroadChordLatched=true;
float _d153=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d77=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d122=false,gasLatch=true,idleHold=false;
bool _d151(){return pause::isPauseRequest("GamePause")||pause::isPauseRequest("PreGamePause")||pause::isPauseRequest("PostGamePause")||pause::isPauseTarget("Custom_PhysicsUpdateWorld");}
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d120=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d120==0)return 0;
uint op=_pu(_d120);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d75=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d75-=0x04000000;
ptr_t _d218=ptr_t(int64(_d120)+_d75*4);
if(_pu(_d218)!=0xf0001382||_pu(_d218+4)!=0xa9be7bfd)return 0;
ptr_t _d61=_d218-0x65b80;if((_d61&0xfff)!=0)return 0;return _d61+0x3d90b8;
}
void _k13(){_d101=0;_d102=false;ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d179();_k19=false;_k20=false;_d165=0;_w15=0;_d117=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d211=_pu(_k16+0x24);if(_d211<2||_d211>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d124,uint _k27){
if(_d124 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d124);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d211=_pu(p+0x24);
return _d211>=2&&_d211<=6;
}
bool _k0(ActorBase@_d124,uint _k27){
if(Player is null||!_k1(_d124,_k27))return false;
ptr_t _d52=_pa(_d124),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d74=_pu(_d52+0x220);ptr_t _d143=_pq(_d52+0x228);
if(_d74<=129||_d74>512||!_k2(_d143))return false;
ptr_t _d73=_pq(_d143+0x408);
if(!_k2(_d73))return false;
uint _d183=_pu(_d73+0x20);ptr_t _k29=_pq(_d73+0x28);
if(_d183!=1||!_k2(_k29))return false;
ptr_t _d181=_pq(_k29);
if(!_k2(_d181))return false;
uint _d182=_pu(_d181+0x10),flags=_pu(_d181+0x18);
float _k33=_pf(_d181+0x74);
if(_d182!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d181+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d124,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d165=a.pos_x;_w15=a.pos_z;return;}
float dx=_d165-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d165=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
int _d138=0,spawnedType=0;bool _d133=true;
string _d132(int t){return t==1?"SpObj_ControlStick_A_02":t==2?"SpObj_ControlStick_A_03":t==3?"SpObj_ControlStick_A_04":"SpObj_ControlStick_A_01";}
string _d135(int t){return t==1?"Pipe Frame":t==2?"B Dasher":t==3?"Standard Bike":"Standard Kart";}
const int _d23=4;bool _d131(int t){return t==3;}
float _d136(int t){return t==1?1.0f:t==2?1.18f:t==3?1.275f:1.0f;}
float _d137(int t){return t==1?1.2f:t==2?1.42f:t==3?1.275f:1.3f;}
void _k8(){
if(!_k3())return;
ActorBase@_d159=_k7();
if(_k15(_d159)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d142=sqrt(fx*fx+fz*fz);if(_d142<0.1f)return;fx/=_d142;fz/=_d142;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d159!is null&&spawnedType!=_d138){_k13();@_d159=null;}//a different kart was chosen:spawn it(the _d159 one stays)
if(_d159!is null){_k10(_d159);_d159.setPos(x,y,z);@_d159=null;_d165=0;_w15=0;_d117=false;}
else{_k13();actor::createAndWatch(2,_d132(_d138),x,y,z);spawnedType=_d138;sleep(60);}//let creation get past its first _d84 before touching the _d52
for(uint f=0;f<600&&_k3();f++){//up to 20 s:a first load of a kart pack can take a while
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);if(!_d103(_k16)){@a=null;sleep(1);continue;}_k17=_pu(_k16+0x10);
ptr_t ct=_pq(_k16+0x228);bool _d167=_d103(ct)&&_d103(_pq(ct+0x50))&&_d103(_pq(_pq(ct+0x50)+0x20));
if(_d167&&a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d165=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d226(ActorBase@a){
ptr_t _d143=_pq(_pa(a)+0x228);if(!_k2(_d143))return 0;
ptr_t mc=_pq(_d143+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
float lf=_pf(b+120),rf=_pf(b+216),lb=_pf(b+312),rb=_pf(b+408);
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(lf+rf)>0.002f||abs(lb+rb)>0.002f)return 0;
if(_d131(spawnedType)){if(abs(lf)>0.01f||abs(lb)>0.01f)return 0;}//bike:both sockets of an axle on the centre line
else if(lf<0.5f||lf>1.2f||lb<0.5f||lb>1.2f)return 0;
return b;
}
void _d227(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
const float _d47=0.3927f;//2*pi/16 tread _d62
float _d224(float _d214){
float m=abs(_d214),half=_d47*0.5f;
if(m<=half*0.9f)return _d214;
float _d62=floor((m-half)/_d47);if(_d62>3)_d62=3;
float v=(_d62+0.5f)*_d47;return _d214<0?-v:v;
}
void _d58(ActorBase@a){
if(a is null){_d117=false;return;}
Matrix33f r=a.rot;float _d142=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d117&&_d142>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d142;}
_w4=x;_w5=z;_d117=true;
_w2+=_d224(ds/(0.28328f*_d136(spawnedType)));_w3+=_d224(ds/(0.28328f*_d137(spawnedType)));//tyre radius x body tyre scale
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d213*0.45f-_w1)*0.25f;
ptr_t b=_d226(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d227(b+72,sf,cf,sd,cd);_d227(b+168,sf,cf,sd,cd);
_d227(b+264,sr,cr,0,1);_d227(b+360,sr,cr,0,1);
}
void _d179(){_d223=0;_d57=false;trickDone=false;gliding=false;_d56=0;groundFrames=0;trickWindow=0;_d153=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d77=0;driftTier=0;boostLeft=0;hopWindow=0;_d122=false;gasLatch=true;idleHold=false;}
int _d112=-1;float _d106=99;//updated by _d109(ray cast under the kart)
float _d219(){
if(!_d158||_d106>=0.8f)return 1;
int m=_d112;
if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;//HeavySand,HeavySnow,Bog,Tar,Water,ContaminatedWater
if(m==1||m==2||m==3||m==5)return _d41;//Soil,Grass,Sand,Snow
return 1;
}
float _d208(float v,float _d220){
if(boostLeft>0){
boostLeft--;float t=_d34*_d39;
if(v<t){float _d127=(t-v)*_d27;if(_d127>MK_BOOST_CAP)_d127=MK_BOOST_CAP;return v+_d127;}
return t;
}
if(_d220>0){
if(v<0)return v+_d28>0?0:v+_d28;//stop reversing first
float t=_d34*_d220*_d219();
if(v<t){float _d127=(t-v)*_d26;if(_d127>_d25)_d127=_d25;return v+_d127;}//[native]form
float d=v*_d32;return d<t?t:d;
}
if(_d220<0){
if(v>0)return v-_d28<0?0:v-_d28;//brake,then reverse
float t=-_d33*(-_d220);
if(v>t){float _d127=(v-t)*_d26;if(_d127>_d25)_d127=_d25;return v-_d127;}
return v;
}
if(v>0)return v-_d30<0?0:v-_d30;
return v+_d30>0?0:v+_d30;
}
void _d78(int _d221){
_L("KART drift tier="+_d221+" charge="+driftCharge);
if(_d221==1)_T(30,"Mini-Turbo\n");else if(_d221==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d118){
_d213=0;
ActorBase@a=_k7();bool _d180=_k15(a);
if(_d180!=_k19){_L("KART mounted="+_d180);_d179();_k19=_d180;_k20=!_d180;if(a!is null){_d165=a.pos_x;_w15=a.pos_z;}}
if(!_d180||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d179();return;}
float _d212=float(ix)/32768.0f,_d220=0;
if(abs(_d212)<0.15f)_d212=0;
bool _d97=(_d118&uint64(A))!=0,brake=(_d118&uint64(B))!=0;
if(!_d97)gasLatch=false;//the A press used to get in must be released first
if(brake)_d220=-1;else if(_d97&&!gasLatch)_d220=1;
_d213=_d212;
Matrix33f r=a.rot;float _d142=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d142<0.1f||r.a4<0.4f){_k10(a);_d179();return;}
float bx=r.a2/_d142,bz=r.a8/_d142,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
_d64=fx;camFz=fz;camBraking=brake&&_d153>0.5f;
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d53=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d54=_d53/_d37;
if(_d153>0&&_d153>_d54+0.6f)_d153=_d54+0.6f<0?0:_d54+0.6f;
if(_d153<0&&_d153<_d54-0.6f)_d153=_d54-0.6f>0?0:_d54-0.6f;
bool _d175=(_d118&uint64(R|ZR))!=0,fast=_d153>_d34*0.35f;
if(_d90())_d113(a.pos_x,a.pos_y+0.2f,a.pos_z);
bool _d162=_d106<AIR_GAP;
if(_d162){groundFrames++;_d56=0;}else{_d56++;groundFrames=0;}
bool _d225=_d57;
bool _d174=_d175&&!_d122;rPressAge=_d174?0:rPressAge+1;
if(!_d57&&_d56>=2){
_d57=true;trickWindow=_d49;trickDone=false;_L("KART airborne");
if(rPressAge<=6+_d56){trickDone=true;_d210(_d212);_d195(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick (buffered)");}
}
if(_d57&&groundFrames>=1){
_d57=false;
if(gliding){gliding=false;_L("KART glider landed");}
if(trickDone){if(boostLeft<TRICK_FRAMES)boostLeft=TRICK_FRAMES;_d195(_d46,CH_SHOT);_L("KART trick boost");}
trickDone=false;_L("KART landed");
}
float _d121=0;
bool _d173=_d175&&!_d122;
if(_d57){
if(trickWindow>0){trickWindow--;if(_d173&&!trickDone){trickDone=true;_d210(_d212);_d195(S_TRICK,CH_SHOT);_T(30,"Trick!\n");_L("KART trick");}}
}else if(_d173){_d121=_d22;hopWindow=24;_d195(S_HOP,CH_SHOT);}//MK8 hops at any speed
_d122=_d175;
bool _d228=(_d118&uint64(Y))!=0;
if(!_d228)gliderLatch=false;
if(_d228&&!gliderLatch){
gliderLatch=true;
if(gliding){gliding=false;autoGlideBlocked=true;_L("KART glider folded");}
else if(_d57&&_d106>=GLIDE_MIN_HEIGHT){gliding=true;_d195(S_GOPEN,CH_SHOT);_d77=0;driftCharge=0;driftTier=0;_T(30,"Glider!\n");_L("KART glider open");}
}
if(!_d57)autoGlideBlocked=false;
if(_d59&&_d57&&!gliding&&!autoGlideBlocked&&_d223==0&&_d56>=_d3&&v.y<-_d2&&_d106>=GLIDE_MIN_HEIGHT){
gliding=true;autoGlideBlocked=true;_d195(S_GOPEN,CH_SHOT);_d77=0;driftCharge=0;driftTier=0;_L("KART glider auto");
}
if(_d77==0&&!_d57&&_d175&&hopWindow>0&&abs(_d212)>0.3f){_d77=_d212>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d77);}
if(_d77!=0&&(!_d175||!fast)){
int _d84=driftTier==3?int(_d50):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d38):0;
if(_d84>0&&_d175==false){boostLeft=_d84;_d195(driftTier==3?S_ULTRA:_d46,CH_SHOT);_L("KART boost tier="+driftTier+" frames="+_d84);}
_d77=0;driftCharge=0;driftTier=0;
}
if(!_d57&&_d220==0&&boostLeft==0&&_d77==0&&_d121==0&&abs(_d153)<_d30){
_d153=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d165=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d229=0,oldOff=bodyOff;
for(int _d214=0;_d214<2;_d214++){
if(hopWindow>0)hopWindow--;
if(gliding){float t=_d18*(iy>16000?1.06f:1.0f);_d153+=(t-_d153)*0.02f;}
else if(!_d57||boostLeft>0)_d153=_d208(_d153,_d220);
float _d63=0;
if(gliding){
driftTrack=0;_d229+=_d212*_d35*GLIDE_STEER;
}else if(_d77!=0){
float _d130=_d212*_d77;if(_d130>1)_d130=1;if(_d130<-1)_d130=-1;
float _d222=_d130>=0?_d11:-_d11,dt=(_d222-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d129=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d229+=_d77*_d31*_d129*_d129*(0.75f+0.25f*_d130);
if(!_d57)driftCharge+=_d130>=CHARGE_INWARD?_d7:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d221=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d8?1:0;
if(_d221>driftTier){driftTier=_d221;_d78(_d221);}
_d63=_d77*_d10;
}else{
driftTrack=0;
float _d206=abs(_d153)/(_d34*0.25f);if(_d206>1)_d206=1;
_d229+=_d212*_d35*_d206*(_d153<0?-1.0f:1.0f)*(_d57?_d1:1.0f);
}
if(_d223>0){bodyOff+=6.2832f/float(_d48*2)*float(trickRollDir);}
else{
float _d96=_d63-bodyOff,ds=_d96*0.07f;
if(abs(ds)<0.001f)ds=abs(_d96)<0.001f?_d96:(_d96>0?0.001f:-0.001f);
bodyOff+=ds;
}
if(!_d57)lateral*=1-_d19*_d36;
else lateral*=gliding?1-GLIDE_SIDE_DRAG:1-AIR_SIDE_DRAG;
}
if(_d223>0){_d223--;if(_d223==0||!_d57){_d223=0;while(bodyOff>3.1416f)bodyOff-=6.2832f;while(bodyOff<-3.1416f)bodyOff+=6.2832f;}}
_k18=_d153*_d37;
float _d207=_k18;
float vy=v.y+_d121;
if(gliding){
float _d188=iy>16000?GLIDE_DIVE:iy<-16000?GLIDE_FLOAT:GLIDE_SINK;//stick forward dives,back floats
vy+=(-_d188-vy)*0.3f+_d17;//ease into the glide descent(gravity compensated)
}
if(gliding&&vy<-_d0)vy=-_d0;//glider only(user:free fall must stay normal speed)
b.setVel(fx*_d207+lx*lateral,vy,fz*_d207+lz*lateral);
float tx=0,ty=1,tz=0,gain=2.0f;
if(gliding){
float _d168=float(iy)/32768.0f;if(_d168>1)_d168=1;if(_d168<-1)_d168=-1;
float _d60=_d212*_d16,nose=_d168*GLIDE_PITCH;//stick right:right side down;stick forward:nose down
tx=-lx*_d60+fx*nose;tz=-lz*_d60+fz*nose;
float _d119=sqrt(tx*tx+tz*tz);if(_d119>GLIDE_MAX_LEAN){tx*=GLIDE_MAX_LEAN/_d119;tz*=GLIDE_MAX_LEAN/_d119;}
ty=1;float tl=sqrt(tx*tx+ty*ty+tz*tz);tx/=tl;ty/=tl;tz/=tl;gain=GLIDE_TILT_GAIN;
}
float ux=r.a1,uy=r.a4,uz=r.a7;
float wx=(uy*tz-uz*ty)*gain,wz=(ux*ty-uy*tx)*gain;//world axes(a body-axis version flipped the kart)
b.setAngularVel(wx,-(_d229+bodyOff-oldOff)*30.0f,wz);
}
const uint _d14=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float _d44=0.35f,FLAME_SCALE=0.15f;//[chosen]from screenshots
ptr_t _d87=0,fxSys=0,fxScr=0;int _d91=-2,fxFlame=-1;
bool _d88(ptr_t p,const string&in _d154){
uint n=_d154.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=_d154[i])return false;
return ptr_deref_u8(p+n)==0;
}
int _d85(const string&in _d154){
ptr_t _d178=_pq(_pq(fxSys+0x2ee8)+8);if(_d178==0||ptr_deref_u8(_d178+0x571)==0)return-1;//static effects=resource 1
int n=_ps(_d178+0x558);ptr_t _d184=_pq(_d178+0x430);
for(int i=0;i<n;i++)if(_d88(_pq(_d184+0x28*i)+0x10,_d154))return i;
return-1;
}
bool _d90(){
if(_d91>=0)return true;
if(_d91==-1)return false;//looked once and failed:stay off
_d91=-1;
ptr_t _d120=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d120==0)return false;
uint op=_pu(_d120);int64 _d75=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d75-=0x04000000;
ptr_t _d218=ptr_t(int64(_d120)+_d75*4),_d61=_d218-0x65b80;
if((_d61&0xfff)!=0||_pu(_d218)!=0xf0001382)return false;
fxScr=_d61+FX_SCRATCH;_d87=sys::mainOffset();
ptr_t _d128=_pq(_pq(_d87+_d14));if(_d128==0)return false;
fxSys=_pq(_d128+0x11b8);if(fxSys==0)return false;
int _d203=_d85("Ply_ShockWave_Spark");fxFlame=_d85("Chm_FlameThrower_ScraBuild");//Zonai _d81 emitter jet
_L("KART fx spark="+_d203+" flame="+fxFlame);
if(_d203<0)return false;
_d91=_d203;return true;
}
ptr_t _d86(int _d190){ptr_t h=fxScr+0x10*_d190,e=_pq(h);if(e==0)return 0;return _pu(e+0x234)==_pu(h+8)?e:0;}
ptr_t _d92(int _d190,int id){
ptr_t e=_d86(_d190);if(e!=0)return e;
ptr_t h=fxScr+0x10*_d190;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d87+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*_d190,0,0,0,0,0);
return _d86(_d190);
}
void _d94(int _d190){if(fxScr==0)return;ptr_t e=_d86(_d190);if(e!=0)ptr_call(_d87+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*_d190,0);}
void _d89(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
_pw(m,r.a0);_pw(m+4,r.a1);_pw(m+8,r.a2);_pw(m+12,px);
_pw(m+16,r.a3);_pw(m+20,r.a4);_pw(m+24,r.a5);_pw(m+28,py);
_pw(m+32,r.a6);_pw(m+36,r.a7);_pw(m+40,r.a8);_pw(m+44,pz);
_pw(fxScr+0x140,s);_pw(fxScr+0x144,s);_pw(fxScr+0x148,s);
ptr_call(_d87+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
void _d95(ptr_t e,float r,float g,float b){_pw(e+0x40,r);_pw(e+0x44,g);_pw(e+0x48,b);}
void _d204(ActorBase@a){
bool _d205=a!is null&&_k19&&_d77!=0&&driftTier>0;
bool _d81=a!is null&&_k19&&boostLeft>0;
if(!_d205&&!_d81&&fxScr==0)return;
if(!_d90()){return;}
if(!_d205)_d94(0);
if(!_d81||fxFlame<0)_d94(1);
if(_d205){
ptr_t e=_d92(0,_d91);
if(e!=0){
if(driftTier==1)_d95(e,0.25f,0.8f,6.0f);else if(driftTier==2)_d95(e,1.0f,1.0f,1.0f);else _d95(e,2.2f,0.4f,6.0f);
ptr_t b=_d226(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(_pf(b+312));wy=_pf(b+28)+_pf(b+316)-0.3683f;wz=_pf(b+32)+_pf(b+320);}
_d89(e,a,wx,wy,wz,_d44);_d89(e,a,-wx,wy,wz,_d44);
}
}
if(_d81&&fxFlame>=0){ptr_t e=_d92(1,fxFlame);if(e!=0){_d89(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);_d89(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
const uint _d13=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int _d114=-1,groundTick=0;
int _d99=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;//effect ids per class,looked up once(no arrays in this runtime)
bool _d113(float x,float y,float z){
ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d87+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);//flags:all false
_pw(v+4,2.0f);ptr_write_u64(q+0x38,v+4);//ray _d142(m)
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d87+_d13,q,0,0,0,0,0,0,0,0,0,0);
if(ptr_deref_u8(v+0x10)==0){_d112=-1;_d106=99;return false;}
_d112=_ps(v+0x40);_d106=_pf(v+0x14);return true;
}
int _d105(int m){
if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return-1;return 6;
}
string _d108="";//diagnostics only:overrides the grass effect _d154
string _d107(int c){
if(c==0&&_d108!="")return _d108;
if(c==0)return"ReFX_Grass_L";if(c==1||c==2)return"ReFX_Sand_L";if(c==3)return"ReFX_Snow_L";
if(c==4)return"Water_Splash01_Move";if(c==5)return"RctFld_Mud_Splash_S";return"Ply_SlipSmoke_Stone";
}
int _d110(int c){
if(c==0){if(_d99==-2)_d99=_d85(_d107(0));return _d99;}if(c==1){if(gid1==-2)gid1=_d85(_d107(1));return gid1;}
if(c==2){if(gid2==-2)gid2=_d85(_d107(2));return gid2;}if(c==3){if(gid3==-2)gid3=_d85(_d107(3));return gid3;}
if(c==4){if(gid4==-2)gid4=_d85(_d107(4));return gid4;}if(c==5){if(gid5==-2)gid5=_d85(_d107(5));return gid5;}
if(gid6==-2)gid6=_d85(_d107(6));return gid6;
}
const float _d21=1.2f,GROUND_MIN_SPEED=3.0f;//[chosen]
const int _d20=6;//[chosen]_d84 between bursts:TOTK's ground effects are one-shot(per footstep/hoof)
int _d104=0,groundBurstSlot=0;
void _d115(){if(fxScr==0)return;for(int k=3;k<7;k++)_d94(k);}
ptr_t _d93(int _d190,int id,ptr_t _d172){
ptr_t h=fxScr+0x10*_d190;_d94(_d190);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d87+FX_CREATE,fxSys,h,id,1,0,_d172,0,0,0,0,0);
return _d86(_d190);
}
void _d109(ActorBase@a){
bool _d51=a!is null&&_k19&&_d90();
if(!_d51){_d115();_d114=-1;return;}
int c=_d106<0.8f?_d105(_d112):-1;
bool _d157=c>=0&&c<6,show=c>=0&&abs(_k18)>GROUND_MIN_SPEED&&(_d157||_d77!=0);
_d114=show?c:-1;
if(!show){_d104=0;return;}
if(_d104-->0)return;
_d104=_d20;
int id=_d110(c);if(id<0)return;
int _d190=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
ptr_t e=_d93(_d190,id,fxScr+0x5000);if(e==0)return;
float wx=0.78f,wz=-0.75f;ptr_t b=_d226(a);if(b!=0){wx=abs(_pf(b+312));wz=_pf(b+32)+_pf(b+320);}
_d89(e,a,wx,0,wz,_d21);_d89(e,a,-wx,0,wz,_d21);
}
const float _d15=-0.15f,GLIDER_Z=-0.45f;//[chosen]attach point in kart space(glider frame _d61)
float _d101=0;bool _d102=false;
ptr_t _d126=0,hostSklAt=0;
ptr_t _d125(ActorBase@a){
ptr_t _d143=_pq(_pa(a)+0x228);if(!_k2(_d143))return 0;
ptr_t mc=_pq(_d143+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
if(m==_d126&&hostSklAt!=0)return hostSklAt;
_d126=m;hostSklAt=0;_d102=false;//new kart(model instances are pooled:a reused one can keep an open glider)
for(uint o=0;o<0x4000;o+=4){
ptr_t r=m+o;
if(abs(_pf(r+52)-0.3766f)<0.003f&&abs(_pf(r+48))<0.003f&&abs(_pf(r+56))<0.003f
&&abs(_pf(r+96+52)-0.5966f)<0.003f&&abs(_pf(r+96+56)-0.4928f)<0.003f){hostSklAt=r;_L("KART host Skl_Root record at +"+o);break;}
}
return hostSklAt;
}
void _d100(ActorBase@a){
float _d218=(a!is null&&_k19&&gliding)?1:0;
if(_d218==0&&_d101==0&&_d102)return;
if(a is null)return;
ptr_t _d189=_d125(a);if(_d189==0)return;
if(_d101<_d218){_d101+=0.17f;if(_d101>_d218)_d101=_d218;}
else if(_d101>_d218){_d101-=0.2f;if(_d101<_d218)_d101=_d218;}
ptr_t r=_d189-192;float sc=_d101;//Control=bone 1,two records before Skl_Root(bone 3)
_pw(r,sc);_pw(r+4,0);_pw(r+8,0);
_pw(r+16,0);_pw(r+20,sc);_pw(r+24,0);
_pw(r+32,0);_pw(r+36,0);_pw(r+40,sc);
_pw(r+48,0);_pw(r+52,_d15);_pw(r+56,GLIDER_Z);
_d102=true;
}
const uint _d12=0x1085b5c;
bool _d83=false;
bool _d103(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d169(){
if(Player is null)return 0;ptr_t p=_pq(_pa(Player)+0x228);if(!_d103(p))return 0;
p=_pq(p+0x50);if(!_d103(p))return 0;p=_pq(p+0x20);return _d103(p)?p:0;
}
void _d82(){
if(!_k19&&!_d83)return;
ptr_t _d166=_d169();if(_d166==0)return;
ptr_call(sys::mainOffset()+_d12,_d166,_k19?0:1,0,0,0,0,0,0,0,0,0);
_d83=_k19;
}
const uint _d42=0x809ee0,SND_FADE=0xb226a4,PROP_SET=0x11acb98;
const int _d9=0,CH_SIZZLE=1,CH_DRIFT=2,CH_RUN=3,CH_SLIP=4,CH_FLUTTER=5,CH_SHOT=6;
const float _d43=1.0f/14.0f;//[chosen]top speed(14 m/s)=1=top of curve 213
const int _d45=1,S_DASH=2,S_IDLE=3,S_SIZZLE=4,S_DRIFT=7,S_FLUTTER=8,S_RUN=10,S_SLIP=20,S_LANDS=30;
const int _d46=40,S_ULTRA=41,S_HOP=42,S_LAND=43,S_TRICK=44,S_GOPEN=45,S_GCLOSE=46,S_HORN=47;
int _d193=0;int _d70=0,chKey1=0,chKey2=0,chKey3=0,chKey4=0,chKey5=0;
string _d216(int s){return s==0?"Grass":s==1?"Dirt":s==2?"Sand":s==3?"Snow":s==4?"Water":s==5?"Stone":"Wood";}
string _d140(int id){
if(id==_d45)return"Kart_Engine";if(id==S_DASH)return"Kart_EngineDash";if(id==S_IDLE)return"Kart_Idle";
if(id>=S_SIZZLE&&id<S_SIZZLE+3)return"Kart_Sizzle"+(id-S_SIZZLE+1);if(id==S_DRIFT)return"Kart_DriftSteer";
if(id==S_FLUTTER)return"Kart_GliderFlutter";if(id>=S_RUN&&id<S_RUN+7)return"Kart_Run_"+_d216(id-S_RUN);
if(id>=S_SLIP&&id<S_SLIP+7)return"Kart_Slip_"+_d216(id-S_SLIP);if(id>=S_LANDS&&id<S_LANDS+7)return"Kart_Land_"+_d216(id-S_LANDS);
if(id==_d46)return"Kart_MiniTurbo";if(id==S_ULTRA)return"Kart_UltraTurbo";if(id==S_HOP)return"Kart_Hop";if(id==S_LAND)return"Kart_Land";
if(id==S_TRICK)return"Kart_Trick";if(id==S_HORN)return"Kart_Horn";if(id==S_GOPEN)return"Kart_GliderOpen";if(id==S_GCLOSE)return"Kart_GliderClose";return"";
}
ptr_t _d200=0;int _d196=-1;bool _d201=false;
ptr_t _d198(){
ActorBase@a=_k7();if(a is null||!_d90())return 0;
ptr_t x=_pq(_pa(a)+0x228);if(!_d103(x))return 0;
x=_pq(x+0x68);if(!_d103(x))return 0;
ptr_t u=_pq(x+0x78);return _d103(u)?u:0;
}
void _d195(int id,int ch){
ptr_t u=_d198();if(u==0||id<=0)return;string _d139=_d140(id);
ptr_t k=fxScr+0x7800,h=fxScr+0x7880+8*ch;uint n=_d139.length();
for(uint w=0;w<4;w++){uint64 v=0;for(uint i=0;i<8;i++){uint c=w*8+i;if(c<n)v|=uint64(_d139[c])<<(8*i);}ptr_write_u64(k+8*w,v);}
ptr_write_u64(h,0xffff00ff);
ptr_call(_d87+_d42,u,k,h,0,0,0,0,0,0,0,0);
if(_d193<80){_d193++;_L("KART snd "+_d139+" h="+_pq(h));}
}
void _d191(int ch){if(fxScr==0)return;ptr_t h=fxScr+0x7880+8*ch;if(_pq(h)!=0xffff00ff)ptr_call(_d87+SND_FADE,h,0xffffffff,0,0,0,0,0,0,0,0,0);ptr_write_u64(h,0xffff00ff);}
int _d69(int ch){return ch==0?_d70:ch==1?chKey1:ch==2?chKey2:ch==3?chKey3:ch==4?chKey4:chKey5;}
void _d71(int ch,int k){if(ch==0)_d70=k;else if(ch==1)chKey1=k;else if(ch==2)chKey2=k;else if(ch==3)chKey3=k;else if(ch==4)chKey4=k;else chKey5=k;}
void _d194(int ch,int _d139){
if(_d69(ch)==_d139)return;
if(_d69(ch)!=0)_d191(ch);
if(_d139!=0)_d195(_d139,ch);
_d71(ch,_d139);
}
bool _d171(ptr_t x){
if(!_d103(x))return false;uint n=_pu(x+0x110);if(n==0||n>16)return false;
ptr_t _d155=_pq(x+0x118);if(!_d103(_d155))return false;
for(uint i=0;i<n;i++){ptr_t s=_pq(_d155+8*i);if(_d103(s)&&_d88(s,"ControlStick_StickSpeedXY")){_d196=int(i);return true;}}
return false;
}
void _d192(){
_d201=true;_d200=0;_d196=-1;
ActorBase@a=_k7();if(a is null)return;
ptr_t p=_pq(_pa(a)+0x228);if(!_d103(p))return;
p=_pq(p);if(!_d103(p))return;
p=_pq(p+0x10);if(!_d103(p))return;
if(_d171(p))_d200=p;
_L("KART snd prop X="+(_d200!=0)+" idx="+_d196+" n="+_pu(p+0x110));
}
void _d197(float ms){
if(_d200==0||_d196<0)return;
ptr_t f=fxScr+0x7a00;
_pw(f,abs(ms)*_d43);
ptr_call(_d87+PROP_SET,_d200,_d196,f,0,0,0,0,0,0,0,0);
}
int _d141=-2,lastSurface=-1;
bool _d149(int m,const string&in w){
ptr_t t=_pq(_d87+0x4637298);if(t==0||m<0||m>=54)return false;ptr_t s=_pq(t+0x250+8*m);if(!_d103(s))return false;
uint n=w.length();for(uint i=0;i<28;i++){if(ptr_deref_u8(s+i)==0)return false;bool ok=true;for(uint k=0;k<n&&ok;k++)if(ptr_deref_u8(s+i+k)!=w[k])ok=false;if(ok)return true;}
return false;
}
int _d217(){
if(_d112==_d141)return lastSurface;
_d141=_d112;int c=_d105(_d112);
lastSurface=c<0?-1:c==0?0:c==1?1:c==2?2:c==3?3:c==4?4:c==5?1:(_d149(_d112,"Wood")?6:5);
return lastSurface;
}
bool _d199=false,sndWasGlide=false;
void _d202(){
if(!_k19){
if(_d70!=0||chKey1!=0||chKey2!=0||chKey3!=0||chKey4!=0||chKey5!=0){for(int c=0;c<6;c++)_d194(c,0);}
_d201=false;_d199=false;sndWasGlide=false;return;
}
if(!_d201)_d192();
float sp=abs(_k18);_d197(sp);
_d194(_d9,gliding?0:boostLeft>0?S_DASH:sp<0.6f?S_IDLE:_d45);
_d194(CH_SIZZLE,(_d77!=0&&driftTier>0&&!gliding)?S_SIZZLE+driftTier-1:0);
int _d215=(_d57||gliding)?-1:_d217();
_d194(CH_DRIFT,(_d77!=0&&!_d57&&!gliding)?S_DRIFT:0);
_d194(CH_RUN,(_d215>=0&&sp>1.0f&&_d77==0)?S_RUN+_d215:0);
_d194(CH_SLIP,(_d215>=0&&_d77!=0)?S_SLIP+_d215:0);
_d194(CH_FLUTTER,gliding?S_FLUTTER:0);
if(sndWasGlide&&!gliding)_d195(S_GCLOSE,CH_SHOT);
if(_d199&&!_d57){_d195(S_LAND,CH_SHOT);int s2=_d217();if(s2>=0)_d195(S_LANDS+s2,CH_SHOT+1);}
_d199=_d57;sndWasGlide=gliding;
}
const bool _d24=true;
const float _d4=6.2f,CAM_HEIGHT=2.4f,CAM_LOOK_AHEAD=1.6f,CAM_LOOK_UP=1.2f,CAM_DRIFT_SWING=0.16f;
const float _d6=3.0f,CAM_LEAD=0.07f;//[chosen]seconds of fall to lead
const float _d5=7.6f,CAM_GLIDE_HEIGHT=4.4f,CAM_BOOST_BACK=0.8f,CAM_KICK=0.7f,CAM_BRAKE_IN=0.5f;
bool _d152=_d24,mkCamChordLatched=true,camFrozen=false,camInit=false,camBraking=false;
float _d64=0,camFz=1,camHx=0,camHz=1,camDist=_d4,camH=CAM_HEIGHT,camY=0,camKick=0,camLook=0;int _d65=0;
void _d67(){if(camFrozen){camera::toggleFreeze();camFrozen=false;}camInit=false;}
void _d68(ActorBase@a,int rx,int ry){
if(!_d152||a is null||!_k19){_d67();return;}
float sp=abs(_k18);
if(boostLeft>_d65+5)camKick=1;_d65=boostLeft;camKick*=0.88f;
float tx=_d64,tz=camFz;
if(_d77!=0){float c=cos(-_d77*CAM_DRIFT_SWING),s2=sin(-_d77*CAM_DRIFT_SWING);float nx=tx*c+tz*s2,nz=-tx*s2+tz*c;tx=nx;tz=nz;}
if(!camInit){camHx=tx;camHz=tz;camY=a.pos_y;camDist=_d4;camH=CAM_HEIGHT;}
float _d176=gliding?0.06f:_d57?0.05f:0.13f;
camHx+=(tx-camHx)*_d176;camHz+=(tz-camHz)*_d176;float hl=sqrt(camHx*camHx+camHz*camHz);if(hl<0.01f){camHx=tx;camHz=tz;hl=1;}camHx/=hl;camHz/=hl;
float _d144=float(rx)/32768.0f;if(abs(_d144)<0.2f)_d144=0;float _d145=_d144*1.8f;
if(float(ry)/32768.0f<-0.7f)_d145=3.1416f;//right stick down:_d144 behind(MK8 _d144-back)
camLook+=(_d145-camLook)*(_d145>3.0f?0.35f:0.15f);
float lc=cos(camLook),ls=sin(camLook),dx=camHx*lc+camHz*ls,dz=-camHx*ls+camHz*lc;
float _d76=gliding?_d5:_d4+sp*0.035f+(boostLeft>0?CAM_BOOST_BACK:0)-(camBraking?CAM_BRAKE_IN:0);
_d76+=camKick*CAM_KICK;
float h=gliding?CAM_GLIDE_HEIGHT:CAM_HEIGHT+sp*0.01f;
camDist+=(_d76-camDist)*(camKick>0.5f?0.3f:0.1f);camH+=(h-camH)*0.08f;
float ky=a.pos_y;if(_d57){RigidBody@cb=a.getMainRigidBody();if(cb!is null)ky+=cb.vel.y*CAM_LEAD;}
camY+=(ky-camY)*((_d57||gliding)?0.12f:0.35f);
if(camY-ky>_d6)camY=ky+_d6;if(ky-camY>_d6)camY=ky-_d6;
double px=a.pos_x-dx*camDist,py=camY+camH,pz=a.pos_z-dz*camDist;
double ax=a.pos_x+dx*CAM_LOOK_AHEAD,ay=ky+(gliding?0.4f:CAM_LOOK_UP),az=a.pos_z+dz*CAM_LOOK_AHEAD;
camera::freeze(0,1,0,px,py,pz,ax,ay,az);camFrozen=true;camInit=true;
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
_L("KART ready");
}
bool _d123=false;
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool _d163=false,exitLatch=false;uint64 _d160=0;int _d161=0,outLY=0,outRX=0,outRY=0;
bool _d185=false;uint64 _d186=0;int _d187=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d164){
uint64 _d118=_d185?_d186:_pq(_d164);
int lx=_d185?_d187:_ps(_d164+8),ly=_d185?simLY:_ps(_d164+12);
int rx=_d185?simRX:_ps(_d164+16),ry=_d185?simRY:_ps(_d164+20);
_d163=false;_d160=_d118;_d161=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
_d67();
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 _d146=uint64(ZL|ZR|DUP);
if((_d118&_d146)==0)_k24=false;
if(!_k24&&(_d118&_d146)==_d146){_k24=true;_k25=true;_L("KART spawn queued");}
uint64 _d134=uint64(ZL|ZR|X);
if((_d118&_d134)==0)_d133=false;
if(!_k19&&!_d133&&(_d118&_d134)==_d134){
_d133=true;_d138=(_d138+1)%_d23;_L("KART type="+_d138);
_T(120,"Kart: "+_d135(_d138)+" (ZL+ZR+Up to spawn)\n");
}
uint64 _d66=uint64(ZL|ZR|DLEFT);
if((_d118&_d66)==0)mkCamChordLatched=false;
if(!mkCamChordLatched&&(_d118&_d66)==_d66){
mkCamChordLatched=true;_d152=!_d152;_L("KART mkcam="+_d152);
_T(90,_d152?"Mario Kart camera: ON\n":"Mario Kart camera: OFF\n");
}
uint64 _d55=uint64(ZL|ZR|DRIGHT);
if((_d118&_d55)==0)autoGlideChordLatched=false;
if(!autoGlideChordLatched&&(_d118&_d55)==_d55){
autoGlideChordLatched=true;_d59=!_d59;_L("KART autoglide="+_d59);
_T(90,_d59?"Auto glider: ON\n":"Auto glider: OFF\n");
}
uint64 _d156=uint64(ZL|ZR|DDOWN);
if((_d118&_d156)==0)offroadChordLatched=false;
if(!offroadChordLatched&&(_d118&_d156)==_d156){
offroadChordLatched=true;_d158=!_d158;_L("KART offroad="+_d158);
_T(90,_d158?"Off-road handling: ON\n":"Off-road handling: OFF\n");
}
if(!_k3()||_d151()){_d67();return;}
if(_k25&&(_d118&_d146)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d118);
_d58(_k7());
_d204(_k7());
_d100(_k7());
_d82();
_d109(_k7());
_d202();
_d68(_k7(),rx,ry);
uint64 _d79=uint64(A|B|X|Y|R|ZR|L);
if(_k19&&(_d118&uint64(L))!=0&&!_d123){_d123=true;_d195(S_HORN,CH_SHOT);}//L:horn(MK8:item button with no item)
if((_d118&uint64(L))==0)_d123=false;
if(_k19){
_d163=true;_d160=_d118&~_d79;
if(_d57||gliding){_d161=0;outLY=0;}//in the air the vanilla stick tilts the contraption;on the ground the game
if((_d118&uint64(X))!=0){_d160|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d118&uint64(X))==0)exitLatch=false;
else{_d163=true;_d160=_d118&~uint64(X);}//do not let the _d118 X make Link jump
}
}
void _d230(){
if(_d163)input(1,_d160,_d161,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d164){while(true){_k5(_d164);_d230();}}
void _d98(uint f){
if(f%75!=0)return;uint k=f/75;
string n=k==0?"Ply_SlipSmoke_Grass_Green":k==1?"ReFX_Grass_M":k==2?"HorseStep_Grass_Tmp":k==3?"Ply_FootEffect_Grass_Green":"ReFX_Grass_L";
_d108=n;_d99=-2;_d115();_d114=-1;
_L("GRASS "+n);
}
void _d116(){ptr_t e=fxScr==0?0:_d86(3);if(e==0){_L("GSTATE none");return;}
_L("GSTATE e8="+ptr_deref_s16(e+0xe8)+" f38="+_pu(e+0x38)+" 4c="+_pf(e+0x4c)+" 5c="+_pf(e+0x5c)+" 24c="+_pf(e+0x24c)+" 250="+_pf(e+0x250)+" 254="+_pf(e+0x254)+" 25c="+_pf(e+0x25c)+" 260="+_pf(e+0x260));}
ptr_t tp=0;
void _d80(uint64 k,int x,int y,int rx,int ry=0){
_d185=true;_d186=k;_d187=x;simLY=y;simRX=rx;simRY=ry;_k5(tp);
if(_d163)input(1,_d160,_d161,outLY,outRX,outRY);else input(1,k,x,y,rx,ry);
}
string _d148(int i){if(i<0||i>=54)return"?";ptr_t t=_pq(sys::mainOffset()+0x4637298);if(t==0)return"?";ptr_t s=_pq(t+0x250+8*i);string r="";for(int k=0;k<32&&s!=0;k++){u8 c=ptr_deref_u8(s+k);if(c==0)break;r+=" ";r[r.length()-1]=c;}return r;}
bool _d170(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d111(ActorBase@a){if(a is null)return 0;ptr_t p=_pq(_pa(a)+0x228);if(!_d170(p))return 0;p=_pq(p+0x50);if(!_d170(p))return 0;
p=_pq(p+0x20);if(!_d170(p))return 0;p=_pq(p+0x10);if(!_d170(p))return 0;p=_pq(p+8);if(!_d170(p))return 0;p=_pq(p+0x20);if(!_d170(p))return 0;return p+0x20;}
string _d150(ActorBase@a){ptr_t g=_d111(a);if(g==0)return"none";int m=_ps(g+0x78);return""+m+":"+_d148(m)+" f="+ptr_deref_u8(g+0x110)+","+ptr_deref_u8(g+0x111);}
string _d72(ActorBase@a){if(a is null)return"null";string r="";ptr_t p=_pa(a);
for(uint i=0;i<6;i++){uint o=i==0?0x228:i==1?0x50:i==2?0x20:i==3?0x10:i==4?8:0x20;p=_pq(p+o);r+=" "+formatInt(int64(p),"H");if(!_d170(p))break;}return r;}
string _d177(float x,float y,float z){
if(!_d90())return"nofx";
ptr_t q=fxScr+0x5000,v=fxScr+0x5100,p1=fxScr+0x5200,p2=fxScr+0x5300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d87+0x4578958);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);
_pw(v+4,3.0f);ptr_write_u64(q+0x38,v+4);
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d87+0x20e4da4,q,0,0,0,0,0,0,0,0,0,0);
int m=_ps(v+0x40);
return"hit="+ptr_deref_u8(v+0x10)+" d="+_pf(v+0x14)+" f58="+_pf(v+0x18)+" n="+_pf(v+0x20)+","+_pf(v+0x24)+","+_pf(v+0x28)+" m="+m+":"+_d148(m)+" b="+ptr_deref_u8(v+0x44);
}
void _d147(const string&in l){ActorBase@k=_k7();
_L("MAT "+l+" player="+_d150(Player)+" rayP="+_d177(Player.pos_x,Player.pos_y+0.5f,Player.pos_z)+(k is null?"":" rayK="+_d177(k.pos_x,k.pos_y+0.2f,k.pos_z)));}
void _d209(const string&in l){_d116();ActorBase@a=_k7();_L("SPK "+l+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+_k18+" tier="+driftTier+" charge="+driftCharge+" boost="+boostLeft+" live0="+(fxScr!=0&&_d86(0)!=0)+" live1="+(fxScr!=0&&_d86(1)!=0)+" ground="+_d112+"/"+_d114+" d="+_d106+" cam="+camFrozen+" ch="+camHx+","+camHz+" f="+_d64+","+camFz+" d="+camDist+" wb="+(a!is null&&_d226(a)!=0)+" mounted="+_k15(a));}
void main(){
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
_d147("start");input(30,0);_d147("start2");
Player.setPos(-150,127.8,-62);input(90,0);for(uint w=0;w<200&&!(_k3()&&abs(Player.pos_x+150)<20);w++)input(10,0);input(60,0);if(!_k3())return;
_d147("field");
_d138=3;_k5(tp);_d80(uint64(ZL|ZR|DUP),0,0,0);
for(uint f=0;f<25;f++)_d80(0,0,0,0);
for(uint t=0;t<10&&!_k15(_k7());t++){
ActorBase@k=_k7();if(k is null){input(10,0);continue;}
Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,k.pos_y+0.3f,pz);input(20,0);
_L("SPK try mount t="+t+" kart="+k.pos_x+","+k.pos_z+" player="+Player.pos_x+","+Player.pos_z);
input(1,1);input(30,0);
}
if(!_k15(_k7())){_L("SPK mount failed");return;}
_d80(0,0,0,0);
for(uint f=0;f<60&&_k3();f++){_d80(uint64(A),0,0,0);if(f%30==0)_d209("run"+f);}
for(uint f=0;f<60&&_k3();f++)_d80(0,0,0,0);
for(uint f=0;f<70&&_k3();f++)_d80(0,0,0,32767,0);_d209("side-right");for(uint f=0;f<40;f++)_d80(0,0,0,32767,0);
for(uint f=0;f<70&&_k3();f++)_d80(0,0,0,-32767,0);_d209("side-left");for(uint f=0;f<40;f++)_d80(0,0,0,-32767,0);
for(uint f=0;f<40&&_k3();f++)_d80(0,0,0,0,0);_d209("behind");for(uint f=0;f<40;f++)_d80(0,0,0,0,0);
for(uint f=0;f<40&&_k3();f++)_d80(0,0,0,0,-32767);_d209("front");for(uint f=0;f<40;f++)_d80(0,0,0,0,-32767);
_L("SPK finished");_d185=false;input(1,0);_k11(tp);
}
