ptr_t _k16=0;
uint _k17=0xffffffff;
float _k18=0;
bool _k19=false;
bool _k20=false;float parkX=0,parkZ=0;
bool _k4(){return Player !is null && !pause::isPauseRequest("LoadingPause") && abs(Player.pos_x)<100000 && abs(Player.pos_y)<100000 && abs(Player.pos_z)<100000;}
bool _k3(){return _k4() && !pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(hook==0)return 0;
uint op=ptr_deref_u32(hook);if((op&0xfc000000)!=0x94000000)return 0;
int64 delta=int64(op&0x03ffffff);if((op&0x02000000)!=0)delta-=0x04000000;
ptr_t target=ptr_t(int64(hook)+delta*4);
if(ptr_deref_u32(target)!=0xf0001382 || ptr_deref_u32(target+4)!=0xa9be7bfd)return 0;
ptr_t base=target-0x65b80;if((base&0xfff)!=0)return 0;return base+0x3d90b8;
}
void _k13(){ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_k18=0;_k19=false;_k20=false;parkX=0;parkZ=0;}
ActorBase@ _k7(){
if(!_k3() || _k16==0)return null;
ActorBase@ a=ActorWatcher::get(2);if(a is null || ptr_from_ActorBase(a)!=_k16)return null;
if(ptr_deref_u32(_k16+0x10)!=_k17)return null;
uint state=ptr_deref_u32(_k16+0x24);if(state<2 || state>6)return null;
return a;
}
bool _k2(ptr_t p) {
return p>=0x10000 && p<0x100000000000 && (p&7)==0;
}
bool _k1(ActorBase@ host,uint _k27) {
if(host is null || _k27==0xffffffff)return false;
ptr_t p=ptr_from_ActorBase(host);
if(!_k2(p) || ptr_deref_u32(p+0x10)!=_k27)return false;
uint state=ptr_deref_u32(p+0x24);
return state>=2 && state<=6;
}
bool _k0(ActorBase@ host,uint _k27) {
if(Player is null || !_k1(host,_k27))return false;
ptr_t actor=ptr_from_ActorBase(host),player=ptr_from_ActorBase(Player);
if(!_k2(player))return false;
uint _k30=ptr_deref_u32(player+0x10);
if(_k30==0xffffffff)return false;
uint _k31=ptr_deref_u32(player+0x24);
if(_k31<2 || _k31>6)return false;
uint count=ptr_deref_u32(actor+0x220);ptr_t list=ptr_deref_u64(actor+0x228);
if(count<=129 || count>512 || !_k2(list))return false;
ptr_t component=ptr_deref_u64(list+0x408);
if(!_k2(component))return false;
uint seats=ptr_deref_u32(component+0x20);ptr_t _k29=ptr_deref_u64(component+0x28);
if(seats!=1 || !_k2(_k29))return false;
ptr_t seat=ptr_deref_u64(_k29);
if(!_k2(seat))return false;
uint seatID=ptr_deref_u32(seat+0x10),flags=ptr_deref_u32(seat+0x18);
float _k33=ptr_deref_float(seat+0x74);
if(seatID!=_k30 || flags==0 || !(_k33<=0 && _k33>=-1000))return false;
ptr_t _k32=ptr_deref_u64(seat+8),_k28=ptr_deref_u64(player+0x1a8);
if(_k32!=_k28 || !_k2(_k28))return false;
if(ptr_deref_u32(_k28+0x48)!=_k30 || ptr_deref_u64(_k28+0x40)!=player)return false;
return _k1(host,_k27) && ptr_deref_u32(player+0x10)==_k30;
}
bool _k15(ActorBase@ a){return _k3() && _k0(a,_k17);}
void _k10(ActorBase@ a){
if(a is null)return;RigidBody@ b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@ a){
RigidBody@ b=a.getMainRigidBody();if(b is null)return;
if((ptr_deref_u64(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){parkX=a.pos_x;parkZ=a.pos_z;return;}
float dx=parkX-a.pos_x,dz=parkZ-a.pos_z;
if(dx*dx+dz*dz>4){parkX=a.pos_x;parkZ=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx< -0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz< -0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@ old=_k7();
if(_k15(old)){TextWriter::toast(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,length=sqrt(fx*fx+fz*fz);if(length<0.1f)return;fx/=length;fz/=length;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(old !is null){_k10(old);old.setPos(x,y,z);@old=null;parkX=0;parkZ=0;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150 && _k3();f++){
ActorBase@ a=ActorWatcher::get(2);
if(a !is null){
_k16=ptr_from_ActorBase(a);_k17=ptr_deref_u32(_k16+0x10);
if(a.getMainRigidBody() !is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;parkX=a.pos_x;parkZ=a.pos_z;
TextWriter::toast(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
sys::debugLog("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();TextWriter::toast(150,"KartLab: spawn unavailable.\n");
}
void _k12(int ix,int iy){
ActorBase@ a=_k7();bool riding=_k15(a);
if(riding!=_k19){sys::debugLog("KART mounted="+riding);_k18=0;_k19=riding;_k20=!riding;if(a !is null){parkX=a.pos_x;parkZ=a.pos_z;}}
if(!riding || a is null){if(a !is null && _k20)_k9(a);return;}
if(abs(float(ix))>32768 || abs(float(iy))>32768){_k10(a);_k18=0;return;}
float steer=float(ix)/32768.0f,throttle=float(iy)/32768.0f;
if(abs(steer)<0.15f)steer=0;if(abs(throttle)<0.15f)throttle=0;
float target=throttle*(throttle<0?1.0f:2.5f),change=target-_k18,limit=throttle==0?0.08f:0.045f;
if(change>limit)change=limit;if(change< -limit)change= -limit;_k18+=change;
Matrix33f r=a.rot;float length=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@ b=a.getMainRigidBody();if(b is null)return;
if(length<0.1f || r.a4<0.4f){_k10(a);_k18=0;return;}
Vector3f v=b.vel;b.setVel(r.a2*_k18/length,v.y,r.a8*_k18/length);
b.setAngularVel(-r.a7*2.0f,steer*0.45f*(_k18/2.5f),r.a1*2.0f);
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
sys::debugLog("KART ready");
}
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
void _k5(ptr_t pad){
if(!_k4()){
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;return;
}
_k26=false;uint64 held=ptr_deref_u64(pad),mask=uint64(ZL|ZR|DUP);
if((held&mask)==0)_k24=false;
if(!_k24 && (held&mask)==mask){_k24=true;_k25=true;sys::debugLog("KART spawn queued");}
if(!_k3())return;
if(_k25 && (held&mask)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(ptr_deref_s32(pad+8),ptr_deref_s32(pad+12));
}
void _k11(ptr_t pad){while(true){_k5(pad);sleep(1);}}
ptr_t resolveModel(){
ActorBase@ k=_k7();if(k is null)return 0;
ptr_t list=ptr_deref_u64(ptr_from_ActorBase(k)+0x228);if(!_k2(list))return 0;
ptr_t mc=ptr_deref_u64(list+0x10);if(!_k2(mc))return 0;
ptr_t model=ptr_deref_u64(mc+0x28);if(!_k2(model))return 0;
return model;
}
void quat(ptr_t p){ptr_write_float(p,0);ptr_write_float(p+4,0.5f);ptr_write_float(p+8,0);ptr_write_float(p+12,0.866f);}
void main(){
_k14();ptr_t pad=_k6();if(pad==0){sys::debugLog("BONE pad-mismatch");while(true)sleep(1);}
input(180,0);
for(uint n=0;n<35;n++){
if(_k3() && Player.pos_x< -100 && Player.pos_x> -400 && Player.pos_y>50)break;
input(1,1);input(90,0);
}
input(60,0);if(!_k3()){sys::debugLog("BONE world-timeout");while(true)sleep(1);}
_k5(pad);input(1,uint64(ZL|ZR|DUP));_k5(pad);
for(uint f=0;f<165;f++){input(1,0);_k5(pad);}
sleep(120);
sys::debugLog("BONE rotating");
while(true){
ptr_t model=resolveModel();
if(model!=0){
ptr_t b=model+35280;
for(uint i=1;i<=4;i++)ptr_write_float(b+96*i+28,1.2f);
quat(b+96+4);
quat(b+192+80);
quat(b+288);
}
input(1,0);_k5(pad);
}
}
