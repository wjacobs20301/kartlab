// Bounded integration probe, not Mario Kart physics or a player controller.
// Assumes unmodified 30 fps timing; do not run during travel, save loads or Recall.
// World +Z is forward for this probe. Native TOTK collisions/gravity remain active.
bool ready() {
    return !pause::isPauseRequest("LoadingPause") && !pause::isPauseTarget("Actor");
}
bool probing = false;
void logCart(const string &in label, ActorBase@ cart, RigidBody@ body) {
    Vector3f velocity = body.vel;
    sys::debugLog("KartLab " + label + " pos=" + cart.pos_x + "," + cart.pos_y + "," + cart.pos_z +
                  " vel=" + velocity.x + "," + velocity.y + "," + velocity.z);
}
void main() {
    if (probing) return;
    probing = true;
    runProbe();
    probing = false;
}
void runProbe() {
    for (uint frame = 0; frame < 90; frame++) {
        if (!ready()) {
            ActorWatcher::clearSlot(1);
            return;
        }
        // Reacquire every iteration: no actor/body handle is held across sleep.
        ActorBase@ cart = ActorWatcher::get(1);
        if (cart is null || cart.getName() != "SpObj_Cart_A_01") return;
        RigidBody@ body = cart.getMainRigidBody();
        if (body is null) {
            sys::debugLog("KartLab probe: no main rigid body");
            return;
        }
        if (frame == 0) logCart("probe begin", cart, body);
        if (frame == 89) logCart("probe end", cart, body);
        float speed;
        if (frame < 30) speed = 0.2f * float(frame + 1);
        else if (frame < 60) speed = 6.0f;
        else speed = 0.2f * float(89 - frame);
        // A shallow turn checks the rotation API independently of wheel dynamics.
        float yaw = frame < 30 ? 0.0f : 0.008726646f * float(frame - 30);
        float s = sin(yaw);
        float c = cos(yaw);
        cart.setRot(c, 0, s, 0, 1, 0, -s, 0, c);
        Vector3f velocity = body.vel;
        body.setVel(s * speed, velocity.y, c * speed);
        @body = null;
        @cart = null;
        sleep(1);
    }
    TextWriter::toast(120, "Kart lab: motion probe finished; horizontal velocity was set to zero.\n");
}
