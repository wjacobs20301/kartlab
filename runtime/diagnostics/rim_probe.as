float _pf(ptr_t p){return ptr_deref_float(p);}
uint64 _pq(ptr_t p){return ptr_deref_u64(p);}
u32 _pu(ptr_t p){return ptr_deref_u32(p);}
void _pw(ptr_t p,float v){ptr_write_float(p,v);}
ptr_t _pa(ActorBase@a){return ptr_from_ActorBase(a);}
void _L(const string&in s){sys::debugLog(s);}
ptr_t _k16=0;
uint _k17=0xffffffff;
float _k18=0;
bool _k19=false;
bool _k20=false;float _d19=0,_w15=0;
float _d26=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d7=false;
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t _d10=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(_d10==0)return 0;
uint op=_pu(_d10);if((op&0xfc000000)!=0x94000000)return 0;
int64 _d5=int64(op&0x03ffffff);if((op&0x02000000)!=0)_d5-=0x04000000;
ptr_t _d27=ptr_t(int64(_d10)+_d5*4);
if(_pu(_d27)!=0xf0001382||_pu(_d27+4)!=0xa9be7bfd)return 0;
ptr_t _d2=_d27-0x65b80;if((_d2&0xfff)!=0)return 0;return _d2+0x3d90b8;
}
void _k13(){ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_k18=0;_k19=false;_k20=false;_d19=0;_w15=0;_d7=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d24=_pu(_k16+0x24);if(_d24<2||_d24>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d11,uint _k27){
if(_d11 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d11);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d24=_pu(p+0x24);
return _d24>=2&&_d24<=6;
}
bool _k0(ActorBase@_d11,uint _k27){
if(Player is null||!_k1(_d11,_k27))return false;
ptr_t _d0=_pa(_d11),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d4=_pu(_d0+0x220);ptr_t _d14=_pq(_d0+0x228);
if(_d4<=129||_d4>512||!_k2(_d14))return false;
ptr_t _d3=_pq(_d14+0x408);
if(!_k2(_d3))return false;
uint _d23=_pu(_d3+0x20);ptr_t _k29=_pq(_d3+0x28);
if(_d23!=1||!_k2(_k29))return false;
ptr_t _d21=_pq(_k29);
if(!_k2(_d21))return false;
uint _d22=_pu(_d21+0x10),flags=_pu(_d21+0x18);
float _k33=_pf(_d21+0x74);
if(_d22!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d21+8),_k28=_pq(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(_pu(_k28+0x48)!=_k30||_pq(_k28+0x40)!=_w22)return false;
return _k1(_d11,_k27)&&_pu(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d19=a.pos_x;_w15=a.pos_z;return;}
float dx=_d19-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d19=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@_d17=_k7();
if(_k15(_d17)){TextWriter::toast(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d13=sqrt(fx*fx+fz*fz);if(_d13<0.1f)return;fx/=_d13;fz/=_d13;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d17!is null){_k10(_d17);_d17.setPos(x,y,z);@_d17=null;_d19=0;_w15=0;_d7=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);_k17=_pu(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d19=a.pos_x;_w15=a.pos_z;
TextWriter::toast(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();TextWriter::toast(150,"KartLab: spawn unavailable.\n");
}
ptr_t _d28(ActorBase@a){
ptr_t _d14=_pq(_pa(a)+0x228);if(!_k2(_d14))return 0;
ptr_t mc=_pq(_d14+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(_pf(b+120)-0.728f)>0.002f||abs(_pf(b+216)+0.728f)>0.002f||abs(_pf(b+312)-0.7776f)>0.002f||abs(_pf(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _d29(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,0);_pw(t+8,-sd);
_pw(t+16,sd*sp);_pw(t+20,cp);_pw(t+24,cd*sp);
_pw(t+32,sd*cp);_pw(t+36,-sp);_pw(t+40,cd*cp);
}
void _d1(ActorBase@a){
if(a is null){_d7=false;return;}
Matrix33f r=a.rot;float _d13=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d7&&_d13>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d13;}
_w4=x;_w5=z;_d7=true;
_w2+=ds/0.28328f;_w3+=ds/0.3683f;
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(-_d26*0.45f-_w1)*0.25f;
ptr_t b=_d28(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d29(b+72,sf,cf,sd,cd);_d29(b+168,sf,cf,sd,cd);
_d29(b+264,sr,cr,0,1);_d29(b+360,sr,cr,0,1);
}
void _k12(int ix,int iy){
_d26=0;
ActorBase@a=_k7();bool _d20=_k15(a);
if(_d20!=_k19){_L("KART mounted="+_d20);_k18=0;_k19=_d20;_k20=!_d20;if(a!is null){_d19=a.pos_x;_w15=a.pos_z;}}
if(!_d20||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_k18=0;return;}
float _d25=float(ix)/32768.0f,_w10=float(iy)/32768.0f;
if(abs(_d25)<0.15f)_d25=0;if(abs(_w10)<0.15f)_w10=0;
_d26=_d25;
float _d27=_w10*(_w10<0?1.0f:2.5f),_w11=_d27-_k18,_w12=_w10==0?0.08f:0.045f;
if(_w11>_w12)_w11=_w12;if(_w11<-_w12)_w11=-_w12;_k18+=_w11;
Matrix33f r=a.rot;float _d13=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d13<0.1f||r.a4<0.4f){_k10(a);_k18=0;return;}
Vector3f v=b.vel;b.setVel(r.a2*_k18/_d13,v.y,r.a8*_k18/_d13);
b.setAngularVel(-r.a7*2.0f,-_d25*0.45f*(_k18/2.5f),r.a1*2.0f);
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
_L("KART ready");
}
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
void _k5(ptr_t _d18){
if(!_k4()){
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;return;
}
_k26=false;uint64 _d8=_pq(_d18),mask=uint64(ZL|ZR|DUP);
if((_d8&mask)==0)_k24=false;
if(!_k24&&(_d8&mask)==mask){_k24=true;_k25=true;_L("KART spawn queued");}
if(!_k3())return;
if(_k25&&(_d8&mask)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(ptr_deref_s32(_d18+8),ptr_deref_s32(_d18+12));
_d1(_k7());
}
void _k11(ptr_t _d18){while(true){_k5(_d18);sleep(1);}}
ptr_t tp=0,hjRec=0;
bool _d16(float a,float b){return a>b-0.003f&&a<b+0.003f;}
ptr_t _d12(){
ActorBase@a=_k7();if(a is null)return 0;
ptr_t _d14=_pq(_pa(a)+0x228);if(!_k2(_d14))return 0;
ptr_t mc=_pq(_d14+0x10);if(!_k2(mc))return 0;
return _pq(mc+0x28);
}
void _d6(){
ptr_t m=_d12();if(!_k2(m))return;
for(uint o=0;o<0x3000;o+=4){
ptr_t s=m+o;
if(_d16(_pf(s+52),0.3766f)&&_d16(_pf(s+48),0)&&_d16(_pf(s+56),0)
&&_d16(_pf(s+148),0.5966f)&&_d16(_pf(s+152),0.4928f)){
hjRec=s+96;_L("HANDLE found sklRec=host+"+o+" hj=host+"+(o+96));return;
}
}
_L("HANDLE not-found");
}
void _d15(const string&in l){
if(hjRec==0)return;
_L("HANDLE "+l+" r0="+_pf(hjRec)+","+_pf(hjRec+4)+","+_pf(hjRec+8)
+" r1="+_pf(hjRec+16)+","+_pf(hjRec+20)+","+_pf(hjRec+24)
+" r2="+_pf(hjRec+32)+","+_pf(hjRec+36)+","+_pf(hjRec+40)
+" t="+_pf(hjRec+48)+","+_pf(hjRec+52)+","+_pf(hjRec+56));
}
void _d9(uint n,int x,int y,const string&in l){
for(uint f=0;f<n&&_k3();f++){input(1,0,x,y);_k5(tp);}
_L("HANDLE at "+l);
_d15(l);
}
void main(){
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
_k5(tp);input(1,uint64(ZL|ZR|DUP));_k5(tp);
for(uint f=0;f<165;f++){input(1,0);_k5(tp);}
_d6();_d15("unmounted");
input(1,1);input(90,0);
if(!_k15(_k7())){_L("HANDLE mount failed");return;}
_d9(45,0,0,"neutral");_d9(45,32767,0,"right");_d9(45,-32767,0,"left");_d9(45,0,32767,"forward");_d9(30,0,0,"neutral2");
_L("HANDLE camera");
for(uint f=0;f<70&&_k3();f++){input(1,0,0,0,32767,0);_k5(tp);}
_L("HANDLE visual");
while(true){_d9(90,32767,0,"vright");_d9(90,0,0,"vneutral");_d9(90,-32767,0,"vleft");_d9(90,0,0,"vneutral");}
_L("HANDLE done");
while(true){input(1,0);_k5(tp);}
}
