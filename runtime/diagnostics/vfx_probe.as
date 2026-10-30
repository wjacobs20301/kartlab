// Read-only probe of TOTK's nn::vfx system (offsets from research/drift-sparks.md). Logs "VFX ...".
string hx(u64 v){string s="";for(int i=15;i>=0;i--){uint d=uint((v>>(i*4))&15);s+=d<10?formatInt(d):(d==10?"a":d==11?"b":d==12?"c":d==13?"d":d==14?"e":"f");}return s;}
string cstr(ptr_t p,int maxLen=64){string s="";for(int i=0;i<maxLen;i++){u8 c=ptr_deref_u8(p+i);if(c==0)break;s+=" ";s[s.length()-1]=c;}return s;}
bool plausible(u64 p){return p>0x1000000 && p<0x8000000000 && (p&7)==0;}
void main(){
 ptr_t m=sys::mainOffset();
 sys::debugLog("VFX main="+hx(m));
 u64 g=ptr_deref_u64(m+0x4631b98);if(!plausible(g)){sys::debugLog("VFX bad g "+hx(g));return;}
 u64 inst=ptr_deref_u64(g);
 while(!plausible(inst)){sleep(1);inst=ptr_deref_u64(g);}
 u64 sys=ptr_deref_u64(inst+0x11b8);
 while(!plausible(sys)){sleep(1);sys=ptr_deref_u64(inst+0x11b8);}
 u64 g2=ptr_deref_u64(m+0x4632138);u64 cfg=ptr_deref_u64(ptr_deref_u64(g2)+0xf0);
 int maxRes=ptr_deref_s32(cfg+0x30);int resNum=ptr_deref_s32(sys+0x2f08);
 sys::debugLog("VFX inst="+hx(inst)+" sys="+hx(sys)+" maxRes="+maxRes+" resNum="+resNum);
 sleep(20);  // let the title/world load
 maxRes=ptr_deref_s32(cfg+0x30);
 u64 arr=ptr_deref_u64(sys+0x2ee8);
 for(int r=0;r<=maxRes && r<512;r++){
  u64 res=ptr_deref_u64(arr+8*r);if(res==0)continue;
  int n=ptr_deref_s32(res+0x558);u8 ready=ptr_deref_u8(res+0x571);
  u64 sets=ptr_deref_u64(res+0x430);
  string names="";
  for(int i=0;i<n && i<6;i++)names+=cstr(ptr_deref_u64(sets+0x28*i)+0x10)+",";
  sys::debugLog("VFX res "+r+" ready="+ready+" sets="+n+" "+names);
  string line="";
  for(int i=0;i<n;i++){
   line+=" "+i+"="+cstr(ptr_deref_u64(sets+0x28*i)+0x10);
   if(i%12==11||i==n-1){sys::debugLog("VFX list res="+r+line);line="";}
  }
 }
 // ELink effect-slot pool (64 x 0x18f0 at inst+0x1260): show live slots to learn the user-data layout at +0x90.
 for(int s=0;s<64;s++){
  u64 slot=inst+0x1260+0x18f0*s;int esid=ptr_deref_s32(slot);
  if(esid<0)continue;
  sys::debugLog("VFX slot "+s+" eset="+esid+" res="+ptr_deref_s32(slot+4)+" name="+cstr(slot+0x28,32)+" h="+hx(ptr_deref_u64(slot+0x18))
   +" u90="+hx(ptr_deref_u64(slot+0x90))+" "+hx(ptr_deref_u64(slot+0x98))+" "+hx(ptr_deref_u64(slot+0xa0)));
 }
 sys::debugLog("VFX done");
 while(true)sleep(1);
}
