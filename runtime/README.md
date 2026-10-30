> Current vehicle controls and limits are in [NATIVE-KART.md](NATIVE-KART.md). The older integration notes below retain historical controller instructions.

# Kart lab for TOTK 1.1.0

A bounded remote-driving prototype. In Ryujinx 1.3.3 / TOTK 1.1.0, the imported MK8DX standard kart rendered, responded to native PS4-controller input, and completed its 900-frame test with camera and Link controls restored. Link stays at his starting position; a seated rider and full Mario Kart handling remain unfinished.

Target: title `0100F2C0115B6000`, TOTK **1.1.0**, main build ID `D5AD6AC71EF53E3E52417C1B81DBC9B4142AA3B3000000000000000000000000`. No Switch hardware test has been performed. Upstream describes its 1.1.0 build as untested/unsupported.

## Use the combined prototype

`dist/KartLab-TOTK-1.1.0-prototype.zip` combines the geometry, scripts and tested spawn-initialization derivative of the pinned lotuskit module. `runtime/dist/KartLab-110` is the original upstream dependency staging area; it does not contain that native fix or the geometry. Use the combined prototype for this test.

For Ryujinx, open the game's **Open Mods Directory**, create `KartLab_110`, and copy the **contents of `mod`** into it. The structure must be `KartLab_110/exefs/...` and `KartLab_110/romfs/...`. Copy `switch-sdcard` contents into Ryujinx's virtual `sdcard` folder. Preserve/merge an existing `totk_lotuskit/autorun.as`. Avoid simultaneously enabling another copy of this module.

For Atmosphere, the expected layout is the contents of `mod` under `/atmosphere/contents/0100F2C0115B6000/` and the contents of `switch-sdcard` at SD-card root. This layout has not been tested on hardware. Other executable mods may compete for `main.npdm`, `subsdk9` or hooks.

## Controller test

Use the mainland save near Lookout Landing. The remote script currently accepts only the rectangle X -400..-100, Z -400..0, Y 50..200 and creates the kart at a fixed road position (-261.102, 126.162, -200.864).

1. Briefly press **ZL + ZR + D-pad Right**, then release all three. On the current PS4 mapping: **L2 + R2 + Right**. Do not first spawn a separate kart with Up.
2. When the camera follows the kart, use the **left stick** for forward/reverse and steering. Releasing the stick brakes. Horizontal speed is capped at three experimental TOTK units; vertical velocity is preserved.
3. Press **B** (PS4 **Cross**) to exit. Plus/Minus, a detected pause, invalid input or 900 logical frames also end the test. At normal 30-fps timing this is approximately 30 seconds.
4. If slot 1 is occupied, briefly press **ZL + ZR + D-pad Down**, release, then retry Right. Clearing stops horizontal motion where safe and removes the watcher reference; it does not delete the actor.

**ZL + ZR + D-pad Up** separately spawns an uncontrolled cart four world-Z units from Link. `drive_smoke.as` retains the earlier three-second scripted motion probe for diagnostics.

Native input still reaches Link, so the remote test holds his starting position each frame. It does not seat or animate him. Native TOTK collision/materials remain; colors, wheel detail, suspension, drift, boost and Mario characters remain unfinished. Avoid loading, fast travel or shrine transitions during a test. Upstream ActorWatcher can retain stale pointers across loads; null/name checks do not solve lifetime tracking. Clear before leaving the area. Repeated tests leave extra actors until the world unloads.

## Implementation and verification

`drive_pad.as` resolves the pinned module's input record through the camera hook, checks the branch and exact hook instruction prefix, then reads left-stick axes. It rejects a mismatched bridge before spawning. This is specific to the pinned build, not a portable input API. The code limits speed/time, waits for the start shortcut to be released, and resets the following camera before clearing the watcher. No native actor/body handle is retained across script sleeps.

The initial unpatched test created an invisible, motionless actor. The native derivative clears 16 previously uninitialized CreateArg option bytes. Both the original cart and imported model moved afterward. The imported body/wheels and following camera were observed in-game. The controller log contains nonzero human stick axes and changing position, followed by `finished; camera and Link controls restored`. See `research/runtime-test-results.json` and `research/native-pad-controller-test.json` in the project, or their included copies in the combined package. This supports the current configuration; it does not prove general fix causation or hardware compatibility.

Host checks compile the scripts with the pinned AngelScript engine and simulate motion bounds, pause/actor guards, bridge rejection, release timeout, input range, B exit and camera cleanup. They do not prove game ABI, pointer lifetime or actual physics. Reproduce from the project root:

```sh
cmake -S runtime -B .tools/totk-runtime/host-build -DCMAKE_BUILD_TYPE=Debug
cmake --build .tools/totk-runtime/host-build -j6
.tools/totk-runtime/host-build/script_harness runtime/scripts .tools/totk-runtime/pulse_forward.as runtime/diagnostics/autorun.as runtime/scripts/drive_pad.as
python3 runtime/verify_target.py
python3 runtime/package_runtime.py
python3 scripts/package_prototype.py
```

The combined packager refuses to overwrite an existing output. Preserve the previous output before rebuilding. The supplied autorun only registers local shortcuts; it neither spawns an actor automatically nor starts a network server.

## Optional browser panel

The older `lab/panel` is a separate physics tool and was not used for the successful native gamepad test. From the project root, serve `runtime` with `python3 -m http.server 7073 --bind 127.0.0.1 --directory runtime`, then open `http://127.0.0.1:7073/panel/`. Upstream's server must be explicitly started with its **L R ZL ZR + −** chord. That server accepts arbitrary scripts on port 7072; use only when needed on a trusted local network. No supplied autorun starts it. The panel does not mount Link or provide the native controller's following camera.

## Dependency and source

- [Pinned lotuskit source](https://github.com/aquacluck/totk-lotuskit/tree/59dcfccd77b6d4bcfa718bff806bc55be640edb7), GPL-2.0.
- [Matching 1.1.0 release](https://github.com/aquacluck/totk-lotuskit/releases/tag/2026-04-20-59dcfccd77b6d4bcfa718bff806bc55be640edb7).
- Release ZIP SHA-256: `dc7b59413cf62e8a8c961aeb905debaacd111d53889fe5bfdd45d0c71cf33d2c`.
- Patched module SHA-256: `59d61add33f737325500a48eb94d35f0d4db59564a99cca60d07459d3fe82841`.

The combined package includes the original module, exact binary patch tool, corresponding pinned source archive, source fix patch and GPL license. See `source/spawn-fix-README.md` for reproduction. A full native source rebuild was not performed. No original game executable or keys are packaged; the combined geometry is derived from the user's local MK8DX files.
