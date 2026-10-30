# One-shot mainland diagnostic

`autorun.as` is a temporary test autorun for the verified mainland save on TOTK 1.1.0. It is separate from the production local hotkey autorun and is not included in the prototype package.

It waits for 60 stable world frames near Lookout Landing (bounded to 9,000 intended frames), creates one cart at the previously checked road position, verifies actor/body readiness, and temporarily sets a camera following the cart. It holds the view for 450 frames, runs the existing 90-frame velocity/yaw probe capped at six, holds another 450 frames, disables watcher following and restores the camera, stops horizontal velocity, and clears the watcher. No native actor/body handle crosses a sleep. The watcher does not delete the cart. No server starts and no emulator input settings change.

The fixed camera is a runtime experiment; source/API existence is not proof that TOTK 1.1.0 structures work. A valid actor and body pointer do not prove rendering or physics movement. Start/end telemetry is written to the emulator debug log.

Host validation: the pinned AngelScript engine compiled the diagnostic; a simulated run checks a single spawn, bounded writes, Y preservation, paired camera freeze/restore and final watcher cleanup. Additional scenarios check world timeout, missing body, and occupied slot. These checks do not establish game ABI or real physics.

The current on-disk production autorun should be restored from `.work/backups/autorun-before-automatic-diagnostic.as` as soon as the diagnostic is confirmed loaded in memory, so future launches return to normal behavior. Install/restore receipt: `research/automatic-diagnostic-install.json`.

The first state log sampled offset +0x2c and mislabeled it as state. It is not interpreted as state. Later diagnostics label raw offsets explicitly: +0x24 (source BaseProc state) and +0x2c (source manager-list flags). These read-only layout samples remain upstream/source-based interpretation.
