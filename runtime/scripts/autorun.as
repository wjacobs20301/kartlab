// Local-only laboratory bindings. This does not start a network server.
void main() {
    hotkey::bindButtonsExecFile(ZL|ZR|DUP, "sdcard:/totk_lotuskit/kart_lab/spawn.as");
    hotkey::bindButtonsExecFile(ZL|ZR|DRIGHT, "sdcard:/totk_lotuskit/kart_lab/drive_pad.as");
    hotkey::bindButtonsExecFile(ZL|ZR|DDOWN, "sdcard:/totk_lotuskit/kart_lab/clear.as");
    hotkey::setCooldown(30);
    TextWriter::toast(300, "Kart lab 1.1.0 ready: ZL+ZR+Right remote drive; Up spawn; Down clear.\n");
}
