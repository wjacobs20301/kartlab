bool padLocationReady() {
return Player !is null && !pause::isPauseRequest("LoadingPause") &&
abs(Player.pos_x)<100000 && abs(Player.pos_z)<100000 &&
abs(Player.pos_y)<100000;
}
bool padWorldReady() { return padLocationReady() && !pause::isPauseTarget("Actor"); }
ptr_t resolvePadInput() {
ptr_t hook=ptr_from_sym("game::component::GameCameraParam::HACK_cameraCalc");
if (hook==0) return 0;
u32 instruction=ptr_deref_u32(hook);
if ((instruction & 0xfc000000)!=0x94000000) return 0;
int64 delta=int64(instruction & 0x03ffffff);
if ((instruction & 0x02000000)!=0) delta-=0x04000000;
ptr_t target=ptr_t(int64(hook)+delta*4);
if (ptr_deref_u32(target)!=0xf0001382 || ptr_deref_u32(target+4)!=0xa9be7bfd) return 0;
ptr_t base=target-0x65b80;
if ((base & 0xfff)!=0) return 0;
return base+0x3d90b8;
}
ptr_t currentCart=0;
bool padCartReady() {
if (!padWorldReady()) return false;
ActorBase@ cart=ActorWatcher::get(1);
if (cart is null || cart.getMainRigidBody() is null) return false;
ptr_t id=ptr_from_ActorBase(cart);
if (currentCart==0) {
if (cart.getName()!="SpObj_Cart_A_01") return false;
currentCart=id;
}
return currentCart==id;
}
void releasePadCamera() {
camera::freeze(0,1,0, -261,130,-210, -261,126,-201);
camera::toggleFreeze();
}
void runPadDrive() {
currentCart=0;
if (!padWorldReady()) {
TextWriter::toast(150,"KartLab: load the world and close menus.\n"); return;
}
ptr_t pad=resolvePadInput();
if (pad==0) {
sys::debugLog("KartLab pad: input bridge signature mismatch; no actor created");
TextWriter::toast(240,"KartLab: input bridge did not match this runtime.\n"); return;
}
bool released=false;
for (uint i=0;i<90;i++) {
if (!padLocationReady()) return;
uint64 held=ptr_deref_u64(pad);
if ((held & uint64(ZL|ZR|DUP|DRIGHT))==0 && padWorldReady()) { released=true; break; }
sleep(1);
}
if (!released) { TextWriter::toast(150,"KartLab: release the start shortcut and close menus.\n"); return; }
ActorBase@ existing=ActorWatcher::get(1);
bool create=existing is null;
if (!create) {
if (existing.getName()!="SpObj_Cart_A_01" || existing.getMainRigidBody() is null) {
TextWriter::toast(180,"KartLab: slot 1 is not a usable kart.\n");return;
}
float dx=existing.pos_x-Player.pos_x,dy=existing.pos_y-Player.pos_y,dz=existing.pos_z-Player.pos_z;
if (dx*dx+dy*dy+dz*dz>144) {
TextWriter::toast(180,"KartLab: move within 12 units of your kart.\n");return;
}
}
@existing=null;
sys::debugLog("KartLab resident: bridge validated; "+(create ? "spawn nearby" : "adopt current kart"));
float anchorX=Player.pos_x,anchorY=Player.pos_y,anchorZ=Player.pos_z;
if (create) actor::createAndWatch(1,"SpObj_Cart_A_01",anchorX,anchorY+1,anchorZ-4);
bool found=false;
for (uint i=0;i<150;i++) {
if (!padWorldReady()) break;
if (padCartReady()) { found=true; break; }
sleep(1);
}
if (!found) { ActorWatcher::clearSlot(1); sys::debugLog("KartLab pad: spawn failed"); return; }
ActorWatcher::doTextWriter(1,false);
ActorWatcher::pauseSlot(1);
ActorWatcher::doWSLog(1,false);
Vector3f direction;direction.x=0;direction.y=0;direction.z=1;
camera::freezeAtActorWatcher(1,7.0f,direction,3.0f,true,true);
TextWriter::toast(300,"KartLab flat-road drive: left stick throttle/steer; B exits; 5-minute maximum.\nLink stays at his starting spot.\n");
Matrix33f initial=ActorWatcher::get(1).rot;
if (initial.a2*initial.a2+initial.a8*initial.a8<0.01f) {
releasePadCamera();ActorWatcher::clearSlot(1);return;
}
float heading=atan2(initial.a2,initial.a8);
float speed=0;
for (uint frame=0;frame<9000;frame++) {
if (!padCartReady()) break;
uint64 buttons=ptr_deref_u64(pad);
if ((buttons & 0xc02)!=0) break;
int ix=ptr_deref_s32(pad+8),iy=ptr_deref_s32(pad+12);
if (abs(float(ix))>32768 || abs(float(iy))>32768) {
sys::debugLog("KartLab pad: input range rejected"); break;
}
float steer=float(ix)/32768.0f,throttle=float(iy)/32768.0f;
if (abs(steer)<0.15f) steer=0;
if (abs(throttle)<0.15f) throttle=0;
float targetSpeed=throttle*0.8f;
float change=targetSpeed-speed;
float limit=throttle==0 ? 0.08f : 0.025f;
if (change>limit) change=limit;
if (change< -limit) change= -limit;
speed+=change;
ActorBase@ cart=ActorWatcher::get(1);
RigidBody@ body=cart.getMainRigidBody();
Matrix33f r=cart.rot;
heading+=steer*0.010f*(speed/0.8f);
float s=sin(heading),c=cos(heading);
float error=abs(r.a0-c)+abs(r.a2-s)+abs(r.a3)+abs(r.a4-1)+abs(r.a5)+abs(r.a6+s)+abs(r.a8-c);
if (error>0.002f) cart.setRot(c,0,s, 0,1,0, -s,0,c);
Vector3f v=body.vel;
body.setVel(s*speed,v.y,c*speed);
Player.setPos(anchorX,anchorY,anchorZ);
@body=null;@cart=null;
sleep(1);
}
if (padCartReady()) {
ActorBase@ cart=ActorWatcher::get(1);
RigidBody@ body=cart.getMainRigidBody();Vector3f v=body.vel;
body.setVel(0,v.y,0);
}
releasePadCamera();
ActorWatcher::clearSlot(1);
sys::debugLog("KartLab resident: finished; camera and Link controls restored");
TextWriter::toast(180,"KartLab remote test finished.\n");
}
void spawnCart() {
if (Player is null || pause::isPauseRequest("LoadingPause") ||
pause::isPauseTarget("Actor")) {
TextWriter::toast(90, "Kart lab: load into the world before spawning.\n");
return;
}
if (ActorWatcher::get(1) !is null) {
TextWriter::toast(90, "Kart lab: slot 1 is occupied; clear it first.\n");
return;
}
actor::createAndWatch(1, "SpObj_Cart_A_01", Player.pos_x, Player.pos_y + 1.0f, Player.pos_z - 4.0f);
for (uint attempt = 0; attempt < 120; attempt++) {
if (pause::isPauseRequest("LoadingPause")) {
ActorWatcher::clearSlot(1);
return;
}
ActorBase@ cart = ActorWatcher::get(1);
if (cart !is null) {
if (cart.getName() != "SpObj_Cart_A_01" || cart.getMainRigidBody() is null) {
TextWriter::toast(120, "Kart lab: actor or physics body did not match.\n");
ActorWatcher::clearSlot(1);
return;
}
ActorWatcher::doTextWriter(1, false);
ActorWatcher::pauseSlot(1);
ActorWatcher::doWSLog(1, false);
TextWriter::toast(120, "Kart lab: cart ready. ZL+ZR+Right drives this kart; release the shortcut.\n");
return;
}
sleep(1);
}
ActorWatcher::clearSlot(1);
TextWriter::toast(120, "Kart lab: spawn timed out.\n");
}
void clearKart() {
if (!pause::isPauseRequest("LoadingPause") && !pause::isPauseTarget("Actor")) {
ActorBase@ cart = ActorWatcher::get(1);
if (cart !is null && cart.getName() == "SpObj_Cart_A_01") {
RigidBody@ body = cart.getMainRigidBody();
if (body !is null) {
Vector3f velocity = body.vel;
body.setVel(0, velocity.y, 0);
}
}
}
ActorWatcher::clearSlot(1);
TextWriter::toast(90, "Kart lab: slot 1 cleared.\n");
}
void main() {
for (uint i=0;i<4;i++) {
ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);
}
ptr_t pad=resolvePadInput();
if (pad==0) { TextWriter::toast(300,"KartLab: input bridge mismatch.\n");return; }
sys::debugLog("KartLab resident controller: ready; all controls compiled.");
TextWriter::toast(300,"KartLab: ZL+ZR+Up spawn; Right drive; Down clear. Left stick drives; B exits.\n");
bool latched=false,loadCleared=false;
uint64 mask=uint64(ZL|ZR|DUP|DRIGHT|DDOWN);
while (true) {
if (Player is null || pause::isPauseRequest("LoadingPause")) {
if (!loadCleared) { ActorWatcher::clearSlot(1);ActorWatcher::clearSlot(2);loadCleared=true; }
latched=true;sleep(1);continue;
}
loadCleared=false;
uint64 held=ptr_deref_u64(pad);
if ((held & mask)==0) latched=false;
if (!latched && padWorldReady()) {
if (held==uint64(ZL|ZR|DUP)) { latched=true;spawnCart(); }
else if (held==uint64(ZL|ZR|DRIGHT)) { latched=true;runPadDrive(); }
else if (held==uint64(ZL|ZR|DDOWN)) { latched=true;clearKart(); }
}
sleep(1);
}
}
