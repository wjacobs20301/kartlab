// Diagnostic candidate only, not autorun or a replacement driving controller.
// Native TOTK Control Stick supplies A-Control mount and its standing rider pose.
// Creates no cart, native constraints, Player teleports, input override or camera.
bool mountPreparing=false;
bool mountWorldReady() {
    return Player !is null && !pause::isPauseRequest("LoadingPause") &&
           !pause::isPauseTarget("Actor");
}
void main() {
    if (mountPreparing) return;
    mountPreparing=true;
    prepareMount();
    mountPreparing=false;
}
void prepareMount() {
    if (!mountWorldReady()) {
        TextWriter::toast(150,"Native mount probe: load into the world first.\n");return;
    }
    if (ActorWatcher::get(2) !is null) {
        TextWriter::toast(180,"Native mount probe: slot 2 occupied; clear its watcher first.\n");return;
    }
    ActorBase@ cart=ActorWatcher::get(1);
    if (cart is null || cart.getName()!="SpObj_Cart_A_01") {
        TextWriter::toast(180,"Native mount probe: spawn a kart into slot 1 first.\n");return;
    }
    float dx=cart.pos_x-Player.pos_x,dy=cart.pos_y-Player.pos_y,dz=cart.pos_z-Player.pos_z;
    if (dx*dx+dy*dy+dz*dz>400.0f) {
        TextWriter::toast(150,"Native mount probe: stand within 20 units of the kart.\n");return;
    }
    Matrix33f r=cart.rot;
    // Place it beside the kart for native Ultrahand attachment. Merely placing
    // a stick atop a cart does not create a bond/constraint between the actors.
    float x=cart.pos_x+2.5f*r.a0,y=cart.pos_y+1.0f,z=cart.pos_z+2.5f*r.a6;
    @cart=null;
    actor::createAndWatch(2,"SpObj_ControlStick_A_01",x,y,z);
    for (uint frame=0;frame<150;frame++) {
        if (!mountWorldReady()) { ActorWatcher::clearSlot(2);return; }
        ActorBase@ stick=ActorWatcher::get(2);
        if (stick !is null) {
            ActorWatcher::doTextWriter(2,false);
            ActorWatcher::doWSLog(2,false);
            ActorWatcher::pauseSlot(2);
            if (stick.getName()!="SpObj_ControlStick_A_01") {
                ActorWatcher::clearSlot(2);return;
            }
            @stick=null;
            // Keep the remote Player-pinning driver inaccessible after mount prep.
            hotkey::bindButtonsExecFile(ZL|ZR|DRIGHT,"sdcard:/totk_lotuskit/kart_lab/drive_native_mount.as");
            hotkey::bindButtonsExecFile(ZL|ZR|DDOWN,"sdcard:/totk_lotuskit/kart_lab/clear_native_mount.as");
            TextWriter::toast(900,"Native mount probe: use Ultrahand to ATTACH the new steering stick to the kart.\nApproach it and press A for Control. Then L2+R2+Right drives. B exits.\nStanding native pose; seated animation is unfinished.\n");
            sys::debugLog("KartLab native mount probe: stick ready; native attachment and A-Control need observation");
            return;
        }
        @stick=null;
        sleep(1);
    }
    ActorWatcher::clearSlot(2);
    TextWriter::toast(180,"Native mount probe: steering stick spawn timed out.\n");
}
