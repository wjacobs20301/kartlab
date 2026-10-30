// Autonomous test on the backed-up mainland save. No network service.
bool worldReady() {
 return Player !is null && !pause::isPauseRequest("LoadingPause") && !pause::isPauseTarget("Actor") &&
 Player.pos_x>-400 && Player.pos_x< -100 && Player.pos_z> -400 && Player.pos_z<0 && Player.pos_y>50 && Player.pos_y<200;
}
void main() {
 tas::doBlockOnLoadingPause(false);
 for(uint i=0;i<4;i++){ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);}
 sys::debugLog("MOUNT native standalone: startup compiled");
 input(180,0);
 for(uint attempt=0;attempt<35 && !worldReady();attempt++){input(1,1);input(90,0);}
 uint stable=0;
 for(uint f=0;f<1800;f++){stable=worldReady()?stable+1:0;if(stable>=60)break;sleep(1);}
 if(stable<60){sys::debugLog("MOUNT world timeout");while(true)sleep(1);}
 Matrix33f pr=Player.rot;float fx=pr.a2,fz=pr.a8;float length=sqrt(fx*fx+fz*fz);if(length<0.1f)return;fx/=length;fz/=length;
 float px=Player.pos_x,py=Player.pos_y,pz=Player.pos_z;
 actor::createAndWatch(2,"SpObj_ControlStick_A_01",px+fx*2.5f,py+0.5f,pz+fz*2.5f);
 bool found=false;
 for(uint f=0;f<180 && worldReady();f++){ActorBase@ stick=ActorWatcher::get(2);if(stick !is null && stick.getMainRigidBody() !is null){found=true;break;}@stick=null;sleep(1);}
 if(!found){sys::debugLog("MOUNT spawn failed");while(true)sleep(1);}
 ActorWatcher::pauseSlot(2);
 ActorBase@ oriented=ActorWatcher::get(2);oriented.setRot(fz,0,fx,0,1,0,-fx,0,fz);@oriented=null;sleep(120);
 sys::debugLog("MOUNT heading="+fx+","+fz);
 ActorBase@ entry=ActorWatcher::get(2);Player.setPos(entry.pos_x-fx*0.7f,entry.pos_y+0.7f,entry.pos_z-fz*0.7f);@entry=null;sleep(45);
 sys::debugLog("MOUNT ready for native A; player="+Player.pos_x+","+Player.pos_y+","+Player.pos_z);
 input(1,1);input(90,0);
 sys::debugLog("MOUNT after A: visual inspection window; player="+Player.pos_x+","+Player.pos_y+","+Player.pos_z);
 for(uint f=0;f<900 && worldReady();f++)sleep(1);
 ActorBase@ stick=ActorWatcher::get(2);
 if(stick is null || !worldReady()){sys::debugLog("MOUNT unavailable before motion");while(true)sleep(1);}
 RigidBody@ physical=stick.getRigidBody("Physical");
 sys::debugLog("MOUNT bodies main="+ptr_from_RigidBody(stick.getMainRigidBody())+" named="+ptr_from_RigidBody(physical));
 if(physical is null)@physical=stick.getMainRigidBody();
 if(physical !is null)sys::debugLog("MOUNT flags="+ptr_deref_u64(ptr_from_RigidBody(physical)+0x68));
 @physical=null;
 float sx=stick.pos_x,sy=stick.pos_y,sz=stick.pos_z;px=Player.pos_x;py=Player.pos_y;pz=Player.pos_z;@stick=null;
 sys::debugLog("MOUNT beginning gentle native-rider motion");
 for(uint f=0;f<90 && worldReady();f++){
  @stick=ActorWatcher::get(2);if(stick is null || stick.getMainRigidBody() is null)break;
  RigidBody@ b=stick.getMainRigidBody();if(b is null)break;Vector3f v=b.vel;
  Matrix33f rotation=stick.rot;b.setVel(rotation.a2*1.5f,v.y,rotation.a8*1.5f);
  if(f==0){Vector3f after=b.vel;sys::debugLog("MOUNT immediate velocity="+after.x+","+after.y+","+after.z);}b.setAngularVel(0,f<45?0:0.35f,0);
  @b=null;@stick=null;sleep(1);
 }
 @stick=ActorWatcher::get(2);
 if(stick !is null && worldReady()){
  sys::debugLog("MOUNT displacement stick="+(stick.pos_x-sx)+","+(stick.pos_y-sy)+","+(stick.pos_z-sz)+" player="+(Player.pos_x-px)+","+(Player.pos_y-py)+","+(Player.pos_z-pz));
  RigidBody@ b=stick.getMainRigidBody();if(b !is null){Vector3f v=b.vel;b.setVel(0,v.y,0);b.setAngularVel(0,0,0);}@b=null;
 }
 @stick=null;
 sys::debugLog("MOUNT motion complete; native B exit");input(1,2);input(30,0);
 sys::debugLog("MOUNT finished");while(true)sleep(1);
}
