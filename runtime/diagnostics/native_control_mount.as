// Standalone, bounded native Control Stick mounting probe. Not installed.
// Native A-Control/B-dismount only: no Player transforms, camera writes or glue.
bool worldReady() {
 return Player !is null && !pause::isPauseRequest("LoadingPause") && !pause::isPauseTarget("Actor") &&
 Player.pos_x>-400 && Player.pos_x< -100 && Player.pos_z> -400 && Player.pos_z<0 && Player.pos_y>50 && Player.pos_y<200;
}
bool stickReady() {
 if(!worldReady())return false;
 ActorBase@ s=ActorWatcher::get(2);
 return s !is null && s.getMainRigidBody() !is null;
}
void report(const string &in stage) {
 if(!stickReady())return;
 ActorBase@ s=ActorWatcher::get(2);
 Matrix33f r=s.rot;
 sys::debugLog("MOUNT "+stage+" player="+Player.pos_x+","+Player.pos_y+","+Player.pos_z+
 " stick="+s.pos_x+","+s.pos_y+","+s.pos_z+" relative="+(Player.pos_x-s.pos_x)+","+(Player.pos_y-s.pos_y)+","+(Player.pos_z-s.pos_z)+" up="+r.a4);
}
void translate(const string &in stage) {
 report(stage+" start");
 for(uint f=0;f<90 && stickReady();f++) {
  ActorBase@ s=ActorWatcher::get(2);RigidBody@ b=s.getMainRigidBody();
  Vector3f v=b.vel;Matrix33f r=s.rot;
  if(abs(v.x)>20 || abs(v.y)>20 || abs(v.z)>20 || r.a4<0.8f){@b=null;@s=null;break;}
  b.setVel(0.6f*r.a2,v.y,0.6f*r.a8);
  @b=null;@s=null;sleep(1);
 }
 if(stickReady()) {ActorBase@ s=ActorWatcher::get(2);RigidBody@ b=s.getMainRigidBody();Vector3f v=b.vel;b.setVel(0,v.y,0);}
 report(stage+" end");
}
void probe() {
 Matrix33f r=Player.rot;
 // Root_Stand is (0,.101635,-.7) in the shipped skeleton. Put that anchor
 // just ahead of Link, preserving his yaw and the original interaction side.
 Vector3f p;p.x=Player.pos_x+0.8f*r.a2;p.y=Player.pos_y-0.101635f;p.z=Player.pos_z+0.8f*r.a8;
 actor::createAndWatch(2,"SpObj_ControlStick_A_01",p,r);
 for(uint f=0;f<150 && !stickReady() && worldReady();f++)sleep(1);
 if(!stickReady()){sys::debugLog("MOUNT spawn timeout");return;}
 ActorWatcher::pauseSlot(2);
 for(uint f=0;f<90 && stickReady();f++)sleep(1);
 report("before A; observe native prompt");
 TextWriter::toast(180,"Native Control Stick probe: observing A-Control prompt.\n");
 input(180,0);
 if(!stickReady())return;
 input(1,1);input(90,0);
 report("after A");
 translate("after native A");
 input(1,2);input(60,0);
 report("after B");
 translate("after native B");
 sys::debugLog("MOUNT probe finished; following alone does not prove a rider relation. Check native Control action/pose and A/B difference.");
}
void main() {
 tas::doBlockOnLoadingPause(false);
 for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
 sys::debugLog("MOUNT standalone native Control Stick probe compiled");
 input(180,0);
 for(uint attempt=0;attempt<35 && !worldReady();attempt++){input(1,1);input(90,0);}
 uint stable=0;
 for(uint f=0;f<1800;f++){stable=worldReady()?stable+1:0;if(stable>=60)break;sleep(1);}
 if(stable>=60)probe();else sys::debugLog("MOUNT world timeout; no actor created");
 ActorWatcher::clearSlot(2);
 while(true)sleep(1);
}
