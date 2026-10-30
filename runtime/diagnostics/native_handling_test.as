float _pf(ptr_t p){return ptr_deref_float(p);}
uint64 _pq(ptr_t p){return ptr_deref_u64(p);}
u32 _pu(ptr_t p){return ptr_deref_u32(p);}
void _pw(ptr_t p,float v){ptr_write_float(p,v);}
ptr_t _pa(ActorBase@a){return ptr_from_ActorBase(a);}
void _L(const string&in s){sys::debugLog(s);}
void _T(u32 t,const string&in s){TextWriter::toast(t,s);}
ptr_t _k16=0;
uint _k17=0xffffffff;
float _k18=0;
bool _k19=false;
bool _k20=false;float _d57=0,_w15=0;
float _d74=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d38=false;
const float _d15=7.775f;//[table]PRSL ground top speed,0 coins
const float _d7=0.011f;//[table]PRAC strength(G)
const float _d6=0.09f;//[table]PRAC limiter(M)
const float _d16=0.0118f;//[table]PRTL _d73,rad per MK frame
const float _d12=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d10=0.9f;//[table]PRTL charge(not used by the recovered charge routine)
const float _d17=0.75f;//[table]PRON road traction
const float _d20=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d19=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d35)
const uint _d21=153;//[chosen]ultra _d48(not in the table):SMT+(SMT-MT)
const float _d1=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d18=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d14=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d9=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d11=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d13=0.993f;//[chosen]decay above _d77(after a boost)
const float _d8=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d4=0.35f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d2=0.53f;//[native]body angle into the turn(rad),approached at 7%/frame,min _d75 0.001
const float _d3=0.8f;//[native]drift _d73 _d72 _w12,approached at 10%/frame,_d75<=0.07
const float _d0=5.0f,CHARGE_OUT=2.0f,CHARGE_INWARD=0.71f;//[native]charge per frame:5 if _d47>=0.71 else 2
const float _d5=3.0f;//[chosen]drift _d41,m/s upward
float _d51=0,driftCharge=0,bodyOff=0,driftTrack=0;int _d31=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d42=false,gasLatch=true,idleHold=false;
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d40=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d40==0)return 0;
uint op=_pu(_d40);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d30=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d30-=0x04000000;
ptr_t _d77=ptr_t(int64(_d40)+_d30*4);
if(_pu(_d77)!=0xf0001382||_pu(_d77+4)!=0xa9be7bfd)return 0;
ptr_t _d26=_d77-0x65b80;if((_d26&0xfff)!=0)return 0;return _d26+0x3d90b8;
}
void _k13(){ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d60();_k19=false;_k20=false;_d57=0;_w15=0;_d38=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d72=_pu(_k16+0x24);if(_d72<2||_d72>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d43,uint _k27){
if(_d43 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d43);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d72=_pu(p+0x24);
return _d72>=2&&_d72<=6;
}
bool _k0(ActorBase@_d43,uint _k27){
if(Player is null||!_k1(_d43,_k27))return false;
ptr_t _d22=_pa(_d43),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d29=_pu(_d22+0x220);ptr_t _d49=_pq(_d22+0x228);
if(_d29<=129||_d29>512||!_k2(_d49))return false;
ptr_t _d28=_pq(_d49+0x408);
if(!_k2(_d28))return false;
uint _d65=_pu(_d28+0x20);ptr_t _k29=_pq(_d28+0x28);
if(_d65!=1||!_k2(_k29))return false;
ptr_t _d63=_pq(_k29);
if(!_k2(_d63))return false;
uint _d64=_pu(_d63+0x10),flags=_pu(_d63+0x18);
float _k33=_pf(_d63+0x74);
if(_d64!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d63+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d43,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d57=a.pos_x;_w15=a.pos_z;return;}
float dx=_d57-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d57=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@_d52=_k7();
if(_k15(_d52)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d48=sqrt(fx*fx+fz*fz);if(_d48<0.1f)return;fx/=_d48;fz/=_d48;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d52!is null){_k10(_d52);_d52.setPos(x,y,z);@_d52=null;_d57=0;_w15=0;_d38=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);_k17=_pu(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d57=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d81(ActorBase@a){
ptr_t _d49=_pq(_pa(a)+0x228);if(!_k2(_d49))return 0;
ptr_t mc=_pq(_d49+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(_pf(b+120)-0.728f)>0.002f||abs(_pf(b+216)+0.728f)>0.002f||abs(_pf(b+312)-0.7776f)>0.002f||abs(_pf(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _d82(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
void _d25(ActorBase@a){
if(a is null){_d38=false;return;}
Matrix33f r=a.rot;float _d48=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d38&&_d48>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d48;}
_w4=x;_w5=z;_d38=true;
float _d76=ds/0.28328f*0.105f,stepR=ds/0.3683f*0.105f*1.3f;
if(_d76>0.18f)_d76=0.18f;if(_d76<-0.18f)_d76=-0.18f;if(stepR>0.18f)stepR=0.18f;if(stepR<-0.18f)stepR=-0.18f;
_w2+=_d76;_w3+=stepR;
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d74*0.45f-_w1)*0.25f;
ptr_t b=_d81(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d82(b+72,sf,cf,sd,cd);_d82(b+168,sf,cf,sd,cd);
_d82(b+264,sr,cr,0,1);_d82(b+360,sr,cr,0,1);
}
void _d60(){_d51=0;bodyOff=0;driftTrack=0;_k18=0;driftCharge=0;_d31=0;driftTier=0;boostLeft=0;hopWindow=0;_d42=false;gasLatch=true;idleHold=false;}
float _d71(float v,float _d78){
if(boostLeft>0){
boostLeft--;float t=_d15*_d20;
if(v<t){float _d45=(t-v)*_d8;if(_d45>MK_BOOST_CAP)_d45=MK_BOOST_CAP;return v+_d45;}
return t;
}
if(_d78>0){
if(v<0)return v+_d9>0?0:v+_d9;//stop reversing first
float t=_d15*_d78;
if(v<t){float _d45=(t-v)*_d7;if(_d45>_d6)_d45=_d6;return v+_d45;}//[native]form
float d=v*_d13;return d<t?t:d;
}
if(_d78<0){
if(v>0)return v-_d9<0?0:v-_d9;//brake,then reverse
float t=-_d14*(-_d78);
if(v>t){float _d45=(v-t)*_d7;if(_d45>_d6)_d45=_d6;return v-_d45;}
return v;
}
if(v>0)return v-_d11<0?0:v-_d11;
return v+_d11>0?0:v+_d11;
}
void _d32(int _d79){
_L("KART drift tier="+_d79+" charge="+driftCharge);
if(_d79==1)_T(30,"Mini-Turbo\n");else if(_d79==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d39){
_d74=0;
ActorBase@a=_k7();bool _d61=_k15(a);
if(_d61!=_k19){_L("KART mounted="+_d61);_d60();_k19=_d61;_k20=!_d61;if(a!is null){_d57=a.pos_x;_w15=a.pos_z;}}
if(!_d61||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d60();return;}
float _d73=float(ix)/32768.0f,_d78=0;
if(abs(_d73)<0.15f)_d73=0;
bool _d37=(_d39&uint64(A))!=0,brake=(_d39&uint64(B))!=0;
if(!_d37)gasLatch=false;//the A press used to get in must be released first
if(brake)_d78=-1;else if(_d37&&!gasLatch)_d78=1;
_d74=_d73;
Matrix33f r=a.rot;float _d48=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d48<0.1f||r.a4<0.4f){_k10(a);_d60();return;}
float bx=r.a2/_d48,bz=r.a8/_d48,co=cos(bodyOff),so=sin(bodyOff);
float fx=bx*co+bz*so,fz=-bx*so+bz*co;//travel direction on the ground plane
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d23=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d24=_d23/_d18;
if(_d51>0&&_d51>_d24+0.6f)_d51=_d24+0.6f<0?0:_d24+0.6f;
if(_d51<0&&_d51<_d24-0.6f)_d51=_d24-0.6f>0?0:_d24-0.6f;
bool _d59=(_d39&uint64(R|ZR))!=0,fast=_d51>_d15*0.35f;
float _d41=0;
if(_d59&&!_d42&&fast){_d41=_d5;hopWindow=24;}
_d42=_d59;
if(_d31==0&&_d59&&hopWindow>0&&abs(_d73)>0.3f){_d31=_d73>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d31);}
if(_d31!=0&&(!_d59||!fast)){
int _d35=driftTier==3?int(_d21):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d19):0;
if(_d35>0&&_d59==false){boostLeft=_d35;_L("KART boost tier="+driftTier+" frames="+_d35);}
_d31=0;driftCharge=0;driftTier=0;
}
if(_d78==0&&boostLeft==0&&_d31==0&&_d41==0&&abs(_d51)<_d11){
_d51=0;_k18=0;bodyOff=0;driftTrack=0;
if(!idleHold){idleHold=true;_d57=a.pos_x;_w15=a.pos_z;}
_k9(a);return;
}
idleHold=false;
float _d83=0,oldOff=bodyOff;
for(int _d75=0;_d75<2;_d75++){
if(hopWindow>0)hopWindow--;
_d51=_d71(_d51,_d78);
float _d27=0;
if(_d31!=0){
float _d47=_d73*_d31;if(_d47>1)_d47=1;if(_d47<-1)_d47=-1;
float _d80=_d47>=0?_d3:-_d3,dt=(_d80-driftTrack)*0.1f;
if(dt>0.07f)dt=0.07f;if(dt<-0.07f)dt=-0.07f;driftTrack+=dt;
float _d46=driftTrack<0?0:driftTrack>1?1:driftTrack;
_d83+=_d31*_d12*_d46*_d46*(0.75f+0.25f*_d47);
driftCharge+=_d47>=CHARGE_INWARD?_d0:CHARGE_OUT;//[native]exact MK8DX charge rule
int _d79=driftCharge>CHARGE_UMT?3:driftCharge>CHARGE_SMT?2:driftCharge>_d1?1:0;
if(_d79>driftTier){driftTier=_d79;_d32(_d79);}
_d27=_d31*_d2;
}else{
driftTrack=0;
float _d69=abs(_d51)/(_d15*0.25f);if(_d69>1)_d69=1;
_d83+=_d73*_d16*_d69*(_d51<0?-1.0f:1.0f);
}
float _d36=_d27-bodyOff,ds=_d36*0.07f;
if(abs(ds)<0.001f)ds=abs(_d36)<0.001f?_d36:(_d36>0?0.001f:-0.001f);
bodyOff+=ds;
lateral*=1-_d4*_d17;
}
_k18=_d51*_d18;
float _d70=_k18;
b.setVel(fx*_d70+lx*lateral,v.y+_d41,fz*_d70+lz*lateral);
b.setAngularVel(-r.a7*2.0f,-(_d83+bodyOff-oldOff)*30.0f,r.a1*2.0f);
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
_L("KART ready");
}
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool _d55=false,exitLatch=false;uint64 _d53=0;int _d54=0,outLY=0,outRX=0,outRY=0;
bool _d66=false;uint64 _d67=0;int _d68=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d56){
uint64 _d39=_d66?_d67:_pq(_d56);
int lx=_d66?_d68:ptr_deref_s32(_d56+8),ly=_d66?simLY:ptr_deref_s32(_d56+12);
int rx=_d66?simRX:ptr_deref_s32(_d56+16),ry=_d66?simRY:ptr_deref_s32(_d56+20);
_d55=false;_d53=_d39;_d54=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 _d50=uint64(ZL|ZR|DUP);
if((_d39&_d50)==0)_k24=false;
if(!_k24&&(_d39&_d50)==_d50){_k24=true;_k25=true;_L("KART spawn queued");}
if(!_k3())return;
if(_k25&&(_d39&_d50)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d39);
_d25(_k7());
uint64 _d33=uint64(A|B|X|R|ZR);
if(_k19){
_d55=true;_d53=_d39&~_d33;
if((_d39&uint64(X))!=0){_d53|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d39&uint64(X))==0)exitLatch=false;
else{_d55=true;_d53=_d39&~uint64(X);}//do not let the _d39 X make Link jump
}
}
void _d84(){
if(_d55)input(1,_d53,_d54,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d56){while(true){_k5(_d56);_d84();}}
ptr_t tp=0;uint hf=0;
void _d44(const string&in l){
ActorBase@a=_k7();if(a is null){_L("HDL "+l+" missing");return;}
RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;Matrix33f r=a.rot;
_L("HDL "+l+" f="+hf+" pos="+a.pos_x+","+a.pos_y+","+a.pos_z+" vel="+v.x+","+v.y+","+v.z+" heading="+r.a2+","+r.a8
+" up="+r.a4+" cmd="+_k18+" drift="+_d31+" charge="+driftCharge+" tier="+driftTier+" boost="+boostLeft+" mounted="+_k15(a));
}
void _d34(uint64 k,int x,int y,int rx){
_d66=true;_d67=k;_d68=x;simLY=y;simRX=rx;simRY=0;_k5(tp);
if(_d55)input(1,_d53,_d54,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
void _d62(uint n,uint64 k,int x,int y,const string&in l){
uint64 _d58=y>0?uint64(A):y<0?uint64(B):0;
for(uint f=0;f<n&&_k3();f++){_d34(k|_d58,x,0,0);hf++;if(f%10==0)_d44(l);}
}
void main(){
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
Player.setPos(-150,127.8,-62);input(90,0);if(!_k3())return;
_L("HDL site player="+Player.pos_x+","+Player.pos_y+","+Player.pos_z);
_k5(tp);_d34(uint64(ZL|ZR|DUP),0,0,0);
for(uint f=0;f<165;f++)_d34(0,0,0,0);
input(1,1);input(90,0);
if(!_k15(_k7())){_L("HDL mount failed");return;}
_d34(0,0,0,0);//release A after getting in,as a _w22 does
_d44("start");
_d62(240,0,32767,32767,"circle");
_d62(200,uint64(R),32767,32767,"drift");
_d62(90,0,32767,32767,"boost");
_d62(60,0,0,-32767,"brake");
_d62(90,0,0,0,"coast");
_d34(uint64(X),0,0,0);_d62(30,0,0,0,"exit");
_L("HDL finished");_d66=false;input(1,0);_k11(tp);
}
