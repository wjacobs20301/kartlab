# Revised remote controller test

This candidate addresses the user's report that spawning a kart did not let them drive it. The original Right script rejected an occupied slot, even when it held the kart just spawned with Up. It also expired after 30 seconds. The revised script adopts a nearby valid cart (within12units), spawns relative to Link if no cart is selected, and runs for up to9000logicalframes (about5minutes at30fps). Left stick drives/steers and B exits. It remains a remote controller; Link is held at his starting position. This is not mounting.

The local host harness passed adoption, wrong actor/body/distance rejection, input bridge/release guards, speed/Y limits, timeout and cleanup. New autorun and spawn scripts compile and retain their startup/occupied guards. On-device results are pending; host checks are not gameplay proof.

The test autorun disables all four watcher displays/log streams and pauses watcher calculation. A newly spawned cart is paused after it resolves; ActorWatcher::get still returns the reference. This avoids the telemetry path seen in the later crash, but does not implement actor lifetime tracking. Source and native crash evidence: research/actor-watcher-crash.md. Clear before loading or travel.

Installed aliases: spawn_v2.as, drive_pad_v2.as, clear_v2.as. Up spawns, Right drives, Down stops/clears. Left prepares the separate native mounting diagnostic. That diagnostic rebinds Right and Down; after preparing it, do not run the remote pinning driver while mounted. The scripts start no network listener.

The current installed build is recorded in research/color-control-v2-install.json. The earlier96-file prototype ZIP is historical and does not contain this revision.
