// Spawn TOTK particle effects next to Link through nn::vfx (runtime/candidates/native-scratch-110). Logs "VFXS ...".
// Offsets: research/drift-sparks.md. Each candidate plays 6 s, following Link 2 m ahead and 0.3 m up, then is killed.
string cstr(ptr_t p,int maxLen=64){string s="";for(int i=0;i<maxLen;i++){u8 c=ptr_deref_u8(p+i);if(c==0)break;s+=" ";s[s.length()-1]=c;}return s;}
bool locationReady(){return Player !is null && !pause::isPauseRequest("LoadingPause") && abs(Player.pos_x)<100000 && abs(Player.pos_y)<100000 && abs(Player.pos_z)<100000;}
bool plausible(u64 p){return p>0x1000000 && p<0x8000000000 && (p&7)==0;}
bool worldReady(){return locationReady() && !pause::isPauseTarget("Actor");}
ptr_t M=0,SYS=0,SCR=0;
int findSet(int res,const string &in name){
 u64 r=ptr_deref_u64(ptr_deref_u64(SYS+0x2ee8)+8*res);if(r==0)return -1;
 int n=ptr_deref_s32(r+0x558);u64 sets=ptr_deref_u64(r+0x430);
 for(int i=0;i<n;i++)if(cstr(ptr_deref_u64(sets+0x28*i)+0x10)==name)return i;
 return -1;
}
float SC=1;
void place(u64 eset,float x,float y,float z){
 Matrix33f q=Player.rot;
 for(int i=0;i<12;i++)ptr_write_float(SCR+0x40+4*i,0);
 ptr_write_float(SCR+0x40,q.a0);ptr_write_float(SCR+0x44,q.a1);ptr_write_float(SCR+0x48,q.a2);ptr_write_float(SCR+0x50,q.a3);ptr_write_float(SCR+0x54,q.a4);ptr_write_float(SCR+0x58,q.a5);ptr_write_float(SCR+0x60,q.a6);ptr_write_float(SCR+0x64,q.a7);ptr_write_float(SCR+0x68,q.a8);
 ptr_write_float(SCR+0x40+12,x);ptr_write_float(SCR+0x40+28,y);ptr_write_float(SCR+0x40+44,z);
 ptr_write_float(SCR+0x80,SC);ptr_write_float(SCR+0x84,SC);ptr_write_float(SCR+0x88,SC);
 ptr_call(M+0x229a164,eset,SCR+0x40,SCR+0x80,0,0,0,0,0,0,0,0);
}
u64 liveSet(){u64 e=ptr_deref_u64(SCR);if(e==0)return 0;return ptr_deref_u32(e+0x234)==ptr_deref_u32(SCR+8)?e:0;}
int MODE=0;
void tint(u64 e,float r,float g,float b){
 if(MODE==1){ptr_write_float(e+0x40,r);ptr_write_float(e+0x44,g);ptr_write_float(e+0x48,b);return;}
 u64 em=ptr_deref_u64(e+8);int k=0;
 while(em!=0 && k<16){ptr_write_float(em+0x3fc,r);ptr_write_float(em+0x400,g);ptr_write_float(em+0x404,b);ptr_write_float(em+0x408,r);ptr_write_float(em+0x40c,g);ptr_write_float(em+0x410,b);em=ptr_deref_u64(em+8);k++;}
}
void play(const string &in name,int group,float r,float g,float b){
 int id=findSet(1,name);if(id<0){sys::debugLog("VFXS missing "+name);return;}
 ptr_write_u64(SCR,0);ptr_write_u64(SCR+8,0);
 u64 ok=ptr_call(M+0x229a0d0,SYS,SCR,id,1,group,SCR+0x1000,0,0,0,0,0);
 u64 e=liveSet();
 sys::debugLog("VFXS create t="+name+" id="+id+" group="+group+" ret="+(ok&0xff)+" live="+(e!=0));
 if(e==0)return;
 for(int f=0;f<150 && worldReady();f++){
  e=liveSet();if(e==0){sys::debugLog("VFXS ended early "+name+" f="+f);return;}
  if(r>=0)tint(e,r,g,b);
  Matrix33f m=Player.rot;
  place(e,Player.pos_x-2.0f*m.a0,Player.pos_y+0.8f,Player.pos_z-2.0f*m.a6);
  if(f==30){sys::debugLog("VFXS state "+name+" flags="+ptr_deref_u32(e+0x38)+" e8="+ptr_deref_s16(e+0xe8)+" grp="+ptr_deref_u8(e+0x65));groups("mine");}
  sleep(1);
 }
 e=liveSet();if(e!=0)ptr_call(M+0x28998,SYS,e,0,0,0,0,0,0,0,0,0);
 sys::debugLog("VFXS killed "+name);
 sleep(30);
}
void groups(const string &in tag){
 string acc="";
 for(int g=0;g<64;g++){int n=0;u64 e=ptr_deref_u64(SYS+0xb8+8*g);u64 first=e;while(e!=0 && n<500){n++;e=ptr_deref_u64(e+0x78);}
  if(n>0){u64 en=ptr_deref_u64(first+0x10);acc+=" g"+g+":"+n+"("+(plausible(en)?cstr(ptr_deref_u64(en)+0x10,40):"?")+")";}}
 sys::debugLog("VFXS groups "+tag+acc);
}
void main(){
 ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(hook==0)return;
 uint op=ptr_deref_u32(hook);int64 delta=int64(op&0x03ffffff);if((op&0x02000000)!=0)delta-=0x04000000;
 ptr_t target=ptr_t(int64(hook)+delta*4);ptr_t base=target-0x65b80;
 if((base&0xfff)!=0 || ptr_deref_u32(target)!=0xf0001382){sys::debugLog("VFXS base mismatch");return;}
 SCR=base+0x3d1000;M=sys::mainOffset();
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && abs(Player.pos_x)>5);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady() || abs(Player.pos_x)<=5){sys::debugLog("VFXS no world");return;}
 u64 inst=ptr_deref_u64(ptr_deref_u64(M+0x4631b98));SYS=ptr_deref_u64(inst+0x11b8);
 int group=ptr_deref_u8(inst+0x1260+8);
 sys::debugLog("VFXS ready sys="+SYS+" scratch0="+ptr_deref_u64(SCR+0x1000)+" slotGroup="+group+" slot1Group="+ptr_deref_u8(inst+0x1260+0x18f0+8));
 sleep(60);groups("world");
 SC=1;play("ReFX_Grass_M",group,-1,0,0);
 play("Ply_SlipSmoke_Grass_Green",group,-1,0,0);
 play("HorseStep_Grass_Tmp",group,-1,0,0);
 play("Ply_FootEffect_Grass_Green",group,-1,0,0);
 play("ReFX_Sand_M",group,-1,0,0);
 play("Ply_SlipSmoke_Stone",group,-1,0,0);
 sys::debugLog("VFXS done");
 while(true)sleep(1);
}
