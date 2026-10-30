// Pinned lotuskit 110 / zero-create-arg candidate only. Bounded remote driving
// lab: Link stays at his starting position; seating/animations are not supplied.
// No network server. Read human input from the pinned module's RecordInput.
bool padLocationReady() {
    return Player !is null && !pause::isPauseRequest("LoadingPause") &&
           Player.pos_x < -100 && Player.pos_x > -400 &&
           Player.pos_z < 0 && Player.pos_z > -400 && Player.pos_y > 50 && Player.pos_y < 200;
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
    // Exact unchanged camera-hook code in our pinned original/trial module.
    if (ptr_deref_u32(target)!=0xf0001382 || ptr_deref_u32(target+4)!=0xa9be7bfd) return 0;
    ptr_t base=target-0x65b80;
    if ((base & 0xfff)!=0) return 0;
    return base+0x3d90b8; // ELF symbol Record::currentInput; 24-byte input prefix
}
bool padCartReady() {
    if (!padWorldReady()) return false;
    ActorBase@ cart=ActorWatcher::get(1);
    return cart !is null && cart.getName()=="SpObj_Cart_A_01" && cart.getMainRigidBody() !is null;
}
void releasePadCamera() {
    // Reset following before the watcher can be cleared.
    camera::freeze(0,1,0, -261,130,-210, -261,126,-201);
    camera::toggleFreeze();
}
bool driving=false;
void main() {
    if (driving) return;
    driving=true;
    runPadDrive();
    driving=false;
}
void runPadDrive() {
    if (!padLocationReady() || ActorWatcher::get(1) !is null) {
        TextWriter::toast(150,"KartLab: world paused or slot 1 occupied.\n"); return;
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
    sys::debugLog("KartLab pad: bridge validated; creating test kart");
    float anchorX=Player.pos_x,anchorY=Player.pos_y,anchorZ=Player.pos_z;
    actor::createAndWatch(1,"SpObj_Cart_A_01",-261.102142f,126.162460f,-200.864029f);
    bool found=false;
    for (uint i=0;i<150;i++) {
        if (!padWorldReady()) break;
        if (padCartReady()) { found=true; break; }
        sleep(1);
    }
    if (!found) { ActorWatcher::clearSlot(1); sys::debugLog("KartLab pad: spawn failed"); return; }
    ActorWatcher::doTextWriter(1,true);
    ActorWatcher::doWSLog(1,false);
    Vector3f direction;direction.x=0;direction.y=0;direction.z=1;
    camera::freezeAtActorWatcher(1,7.0f,direction,3.0f,true,true);
    TextWriter::toast(900,"KartLab remote drive: left stick throttle/steer; B exits; 30s maximum.\nLink stays at his starting spot.\n");
    float speed=0;
    for (uint frame=0;frame<900;frame++) {
        if (!padCartReady()) break;
        uint64 buttons=ptr_deref_u64(pad);
        // B, Plus, Minus: stop before normal menu/travel interactions.
        if ((buttons & 0xc02)!=0) break;
        int ix=ptr_deref_s32(pad+8),iy=ptr_deref_s32(pad+12);
        if (abs(float(ix))>32768 || abs(float(iy))>32768) {
            sys::debugLog("KartLab pad: input range rejected"); break;
        }
        float steer=float(ix)/32768.0f,throttle=float(iy)/32768.0f;
        if (abs(steer)<0.15f) steer=0;
        if (abs(throttle)<0.15f) throttle=0;
        float targetSpeed=throttle*3.0f;
        float change=targetSpeed-speed;
        float limit=throttle==0 ? 0.20f : 0.10f;
        if (change>limit) change=limit;
        if (change< -limit) change= -limit;
        speed+=change;
        ActorBase@ cart=ActorWatcher::get(1);
        RigidBody@ body=cart.getMainRigidBody();
        Matrix33f r=cart.rot;
        float yaw=steer*0.025f*(speed/3.0f),s=sin(yaw),c=cos(yaw);
        // Increment yaw while retaining the native pitch/roll on uneven ground.
        cart.setRot(c*r.a0+s*r.a6,c*r.a1+s*r.a7,c*r.a2+s*r.a8,
                    r.a3,r.a4,r.a5,-s*r.a0+c*r.a6,-s*r.a1+c*r.a7,-s*r.a2+c*r.a8);
        float fx=c*r.a2+s*r.a8,fz= -s*r.a2+c*r.a8;
        float length=sqrt(fx*fx+fz*fz);
        if (length<0.01f) { @body=null;@cart=null; break; }
        Vector3f v=body.vel;
        body.setVel(fx*speed/length,v.y,fz*speed/length);
        // Input still reaches Link; hold his start position for this remote lab.
        Player.setPos(anchorX,anchorY,anchorZ);
        if (frame%30==0) sys::debugLog("KartLab pad frame="+frame+" lx="+ix+" ly="+iy+
             " pos="+cart.pos_x+","+cart.pos_y+","+cart.pos_z);
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
    sys::debugLog("KartLab pad: finished; camera and Link controls restored");
    TextWriter::toast(180,"KartLab remote test finished.\n");
}
