// Diagnostic only: FIRST attach a native Control Stick to the existing kart,
// then use its native A-Control action. This API cannot verify the rider state.
// Does not create actors, move Player, override input, or change the camera.
bool nativeDriving=false;
bool nativeWorldReady() {
    return Player !is null && !pause::isPauseRequest("LoadingPause") &&
           !pause::isPauseTarget("Actor") && Player.pos_x>-400 && Player.pos_x< -100 &&
           Player.pos_z> -400 && Player.pos_z<0 && Player.pos_y>50 && Player.pos_y<200;
}
ptr_t nativeInput() {
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
bool nativePairReady() {
    if (!nativeWorldReady()) return false;
    ActorBase@ cart=ActorWatcher::get(1);
    ActorBase@ stick=ActorWatcher::get(2);
    if (cart is null || stick is null) return false;
    if (cart.getName()!="SpObj_Cart_A_01" || stick.getName()!="SpObj_ControlStick_A_01") return false;
    if (cart.getMainRigidBody() is null) return false;
    float dx=cart.pos_x-stick.pos_x,dy=cart.pos_y-stick.pos_y,dz=cart.pos_z-stick.pos_z;
    if (dx*dx+dy*dy+dz*dz>9.0f) return false;
    dx=Player.pos_x-stick.pos_x;dy=Player.pos_y-stick.pos_y;dz=Player.pos_z-stick.pos_z;
    return dx*dx+dy*dy+dz*dz<9.0f;
}
void main() {
    if (nativeDriving) return;
    nativeDriving=true;
    runNativeDrive();
    nativeDriving=false;
}
void runNativeDrive() {
    // Prevent the faulty watcher telemetry path; these calls do not pause actors.
    ActorWatcher::doTextWriter(1,false);ActorWatcher::doWSLog(1,false);ActorWatcher::pauseSlot(1);
    ActorWatcher::doTextWriter(2,false);ActorWatcher::doWSLog(2,false);ActorWatcher::pauseSlot(2);
    if (!nativePairReady()) {
        TextWriter::toast(240,"Native drive probe: need nearby kart in slot 1 and attached steering stick in slot 2.\nUse native A-Control before starting. No actors created.\n");return;
    }
    ptr_t pad=nativeInput();
    if (pad==0) { TextWriter::toast(180,"Native drive probe: pinned input bridge mismatch.\n");return; }
    bool released=false;
    for (uint i=0;i<90;i++) {
        if (!nativePairReady()) return;
        uint64 held=ptr_deref_u64(pad);
        if ((held & uint64(ZL|ZR|DLEFT|DUP|DRIGHT))==0) { released=true;break; }
        sleep(1);
    }
    if (!released) { TextWriter::toast(180,"Native drive probe: release the start shortcut.\n");return; }
    TextWriter::toast(900,"Native drive probe: requires A-Control rider. Left stick drives; B exits.\n30s / 1.5 speed limit. Rider and bond state are not verified by this script.\n");
    sys::debugLog("KartLab native mount drive: beginning; no Player pin or camera override");
    float speed=0;
    for (uint frame=0;frame<900;frame++) {
        if (!nativePairReady()) break;
        uint64 buttons=ptr_deref_u64(pad);
        if ((buttons & 0xc02)!=0) break; // B / Plus / Minus still reach native game
        int ix=ptr_deref_s32(pad+8),iy=ptr_deref_s32(pad+12);
        if (abs(float(ix))>32768 || abs(float(iy))>32768) break;
        float steer=float(ix)/32768.0f,throttle=float(iy)/32768.0f;
        if (abs(steer)<0.15f) steer=0;
        if (abs(throttle)<0.15f) throttle=0;
        float change=throttle*1.5f-speed;
        float limit=throttle==0 ? 0.15f : 0.05f;
        if (change>limit) change=limit;
        if (change< -limit) change= -limit;
        speed+=change;
        ActorBase@ cart=ActorWatcher::get(1);
        RigidBody@ body=cart.getMainRigidBody();
        Matrix33f r=cart.rot;
        float yaw=steer*0.0125f*(speed/1.5f),s=sin(yaw),c=cos(yaw);
        float fx=c*r.a2+s*r.a8,fz= -s*r.a2+c*r.a8;
        float length=sqrt(fx*fx+fz*fz);
        if (length<0.01f) { @body=null;@cart=null;break; }
        cart.setRot(c*r.a0+s*r.a6,c*r.a1+s*r.a7,c*r.a2+s*r.a8,
                    r.a3,r.a4,r.a5,-s*r.a0+c*r.a6,-s*r.a1+c*r.a7,-s*r.a2+c*r.a8);
        Vector3f v=body.vel;
        body.setVel(fx*speed/length,v.y,fz*speed/length);
        @body=null;@cart=null;
        sleep(1);
    }
    if (nativeWorldReady()) {
        ActorBase@ cart=ActorWatcher::get(1);
        if (cart !is null && cart.getName()=="SpObj_Cart_A_01") {
            RigidBody@ body=cart.getMainRigidBody();
            if (body !is null) { Vector3f v=body.vel;body.setVel(0,v.y,0); }
        }
    }
    ActorWatcher::clearSlot(1);ActorWatcher::clearSlot(2);
    sys::debugLog("KartLab native mount drive: finished; watchers cleared");
    TextWriter::toast(240,"Native drive probe stopped. B dismounts. Watchers cleared; actors remain.\nRight stays native. Respawn/reprepare before another test.\n");
}
