// Autonomous test on the backed-up mainland save. No network service.
bool worldReady() {
 return Player !is null && !pause::isPauseRequest("LoadingPause") && !pause::isPauseTarget("Actor") &&
 Player.pos_x>-400 && Player.pos_x< -100 && Player.pos_z> -400 && Player.pos_z<0 && Player.pos_y>50 && Player.pos_y<200;
}
bool ready() {
 if (!worldReady()) return false;
 ActorBase@ c=ActorWatcher::get(1);
 return c !is null && c.getMainRigidBody() !is null;
}
void phase(uint mode) {
 ActorWatcher::clearSlot(1);
 float x=-261.102142f-8*float(mode),y=127.0f,z=-200.864029f;
 actor::createAndWatch(1,"SpObj_Cart_A_01",x,y,z);
 bool found=false;
 for(uint i=0;i<150;i++) { if(!worldReady())break; if(ready()){found=true;break;} sleep(1); }
 if(!found) {sys::debugLog("PHYS phase spawn failed "+mode);ActorWatcher::clearSlot(1);return;}
 ActorWatcher::pauseSlot(1);
 Vector3f dir;dir.x=0;dir.y=0;dir.z=1;
 camera::freezeAtActorWatcher(1,9.0f,dir,3.0f,true,false);
 for(uint i=0;i<120 && ready();i++)sleep(1);
 if(!ready())return;
 ActorBase@ c=ActorWatcher::get(1);
 float x0=c.pos_x,y0=c.pos_y,z0=c.pos_z;
 float minX=x0,maxX=x0,minY=y0,maxY=y0,minZ=z0,maxZ=z0,minUp=1,maxV=0;
 @c=null;
 for(uint f=0;f<180 && ready();f++) {
  @c=ActorWatcher::get(1);RigidBody@ b=c.getMainRigidBody();Vector3f v=b.vel;
  if(abs(v.x)>100 || abs(v.y)>100 || abs(v.z)>100) {sys::debugLog("PHYS invalid velocity guard");@b=null;@c=null;break;}
  // 0 natural idle; 1 velocity only; 2 forced upright rotation + velocity;
  // 3 linear impulse only. Separate actors avoid warp/resetting native joints.
  if(mode==1)b.setVel(0,v.y,1.5f);
  if(mode==2){c.setRot(1,0,0,0,1,0,0,0,1);b.setVel(0,v.y,1.5f);}
  if(mode==3 && v.z<1.5f)b.applyImpulse(0,0,15.0f);
  if(c.pos_x<minX)minX=c.pos_x;if(c.pos_x>maxX)maxX=c.pos_x;
  if(c.pos_y<minY)minY=c.pos_y;if(c.pos_y>maxY)maxY=c.pos_y;
  if(c.pos_z<minZ)minZ=c.pos_z;if(c.pos_z>maxZ)maxZ=c.pos_z;
  Matrix33f r=c.rot;if(r.a4<minUp)minUp=r.a4;
  float speed=sqrt(v.x*v.x+v.z*v.z);if(speed>maxV)maxV=speed;
  @b=null;@c=null;sleep(1);
 }
 if(ready()) {
  @c=ActorWatcher::get(1);RigidBody@ b=c.getMainRigidBody();Vector3f v=b.vel;Matrix33f r=c.rot;
  sys::debugLog("PHYS result mode="+mode+" start="+x0+","+y0+","+z0+" end="+c.pos_x+","+c.pos_y+","+c.pos_z);
  sys::debugLog("PHYS metrics mode="+mode+" ranges="+(maxX-minX)+","+(maxY-minY)+","+(maxZ-minZ)+" minUp="+minUp+" maxSpeed="+maxV+" finalVel="+v.x+","+v.y+","+v.z);
  b.setVel(0,v.y,0);@b=null;@c=null;
 }
 camera::freeze(0,1,0,-261,130,-210,-261,126,-201);camera::toggleFreeze();
 ActorWatcher::clearSlot(1);
 sleep(30);
}
void main() {
 tas::doBlockOnLoadingPause(false);
 for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
 sys::debugLog("PHYS automated baseline: startup compiled");
 // Navigate Continue, selected top manual save and its Load confirmation.
 // Input is injected only until the known mainland world is ready.
 input(180,0);
 for(uint attempt=0;attempt<35 && !worldReady();attempt++) {input(1,1);input(90,0);}
 uint stable=0;
 for(uint f=0;f<1800;f++){stable=worldReady()?stable+1:0;if(stable>=60)break;sleep(1);}
 if(stable>=60) {
  sys::debugLog("PHYS world ready; beginning four bounded cases");
  for(uint mode=0;mode<4 && worldReady();mode++)phase(mode);
  sys::debugLog("PHYS all cases finished");
  TextWriter::toast(300,"KartLab autonomous physics test finished.\n");
 }else sys::debugLog("PHYS world timeout; no actor created");
 // Retain one module instead of compiling/discarding more scripts in this run.
 while(true)sleep(1);
}
