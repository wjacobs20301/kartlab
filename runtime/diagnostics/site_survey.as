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
bool _k20=false;float _d52=0,_w15=0;
float _d68=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d34=false;
const float _d12=7.775f;//[table]PRSL ground top speed,0 coins
const float _d4=0.011f;//[table]PRAC strength(G)
const float _d3=0.09f;//[table]PRAC limiter(M)
const float _d13=0.0118f;//[table]PRTL _d67,rad per MK frame
const float _d9=0.0196f;//[table]PRTL drift,rad per MK frame
const float _d7=0.9f;//[table]PRTL charge
const float _d14=0.75f;//[table]PRON road traction
const float _d17=1.105f;//[table]PRMT mini-turbo/super-mini-turbo speed
const uint _d16=31,SMT_FRAMES=92;//[table]PRMT boost lengths(MK _d32)
const uint _d18=153;//[chosen]ultra _d43(not in the table):SMT+(SMT-MT)
const float _d0=252,CHARGE_SMT=534,CHARGE_UMT=816;//[table]PRMT charge thresholds
const float _d15=1.8f;//[chosen]m/s per MK unit/frame(top speed about 14 m/s)
const float _d11=2.7f;//[chosen]reverse top speed,MK units(about 4.9 m/s)
const float _d6=0.11f;//[chosen]braking per MK frame(top speed to 0 in~1.2 s)
const float _d8=0.07f;//[chosen]coasting deceleration per MK frame(~1.9 s)
const float _d10=0.993f;//[chosen]decay above _d71(after a boost)
const float _d5=0.05f,MK_BOOST_CAP=0.3f;//[chosen]stronger push while boosting
const float _d1=0.35f,DRIFT_GRIP=0.08f;//[chosen]fraction of traction removing sideways slip per MK frame
const float _d2=3.0f;//[chosen]drift _d37,m/s upward
float _d46=0,driftCharge=0;int _d27=0,driftTier=0,boostLeft=0,hopWindow=0;bool _d38=false,gasLatch=true;
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d36=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d36==0)return 0;
uint op=_pu(_d36);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d26=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d26-=0x04000000;
ptr_t _d71=ptr_t(int64(_d36)+_d26*4);
if(_pu(_d71)!=0xf0001382||_pu(_d71+4)!=0xa9be7bfd)return 0;
ptr_t _d23=_d71-0x65b80;if((_d23&0xfff)!=0)return 0;return _d23+0x3d90b8;
}
void _k13(){ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_d54();_k19=false;_k20=false;_d52=0;_w15=0;_d34=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d66=_pu(_k16+0x24);if(_d66<2||_d66>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d39,uint _k27){
if(_d39 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d39);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d66=_pu(p+0x24);
return _d66>=2&&_d66<=6;
}
bool _k0(ActorBase@_d39,uint _k27){
if(Player is null||!_k1(_d39,_k27))return false;
ptr_t _d19=_pa(_d39),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d25=_pu(_d19+0x220);ptr_t _d44=_pq(_d19+0x228);
if(_d25<=129||_d25>512||!_k2(_d44))return false;
ptr_t _d24=_pq(_d44+0x408);
if(!_k2(_d24))return false;
uint _d58=_pu(_d24+0x20);ptr_t _k29=_pq(_d24+0x28);
if(_d58!=1||!_k2(_k29))return false;
ptr_t _d56=_pq(_k29);
if(!_k2(_d56))return false;
uint _d57=_pu(_d56+0x10),flags=_pu(_d56+0x18);
float _k33=_pf(_d56+0x74);
if(_d57!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d56+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d39,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d52=a.pos_x;_w15=a.pos_z;return;}
float dx=_d52-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d52=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@_d47=_k7();
if(_k15(_d47)){_T(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d43=sqrt(fx*fx+fz*fz);if(_d43<0.1f)return;fx/=_d43;fz/=_d43;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d47!is null){_k10(_d47);_d47.setPos(x,y,z);@_d47=null;_d52=0;_w15=0;_d34=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);_k17=_pu(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d52=a.pos_x;_w15=a.pos_z;
_T(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();_T(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d74(ActorBase@a){
ptr_t _d44=_pq(_pa(a)+0x228);if(!_k2(_d44))return 0;
ptr_t mc=_pq(_d44+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(_pf(b+120)-0.728f)>0.002f||abs(_pf(b+216)+0.728f)>0.002f||abs(_pf(b+312)-0.7776f)>0.002f||abs(_pf(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _d75(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
void _d22(ActorBase@a){
if(a is null){_d34=false;return;}
Matrix33f r=a.rot;float _d43=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d34&&_d43>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d43;}
_w4=x;_w5=z;_d34=true;
_w2+=ds/0.28328f;_w3+=ds/0.3683f;
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d68*0.45f-_w1)*0.25f;
ptr_t b=_d74(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d75(b+72,sf,cf,sd,cd);_d75(b+168,sf,cf,sd,cd);
_d75(b+264,sr,cr,0,1);_d75(b+360,sr,cr,0,1);
}
void _d54(){_d46=0;_k18=0;driftCharge=0;_d27=0;driftTier=0;boostLeft=0;hopWindow=0;_d38=false;gasLatch=true;}
float _d65(float v,float _d72){
if(boostLeft>0){
boostLeft--;float t=_d12*_d17;
if(v<t){float _d40=(t-v)*_d5;if(_d40>MK_BOOST_CAP)_d40=MK_BOOST_CAP;return v+_d40;}
return t;
}
if(_d72>0){
if(v<0)return v+_d6>0?0:v+_d6;//stop reversing first
float t=_d12*_d72;
if(v<t){float _d40=(t-v)*_d4;if(_d40>_d3)_d40=_d3;return v+_d40;}//[native]form
float d=v*_d10;return d<t?t:d;
}
if(_d72<0){
if(v>0)return v-_d6<0?0:v-_d6;//brake,then reverse
float t=-_d11*(-_d72);
if(v>t){float _d40=(v-t)*_d4;if(_d40>_d3)_d40=_d3;return v-_d40;}
return v;
}
if(v>0)return v-_d8<0?0:v-_d8;
return v+_d8>0?0:v+_d8;
}
void _d28(int _d73){
_L("KART drift tier="+_d73+" charge="+driftCharge);
if(_d73==1)_T(30,"Mini-Turbo\n");else if(_d73==2)_T(30,"Super Mini-Turbo\n");else _T(30,"Ultra Mini-Turbo\n");
}
void _k12(int ix,int iy,uint64 _d35){
_d68=0;
ActorBase@a=_k7();bool _d55=_k15(a);
if(_d55!=_k19){_L("KART mounted="+_d55);_d54();_k19=_d55;_k20=!_d55;if(a!is null){_d52=a.pos_x;_w15=a.pos_z;}}
if(!_d55||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_d54();return;}
float _d67=float(ix)/32768.0f,_d72=0;
if(abs(_d67)<0.15f)_d67=0;
bool _d33=(_d35&uint64(A))!=0,brake=(_d35&uint64(B))!=0;
if(!_d33)gasLatch=false;//the A press used to get in must be released first
if(brake)_d72=-1;else if(_d33&&!gasLatch)_d72=1;
_d68=_d67;
Matrix33f r=a.rot;float _d43=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d43<0.1f||r.a4<0.4f){_k10(a);_d54();return;}
float fx=r.a2/_d43,fz=r.a8/_d43;//forward(local+Z)on the ground plane
float lx=fz,lz=-fx;//a sideways axis
Vector3f v=b.vel;
float _d20=v.x*fx+v.z*fz,lateral=v.x*lx+v.z*lz;
float _d21=_d20/_d15;
if(_d46>0&&_d46>_d21+0.6f)_d46=_d21+0.6f<0?0:_d21+0.6f;
if(_d46<0&&_d46<_d21-0.6f)_d46=_d21-0.6f>0?0:_d21-0.6f;
bool _d53=(_d35&uint64(R|ZR))!=0,fast=_d46>_d12*0.35f;
float _d37=0;
if(_d53&&!_d38&&fast){_d37=_d2;hopWindow=24;}
_d38=_d53;
if(_d27==0&&_d53&&hopWindow>0&&abs(_d67)>0.3f){_d27=_d67>0?1:-1;driftCharge=0;driftTier=0;_L("KART drift start dir="+_d27);}
if(_d27!=0&&(!_d53||!fast)){
int _d32=driftTier==3?int(_d18):driftTier==2?int(SMT_FRAMES):driftTier==1?int(_d16):0;
if(_d32>0&&_d53==false){boostLeft=_d32;_L("KART boost tier="+driftTier+" frames="+_d32);}
_d27=0;driftCharge=0;driftTier=0;
}
float _d76=0,grip=_d1;
for(int _d69=0;_d69<2;_d69++){
if(hopWindow>0)hopWindow--;
_d46=_d65(_d46,_d72);
if(_d27!=0){
float _d41=_d67*_d27;if(_d41>1)_d41=1;if(_d41<-1)_d41=-1;
_d76+=_d27*_d9*(0.55f+0.45f*_d41);//never reverses the drift
driftCharge+=(2.5f+3.5f*(_d41>0?_d41:0))*_d7;//[chosen]rate;tiers are[table]
int _d73=driftCharge>=CHARGE_UMT?3:driftCharge>=CHARGE_SMT?2:driftCharge>=_d0?1:0;
if(_d73>driftTier){driftTier=_d73;_d28(_d73);}
grip=DRIFT_GRIP;
}else{
float _d63=abs(_d46)/(_d12*0.25f);if(_d63>1)_d63=1;
_d76+=_d67*_d13*_d63*(_d46<0?-1.0f:1.0f);
}
lateral*=1-grip*_d14;
}
_k18=_d46*_d15;
float _d64=_k18;
b.setVel(fx*_d64+lx*lateral,v.y+_d37,fz*_d64+lz*lateral);
b.setAngularVel(-r.a7*2.0f,-_d76*30.0f,r.a1*2.0f);
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
_L("KART ready");
}
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
bool _d50=false,exitLatch=false;uint64 _d48=0;int _d49=0,outLY=0,outRX=0,outRY=0;
bool _d59=false;uint64 _d60=0;int _d61=0,simLY=0,simRX=0,simRY=0;
void _k5(ptr_t _d51){
uint64 _d35=_d59?_d60:_pq(_d51);
int lx=_d59?_d61:ptr_deref_s32(_d51+8),ly=_d59?simLY:ptr_deref_s32(_d51+12);
int rx=_d59?simRX:ptr_deref_s32(_d51+16),ry=_d59?simRY:ptr_deref_s32(_d51+20);
_d50=false;_d48=_d35;_d49=lx;outLY=ly;outRX=rx;outRY=ry;
if(!_k4()){
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;exitLatch=false;return;
}
_k26=false;uint64 _d45=uint64(ZL|ZR|DUP);
if((_d35&_d45)==0)_k24=false;
if(!_k24&&(_d35&_d45)==_d45){_k24=true;_k25=true;_L("KART spawn queued");}
if(!_k3())return;
if(_k25&&(_d35&_d45)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(lx,ly,_d35);
_d22(_k7());
uint64 _d29=uint64(A|B|X|R|ZR);
if(_k19){
_d50=true;_d48=_d35&~_d29;
if((_d35&uint64(X))!=0){_d48|=uint64(B);exitLatch=true;}//X gets out:TOTK's own dismount is B
}else if(exitLatch){
if((_d35&uint64(X))==0)exitLatch=false;
else{_d50=true;_d48=_d35&~uint64(X);}//do not let the _d35 X make Link jump
}
}
void _d77(){
if(_d50)input(1,_d48,_d49,outLY,outRX,outRY);
else sleep(1);
}
void _k11(ptr_t _d51){while(true){_k5(_d51);_d77();}}
ptr_t tp=0;
void _d31(uint64 k){_d59=true;_d60=k;_d61=0;simLY=0;simRX=0;simRY=0;_k5(tp);input(1,k,0,0,0,0);}
void _d30(float x,float z){
ActorBase@a=_k7();if(a is null){_L("SITE nokart");return;}
a.setPos(x,185,z);@a=null;
float _d42=0;uint _d70=0;
for(uint f=0;f<200&&_k3();f++){
_d31(0);
ActorBase@k=_k7();if(k is null)return;
if(f>20&&abs(k.pos_y-_d42)<0.01f)_d70++;else _d70=0;_d42=k.pos_y;
if(_d70>15)break;
}
ActorBase@k=_k7();if(k is null)return;Matrix33f r=k.rot;
_L("SITE "+x+" "+z+" y="+k.pos_y+" at="+k.pos_x+","+k.pos_z+" up="+r.a4);
}
void _d62(float x,float z){_d30(x,z);_d30(x+15,z);_d30(x-15,z);_d30(x,z+15);_d30(x,z-15);}
void main(){
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
_k5(tp);_d31(uint64(ZL|ZR|DUP));
for(uint f=0;f<165;f++)_d31(0);
_d62(-250,-60);_d62(-200,-90);_d62(-300,-90);_d62(-250,-110);_d62(-150,-60);_d62(-350,-60);
_L("SITE done");
while(true)sleep(1);
}
