// Local-only laboratory bindings. This does not start a network server.
void main() {
    // This isolated lab does not need the upstream default Player watcher.
    for (uint i=0;i<4;i++) {
        ActorWatcher::doTextWriter(i,false);
        ActorWatcher::doWSLog(i,false);
        ActorWatcher::pauseSlot(i);
    }
    hotkey::bindButtonsExecFile(ZL|ZR|DUP, "sdcard:/totk_lotuskit/kart_lab/spawn_v2.as");
    hotkey::bindButtonsExecFile(ZL|ZR|DRIGHT, "sdcard:/totk_lotuskit/kart_lab/drive_pad_v3.as");
    hotkey::bindButtonsExecFile(ZL|ZR|DDOWN, "sdcard:/totk_lotuskit/kart_lab/clear_v2.as");
    hotkey::bindButtonsExecFile(ZL|ZR|DLEFT, "sdcard:/totk_lotuskit/kart_lab/prepare_native_mount.as");
    hotkey::setCooldown(30);
    TextWriter::toast(300, "Kart lab 1.1.0 ready: ZL+ZR+Right remote drive; Up spawn; Right uses that kart; Down clear.\n");
}
