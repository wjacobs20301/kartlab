// Clear before fast travel, entering a shrine, loading a save, or leaving play.
// Clear removes the watcher, not the cart actor from the world.
void main() {
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
