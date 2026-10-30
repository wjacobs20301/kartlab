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
bool _k20=false;float _d102=0,_w15=0;
float _d127=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d76=false;
const float _d19=7.775f;//[table]PRSL ground top speed,0 coins
const float _d11=0.011f;//[table]PRAC strength(G)
const float _d10=0.09f;//[table]PRAC limiter(M)
const float _d20=0.0118f;//[table]PRTL _d126,rad per MK frame
const float _d16=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d14=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d21=0.75f;//[table]PRON road traction
const float _d24=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d23=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d47)
const uint _d29=153;//[chosen]ultra _d86(not in the table):SMT+(SMT-MT)
const float _d1=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d22=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d18=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d13=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d15=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d17=0.993f;//[chosen]decay above _d129(after a boost)
const float _d12=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d6=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d2=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d128 0.001
const float _d3=0.8f;//[native]drift _d126 _d125 _w12,approached at 10%/frame,_d128<=0.07
const float _d0=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d85>=0.71 else 2
const float _d9=3.0f;//[chosen]drift _d79,m/s upward
const bool _d25=false;
const float _d26=0.7f,OFFROAD_HEAVY=0.5f;//[table]PROF
bool _d96=_d25,offroadChordLatched=true;
float _d92=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d42=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d80=false,gasLatch=true,idleHold=false;
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d78=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d78==0)return 0;
uint op=_pu(_d78);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d41=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d41-=0x04000000;
ptr_t _d129=ptr_t(int64(_d78)+_d41*4);
if(_pu(_d129)!=0xf0001382||_pu(_d129+4)!=0xa9be7bfd)return 0;
ptr_t _d35=_d129-0x65b80;if((_d35&0xfff)!=0)return 0;return _d35+0x3d90b8;
}
void _k13(){ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d108();_k19=false;_k20=false;_d102=0;_w15=0;_d76=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d125=_pu(_k16+0x24);if(_d125<2||_d125>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d81,uint _k27){
if(_d81 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d81);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d125=_pu(p+0x24);
return _d125>=2&&_d125<=6;
}
bool _k0(ActorBase@_d81,uint _k27){
if(Player is null||!_k1(_d81,_k27))return false;
ptr_t _d31=_pa(_d81),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d40=_pu(_d31+0x220);ptr_t _d87=_pq(_d31+0x228);
if(_d40<=129||_d40>512||!_k2(_d87))return false;
ptr_t _d39=_pq(_d87+0x408);
if(!_k2(_d39))return false;
uint _d112=_pu(_d39+0x20);ptr_t _k29=_pq(_d39+0x28);
if(_d112!=1||!_k2(_k29))return false;
ptr_t _d110=_pq(_k29);
if(!_k2(_d110))return false;
uint _d111=_pu(_d110+0x10),flags=_pu(_d110+0x18);
float _k33=_pf(_d110+0x74);
if(_d111!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d110+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d81,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d102=a.pos_x;_w15=a.pos_z;return;}
float dx=_d102-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d102=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@_d97=_k7();
if(_k15(_d97)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d86=sqrt(fx*fx+fz*fz);if(_d86<0.1f)return;fx/=_d86;fz/=_d86;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d97!is null){_k10(_d97);_d97.setPos(x,y,z);@_d97=null;_d102=0;_w15=0;_d76=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);_k17=_pu(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d102=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d135(ActorBase@a){
ptr_t _d87=_pq(_pa(a)+0x228);if(!_k2(_d87))return 0;
ptr_t mc=_pq(_d87+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(_pf(b+120)-0.728f)>0.002f||abs(_pf(b+216)+0.728f)>0.002f||abs(_pf(b+312)-0.7776f)>0.002f||abs(_pf(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _d136(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
const float _d28=0.3927f;//2*pi/16 tread _d36
float _d134(float _d128){
float m=abs(_d128),half=_d28*0.5f;
if(m<=half*0.9f)return _d128;
float _d36=floor((m-half)/_d28);if(_d36>3)_d36=3;
float v=(_d36+0.5f)*_d28;return _d128<0?-v:v;
}
void _d34(ActorBase@a){
if(a is null){_d76=false;return;}
Matrix33f r=a.rot;float _d86=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d76&&_d86>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d86;}
_w4=x;_w5=z;_d76=true;
_w2+=_d134(ds/0.28328f);_w3+=_d134(ds/0.3683f);
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d127*0.45f-_w1)*0.25f;
ptr_t b=_d135(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d136(b+72,sf,cf,sd,cd);_d136(b+168,sf,cf,sd,cd);
_d136(b+264,sr,cr,0,1);_d136(b+360,sr,cr,0,1);
}
void _d108(){_d92=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d42=0;driftTier=0;boostLeft=0;hopWindow=0;_d80=false;gasLatch=true;idleHold=false;}
int _d71=-1;float _d65=99;//updated by _d68(ray cast under the kart)
float _d130(){
if(!_d96||_d65>=0.8f)return 1;
int m=_d71;
if(m==4||m==6||m==42||m==37||m==38||m==43)return OFFROAD_HEAVY;//HeavySand,HeavySnow,Bog,Tar,Water,ContaminatedWater
if(m==1||m==2||m==3||m==5)return _d26;//Soil,Grass,Sand,Snow
return 1;
}
float _d123(float v,float _d131){
if(boostLeft>0){
boostLeft--;float t=_d19*_d24;
if(v<t){float _d82=(t-v)*_d12;if(_d82>MK_BOOST_CAP)_d82=MK_BOOST_CAP;return v+_d82;}
return t;
}
if(_d131>0){
if(v<0)return v+_d13>0?0:v+_d13;//stop reversing first
float t=_d19*_d131*_d130();
if(v<t){float _d82=(t-v)*_d11;if(_d82>_d10)_d82=_d10;return v+_d82;}//[native]form
float d=v*_d17;return d<t?t:d;
}
if(_d131<0){
if(v>0)return v-_d13<0?0:v-_d13;//brake,then reverse
float t=-_d18*(-_d131);
if(v>t){float _d82=(v-t)*_d11;if(_d82>_d10)_d82=_d10;return v-_d82;}
return v;
}
if(v>0)return v-_d15<0?0:v-_d15;
return v+_d15>0?0:v+_d15;
}
void _d43(int _d132){
_L("KART drift tier="+_d132+" charge="+driftCharge);
if(_d132==1)_T(30,"Mini-Turbo\n");else if(_d132==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d77){
_d127=0;
ActorBase@a=_k7();bool _d109=_k15(a);
if(_d109!=_k19){_L("KART mounted="+_d109);_d108();_k19=_d109;_k20=!_d109;if(a!is null){_d102=a.pos_x;_w15=a.pos_z;}}
if(!_d109||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d108();return;}
float _d126=float(ix)/32768.0f,_d131=0;
if(abs(_d126)<0.15f)_d126=0;
bool _d60=(_d77&uint64(A))!=0,brake=(_d77&uint64(B))!=0;
if(!_d60)gasLatch=false;//the A press used to get in must be released first
if(brake)_d131=-1;else if(_d60&&!gasLatch)_d131=1;
_d127=_d126;
Matrix33f r=a.rot;float _d86=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d86<0.1f||r.a4<0.4f){_k10(a);_d108();return;}
float bx=r.a2/_d86,bz=r.a8/_d86,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d32=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d33=_d32/_d22;
if(_d92>0&&_d92>_d33+0.6f)_d92=_d33+0.6f<0?0:_d33+0.6f;
if(_d92<0&&_d92<_d33-0.6f)_d92=_d33-0.6f>0?0:_d33-0.6f;
bool _d105=(_d77&uint64(R|ZR))!=0,fast=_d92>_d19*0.35f;
float _d79=0;
if(_d105&&!_d80&&fast){_d79=_d9;hopWindow=24;}
_d80=_d105;
if(_d42==0&&_d105&&hopWindow>0&&abs(_d126)>0.3f){_d42=_d126>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d42);}
if(_d42!=0&&(!_d105||!fast)){
int _d47=driftTier==3?int(_d29):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d23):0;
if(_d47>0&&_d105==false){boostLeft=_d47;_L("KART boost tier="+driftTier+" frames="+_d47);}
_d42=0;driftCharge=0;driftTier=0;
}
if(_d131==0&&boostLeft==0&&_d42==0&&_d79==0&&abs(_d92)<_d15){
_d92=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d102=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d137=0,oldOff=bodyOff;
for(int _d128=0;_d128<2;_d128++){
if(hopWindow>0)hopWindow--;
_d92=_d123(_d92,_d131);
float _d37=0;
if(_d42!=0){
float _d85=_d126*_d42;if(_d85>1)_d85=1;if(_d85<-1)_d85=-1;
float _d133=_d85>=0?_d3:-_d3,dt=(_d133-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d84=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d137+=_d42*_d16*_d84*_d84*(0.75f+0.25f*_d85);
driftCharge+=_d85>=CHARGE_INWARD?_d0:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d132=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d1?1:0;
if(_d132>driftTier){driftTier=_d132;_d43(_d132);}
_d37=_d42*_d2;
}else{
driftTrack=0;
float _d121=abs(_d92)/(_d19*0.25f);if(_d121>1)_d121=1;
_d137+=_d126*_d20*_d121*(_d92<0?-1.0f:1.0f);
}
float _d59=_d37-bodyOff,ds=_d59*0.07f;
if(abs(ds)<0.001f)ds=abs(_d59)<0.001f?_d59:(_d59>0?0.001f:-0.001f);
bodyOff+=ds;
lateral*=1-_d6*_d21;
}
_k18=_d92*_d22;
float _d122=_k18;
b.setVel(fx*_d122+lx*lateral,v.y+_d79,fz*_d122+lz*lateral);
b.setAngularVel(-r.a7*2.0f,-(_d137+bodyOff-oldOff)*30.0f,r.a1*2.0f);
}
const uint _d5=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float _d27=0.35f,FLAME_SCALE=0.15f;//[chosen]from screenshots
ptr_t _d50=0,fxSys=0,fxScr=0;int _d54=-2,fxFlame=-1;
bool _d51(ptr_t p,const string&in _d93){
uint n=_d93.length();for(uint i=0;i<n;i++)if(ptr_deref_u8(p+i)!=_d93[i])return false;
return ptr_deref_u8(p+n)==0;
}
int _d48(const string&in _d93){
ptr_t _d107=_pq(_pq(fxSys+0x2ee8)+8);if(_d107==0||ptr_deref_u8(_d107+0x571)==0)return-1;//static effects=resource 1
int n=_ps(_d107+0x558);ptr_t _d113=_pq(_d107+0x430);
for(int i=0;i<n;i++)if(_d51(_pq(_d113+0x28*i)+0x10,_d93))return i;
return-1;
}
bool _d53(){
if(_d54>=0)return true;
if(_d54==-1)return false;//looked once and failed:stay off
_d54=-1;
ptr_t _d78=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d78==0)return false;
uint op=_pu(_d78);int64 _d41=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d41-=0x04000000;
ptr_t _d129=ptr_t(int64(_d78)+_d41*4),_d35=_d129-0x65b80;
if((_d35&0xfff)!=0||_pu(_d129)!=0xf0001382)return false;
fxScr=_d35+FX_SCRATCH;_d50=sys::mainOffset();
ptr_t _d83=_pq(_pq(_d50+_d5));if(_d83==0)return false;
fxSys=_pq(_d83+0x11b8);if(fxSys==0)return false;
int _d118=_d48("Ply_ShockWave_Spark");fxFlame=_d48("Chm_FlameThrower_ScraBuild");//Zonai _d46 emitter jet
_L("KART fx spark="+_d118+" flame="+fxFlame);
if(_d118<0)return false;
_d54=_d118;return true;
}
ptr_t _d49(int _d117){ptr_t h=fxScr+0x10*_d117,e=_pq(h);if(e==0)return 0;return _pu(e+0x234)==_pu(h+8)?e:0;}
ptr_t _d55(int _d117,int id){
ptr_t e=_d49(_d117);if(e!=0)return e;
ptr_t h=fxScr+0x10*_d117;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d50+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*_d117,0,0,0,0,0);
return _d49(_d117);
}
void _d57(int _d117){if(fxScr==0)return;ptr_t e=_d49(_d117);if(e!=0)ptr_call(_d50+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*_d117,0);}
void _d52(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x100;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
_pw(m,r.a0);_pw(m+4,r.a1);_pw(m+8,r.a2);_pw(m+12,px);
_pw(m+16,r.a3);_pw(m+20,r.a4);_pw(m+24,r.a5);_pw(m+28,py);
_pw(m+32,r.a6);_pw(m+36,r.a7);_pw(m+40,r.a8);_pw(m+44,pz);
_pw(fxScr+0x140,s);_pw(fxScr+0x144,s);_pw(fxScr+0x148,s);
ptr_call(_d50+FX_PLACE,e,m,fxScr+0x140,0,0,0,0,0,0,0,0);
}
void _d58(ptr_t e,float r,float g,float b){_pw(e+0x40,r);_pw(e+0x44,g);_pw(e+0x48,b);}
void _d119(ActorBase@a){
bool _d120=a!is null&&_k19&&_d42!=0&&driftTier>0;
bool _d46=a!is null&&_k19&&boostLeft>0;
if(!_d120&&!_d46&&fxScr==0)return;
if(!_d53()){return;}
if(!_d120)_d57(0);
if(!_d46||fxFlame<0)_d57(1);
if(_d120){
ptr_t e=_d55(0,_d54);
if(e!=0){
if(driftTier==1)_d58(e,0.25f,0.8f,6.0f);else if(driftTier==2)_d58(e,1.0f,1.0f,1.0f);else _d58(e,2.2f,0.4f,6.0f);
ptr_t b=_d135(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(_pf(b+312));wy=_pf(b+28)+_pf(b+316)-0.3683f;wz=_pf(b+32)+_pf(b+320);}
_d52(e,a,wx,wy,wz,_d27);_d52(e,a,-wx,wy,wz,_d27);
}
}
if(_d46&&fxFlame>=0){ptr_t e=_d55(1,fxFlame);if(e!=0){_d52(e,a,0.25f,0.45f,-0.95f,FLAME_SCALE);_d52(e,a,-0.25f,0.45f,-0.95f,FLAME_SCALE);}}
}
const uint _d4=0x20e4da4,FX_RAY_VTABLE=0x4578958;
int _d73=-1,groundTick=0;
int _d62=-2,gid1=-2,gid2=-2,gid3=-2,gid4=-2,gid5=-2,gid6=-2;//effect ids per class,looked up once(no arrays in this runtime)
bool _d72(float x,float y,float z){
ptr_t q=fxScr+0x7000,v=fxScr+0x7100,p1=fxScr+0x7200,p2=fxScr+0x7300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d50+FX_RAY_VTABLE);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);//flags:all false
_pw(v+4,2.0f);ptr_write_u64(q+0x38,v+4);//ray _d86(m)
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d50+_d4,q,0,0,0,0,0,0,0,0,0,0);
if(ptr_deref_u8(v+0x10)==0){_d71=-1;_d65=99;return false;}
_d71=_ps(v+0x40);_d65=_pf(v+0x14);return true;
}
int _d64(int m){
if(m==2)return 0;if(m==1)return 1;if(m==3||m==4)return 2;if(m==5||m==6)return 3;
if(m==38||m==39||m==40||m==43||m==52)return 4;if(m==42||m==37)return 5;if(m<0)return-1;return 6;
}
string _d67="";//diagnostics only:overrides the grass effect _d93
string _d66(int c){
if(c==0&&_d67!="")return _d67;
if(c==0)return"ReFX_Grass_L";if(c==1||c==2)return"ReFX_Sand_L";if(c==3)return"ReFX_Snow_L";
if(c==4)return"Water_Splash01_Move";if(c==5)return"RctFld_Mud_Splash_S";return"Ply_SlipSmoke_Stone";
}
int _d69(int c){
if(c==0){if(_d62==-2)_d62=_d48(_d66(0));return _d62;}if(c==1){if(gid1==-2)gid1=_d48(_d66(1));return gid1;}
if(c==2){if(gid2==-2)gid2=_d48(_d66(2));return gid2;}if(c==3){if(gid3==-2)gid3=_d48(_d66(3));return gid3;}
if(c==4){if(gid4==-2)gid4=_d48(_d66(4));return gid4;}if(c==5){if(gid5==-2)gid5=_d48(_d66(5));return gid5;}
if(gid6==-2)gid6=_d48(_d66(6));return gid6;
}
const float _d8=1.2f,GROUND_MIN_SPEED=3.0f;//[chosen]
const int _d7=6;//[chosen]_d47 between bursts:TOTK's ground effects are one-shot(per footstep/hoof)
int _d63=0,groundBurstSlot=0;
void _d74(){if(fxScr==0)return;for(int k=3;k<7;k++)_d57(k);}
ptr_t _d56(int _d117,int id,ptr_t _d104){
ptr_t h=fxScr+0x10*_d117;_d57(_d117);ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d50+FX_CREATE,fxSys,h,id,1,0,_d104,0,0,0,0,0);
return _d49(_d117);
}
void _d68(ActorBase@a){
bool _d30=a!is null&&_k19&&_d53();
if(!_d30){_d74();_d73=-1;return;}
if(++groundTick>=3){groundTick=0;_d72(a.pos_x,a.pos_y+0.2f,a.pos_z);}
int c=_d65<0.8f?_d64(_d71):-1;
bool _d95=c>=0&&c<6,show=c>=0&&abs(_k18)>GROUND_MIN_SPEED&&(_d95||_d42!=0);
_d73=show?c:-1;
if(!show){_d63=0;return;}
if(_d63-->0)return;
_d63=_d7;
int id=_d69(c);if(id<0)return;
int _d117=3+groundBurstSlot;groundBurstSlot=(groundBurstSlot+1)%4;
ptr_t e=_d56(_d117,id,fxScr+0x5000);if(e==0)return;
float wx=0.78f,wz=-0.75f;ptr_t b=_d135(a);if(b!=0){wx=abs(_pf(b+312));wz=_pf(b+32)+_pf(b+320);}
_d52(e,a,wx,0,wz,_d8);_d52(e,a,-wx,0,wz,_d8);
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
_L("KART ready");
}
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool _d100=false,exitLatch=false;uint64 _d98=0;int _d99=0,outLY=0,outRX=0,outRY=0;
bool _d114=false;uint64 _d115=0;int _d116=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d101){
uint64 _d77=_d114?_d115:_pq(_d101);
int lx=_d114?_d116:_ps(_d101+8),ly=_d114?simLY:_ps(_d101+12);
int rx=_d114?simRX:_ps(_d101+16),ry=_d114?simRY:_ps(_d101+20);
_d100=false;_d98=_d77;_d99=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 _d88=uint64(ZL|ZR|DUP);
if((_d77&_d88)==0)_k24=false;
if(!_k24&&(_d77&_d88)==_d88){_k24=true;_k25=true;_L("KART spawn queued");}
uint64 _d94=uint64(ZL|ZR|DDOWN);
if((_d77&_d94)==0)offroadChordLatched=false;
if(!offroadChordLatched&&(_d77&_d94)==_d94){
offroadChordLatched=true;_d96=!_d96;_L("KART offroad="+_d96);
_T(90,_d96?"Off-road handling: ON\n":"Off-road handling: OFF\n");
}
if(!_k3())return;
if(_k25&&(_d77&_d88)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d77);
_d34(_k7());
_d119(_k7());
_d68(_k7());
uint64 _d44=uint64(A|B|X|R|ZR);
if(_k19){
_d100=true;_d98=_d77&~_d44;
if((_d77&uint64(X))!=0){_d98|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d77&uint64(X))==0)exitLatch=false;
else{_d100=true;_d98=_d77&~uint64(X);}//do not let the _d77 X make Link jump
}
}
void _d138(){
if(_d100)input(1,_d98,_d99,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d101){while(true){_k5(_d101);_d138();}}
void _d61(uint f){
if(f%75!=0)return;uint k=f/75;
string n=k==0?"Ply_SlipSmoke_Grass_Green":k==1?"ReFX_Grass_M":k==2?"HorseStep_Grass_Tmp":k==3?"Ply_FootEffect_Grass_Green":"ReFX_Grass_L";
_d67=n;_d62=-2;_d74();_d73=-1;
_L("GRASS "+n);
}
void _d75(){ptr_t e=fxScr==0?0:_d49(3);if(e==0){_L("GSTATE none");return;}
_L("GSTATE e8="+ptr_deref_s16(e+0xe8)+" f38="+_pu(e+0x38)+" 4c="+_pf(e+0x4c)+" 5c="+_pf(e+0x5c)+" 24c="+_pf(e+0x24c)+" 250="+_pf(e+0x250)+" 254="+_pf(e+0x254)+" 25c="+_pf(e+0x25c)+" 260="+_pf(e+0x260));}
ptr_t tp=0;
void _d45(uint64 k,int x,int y,int rx){
_d114=true;_d115=k;_d116=x;simLY=y;simRX=rx;simRY=0;_k5(tp);
if(_d100)input(1,_d98,_d99,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
string _d90(int i){if(i<0||i>=54)return"?";ptr_t t=_pq(sys::mainOffset()+0x4637298);if(t==0)return"?";ptr_t s=_pq(t+0x250+8*i);string r="";for(int k=0;k<32&&s!=0;k++){u8 c=ptr_deref_u8(s+k);if(c==0)break;r+=" ";r[r.length()-1]=c;}return r;}
bool _d103(ptr_t p){return p>0x1000000&&p<0x8000000000&&(p&7)==0;}
ptr_t _d70(ActorBase@a){if(a is null)return 0;ptr_t p=_pq(_pa(a)+0x228);if(!_d103(p))return 0;p=_pq(p+0x50);if(!_d103(p))return 0;
p=_pq(p+0x20);if(!_d103(p))return 0;p=_pq(p+0x10);if(!_d103(p))return 0;p=_pq(p+8);if(!_d103(p))return 0;p=_pq(p+0x20);if(!_d103(p))return 0;return p+0x20;}
string _d91(ActorBase@a){ptr_t g=_d70(a);if(g==0)return"none";int m=_ps(g+0x78);return""+m+":"+_d90(m)+" f="+ptr_deref_u8(g+0x110)+","+ptr_deref_u8(g+0x111);}
string _d38(ActorBase@a){if(a is null)return"null";string r="";ptr_t p=_pa(a);
for(uint i=0;i<6;i++){uint o=i==0?0x228:i==1?0x50:i==2?0x20:i==3?0x10:i==4?8:0x20;p=_pq(p+o);r+=" "+formatInt(int64(p),"H");if(!_d103(p))break;}return r;}
string _d106(float x,float y,float z){
if(!_d53())return"nofx";
ptr_t q=fxScr+0x5000,v=fxScr+0x5100,p1=fxScr+0x5200,p2=fxScr+0x5300;
for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,_pa(Player));
ptr_write_u64(q,_d50+0x4578958);ptr_write_u64(q+8,p1);
ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);
_pw(v+4,3.0f);ptr_write_u64(q+0x38,v+4);
ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
_pw(v+0x50,x);_pw(v+0x54,y);_pw(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
ptr_call(_d50+0x20e4da4,q,0,0,0,0,0,0,0,0,0,0);
int m=_ps(v+0x40);
return"hit="+ptr_deref_u8(v+0x10)+" d="+_pf(v+0x14)+" f58="+_pf(v+0x18)+" n="+_pf(v+0x20)+","+_pf(v+0x24)+","+_pf(v+0x28)+" m="+m+":"+_d90(m)+" b="+ptr_deref_u8(v+0x44);
}
void _d89(const string&in l){ActorBase@k=_k7();
_L("MAT "+l+" player="+_d91(Player)+" rayP="+_d106(Player.pos_x,Player.pos_y+0.5f,Player.pos_z)+(k is null?"":" rayK="+_d106(k.pos_x,k.pos_y+0.2f,k.pos_z)));}
void _d124(const string&in l){_d75();ActorBase@a=_k7();_L("SPK "+l+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+_k18+" tier="+driftTier+" charge="+driftCharge+" boost="+boostLeft+" live0="+(fxScr!=0&&_d49(0)!=0)+" live1="+(fxScr!=0&&_d49(1)!=0)+" ground="+_d71+"/"+_d73+" d="+_d65+" mounted="+_k15(a));}
void main(){
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
_d89("start");input(30,0);_d89("start2");
Player.setPos(-150,127.8,-62);input(90,0);if(!_k3())return;
_d89("field");
_k5(tp);_d45(uint64(ZL|ZR|DUP),0,0,0);
for(uint f=0;f<25;f++)_d45(0,0,0,0);
for(uint t=0;t<10&&!_k15(_k7());t++){
ActorBase@k=_k7();if(k is null){input(10,0);continue;}
Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,k.pos_y+0.3f,pz);input(20,0);
_L("SPK try mount t="+t+" kart="+k.pos_x+","+k.pos_z+" player="+Player.pos_x+","+Player.pos_z);
input(1,1);input(30,0);
}
if(!_k15(_k7())){_L("SPK mount failed");return;}
_d45(0,0,0,0);
for(uint f=0;f<60&&_k3();f++){_d45(uint64(A),0,0,0);if(f%30==0)_d124("run"+f);}
_d45(uint64(ZL|ZR|DDOWN),0,0,0);_d45(0,0,0,0);_d124("toggled-on offroad="+_d96);
for(uint f=0;f<150&&_k3();f++){_d45(uint64(A),0,0,0);if(f%30==0)_d124("on"+f+" factor="+_d130());}
_d45(uint64(ZL|ZR|DDOWN),0,0,0);_d45(0,0,0,0);_d124("toggled-off offroad="+_d96);
for(uint f=0;f<150&&_k3();f++){_d45(uint64(A),0,0,0);if(f%30==0)_d124("off"+f+" factor="+_d130());}
_L("SPK finished");_d114=false;input(1,0);_k11(tp);
}
