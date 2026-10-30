// Reads LotusKit's newlib heap bounds (fake_heap_start/end 0x3db310/318, sbrk cursor heap_start.0 0x3db328).
string hx(u64 v){string s="";for(int i=15;i>=0;i--){uint d=uint((v>>(i*4))&15);s+=d<10?formatInt(d):(d==10?"a":d==11?"b":d==12?"c":d==13?"d":d==14?"e":"f");}return s;}
void main(){
 ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");
 uint op=ptr_deref_u32(hook);int64 delta=int64(op&0x03ffffff);if((op&0x02000000)!=0)delta-=0x04000000;
 ptr_t base=ptr_t(int64(hook)+delta*4)-0x65b80;
 for(int i=0;i<6;i++){
  sys::debugLog("HEAP base="+hx(base)+" start="+hx(ptr_deref_u64(base+0x3db310))+" end="+hx(ptr_deref_u64(base+0x3db318))+" cursor="+hx(ptr_deref_u64(base+0x3db328))+" mallinfo="+ptr_deref_u64(base+0x3db020)+","+ptr_deref_u64(base+0x3db070));
  sleep(150);
 }
 sys::debugLog("HEAP done");
}
