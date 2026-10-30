ptr_t _k16=0;
uint _k17=0xffffffff;
float _k18=0;
bool _k19=false;
bool _k20=false;float _w14=0,_w15=0;
float _w0=0,_w1=0,_w2=0,_w3=0,_w4=0,_w5=0;bool _w6=false;
bool _k4(){return Player!is null&&!pause::isPauseRequest("LoadingPause")&&abs(Player.pos_x)<100000&&abs(Player.pos_y)<100000&&abs(Player.pos_z)<100000;}
bool _k3(){return _k4()&&!pause::isPauseTarget("Actor");}
ptr_t _k6(){
ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(hook==0)return 0;
uint op=ptr_deref_u32(hook);if((op&0xfc000000)!=0x94000000)return 0;
int64 _w28=int64(op&0x03ffffff);if((op&0x02000000)!=0)_w28-=0x04000000;
ptr_t _w23=ptr_t(int64(hook)+_w28*4);
if(ptr_deref_u32(_w23)!=0xf0001382||ptr_deref_u32(_w23+4)!=0xa9be7bfd)return 0;
ptr_t base=_w23-0x65b80;if((base&0xfff)!=0)return 0;return base+0x3d90b8;
}
void _k13(){ActorWatcher::clearSlot(2);_k16=0;_k17=0xffffffff;_k18=0;_k19=false;_k20=false;_w14=0;_w15=0;_w6=false;}
ActorBase@_k7(){
if(!_k3()||_k16==0)return null;
ActorBase@a=ActorWatcher::get(2);if(a is null||ptr_from_ActorBase(a)!=_k16)return null;
if(ptr_deref_u32(_k16+0x10)!=_k17)return null;
uint _w24=ptr_deref_u32(_k16+0x24);if(_w24<2||_w24>6)return null;
return a;
}
bool _k2(ptr_t p){
return p>=0x10000&&p<0x100000000000&&(p&7)==0;
}
bool _k1(ActorBase@host,uint _k27){
if(host is null||_k27==0xffffffff)return false;
ptr_t p=ptr_from_ActorBase(host);
if(!_k2(p)||ptr_deref_u32(p+0x10)!=_k27)return false;
uint _w24=ptr_deref_u32(p+0x24);
return _w24>=2&&_w24<=6;
}
bool _k0(ActorBase@host,uint _k27){
if(Player is null||!_k1(host,_k27))return false;
ptr_t actor=ptr_from_ActorBase(host),_w22=ptr_from_ActorBase(Player);
if(!_k2(_w22))return false;
uint _k30=ptr_deref_u32(_w22+0x10);
if(_k30==0xffffffff)return false;
uint _k31=ptr_deref_u32(_w22+0x24);
if(_k31<2||_k31>6)return false;
uint _w29=ptr_deref_u32(actor+0x220);ptr_t list=ptr_deref_u64(actor+0x228);
if(_w29<=129||_w29>512||!_k2(list))return false;
ptr_t _w21=ptr_deref_u64(list+0x408);
if(!_k2(_w21))return false;
uint _w27=ptr_deref_u32(_w21+0x20);ptr_t _k29=ptr_deref_u64(_w21+0x28);
if(_w27!=1||!_k2(_k29))return false;
ptr_t seat=ptr_deref_u64(_k29);
if(!_k2(seat))return false;
uint _w26=ptr_deref_u32(seat+0x10),flags=ptr_deref_u32(seat+0x18);
float _k33=ptr_deref_float(seat+0x74);
if(_w26!=_k30||flags==0||!(_k33<=0&&_k33>=-1000))return false;
ptr_t _k32=ptr_deref_u64(seat+8),_k28=ptr_deref_u64(_w22+0x1a8);
if(_k32!=_k28||!_k2(_k28))return false;
if(ptr_deref_u32(_k28+0x48)!=_k30||ptr_deref_u64(_k28+0x40)!=_w22)return false;
return _k1(host,_k27)&&ptr_deref_u32(_w22+0x10)==_k30;
}
bool _k15(ActorBase@a){return _k3()&&_k0(a,_k17);}
void _k10(ActorBase@a){
if(a is null)return;RigidBody@b=a.getMainRigidBody();if(b is null)return;
Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);
}
void _k9(ActorBase@a){
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if((ptr_deref_u64(ptr_from_RigidBody(b)+0x68)&0x40000000)!=0){_w14=a.pos_x;_w15=a.pos_z;return;}
float dx=_w14-a.pos_x,dz=_w15-a.pos_z;
if(dx*dx+dz*dz>4){_w14=a.pos_x;_w15=a.pos_z;dx=0;dz=0;}
float vx=dx*2,vz=dz*2;if(vx>0.5f)vx=0.5f;if(vx<-0.5f)vx=-0.5f;if(vz>0.5f)vz=0.5f;if(vz<-0.5f)vz=-0.5f;
Vector3f v=b.vel;Matrix33f r=a.rot;b.setVel(vx,v.y,vz);b.setAngularVel(-r.a7*2.0f,0,r.a1*2.0f);
}
void _k8(){
if(!_k3())return;
ActorBase@old=_k7();
if(_k15(old)){TextWriter::toast(150,"Dismount before recalling the kart.\n");return;}
Matrix33f r=Player.rot;float fx=r.a2,fz=r.a8,_w13=sqrt(fx*fx+fz*fz);if(_w13<0.1f)return;fx/=_w13;fz/=_w13;
float x=Player.pos_x+fx*2.0f,y=Player.pos_y+0.5f,z=Player.pos_z+fz*2.0f;
if(old!is null){_k10(old);old.setPos(x,y,z);@old=null;_w14=0;_w15=0;_w6=false;}
else{_k13();actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);}
for(uint f=0;f<150&&_k3();f++){
ActorBase@a=ActorWatcher::get(2);
if(a!is null){
_k16=ptr_from_ActorBase(a);_k17=ptr_deref_u32(_k16+0x10);
if(a.getMainRigidBody()!is null){
ActorWatcher::pauseSlot(2);@a=null;sleep(30);@a=_k7();if(a is null)return;a.setRot(fz,0,fx,0,1,0,-fx,0,fz);_k10(a);_k20=true;_w14=a.pos_x;_w15=a.pos_z;
TextWriter::toast(240,"Kart ready: approach and press A. Left stick drives; B dismounts.\n");
sys::debugLog("KART ready id="+_k17);return;
}
}
@a=null;sleep(1);
}
_k13();TextWriter::toast(150,"KartLab: spawn unavailable.\n");
}
ptr_t _w7(ActorBase@a){
ptr_t list=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!_k2(list))return 0;
ptr_t mc=ptr_deref_u64(list+0x10);if(!_k2(mc))return 0;
ptr_t m=ptr_deref_u64(mc+0x28);if(!_k2(m))return 0;
ptr_t x=ptr_deref_u64(m+0x18);if(x!=m+0x258)return 0;
ptr_t y=ptr_deref_u64(x+0x38);if(!_k2(y))return 0;
int64 d=int64(y)-int64(m);if(d<-0x10000000||d>0x10000000)return 0;
ptr_t b=y+0x580;
if(abs(ptr_deref_float(b+28)-0.3766f)>0.002f||abs(ptr_deref_float(b+120)-0.728f)>0.002f||abs(ptr_deref_float(b+216)+0.728f)>0.002f||abs(ptr_deref_float(b+312)-0.7776f)>0.002f||abs(ptr_deref_float(b+408)+0.7776f)>0.002f)return 0;
return b;
}
void _w8(ptr_t t,float sp,float cp,float sd,float cd){
ptr_write_float(t,cd);ptr_write_float(t+4,sd*sp);ptr_write_float(t+8,sd*cp);
ptr_write_float(t+16,0);ptr_write_float(t+20,cp);ptr_write_float(t+24,-sp);
ptr_write_float(t+32,-sd);ptr_write_float(t+36,cd*sp);ptr_write_float(t+40,cd*cp);
}
void _w9(ActorBase@a){
if(a is null){_w6=false;return;}
Matrix33f r=a.rot;float _w13=sqrt(r.a2*r.a2+r.a8*r.a8),x=a.pos_x,z=a.pos_z,ds=0;
if(_w6&&_w13>0.1f){float dx=x-_w4,dz=z-_w5;if(dx*dx+dz*dz<1)ds=(dx*r.a2+dz*r.a8)/_w13;}
_w4=x;_w5=z;_w6=true;
_w2+=ds/0.28328f;_w3+=ds/0.3683f;
if(_w2>6.2832f)_w2-=6.2832f;if(_w2<-6.2832f)_w2+=6.2832f;
if(_w3>6.2832f)_w3-=6.2832f;if(_w3<-6.2832f)_w3+=6.2832f;
_w1+=(_w0*0.45f-_w1)*0.25f;
ptr_t b=_w7(a);if(b==0)return;
float sf=sin(_w2),cf=cos(_w2),sr=sin(_w3),cr=cos(_w3),sd=sin(_w1),cd=cos(_w1);
_w8(b+72,sf,cf,sd,cd);_w8(b+168,sf,cf,sd,cd);
_w8(b+264,sr,cr,0,1);_w8(b+360,sr,cr,0,1);
}
void _k12(int ix,int iy){
_w0=0;
ActorBase@a=_k7();bool _w20=_k15(a);
if(_w20!=_k19){sys::debugLog("KART mounted="+_w20);_k18=0;_k19=_w20;_k20=!_w20;if(a!is null){_w14=a.pos_x;_w15=a.pos_z;}}
if(!_w20||a is null){if(a!is null&&_k20)_k9(a);return;}
if(abs(float(ix))>32768||abs(float(iy))>32768){_k10(a);_k18=0;return;}
float _w25=float(ix)/32768.0f,_w10=float(iy)/32768.0f;
if(abs(_w25)<0.15f)_w25=0;if(abs(_w10)<0.15f)_w10=0;
_w0=_w25;
float _w23=_w10*(_w10<0?1.0f:2.5f),_w11=_w23-_k18,_w12=_w10==0?0.08f:0.045f;
if(_w11>_w12)_w11=_w12;if(_w11<-_w12)_w11=-_w12;_k18+=_w11;
Matrix33f r=a.rot;float _w13=sqrt(r.a2*r.a2+r.a8*r.a8);
RigidBody@b=a.getMainRigidBody();if(b is null)return;
if(_w13<0.1f||r.a4<0.4f){_k10(a);_k18=0;return;}
Vector3f v=b.vel;b.setVel(r.a2*_k18/_w13,v.y,r.a8*_k18/_w13);
b.setAngularVel(-r.a7*2.0f,_w25*0.45f*(_k18/2.5f),r.a1*2.0f);
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
if(!_k24&&(held&mask)==mask){_k24=true;_k25=true;sys::debugLog("KART spawn queued");}
if(!_k3())return;
if(_k25&&(held&mask)==0){if(++_k23>=15){_k25=false;_k23=0;_k8();}}else _k23=0;
_k12(ptr_deref_s32(pad+8),ptr_deref_s32(pad+12));
_w9(_k7());
}
void _k11(ptr_t pad){while(true){_k5(pad);sleep(1);}}
void main(){_bigTail();
_k14();ptr_t pad=_k6();if(pad==0){TextWriter::toast(300,"KartLab: runtime input signature mismatch.\n");return;}
TextWriter::toast(300,"KartLab: ZL+ZR+Up spawns a kart. A controls; left stick drives; B dismounts.\n");
_k11(pad);
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
float _bigPad242(float v){return v*1.0001+242.5;}// padding 00242
float _bigPad243(float v){return v*1.0001+243.5;}// padding 00243
float _bigPad244(float v){return v*1.0001+244.5;}// padding 00244
float _bigPad245(float v){return v*1.0001+245.5;}// padding 00245
float _bigPad246(float v){return v*1.0001+246.5;}// padding 00246
float _bigPad247(float v){return v*1.0001+247.5;}// padding 00247
float _bigPad248(float v){return v*1.0001+248.5;}// padding 00248
void _bigTail(){float s=_bigPad0(1);s=_bigPad248(s);sys::debugLog("LARGESCRIPT controller tail ok bytes=24042 s="+s);}
