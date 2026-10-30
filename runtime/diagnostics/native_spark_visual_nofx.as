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
bool _k20=false;float _d74=0,_w15=0;
float _d96=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d54=false;
const float _d16=7.775f;//[table]PRSL ground top speed,0 coins
const float _d8=0.011f;//[table]PRAC strength(G)
const float _d7=0.09f;//[table]PRAC limiter(M)
const float _d17=0.0118f;//[table]PRTL _d95,rad per MK frame
const float _d13=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d11=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d18=0.75f;//[table]PRON road traction
const float _d21=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d20=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d41)
const uint _d24=153;//[chosen]ultra _d64(not in the table):SMT+(SMT-MT)
const float _d1=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d19=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d15=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d10=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d12=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d14=0.993f;//[chosen]decay above _d98(after a boost)
const float _d9=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d5=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d2=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d97 0.001
const float _d3=0.8f;//[native]drift _d95 _d94 _w12,approached at 10%/frame,_d97<=0.07
const float _d0=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d63>=0.71 else 2
const float _d6=3.0f;//[chosen]drift _d57,m/s upward
float _d67=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d36=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d58=false,gasLatch=true,idleHold=false;
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d56=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d56==0)return 0;
uint op=_pu(_d56);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d35=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d35-=0x04000000;
ptr_t _d98=ptr_t(int64(_d56)+_d35*4);
if(_pu(_d98)!=0xf0001382||_pu(_d98+4)!=0xa9be7bfd)return 0;
ptr_t _d29=_d98-0x65b80;if((_d29&0xfff)!=0)return 0;return _d29+0x3d90b8;
}
void _k13(){ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d77();_k19=false;_k20=false;_d74=0;_w15=0;_d54=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d94=_pu(_k16+0x24);if(_d94<2||_d94>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d59,uint _k27){
if(_d59 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d59);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d94=_pu(p+0x24);
return _d94>=2&&_d94<=6;
}
bool _k0(ActorBase@_d59,uint _k27){
if(Player is null||!_k1(_d59,_k27))return false;
ptr_t _d25=_pa(_d59),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d34=_pu(_d25+0x220);ptr_t _d65=_pq(_d25+0x228);
if(_d34<=129||_d34>512||!_k2(_d65))return false;
ptr_t _d33=_pq(_d65+0x408);
if(!_k2(_d33))return false;
uint _d81=_pu(_d33+0x20);ptr_t _k29=_pq(_d33+0x28);
if(_d81!=1||!_k2(_k29))return false;
ptr_t _d79=_pq(_k29);
if(!_k2(_d79))return false;
uint _d80=_pu(_d79+0x10),flags=_pu(_d79+0x18);
float _k33=_pf(_d79+0x74);
if(_d80!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d79+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d59,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d74=a.pos_x;_w15=a.pos_z;return;}
float dx=_d74-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d74=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@_d69=_k7();
if(_k15(_d69)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d64=sqrt(fx*fx+fz*fz);if(_d64<0.1f)return;fx/=_d64;fz/=_d64;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d69!is null){_k10(_d69);_d69.setPos(x,y,z);@_d69=null;_d74=0;_w15=0;_d54=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);_k17=_pu(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d74=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d104(ActorBase@a){
ptr_t _d65=_pq(_pa(a)+0x228);if(!_k2(_d65))return 0;
ptr_t mc=_pq(_d65+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(_pf(b+120)-0.728f)>0.002f||abs(_pf(b+216)+0.728f)>0.002f||abs(_pf(b+312)-0.7776f)>0.002f||abs(_pf(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _d105(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
const float _d23=0.3927f;//2*pi/16 tread _d30
float _d103(float _d97){
float m=abs(_d97),half=_d23*0.5f;
if(m<=half*0.9f)return _d97;
float _d30=floor((m-half)/_d23);if(_d30>3)_d30=3;
float v=(_d30+0.5f)*_d23;return _d97<0?-v:v;
}
void _d28(ActorBase@a){
if(a is null){_d54=false;return;}
Matrix33f r=a.rot;float _d64=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d54&&_d64>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d64;}
_w4=x;_w5=z;_d54=true;
_w2+=_d103(ds/0.28328f);_w3+=_d103(ds/0.3683f);
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d96*0.45f-_w1)*0.25f;
ptr_t b=_d104(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d105(b+72,sf,cf,sd,cd);_d105(b+168,sf,cf,sd,cd);
_d105(b+264,sr,cr,0,1);_d105(b+360,sr,cr,0,1);
}
void _d77(){_d67=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d36=0;driftTier=0;boostLeft=0;hopWindow=0;_d58=false;gasLatch=true;idleHold=false;}
float _d92(float v,float _d99){
if(boostLeft>0){
boostLeft--;float t=_d16*_d21;
if(v<t){float _d60=(t-v)*_d9;if(_d60>MK_BOOST_CAP)_d60=MK_BOOST_CAP;return v+_d60;}
return t;
}
if(_d99>0){
if(v<0)return v+_d10>0?0:v+_d10;//stop reversing first
float t=_d16*_d99;
if(v<t){float _d60=(t-v)*_d8;if(_d60>_d7)_d60=_d7;return v+_d60;}//[native]form
float d=v*_d14;return d<t?t:d;
}
if(_d99<0){
if(v>0)return v-_d10<0?0:v-_d10;//brake,then reverse
float t=-_d15*(-_d99);
if(v>t){float _d60=(v-t)*_d8;if(_d60>_d7)_d60=_d7;return v-_d60;}
return v;
}
if(v>0)return v-_d12<0?0:v-_d12;
return v+_d12>0?0:v+_d12;
}
void _d37(int _d100){
_L("KART drift tier="+_d100+" charge="+driftCharge);
if(_d100==1)_T(30,"Mini-Turbo\n");else if(_d100==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d55){
_d96=0;
ActorBase@a=_k7();bool _d78=_k15(a);
if(_d78!=_k19){_L("KART mounted="+_d78);_d77();_k19=_d78;_k20=!_d78;if(a!is null){_d74=a.pos_x;_w15=a.pos_z;}}
if(!_d78||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d77();return;}
float _d95=float(ix)/32768.0f,_d99=0;
if(abs(_d95)<0.15f)_d95=0;
bool _d53=(_d55&uint64(A))!=0,brake=(_d55&uint64(B))!=0;
if(!_d53)gasLatch=false;//the A press used to get in must be released first
if(brake)_d99=-1;else if(_d53&&!gasLatch)_d99=1;
_d96=_d95;
Matrix33f r=a.rot;float _d64=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d64<0.1f||r.a4<0.4f){_k10(a);_d77();return;}
float bx=r.a2/_d64,bz=r.a8/_d64,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d26=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d27=_d26/_d19;
if(_d67>0&&_d67>_d27+0.6f)_d67=_d27+0.6f<0?0:_d27+0.6f;
if(_d67<0&&_d67<_d27-0.6f)_d67=_d27-0.6f>0?0:_d27-0.6f;
bool _d75=(_d55&uint64(R|ZR))!=0,fast=_d67>_d16*0.35f;
float _d57=0;
if(_d75&&!_d58&&fast){_d57=_d6;hopWindow=24;}
_d58=_d75;
if(_d36==0&&_d75&&hopWindow>0&&abs(_d95)>0.3f){_d36=_d95>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d36);}
if(_d36!=0&&(!_d75||!fast)){
int _d41=driftTier==3?int(_d24):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d20):0;
if(_d41>0&&_d75==false){boostLeft=_d41;_L("KART boost tier="+driftTier+" frames="+_d41);}
_d36=0;driftCharge=0;driftTier=0;
}
if(_d99==0&&boostLeft==0&&_d36==0&&_d57==0&&abs(_d67)<_d12){
_d67=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d74=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d106=0,oldOff=bodyOff;
for(int _d97=0;_d97<2;_d97++){
if(hopWindow>0)hopWindow--;
_d67=_d92(_d67,_d99);
float _d31=0;
if(_d36!=0){
float _d63=_d95*_d36;if(_d63>1)_d63=1;if(_d63<-1)_d63=-1;
float _d102=_d63>=0?_d3:-_d3,dt=(_d102-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d62=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d106+=_d36*_d13*_d62*_d62*(0.75f+0.25f*_d63);
driftCharge+=_d63>=CHARGE_INWARD?_d0:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d100=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d1?1:0;
if(_d100>driftTier){driftTier=_d100;_d37(_d100);}
_d31=_d36*_d2;
}else{
driftTrack=0;
float _d90=abs(_d67)/(_d16*0.25f);if(_d90>1)_d90=1;
_d106+=_d95*_d17*_d90*(_d67<0?-1.0f:1.0f);
}
float _d52=_d31-bodyOff,ds=_d52*0.07f;
if(abs(ds)<0.001f)ds=abs(_d52)<0.001f?_d52:(_d52>0?0.001f:-0.001f);
bodyOff+=ds;
lateral*=1-_d5*_d18;
}
_k18=_d67*_d19;
float _d91=_k18;
b.setVel(fx*_d91+lx*lateral,v.y+_d57,fz*_d91+lz*lateral);
b.setAngularVel(-r.a7*2.0f,-(_d106+bodyOff-oldOff)*30.0f,r.a1*2.0f);
}
const uint _d4=0x4631b98,FX_CREATE=0x229a0d0,FX_PLACE=0x229a164,FX_KILL=0x28998,FX_SCRATCH=0x3d1000;
const float _d22=0.35f,FLAME_SCALE=0.18f;//[chosen]from screenshots
ptr_t _d44=0,fxSys=0,fxScr=0;int _d48=-2,fxFlame=-2;
string _d45(ptr_t p){string s="";for(int i=0;i<48;i++){u8 c=ptr_deref_u8(p+i);if(c==0)break;s+=" ";s[s.length()-1]=c;}return s;}
int _d42(const string&in _d68){
ptr_t _d76=_pq(_pq(fxSys+0x2ee8)+8);if(_d76==0||ptr_deref_u8(_d76+0x571)==0)return-1;//static effects=resource 1
int n=_ps(_d76+0x558);ptr_t _d82=_pq(_d76+0x430);
for(int i=0;i<n;i++)if(_d45(_pq(_d82+0x28*i)+0x10)==_d68)return i;
return-1;
}
bool _d47(){
if(_d48>=0)return true;
if(_d48==-1)return false;//looked once and failed:stay off
_d48=-1;
ptr_t _d56=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d56==0)return false;
uint op=_pu(_d56);int64 _d35=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d35-=0x04000000;
ptr_t _d98=ptr_t(int64(_d56)+_d35*4),_d29=_d98-0x65b80;
if((_d29&0xfff)!=0||_pu(_d98)!=0xf0001382)return false;
fxScr=_d29+FX_SCRATCH;_d44=sys::mainOffset();
ptr_t _d61=_pq(_pq(_d44+_d4));if(_d61==0)return false;
fxSys=_pq(_d61+0x11b8);if(fxSys==0)return false;
int _d87=_d42("Ply_ShockWave_Spark");fxFlame=_d42("Chm_Fire_BoostLoop");
_L("KART fx spark="+_d87+" flame="+fxFlame);
if(_d87<0)return false;
_d48=_d87;return true;
}
ptr_t _d43(int _d86){ptr_t h=fxScr+0x10*_d86,e=_pq(h);if(e==0)return 0;return _pu(e+0x234)==_pu(h+8)?e:0;}
ptr_t _d49(int _d86,int id){
ptr_t e=_d43(_d86);if(e!=0)return e;
ptr_t h=fxScr+0x10*_d86;ptr_write_u64(h,0);ptr_write_u64(h+8,0);
ptr_call(_d44+FX_CREATE,fxSys,h,id,1,0,fxScr+0x1000+0x2000*_d86,0,0,0,0,0);
return _d43(_d86);
}
void _d50(int _d86){if(fxScr==0)return;ptr_t e=_d43(_d86);if(e!=0)ptr_call(_d44+FX_KILL,fxSys,e,0,0,0,0,0,0,0,0,0);ptr_write_u64(fxScr+0x10*_d86,0);}
void _d46(ptr_t e,ActorBase@a,float lx,float ly,float lz,float s){
Matrix33f r=a.rot;ptr_t m=fxScr+0x40;
float px=a.pos_x+r.a0*lx+r.a1*ly+r.a2*lz,py=a.pos_y+r.a3*lx+r.a4*ly+r.a5*lz,pz=a.pos_z+r.a6*lx+r.a7*ly+r.a8*lz;
_pw(m,r.a0);_pw(m+4,r.a1);_pw(m+8,r.a2);_pw(m+12,px);
_pw(m+16,r.a3);_pw(m+20,r.a4);_pw(m+24,r.a5);_pw(m+28,py);
_pw(m+32,r.a6);_pw(m+36,r.a7);_pw(m+40,r.a8);_pw(m+44,pz);
_pw(fxScr+0x80,s);_pw(fxScr+0x84,s);_pw(fxScr+0x88,s);
ptr_call(_d44+FX_PLACE,e,m,fxScr+0x80,0,0,0,0,0,0,0,0);
}
void _d51(ptr_t e,float r,float g,float b){_pw(e+0x40,r);_pw(e+0x44,g);_pw(e+0x48,b);}
void _d88(ActorBase@a){
bool _d89=a!is null&&_k19&&_d36!=0&&driftTier>0;
bool _d40=a!is null&&_k19&&boostLeft>0&&fxFlame>=0;
if(!_d89&&!_d40&&fxScr==0)return;
if(!_d47()){return;}
if(!_d89)_d50(0);
if(!_d40)_d50(1);
if(_d89){
ptr_t e=_d49(0,_d48);
if(e!=0){
if(driftTier==1)_d51(e,0.25f,0.8f,6.0f);else if(driftTier==2)_d51(e,1.0f,1.0f,1.0f);else _d51(e,2.2f,0.4f,6.0f);
ptr_t b=_d104(a);float wy=0.05f,wz=-0.75f,wx=0.78f;
if(b!=0){wx=abs(_pf(b+312));wy=_pf(b+28)+_pf(b+316)-0.3683f;wz=_pf(b+32)+_pf(b+320);}
_d46(e,a,wx,wy,wz,_d22);_d46(e,a,-wx,wy,wz,_d22);
}
}
if(_d40){ptr_t e=_d49(1,fxFlame);if(e!=0)_d46(e,a,0,0.45f,-1.0f,FLAME_SCALE);}
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
_L("KART ready");
}
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool _d72=false,exitLatch=false;uint64 _d70=0;int _d71=0,outLY=0,outRX=0,outRY=0;
bool _d83=false;uint64 _d84=0;int _d85=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d73){
uint64 _d55=_d83?_d84:_pq(_d73);
int lx=_d83?_d85:_ps(_d73+8),ly=_d83?simLY:_ps(_d73+12);
int rx=_d83?simRX:_ps(_d73+16),ry=_d83?simRY:_ps(_d73+20);
_d72=false;_d70=_d55;_d71=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 _d66=uint64(ZL|ZR|DUP);
if((_d55&_d66)==0)_k24=false;
if(!_k24&&(_d55&_d66)==_d66){_k24=true;_k25=true;_L("KART spawn queued");}
if(!_k3())return;
if(_k25&&(_d55&_d66)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d55);
_d28(_k7());
uint64 _d38=uint64(A|B|X|R|ZR);
if(_k19){
_d72=true;_d70=_d55&~_d38;
if((_d55&uint64(X))!=0){_d70|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d55&uint64(X))==0)exitLatch=false;
else{_d72=true;_d70=_d55&~uint64(X);}//do not let the _d55 X make Link jump
}
}
void _d107(){
if(_d72)input(1,_d70,_d71,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d73){while(true){_k5(_d73);_d107();}}
ptr_t tp=0;
void _d39(uint64 k,int x,int y,int rx){
_d83=true;_d84=k;_d85=x;simLY=y;simRX=rx;simRY=0;_k5(tp);
if(_d72)input(1,_d70,_d71,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
void _d93(const string&in l){ActorBase@a=_k7();_L("SPK "+l+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+_k18+" tier="+driftTier+" charge="+driftCharge+" boost="+boostLeft+" live0="+(fxScr!=0&&_d43(0)!=0)+" live1="+(fxScr!=0&&_d43(1)!=0)+" mounted="+_k15(a));}
void main(){
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
Player.setPos(-150,127.8,-62);input(90,0);if(!_k3())return;
_k5(tp);_d39(uint64(ZL|ZR|DUP),0,0,0);
for(uint f=0;f<25;f++)_d39(0,0,0,0);
for(uint t=0;t<10&&!_k15(_k7());t++){
ActorBase@k=_k7();if(k is null){input(10,0);continue;}
Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,k.pos_y+0.3f,pz);input(20,0);
_L("SPK try mount t="+t+" kart="+k.pos_x+","+k.pos_z+" player="+Player.pos_x+","+Player.pos_z);
input(1,1);input(30,0);
}
if(!_k15(_k7())){_L("SPK mount failed");return;}
_d39(0,0,0,0);
for(uint f=0;f<60&&_k3();f++){_d39(uint64(A),0,0,0);if(f%30==0)_d93("run"+f);}
_d93("drift-start");
for(uint k=0;k<3;k++){
bool _d101=false;
for(uint f=0;f<220&&_k3();f++){
_d39(uint64(A|R),32767,0,0);
float _d32=k==0?_d1+1:k==1?CHARGE_SMT+1:CHARGE_UMT+1;if(driftCharge>_d32)driftCharge=_d32;
if(!_d101&&driftTier==int(k)+1){_d101=true;_d93("hold"+(k+1));}
if(f%30==0)_d93("d"+k+"_"+f);
}
}
_d93("release");
for(uint f=0;f<20&&_k3();f++)_d39(uint64(A),32767,0,0);
_d93("boosting");
for(uint f=0;f<160&&_k3();f++)_d39(uint64(A),32767,0,0);
_d93("after");
_d39(uint64(X),0,0,0);for(uint f=0;f<30;f++)_d39(0,0,0,0);
_d93("exit");
_L("SPK finished");_d83=false;input(1,0);_k11(tp);
}
