// Runtime test for the native-call binding (runtime/candidates/native-call-110). Calls only LotusKit-internal
// functions whose results can be checked: ptr_deref_u64 (integer path) and sqrtf/cosf (float argument + return).
void main(){
 ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");if(hook==0){sys::debugLog("NCALL no hook");return;}
 uint op=ptr_deref_u32(hook);int64 delta=int64(op&0x03ffffff);if((op&0x02000000)!=0)delta-=0x04000000;
 ptr_t target=ptr_t(int64(hook)+delta*4);ptr_t base=target-0x65b80;
 if((base&0xfff)!=0 || ptr_deref_u32(target)!=0xf0001382){sys::debugLog("NCALL base mismatch");return;}
 u64 direct=ptr_deref_u64(target);
 u64 viaCall=ptr_call(base+0x31250,target,0,0,0,0,0,0,0,0,0);
 sys::debugLog("NCALL u64 direct="+direct+" via="+viaCall+" ok="+(direct==viaCall));
 float s=ptr_callf(base+0x1ec100,0,0,0,0,0,0,2.0f,0,0,0);
 float c=ptr_callf(base+0x1ec7c0,0,0,0,0,0,0,0.5f,0,0,0);
 sys::debugLog("NCALL sqrtf(2)="+s+" cosf(0.5)="+c+" ok="+(abs(s-1.41421f)<0.0001f && abs(c-0.877583f)<0.0001f));
 sys::debugLog("NCALL done");
 while(true)sleep(1);
}
