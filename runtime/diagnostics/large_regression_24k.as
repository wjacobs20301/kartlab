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
bool _k20=false;float _d16=0,_w15=0;
float _d25=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _d8=false;
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
void _k13(){ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_k18=0;_k19=false;_k20=false;_d16=0;_w15=0;_d8=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||_pa(a)!=_k16)return null;
if(_pu(_k16+0x10)!=_k17)return null;
uint _d23=_pu(_k16+0x24);if(_d23<2||_d23>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@_d11,uint _k27){
if(_d11 is null||_k27==0xffffffff)return false;
ptr_t p=_pa(_d11);
if(!_k2(p)||_pu(p+0x10)!=_k27)return false;
uint _d23=_pu(p+0x24);
return _d23>=2&&_d23<=6;
}
bool _k0(ActorBase@_d11,uint _k27){
if(Player is null||!_k1(_d11,_k27))return false;
ptr_t _d0=_pa(_d11),_w22=_pa(Player);
if(!_k2(_w22))return false;
uint _k30=_pu(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=_pu(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _d4=_pu(_d0+0x220);ptr_t _d13=_pq(_d0+0x228);
if(_d4<=129||_d4>512||!_k2(_d13))return false;
ptr_t _d3=_pq(_d13+0x408);
if(!_k2(_d3))return false;
uint _d22=_pu(_d3+0x20);ptr_t _k29=_pq(_d3+0x28);
if(_d22!=1||!_k2(_k29))return false;
ptr_t _d20=_pq(_k29);
if(!_k2(_d20))return false;
uint _d21=_pu(_d20+0x10),flags=_pu(_d20+0x18);
float _k33=_pf(_d20+0x74);
if(_d21!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=_pq(_d20+8),_k28=_pq(_w22+0x1a8);
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
if((_pq(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_d16=a.pos_x;_w15=a.pos_z;return;}
float dx=_d16-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_d16=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@_d14=_k7();
if(_k15(_d14)){TextWriter::toast(150,"K");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_d12=sqrt(fx*fx+fz*fz);if(_d12<0.1f)return;fx/=_d12;fz/=_d12;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(_d14!is null){_k10(_d14);_d14.setPos(x,y,z);@_d14=null;_d16=0;_w15=0;_d8=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=_pa(a);_k17=_pu(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_d16=a.pos_x;_w15=a.pos_z;
TextWriter::toast(240,"K");
_L("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();TextWriter::toast(150,"K");
}
ptr_t _d28(ActorBase@a){
ptr_t _d13=_pq(_pa(a)+0x228);if(!_k2(_d13))return 0;
ptr_t mc=_pq(_d13+0x10);if(!_k2(mc))return 0;
ptr_t m=_pq(mc+0x28);if(!_k2(m))return 0;
ptr_t x=_pq(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=_pq(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(_pf(b+28)-0.3766f)>0.002f||abs(_pf(b+120)-0.728f)>0.002f||abs(_pf(b+216)+0.728f)>0.002f||abs(_pf(b+312)-0.7776f)>0.002f||abs(_pf(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _d29(ptr_t t,float sp,float cp,float sd,float cd){
_pw(t,cd);_pw(t+4,sd*sp);_pw(t+8,sd*cp);
_pw(t+16,0);_pw(t+20,cp);_pw(t+24,-sp);
_pw(t+32,-sd);_pw(t+36,cd*sp);_pw(t+40,cd*cp);
}
void _d1(ActorBase@a){
if(a is null){_d8=false;return;}
Matrix33f r=a.rot;float _d12=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_d8&&_d12>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_d12;}
_w4=x;_w5=z;_d8=true;
_w2+=ds/0.28328f;_w3+=ds/0.3683f;
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(_d25*0.45f-_w1)*0.25f;
ptr_t b=_d28(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_d29(b+72,sf,cf,sd,cd);_d29(b+168,sf,cf,sd,cd);
_d29(b+264,sr,cr,0,1);_d29(b+360,sr,cr,0,1);
}
void _k12(int ix,int iy){
_d25=0;
ActorBase@a=_k7();bool _d18=_k15(a);
if(_d18!=_k19){_L("KART mounted="+_d18);_k18=0;_k19=_d18;_k20=!_d18;if(a!is null){_d16=a.pos_x;_w15=a.pos_z;}}
if(!_d18||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_k18=0;return;}
float _d24=float(ix)/32768.0f,_w10=float(iy)/32768.0f;
if(abs(_d24)<0.15f)_d24=0;if(abs(_w10)<0.15f)_w10=0;
_d25=_d24;
float _d27=_w10*(_w10<0?1.0f:2.5f),_w11=_d27-_k18,_w12=_w10==0?0.08f:0.045f;
if(_w11>_w12)_w11=_w12;if(_w11<-_w12)_w11=-_w12;_k18+=_w11;
Matrix33f r=a.rot;float _d12=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_d12<0.1f||r.a4<0.4f){_k10(a);_k18=0;return;}
Vector3f v=b.vel;b.setVel(r.a2*_k18/_d12,v.y,r.a8*_k18/_d12);
b.setAngularVel(-r.a7*2.0f,_d24*0.45f*(_k18/2.5f),r.a1*2.0f);
}
void _k14(){
tas::doBlockOnLoadingPause(false);
for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
_L("KART ready");
}
bool _k24=true,_k25=false,_k26=false;
uint _k23=0;
void _k5(ptr_t _d15){
if(!_k4()){
if(!_k26){_k13();_k26=true;}
_k24=true;_k25=false;_k23=0;return;
}
_k26=false;uint64 _d9=_pq(_d15),mask=uint64(ZL|ZR|DUP);
if((_d9&mask)==0)_k24=false;
if(!_k24&&(_d9&mask)==mask){_k24=true;_k25=true;_L("KART spawn queued");}
if(!_k3())return;
if(_k25&&(_d9&mask)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(ptr_deref_s32(_d15+8),ptr_deref_s32(_d15+12));
_d1(_k7());
}
void _k11(ptr_t _d15){while(true){_k5(_d15);sleep(1);}}
ptr_t tp=0;
void _d19(const string&in _d17){
ActorBase@a=_k7();if(a is null)return;
Matrix33f r=a.rot;
_L("DRIVE "+_d17+" pos="+a.pos_x+","+a.pos_y+","+a.pos_z+" up="+r.a4+" heading="+r.a2+","+r.a8+" mounted="+_k15(a)+" speed="+_k18+" pad="+ptr_deref_s32(tp+8)+","+ptr_deref_s32(tp+12)+" w="+(_d28(a)!=0)+","+_w2+","+_w1);
}
void _d26(uint n,uint64 k,int x,int y,const string&in l,uint _d6){
for(uint f=0;f<n&&_k3();f++){input(1,k,x,y);k=0;_k5(tp);if(_d6>0&&f%_d6==0)_d19(l+f);}
}
void main(){_bigTail();
_k14();tp=_k6();if(tp==0)return;
input(180,0);
for(uint n=0;n<35&&!(_k3()&&Player.pos_x<-100&&Player.pos_x>-400);n++){input(1,1);input(90,0);}
input(60,0);if(!_k3())return;
_k5(tp);_d26(166,uint64(ZL|ZR|DUP),0,0,"",0);
_d19("beforeA");input(1,1);input(90,0);_d19("afterA");
if(!_k15(_k7()))return;
for(uint _d17=0;_d17<6;_d17++){
uint _d7=_d17==0?180:_d17==2?60:_d17==4?90:120;
int x=_d17==1?24000:_d17==4?-24000:0;
int y=_d17%3==2?0:_d17==3?-32767:32767;
_d26(_d7,0,x,y,"p"+_d17+"f",30);_d19("end"+_d17);
}
_d26(61,2,0,0,"",0);_d19("afterB");
_d26(90,0,0,32767,"",0);_d19("unmountedEnd");_d19("parkStart");
_d26(180,0,0,0,"",0);_d19("parkEnd");
_L("DRIVE finished");input(1,0);_k11(tp);
}
float _bigPad0(float v){return v*1.0001+0.5;}// padding 00000
float _bigPad1(float v){return v*1.0001+1.5;}// padding 00001
float _bigPad2(float v){return v*1.0001+2.5;}// padding 00002
float _bigPad3(float v){return v*1.0001+3.5;}// padding 00003
float _bigPad4(float v){return v*1.0001+4.5;}// padding 00004
float _bigPad5(float v){return v*1.0001+5.5;}// padding 00005
float _bigPad6(float v){return v*1.0001+6.5;}// padding 00006
float _bigPad7(float v){return v*1.0001+7.5;}// padding 00007
float _bigPad8(float v){return v*1.0001+8.5;}// padding 00008
float _bigPad9(float v){return v*1.0001+9.5;}// padding 00009
float _bigPad10(float v){return v*1.0001+10.5;}// padding 00010
float _bigPad11(float v){return v*1.0001+11.5;}// padding 00011
float _bigPad12(float v){return v*1.0001+12.5;}// padding 00012
float _bigPad13(float v){return v*1.0001+13.5;}// padding 00013
float _bigPad14(float v){return v*1.0001+14.5;}// padding 00014
float _bigPad15(float v){return v*1.0001+15.5;}// padding 00015
float _bigPad16(float v){return v*1.0001+16.5;}// padding 00016
float _bigPad17(float v){return v*1.0001+17.5;}// padding 00017
float _bigPad18(float v){return v*1.0001+18.5;}// padding 00018
float _bigPad19(float v){return v*1.0001+19.5;}// padding 00019
float _bigPad20(float v){return v*1.0001+20.5;}// padding 00020
float _bigPad21(float v){return v*1.0001+21.5;}// padding 00021
float _bigPad22(float v){return v*1.0001+22.5;}// padding 00022
float _bigPad23(float v){return v*1.0001+23.5;}// padding 00023
float _bigPad24(float v){return v*1.0001+24.5;}// padding 00024
float _bigPad25(float v){return v*1.0001+25.5;}// padding 00025
float _bigPad26(float v){return v*1.0001+26.5;}// padding 00026
float _bigPad27(float v){return v*1.0001+27.5;}// padding 00027
float _bigPad28(float v){return v*1.0001+28.5;}// padding 00028
float _bigPad29(float v){return v*1.0001+29.5;}// padding 00029
float _bigPad30(float v){return v*1.0001+30.5;}// padding 00030
float _bigPad31(float v){return v*1.0001+31.5;}// padding 00031
float _bigPad32(float v){return v*1.0001+32.5;}// padding 00032
float _bigPad33(float v){return v*1.0001+33.5;}// padding 00033
float _bigPad34(float v){return v*1.0001+34.5;}// padding 00034
float _bigPad35(float v){return v*1.0001+35.5;}// padding 00035
float _bigPad36(float v){return v*1.0001+36.5;}// padding 00036
float _bigPad37(float v){return v*1.0001+37.5;}// padding 00037
float _bigPad38(float v){return v*1.0001+38.5;}// padding 00038
float _bigPad39(float v){return v*1.0001+39.5;}// padding 00039
float _bigPad40(float v){return v*1.0001+40.5;}// padding 00040
float _bigPad41(float v){return v*1.0001+41.5;}// padding 00041
float _bigPad42(float v){return v*1.0001+42.5;}// padding 00042
float _bigPad43(float v){return v*1.0001+43.5;}// padding 00043
float _bigPad44(float v){return v*1.0001+44.5;}// padding 00044
float _bigPad45(float v){return v*1.0001+45.5;}// padding 00045
float _bigPad46(float v){return v*1.0001+46.5;}// padding 00046
float _bigPad47(float v){return v*1.0001+47.5;}// padding 00047
float _bigPad48(float v){return v*1.0001+48.5;}// padding 00048
float _bigPad49(float v){return v*1.0001+49.5;}// padding 00049
float _bigPad50(float v){return v*1.0001+50.5;}// padding 00050
float _bigPad51(float v){return v*1.0001+51.5;}// padding 00051
float _bigPad52(float v){return v*1.0001+52.5;}// padding 00052
float _bigPad53(float v){return v*1.0001+53.5;}// padding 00053
float _bigPad54(float v){return v*1.0001+54.5;}// padding 00054
float _bigPad55(float v){return v*1.0001+55.5;}// padding 00055
float _bigPad56(float v){return v*1.0001+56.5;}// padding 00056
float _bigPad57(float v){return v*1.0001+57.5;}// padding 00057
float _bigPad58(float v){return v*1.0001+58.5;}// padding 00058
float _bigPad59(float v){return v*1.0001+59.5;}// padding 00059
float _bigPad60(float v){return v*1.0001+60.5;}// padding 00060
float _bigPad61(float v){return v*1.0001+61.5;}// padding 00061
float _bigPad62(float v){return v*1.0001+62.5;}// padding 00062
float _bigPad63(float v){return v*1.0001+63.5;}// padding 00063
float _bigPad64(float v){return v*1.0001+64.5;}// padding 00064
float _bigPad65(float v){return v*1.0001+65.5;}// padding 00065
float _bigPad66(float v){return v*1.0001+66.5;}// padding 00066
float _bigPad67(float v){return v*1.0001+67.5;}// padding 00067
float _bigPad68(float v){return v*1.0001+68.5;}// padding 00068
float _bigPad69(float v){return v*1.0001+69.5;}// padding 00069
float _bigPad70(float v){return v*1.0001+70.5;}// padding 00070
float _bigPad71(float v){return v*1.0001+71.5;}// padding 00071
float _bigPad72(float v){return v*1.0001+72.5;}// padding 00072
float _bigPad73(float v){return v*1.0001+73.5;}// padding 00073
float _bigPad74(float v){return v*1.0001+74.5;}// padding 00074
float _bigPad75(float v){return v*1.0001+75.5;}// padding 00075
float _bigPad76(float v){return v*1.0001+76.5;}// padding 00076
float _bigPad77(float v){return v*1.0001+77.5;}// padding 00077
float _bigPad78(float v){return v*1.0001+78.5;}// padding 00078
float _bigPad79(float v){return v*1.0001+79.5;}// padding 00079
float _bigPad80(float v){return v*1.0001+80.5;}// padding 00080
float _bigPad81(float v){return v*1.0001+81.5;}// padding 00081
float _bigPad82(float v){return v*1.0001+82.5;}// padding 00082
float _bigPad83(float v){return v*1.0001+83.5;}// padding 00083
float _bigPad84(float v){return v*1.0001+84.5;}// padding 00084
float _bigPad85(float v){return v*1.0001+85.5;}// padding 00085
float _bigPad86(float v){return v*1.0001+86.5;}// padding 00086
float _bigPad87(float v){return v*1.0001+87.5;}// padding 00087
float _bigPad88(float v){return v*1.0001+88.5;}// padding 00088
float _bigPad89(float v){return v*1.0001+89.5;}// padding 00089
float _bigPad90(float v){return v*1.0001+90.5;}// padding 00090
float _bigPad91(float v){return v*1.0001+91.5;}// padding 00091
float _bigPad92(float v){return v*1.0001+92.5;}// padding 00092
float _bigPad93(float v){return v*1.0001+93.5;}// padding 00093
float _bigPad94(float v){return v*1.0001+94.5;}// padding 00094
float _bigPad95(float v){return v*1.0001+95.5;}// padding 00095
float _bigPad96(float v){return v*1.0001+96.5;}// padding 00096
float _bigPad97(float v){return v*1.0001+97.5;}// padding 00097
float _bigPad98(float v){return v*1.0001+98.5;}// padding 00098
float _bigPad99(float v){return v*1.0001+99.5;}// padding 00099
float _bigPad100(float v){return v*1.0001+100.5;}// padding 00100
float _bigPad101(float v){return v*1.0001+101.5;}// padding 00101
float _bigPad102(float v){return v*1.0001+102.5;}// padding 00102
float _bigPad103(float v){return v*1.0001+103.5;}// padding 00103
float _bigPad104(float v){return v*1.0001+104.5;}// padding 00104
float _bigPad105(float v){return v*1.0001+105.5;}// padding 00105
float _bigPad106(float v){return v*1.0001+106.5;}// padding 00106
float _bigPad107(float v){return v*1.0001+107.5;}// padding 00107
float _bigPad108(float v){return v*1.0001+108.5;}// padding 00108
float _bigPad109(float v){return v*1.0001+109.5;}// padding 00109
float _bigPad110(float v){return v*1.0001+110.5;}// padding 00110
float _bigPad111(float v){return v*1.0001+111.5;}// padding 00111
float _bigPad112(float v){return v*1.0001+112.5;}// padding 00112
float _bigPad113(float v){return v*1.0001+113.5;}// padding 00113
float _bigPad114(float v){return v*1.0001+114.5;}// padding 00114
float _bigPad115(float v){return v*1.0001+115.5;}// padding 00115
float _bigPad116(float v){return v*1.0001+116.5;}// padding 00116
float _bigPad117(float v){return v*1.0001+117.5;}// padding 00117
float _bigPad118(float v){return v*1.0001+118.5;}// padding 00118
float _bigPad119(float v){return v*1.0001+119.5;}// padding 00119
float _bigPad120(float v){return v*1.0001+120.5;}// padding 00120
float _bigPad121(float v){return v*1.0001+121.5;}// padding 00121
float _bigPad122(float v){return v*1.0001+122.5;}// padding 00122
float _bigPad123(float v){return v*1.0001+123.5;}// padding 00123
float _bigPad124(float v){return v*1.0001+124.5;}// padding 00124
float _bigPad125(float v){return v*1.0001+125.5;}// padding 00125
float _bigPad126(float v){return v*1.0001+126.5;}// padding 00126
float _bigPad127(float v){return v*1.0001+127.5;}// padding 00127
float _bigPad128(float v){return v*1.0001+128.5;}// padding 00128
float _bigPad129(float v){return v*1.0001+129.5;}// padding 00129
float _bigPad130(float v){return v*1.0001+130.5;}// padding 00130
float _bigPad131(float v){return v*1.0001+131.5;}// padding 00131
float _bigPad132(float v){return v*1.0001+132.5;}// padding 00132
float _bigPad133(float v){return v*1.0001+133.5;}// padding 00133
float _bigPad134(float v){return v*1.0001+134.5;}// padding 00134
float _bigPad135(float v){return v*1.0001+135.5;}// padding 00135
float _bigPad136(float v){return v*1.0001+136.5;}// padding 00136
float _bigPad137(float v){return v*1.0001+137.5;}// padding 00137
float _bigPad138(float v){return v*1.0001+138.5;}// padding 00138
float _bigPad139(float v){return v*1.0001+139.5;}// padding 00139
float _bigPad140(float v){return v*1.0001+140.5;}// padding 00140
float _bigPad141(float v){return v*1.0001+141.5;}// padding 00141
float _bigPad142(float v){return v*1.0001+142.5;}// padding 00142
float _bigPad143(float v){return v*1.0001+143.5;}// padding 00143
float _bigPad144(float v){return v*1.0001+144.5;}// padding 00144
float _bigPad145(float v){return v*1.0001+145.5;}// padding 00145
float _bigPad146(float v){return v*1.0001+146.5;}// padding 00146
float _bigPad147(float v){return v*1.0001+147.5;}// padding 00147
float _bigPad148(float v){return v*1.0001+148.5;}// padding 00148
float _bigPad149(float v){return v*1.0001+149.5;}// padding 00149
float _bigPad150(float v){return v*1.0001+150.5;}// padding 00150
float _bigPad151(float v){return v*1.0001+151.5;}// padding 00151
float _bigPad152(float v){return v*1.0001+152.5;}// padding 00152
float _bigPad153(float v){return v*1.0001+153.5;}// padding 00153
float _bigPad154(float v){return v*1.0001+154.5;}// padding 00154
float _bigPad155(float v){return v*1.0001+155.5;}// padding 00155
float _bigPad156(float v){return v*1.0001+156.5;}// padding 00156
float _bigPad157(float v){return v*1.0001+157.5;}// padding 00157
float _bigPad158(float v){return v*1.0001+158.5;}// padding 00158
float _bigPad159(float v){return v*1.0001+159.5;}// padding 00159
float _bigPad160(float v){return v*1.0001+160.5;}// padding 00160
float _bigPad161(float v){return v*1.0001+161.5;}// padding 00161
float _bigPad162(float v){return v*1.0001+162.5;}// padding 00162
float _bigPad163(float v){return v*1.0001+163.5;}// padding 00163
float _bigPad164(float v){return v*1.0001+164.5;}// padding 00164
float _bigPad165(float v){return v*1.0001+165.5;}// padding 00165
float _bigPad166(float v){return v*1.0001+166.5;}// padding 00166
float _bigPad167(float v){return v*1.0001+167.5;}// padding 00167
float _bigPad168(float v){return v*1.0001+168.5;}// padding 00168
float _bigPad169(float v){return v*1.0001+169.5;}// padding 00169
float _bigPad170(float v){return v*1.0001+170.5;}// padding 00170
float _bigPad171(float v){return v*1.0001+171.5;}// padding 00171
float _bigPad172(float v){return v*1.0001+172.5;}// padding 00172
float _bigPad173(float v){return v*1.0001+173.5;}// padding 00173
float _bigPad174(float v){return v*1.0001+174.5;}// padding 00174
float _bigPad175(float v){return v*1.0001+175.5;}// padding 00175
float _bigPad176(float v){return v*1.0001+176.5;}// padding 00176
float _bigPad177(float v){return v*1.0001+177.5;}// padding 00177
float _bigPad178(float v){return v*1.0001+178.5;}// padding 00178
float _bigPad179(float v){return v*1.0001+179.5;}// padding 00179
float _bigPad180(float v){return v*1.0001+180.5;}// padding 00180
float _bigPad181(float v){return v*1.0001+181.5;}// padding 00181
float _bigPad182(float v){return v*1.0001+182.5;}// padding 00182
float _bigPad183(float v){return v*1.0001+183.5;}// padding 00183
float _bigPad184(float v){return v*1.0001+184.5;}// padding 00184
float _bigPad185(float v){return v*1.0001+185.5;}// padding 00185
float _bigPad186(float v){return v*1.0001+186.5;}// padding 00186
float _bigPad187(float v){return v*1.0001+187.5;}// padding 00187
float _bigPad188(float v){return v*1.0001+188.5;}// padding 00188
float _bigPad189(float v){return v*1.0001+189.5;}// padding 00189
float _bigPad190(float v){return v*1.0001+190.5;}// padding 00190
float _bigPad191(float v){return v*1.0001+191.5;}// padding 00191
float _bigPad192(float v){return v*1.0001+192.5;}// padding 00192
float _bigPad193(float v){return v*1.0001+193.5;}// padding 00193
float _bigPad194(float v){return v*1.0001+194.5;}// padding 00194
float _bigPad195(float v){return v*1.0001+195.5;}// padding 00195
float _bigPad196(float v){return v*1.0001+196.5;}// padding 00196
float _bigPad197(float v){return v*1.0001+197.5;}// padding 00197
float _bigPad198(float v){return v*1.0001+198.5;}// padding 00198
float _bigPad199(float v){return v*1.0001+199.5;}// padding 00199
float _bigPad200(float v){return v*1.0001+200.5;}// padding 00200
float _bigPad201(float v){return v*1.0001+201.5;}// padding 00201
float _bigPad202(float v){return v*1.0001+202.5;}// padding 00202
float _bigPad203(float v){return v*1.0001+203.5;}// padding 00203
float _bigPad204(float v){return v*1.0001+204.5;}// padding 00204
float _bigPad205(float v){return v*1.0001+205.5;}// padding 00205
float _bigPad206(float v){return v*1.0001+206.5;}// padding 00206
float _bigPad207(float v){return v*1.0001+207.5;}// padding 00207
float _bigPad208(float v){return v*1.0001+208.5;}// padding 00208
float _bigPad209(float v){return v*1.0001+209.5;}// padding 00209
float _bigPad210(float v){return v*1.0001+210.5;}// padding 00210
float _bigPad211(float v){return v*1.0001+211.5;}// padding 00211
float _bigPad212(float v){return v*1.0001+212.5;}// padding 00212
float _bigPad213(float v){return v*1.0001+213.5;}// padding 00213
float _bigPad214(float v){return v*1.0001+214.5;}// padding 00214
float _bigPad215(float v){return v*1.0001+215.5;}// padding 00215
float _bigPad216(float v){return v*1.0001+216.5;}// padding 00216
float _bigPad217(float v){return v*1.0001+217.5;}// padding 00217
float _bigPad218(float v){return v*1.0001+218.5;}// padding 00218
float _bigPad219(float v){return v*1.0001+219.5;}// padding 00219
float _bigPad220(float v){return v*1.0001+220.5;}// padding 00220
float _bigPad221(float v){return v*1.0001+221.5;}// padding 00221
float _bigPad222(float v){return v*1.0001+222.5;}// padding 00222
float _bigPad223(float v){return v*1.0001+223.5;}// padding 00223
float _bigPad224(float v){return v*1.0001+224.5;}// padding 00224
float _bigPad225(float v){return v*1.0001+225.5;}// padding 00225
float _bigPad226(float v){return v*1.0001+226.5;}// padding 00226
float _bigPad227(float v){return v*1.0001+227.5;}// padding 00227
float _bigPad228(float v){return v*1.0001+228.5;}// padding 00228
float _bigPad229(float v){return v*1.0001+229.5;}// padding 00229
float _bigPad230(float v){return v*1.0001+230.5;}// padding 00230
float _bigPad231(float v){return v*1.0001+231.5;}// padding 00231
float _bigPad232(float v){return v*1.0001+232.5;}// padding 00232
float _bigPad233(float v){return v*1.0001+233.5;}// padding 00233
float _bigPad234(float v){return v*1.0001+234.5;}// padding 00234
float _bigPad235(float v){return v*1.0001+235.5;}// padding 00235
float _bigPad236(float v){return v*1.0001+236.5;}// padding 00236
float _bigPad237(float v){return v*1.0001+237.5;}// padding 00237
float _bigPad238(float v){return v*1.0001+238.5;}// padding 00238
float _bigPad239(float v){return v*1.0001+239.5;}// padding 00239
float _bigPad240(float v){return v*1.0001+240.5;}// padding 00240
float _bigPad241(float v){return v*1.0001+241.5;}// padding 00241
void _bigTail(){float s=_bigPad0(1);s=_bigPad241(s);sys::debugLog("LARGESCRIPT regression tail ok bytes=24061 s="+s);}
