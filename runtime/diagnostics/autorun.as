// Temporary one-shot diagnostic for the verified mainland save and TOTK 1.1.0.
// No server or emulator input changes. Does not modify the production autorun.
bool worldReady() {
    return Player !is null && !pause::isPauseRequest("LoadingPause") &&
           !pause::isPauseTarget("Actor") && Player.pos_x < -100 &&
           Player.pos_x > -400 && Player.pos_z < 0 && Player.pos_z > -400 &&
           Player.pos_y > 50 && Player.pos_y < 200;
}
void bindLab() {
    hotkey::bindButtonsExecFile(ZL|ZR|DUP, "sdcard:/totk_lotuskit/kart_lab/spawn.as");
    hotkey::bindButtonsExecFile(ZL|ZR|DRIGHT, "sdcard:/totk_lotuskit/kart_lab/drive_smoke.as");
    hotkey::bindButtonsExecFile(ZL|ZR|DDOWN, "sdcard:/totk_lotuskit/kart_lab/clear.as");
    hotkey::setCooldown(30);
}
bool cartReady() {
    if (!worldReady()) return false;
    ActorBase@ cart = ActorWatcher::get(1);
    return cart !is null && cart.getName() == "SpObj_Cart_A_01" &&
           cart.getMainRigidBody() !is null;
}
void report(const string &in stage) {
    ActorBase@ cart = ActorWatcher::get(1);
    if (cart is null) return;
    RigidBody@ body = cart.getMainRigidBody();
    if (body is null) return;
    Vector3f v = body.vel;
    sys::debugLog("KartLab diagnostic " + stage + " pos=" + cart.pos_x + "," +
                  cart.pos_y + "," + cart.pos_z + " vel=" + v.x + "," + v.y + "," + v.z);
    // Read-only state sample from the pinned BaseProc layout; enum meaning is
    // an upstream claim, so compare the raw cart/player values in the log.
    sys::debugLog("KartLab diagnostic raw_state_24 cart=" + ptr_deref_u32(ptr_from_ActorBase(cart)+0x24) +
                  " player=" + ptr_deref_u32(ptr_from_ActorBase(Player)+0x24) +
                  " cart_list_flags_2c=" + ptr_deref_u32(ptr_from_ActorBase(cart)+0x2c));
}
void runDiagnostic() {
    if (ActorWatcher::get(1) !is null) {
        sys::debugLog("KartLab diagnostic: slot occupied before one-shot test; skipped");
        return;
    }
    // Known open road beside Lookout Landing, checked in the preceding live test.
    actor::createAndWatch(1, "SpObj_Cart_A_01", -261.102142f, 126.162460f, -200.864029f);
    bool found = false;
    for (uint i=0; i<150; i++) {
        if (!worldReady()) break;
        if (cartReady()) { found=true; break; }
        sleep(1);
    }
    if (!found) {
        sys::debugLog("KartLab diagnostic: actor/body readiness failed");
        ActorWatcher::clearSlot(1);
        return;
    }
    ActorWatcher::doTextWriter(1, true);
    ActorWatcher::doWSLog(1, false);
    report("actor ready");
    // Keep the cart in frame during motion; clear follow before the watcher.
    Vector3f direction;
    direction.x=0; direction.y=0; direction.z=1;
    camera::freezeAtActorWatcher(1,9.0f,direction,3.0f,true,false);
    TextWriter::toast(450, "KartLab diagnostic: inspecting cart, then short motion test.\n");
    for (uint i=0; i<450 && cartReady(); i++) sleep(1);
    if (cartReady()) {
        report("before motion");
        for (uint frame=0; frame<90 && cartReady(); frame++) {
            ActorBase@ cart = ActorWatcher::get(1);
            RigidBody@ body = cart.getMainRigidBody();
            float speed = frame<30 ? 0.2f*float(frame+1) :
                          (frame<60 ? 6.0f : 0.2f*float(89-frame));
            float yaw = frame<30 ? 0.0f : 0.008726646f*float(frame-30);
            float s=sin(yaw), c=cos(yaw);
            cart.setRot(c,0,s, 0,1,0, -s,0,c);
            Vector3f v=body.vel;
            body.setVel(s*speed,v.y,c*speed);
            @body=null; @cart=null;
            sleep(1);
        }
        if (cartReady()) report("after motion");
    }
    for (uint i=0; i<450 && cartReady(); i++) sleep(1);
    // freeze() also disables ActorWatcher following, then toggle it off.
    camera::freeze(0,1,0, -261.102142,130.162460,-209.864029,
                   -261.102142,126.562460,-200.864029);
    camera::toggleFreeze();
    if (cartReady()) {
        ActorBase@ cart = ActorWatcher::get(1);
        RigidBody@ body = cart.getMainRigidBody();
        Vector3f v=body.vel;
        body.setVel(0,v.y,0);
    }
    ActorWatcher::clearSlot(1);
    sys::debugLog("KartLab diagnostic: finished; camera restored and watcher cleared");
    TextWriter::toast(300, "KartLab diagnostic finished. Camera restored.\n");
}
void main() {
    sys::debugLog("KartLab diagnostic: waiting for mainland world");
    TextWriter::toast(300, "KartLab diagnostic: load the mainland manual save.\n");
    uint stable=0;
    for (uint frame=0; frame<9000; frame++) {
        stable=worldReady() ? stable+1 : 0;
        if (stable>=60) { runDiagnostic(); bindLab(); return; }
        sleep(1);
    }
    sys::debugLog("KartLab diagnostic: world wait timed out; no automatic spawn");
    bindLab();
}
