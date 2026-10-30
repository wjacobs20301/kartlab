// Drops both diagnostic watchers without dereferencing/deleting native actors.
// Dismount normally with B first. Clear before loading, travel or area changes.
void main() {
    ActorWatcher::clearSlot(1);
    ActorWatcher::clearSlot(2);
    TextWriter::toast(180,"Native mount probe: watchers 1/2 cleared; actors remain.\nRight stays in native rider mode. Respawn/reprepare before another test.\n");
}
