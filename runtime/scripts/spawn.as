// Laboratory prototype: use with the pinned lotuskit TOTK 1.1.0 build.
// Slot 1 is reserved; do not run across loading screens.
bool spawning = false;
void main() {
    if (spawning) return;
    spawning = true;
    spawnCart();
    spawning = false;
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
    // Creation is asynchronous; never assume the result is ready immediately.
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
            ActorWatcher::doTextWriter(1, true);
            ActorWatcher::doWSLog(1, true);
            TextWriter::toast(120, "Kart lab: cart ready. Run drive_smoke.as for the bounded motion test.\n");
            return;
        }
        sleep(1);
    }
    ActorWatcher::clearSlot(1);
    TextWriter::toast(120, "Kart lab: spawn timed out.\n");
}
