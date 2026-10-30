# TOTK Mario Kart mod — handoff for Claude

Updated October 16, 2026. Workspace: `<repo>`.

## CURRENT STATE (Claude, October 16, 2026, late) — read this first

> **Newest (Oct 19): placement/seat/sliding fixes INSTALLED** — variants are new actors A_06 Pipe Frame, A_05 B Dasher,
> A_04 Bike (vanilla A_02/A_03 untouched); Standard Kart texture restored (stray file); grippy Material_Stone_ZonauLight
> tyres; variant steering wheels removed, Pipe Frame seat, bike hands on grips. Rebuild everything with
> `scripts/rebuild_all_karts.sh`, check with `scripts/check_mod_sizes.py`. Controller `9b3b50cb…`. research/kart-variants.md.

> **Newest (Oct 18, night): kart chests INSTALLED** — four Zonai chests outside Lookout Landing's east fence give 5
> capsules of each kart; kart chords now test-only (`devChords`). Controller `0da7c2db…`. research/kart-variants.md.

> **Newest (Oct 18, evening): Standard Bike + inventory karts INSTALLED** — actor A_04 (new RSDB rows, own saddle,
> visual lean), capsules for every kart (names, icons, Take out device), controller adopts any kart Link rides, glider
> mesh stored 1/1000 size so unadopted karts don't show it. Controller `4bdb84a8…`. research/kart-variants.md.

> **Newest (Oct 18): the remaining ~52 s Ryujinx exit has been investigated; nothing installed or changed.** The MoltenVK
> "Subgroup builtins" error is harmless: one vanilla vertex pipeline fails on every boot (186/200 logs, 55/55 passing boots on
> Oct 18, already present Oct 15 before any kart assets). The real crash is a .NET access violation in Ryujinx's own managed
> code on a thread-pool worker during world load (fail-fast; ~2%: 3 in ~175 loads, 0 in 55 on Oct 18). It is not the heap
> race or the mod's assets. Don't purge the shader cache (it's complete at 2324; purging only adds compile work). Relaunch if it happens.
> The harness discarded stderr, which holds the managed stack. `.work/failfast/run_capture.py`/`batch.sh` keep it. Details:
> research/host-failfast-crash.md.

> **Newest (Oct 17, night): "pointer overwritten with actor-name text" crash — cause found, FIX INSTALLED.** LotusKit's
> newlib malloc had no lock (`__malloc_lock` → a `nop`ed weak hook), and LotusKit's spawn hook builds a heap `std::string` of
> every actor name on whatever game thread requests the actor; the script thread allocates at the same time. Fault address is
> always text+0x18 = dlmalloc unlink through a clobbered `fd`. Runtime now `runtime/candidates/malloc-lock-110/subsdk9`
> (`0eb29953…`, `scripts/patch_lotuskit_malloc_lock_110.py`) = native-heap-110 + a recursive spinlock in
> `__malloc_lock/__malloc_unlock`. Stress A/B: old 1 crash ("Horse_Li"+0x18, thread 96) in 8, fixed 0 in 11; a counter build saw
> 2–15 concurrent malloc entries per launch. Regression 12/12, recall 8/8. A different, rarer crash remains: Ryujinx exits
> (.NET fail-fast) right after a MoltenVK "Subgroup builtins" shader error, on either runtime. Details: research/heap-race.md.
> Packaging: ship `0eb29953…`, not `fe1f0d79…`. Rollback: copy native-heap-110/subsdk9 back.

> **Newest (Oct 18, later): Pipe Frame + B Dasher INSTALLED** — ZL+ZR+X picks the kart, ZL+ZR+Up spawns. Actors A_02/A_03,
> models K1/K3, `scripts/build_kart_variant.py`, research/kart-variants.md. Also trick spin, auto-glider (ZL+ZR+Right),
> horn (L), look-behind (right stick down), bigger hop. Controller `16280945…`. Private repo: github.com/wjacobs20301/totk-kartlab.

> **Newest (Oct 18): feedback fixes INSTALLED** — controller `399a5a76…`, sound DB `4449cc83…` (vanilla stick keys no longer
> renamed: that caused the null+0x8C06C crash), lean pose `assets/kart-seated-lean`. Free-fall camera follows, no
> sideways slide while gliding, Link leans into ground turns. Details: research/air-and-glider.md (bottom).

> **Newest (Oct 17, evening): mid-glide kick-off FIXED** — new main IPS patch in the mod's exefs
> (`runtime/candidates/fall-release-110`, `scripts/build_fall_release_patch.py`) disables the control stick's
> fall/speed release (it read Link's jittering body velocity). Controller `5a3d98d8…`; free fall normal speed again.
> Details: research/air-and-glider.md (bottom). Packaging must now include the .ips.

> **Newest (Oct 17, late afternoon): user-test fixes INSTALLED** — controller `f00ebf94…`: fall cap 9 m/s only while gliding (TOTK throws
> the rider off after ~1.5 s faster than ~10-13 m/s; free fall left normal at user request), menus get every button back (GamePause), pooled-model glider reset,
> camera further back, integer sound ids. Details: research/air-and-glider.md (bottom).

> **Newest (Oct 17, afternoon): glider v2 + banking + MK8 camera INSTALLED** — controller `49015fe6…`, host model
> `8c3129ca…` from `assets/kart-glider-v2`. Glide test: bank/pitch stable, camera behind/above, no crash. Details:
> research/air-and-glider.md (bottom). Sound v2 unchanged (below).

> **Newest (Oct 17, midday): kart sound v2 INSTALLED** — controller `b1b8d382…`, bank + extended SLink DB + RSTB from
> `assets/kart-sound-v2` (`scripts/build_kart_sound_db.py`). Drift and air tests clean, every sound key live. Engine pitch
> vs speed unverified (game clears the property each frame). Details + rollback: research/kart-sound-notes.md (v2).
> Config: found the keyboard test layout active at 11:45 (not switched by this session); PS4 config restored.

> **Newest (Oct 17, ~02:40): kart sound — built, staged, NOT installed, NOT tested in game** (screen was locked all
> night; Ryujinx/MoltenVK cannot compile shaders while the Mac is locked). Details: research/kart-sound-notes.md.
> * `scripts/build_kart_sound_bank.py` → `assets/kart-sound/romfs`: kart bank `Sound/Resource/SpObj_ControlStick_A_01.bars.zs`
>   (6 MK8DX sounds: mini-turbo, ultra, spark sizzle loop, glider open, trick, engine loop), SLink DB with the vanilla
>   stick keys disabled, RSTB (built on the installed glider RSTB `58d9ba98…`). Previews in `assets/kart-sound/preview`.
> * Controller source now has `sndPlay`/`sndFade`/`soundFrame` (built autorun `4fa840d9…`, 28,440 bytes, compiles).
>   **The installed autorun is still the last tested one (`d39504a1…`).**
> * Tests ready: `runtime/diagnostics/sound_drift_test.as`, `sound_air_test.as` (check `KART snd … r= h=` log lines).
> * Install for test = copy the 3 files from `assets/kart-sound/romfs` into the mod romfs + new autorun; rollback = delete
>   the bank and DB files and restore RSTB from `assets/kart-glider/romfs`.

> **Newest (Oct 16, night):** effects, pose, texture, off-road and heap. All installed; regression 12/12, recall 8/8,
> signed 4/4. Details: [research/drift-sparks.md](research/drift-sparks.md) (sections below the sparks).
> * Runtime: `runtime/candidates/native-heap-110/subsdk9` (`fe1f0d79…`) = native-call7 (`ptr_call`/`ptr_callf`,
>   7 int args) + LotusKit's C heap moved from the 64 KiB fake heap to the unused WebSocket buffer (module +0x2d9000,
>   ~992 KiB; `scripts/patch_lotuskit_bigheap_110.py`). That fixed a deterministic crash at kart spawn
>   (json alloc, null+0x21) and is the likely cause of the old "pointer overwritten by text" crashes.
> * Controller `02598…` superseded: startup `3297687b…` (22,543 bytes) adds the Zonai flame-jet boost flame,
>   ground ray cast + per-surface burst effects, and off-road (ZL+ZR+D-pad Down, default OFF, MK8 PROF 0.7/0.5).
>   Effect scratch: module +0x3d1000 (last 32 KiB of that buffer, above the heap limit).
> * Pose: `assets/kart-seated-legs-a` (`5cb99bbb…`): `LEGS="0,8,75,-55,-9,4,73" scripts/build_kart_seated_pose.py
>   A_Pose_RaumiGolem_Ride <out> full` = construct-seat body/arms + authored legs (thighs together/forward, knees 55°),
>   written into each Vehicle_Wait clip's own leg base blocks. Previous: `assets/kart-seated-golem-full` (straddled legs).
> * Air / tricks / glider (Y): [research/air-and-glider.md](research/air-and-glider.md). Host model + anim + textures +
>   RSTB now from `assets/kart-glider`. Foot IK is disabled while riding (0x1085b5c) so the seated legs hold.
> * Sound (next, not started in code; notes in research/kart-sound-notes.md): TOTK plays via SLink keys per actor; the Zonai cart user has a `Cart_RotateSpeed`
>   rolling loop. MK8DX banks: Audio/Body/Body_K_Std.bars (engine), Audio/Ground/*.bars (surfaces); BARS v1.1 vs TOTK v1.2.
> * Texture: `assets/kart-texture-hd` (`scripts/build_kart_texture_hd.py`): 2048² atlas (was 256²) + RSTB entry.
> * Testing without a controller: `python3 .work/use_keyboard_input.py`, restore `.work/Config.json.ps4-original`.
>   Tests autosave over the user's latest save; a backup is in `.work/backups/totk-save-20261016-214314`.
> * Not repackaged; the packager does not know these runtimes or assets yet. Switch hardware untested.

> **Newer (same night):** drift now uses MK8DX's recovered rules (exact charge rule, 30° body angle and travel heading),
> wheel spin is anti-aliased, and Link sits 0.45 m further forward. Installed startup is now `bdfdd85f…`, and the actor pack
> comes from `assets/source-native-contacts-raised-chassis-seat-070-cart-dynamics-fwd045`. **Not yet repackaged**: the
> mk-handling ZIP predates these changes. Details: bottom section of [research/mk-handling.md](research/mk-handling.md). Still open: spark/dirt
> effects, ground-surface detection, texture sharpness.

Installed and verified in Ryujinx (identical to `dist/KartLab-TOTK-1.1.0-mk-handling-2026-10-16.zip`,
SHA-256 `d42b4cd48054cabff26260f5a8c9cfbc831e332e68e6356771e469b1f67dcf7f`):

| Piece | Value |
| --- | --- |
| Runtime `subsdk9` | `runtime/candidates/raw-input-110` `10b63b32…`: large-script (65,535-byte scripts) + raw controller input kept in `Record::currentInput` |
| Startup | `runtime/candidates/native-rider-wheels/autorun.as` `a843e27e…` (from `controller.src.as` via `scripts/build_native_wheels.py`) |
| Assets | previous 19 files + `assets/rim-transfer` (Cart model, ControlStick model + anim) |

What works now:

* **Mario Kart controls:** A gas, B brake/reverse, stick steer, R/ZR hop and drift, X exit. While mounted, the controller
  rewrites the game's input (B hidden from TOTK's dismount). **Mario Kart handling** comes from MK8DX tables plus the
  recovered speed step: ~14 m/s, 18.7 m full-lock radius, mini-turbo tiers, boost to 15.5 m/s.
  → [research/mk-handling.md](research/mk-handling.md)
* **Wheels** roll and steer ([research/native-wheel-animation.md](research/native-wheel-animation.md)); the **steering wheel**
  turns ([research/steering-rim-animation.md](research/steering-rim-animation.md)). The kart turns the correct way (an inherited
  inversion was fixed).
* Last results (same build): handling run clean; drive regression 12/12; recall 8/8; signed direction 4/4. Tests now start at the
  surveyed open field (−150, −60) (`research/site-survey.log`); the castle-town start is too cluttered for these speeds.

Testing: diagnostics simulate the player through the controller's `sim*` hook (the record is raw now, so `input()` no longer
shows up in it). Build → `.work/rider/compile_wheels file.as 65535` → copy over the installed `autorun.as` → launch →
`scripts/summarize_native_controller.py` / `scripts/analyze_handling.py` / `scripts/check_turn_direction.py` → **restore the
normal autorun**.

Rollbacks: runtime → `large-script-110/subsdk9` (`3e22fadc…`, then use a stick-throttle controller, because the MK controller needs raw
input); startup → `runtime/candidates/native-rider-controls/autorun.as` (old, inverted steering); rim → copy from
`assets/source-native-assembly-mod` + `assets/kart-grip-targets`.

Known issue (FIXED Oct 17 night, research/heap-race.md): 1 of 9 heavy-logging handling runs crashed with a pointer overwritten by log-string text —
LotusKit's malloc had no lock. Not done: off-road/terrain types, air handling, items, characters, rim colour,
transition polish, Switch hardware.

Sections below are earlier snapshots from today, kept for history.

## (History) script limit raised to 65,535 bytes

Installed runtime is now `runtime/candidates/large-script-110/subsdk9` (SHA-256 `3e22fadc6db15f650ea5bfbe9bed33be79d0259ecdb0150026c5a305425431e2`),
replacing `b0dc2c3b…` (roll back with `runtime/candidates/angular-velocity-110/subsdk9`). Startup autorun unchanged (`a2529a6f…`).
Scripts may now be up to 65,535 bytes; compile-check with `.work/rider/compile_wheels file.as 65535`. Details:
[research/large-script-runtime.md](research/large-script-runtime.md); receipt `research/large-script-install.json`. The `dist/` ZIPs still ship `b0dc2c3b`.
Hashes quoted further below for `subsdk9` (`b0dc2c3b…`) are historical.

## (History) steering-direction fix; rim plan

* **Bug fixed:** the inherited controller turned the kart LEFT on right stick (positive Y angular
  velocity turns toward +X = left). Yaw is now `-steer*0.45*(speed/2.5)`. Also, bone records store
  **axis vectors (matrix columns)**, not rows: proven by Handle_J's +90 deg rest reading (0,1,0),(-1,0,0)
  and an in-game camber test (`research/native-wheels-visual` not updated; log `.work/ryujinx-bone-probe-camber.log`).
  Wheel matrices are now written as columns of `Ry(-0.45*stick) * Rx(spin)`.
* Installed startup is now `44538d5a…` (`runtime/candidates/native-rider-wheels/autorun.as`); runtime is
  the large-script build `3e22fadc…`. Regression 12/12, recall 8/8, and the new signed check
  `scripts/check_turn_direction.py` 4/4 pass (`research/fixedsteer-wheels-*-results.json`). The pre-fix
  build fails all 4 signed checks.
* **Package is stale:** `dist/KartLab-TOTK-1.1.0-native-wheels-largescript-2026-10-16.zip` has the large-script
  runtime but the pre-fix controller (`a2529a6f…`). Rebuild it with the same `package_native_kart.py`
  arguments used for that package (the packager now has a 4th runtime step).
* **Steering-wheel rim, not built yet.** Findings: the native `LeftRight` clip already rotates host `Handle_J`
  ±20 deg with the stick (`.work/ryujinx-handle-probe.log`; host bone records at host+2384 Skl_Root,
  host+2480 Handle_J). Throttle pitches it ±10 deg (`UpDown`). Plan: (1) move the rim triangles
  (`research/animation-assets-handoff/kart-rim-components-LOD*.json`) out of the Cart body (degenerate them)
  into hidden host shape0, bound to Handle_J (rigid matrix 1); (2) move Handle_J's pivot to the rim centre
  (0, 0.97305, 0.4928) and orient its local X along the rim's column axis (PCA of the rim vertices); retarget the
  LeftRight curve from rotZ (offset 40) to rotX (offset 32); re-express Handle_L/R so the hands stay put;
  (3) consider zeroing UpDown. Extend `scripts/build_kart_grip_targets.py` (same in-place edit + `mc_test`
  validation pattern). Material: host shape0 uses the metal-handle texture, so the rim UVs need a sensible region.

## (History) wheel spin + steering first installed

**Read [research/native-wheel-animation.md](research/native-wheel-animation.md) first.** It supersedes the
"wheel animation route not proved" statements in sections 2, 6, 7 and 12 below.

* Wheels now roll from measured travel (forward/reverse) and the front wheels steer with the stick.
  The controller writes the Cart submodel's wheel-bone rotation rows each frame through a validated
  pointer path: `component[2]+0x28` (host model) `→ +0x18 → +0x38 → +0x580`, records 96 bytes at
  `base + 96*i - 24`. Signature-checked before every write; mismatch = no write.
* **Installed normal startup** is now `runtime/candidates/native-rider-wheels/autorun.as`
  (SHA-256 `a2529a6f78e002df55623cfe2c3a404d39728455ae823489a08b7803d5a23eb2`, 7,698 bytes), built from
  readable `controller.src.as` by `scripts/build_native_wheels.py`. Runtime module and all 19 mod files
  are unchanged (`subsdk9` still `b0dc2c3b…`). Roll back by copying
  `runtime/candidates/native-rider-controls/autorun.as` (`e23aedeb…`) over the installed startup script.
* **Regression:** 12/12 drive checks + 8/8 recall checks (all 14 distinct checks) pass on the final build
  with the animation running; no memory faults. Results: `research/native-wheels-{regression,recall}-final-results.json`.
* **New package:** `dist/KartLab-TOTK-1.1.0-native-wheels-2026-10-16.zip`, SHA-256
  `ed46c38ef54caa070518a48ce492b5539dcf1fb17fa938a597a53d3bc3a12374`, 29,633,196 bytes, 73 files.
  The previous `native-rider` ZIP is preserved.
* **New compile harness:** `.work/rider/compile_wheels` (source `.work/rider/compile_wheels.cpp`). The old
  `compile_physics` lacks `ptr_write_*`; use the new one for any script that writes memory. It enforces the
  8,191-byte runtime limit.
* **Hazards learned (see the research note):** the bone array is *not* at a fixed host offset (an early
  fixed-offset write corrupted a heap pointer and crashed); record boundaries are offset by −24 from the
  naive guess; blind pointer walks fault. All diagnostics from this pass are `runtime/diagnostics/bone_probe_*.as`.
* **Script budget is now the main constraint:** 7,698 of 8,191 bytes. Handling work will need a runtime
  patch enlarging `scriptBuf[0x2000]` in `schedule.cpp` (no `#include`, modules don't share code) or tighter code.
* Still not done: independent suspension, steering-wheel rim rotation, entry/exit transition polish,
  Mario Kart handling, characters, hardware validation. Ryujinx is not running at handoff.

## Read this first

The user wants a playable Mario Kart vehicle in Tears of the Kingdom, eventually with Mario Kart characters and handling. **The latest requested order is animations first, Mario Kart handling second.** The user then asked Codex to document the project so Claude can take over. Codex has stopped implementation for this handoff. No animation experiment from the latest investigation has been installed.

Detailed companion notes:

- [Animation asset investigation](research/animation-assets-handoff/README.md): actual retail clip inventory, wheel matrices, steering-rim topology, and a concrete unimplemented rim-transfer option.
- [Seated transition investigation](research/native-seated-transition-investigation.md): exact eight entry clips, curve channels, ASB limitations, and an unimplemented transition-edit approach.

Both workers have stopped. Neither built or installed a new animation candidate; neither owns a pending process or REA session. The running emulator is the existing baseline session described below.

There is already a working, seated, drivable prototype. Preserve it before experimenting. Do not restart from the earlier remote-driving implementation. The top of `PROJECT.md` and `runtime/NATIVE-KART.md` describe the current build; most of the rest of `PROJECT.md` is explicitly historical and contains obsolete controls and conclusions.

The user prefers that the agent perform its own emulator testing, investigate failures, and keep improving the mod instead of repeatedly asking the user to load saves or press test shortcuts. They have authorized local extraction, mod installation, emulator restarts, and testing in this project. They can help manually when necessary. Do not publish or redistribute their extracted game assets.

This workspace is **not a Git repository**. Preserve files with explicit candidate folders/backups. There are many old experiments; a newer filename alone does not establish that an experiment works.

## 1. Exact target and current state

| Item | Current value |
| --- | --- |
| TOTK version | **1.1.0**, base XCI plus selected update NSP |
| TOTK title ID | `0100F2C0115B6000` |
| TOTK build ID | `D5AD6AC71EF53E3E52417C1B81DBC9B4142AA3B3000000000000000000000000` |
| MK8 Deluxe export | **1.7.1**, title `0100152000022000` |
| Test platform | Ryujinx **1.3.3**, macOS, Apple M4 |
| Eventual deployment | Modded Switch, **not yet tested on hardware** |
| Current package | `dist/KartLab-TOTK-1.1.0-native-rider-2026-10-16.zip` |
| ZIP SHA-256 | `2eebd75623d17e130d9b92b75a7e63a221f7433f944451eb76ffaa366a79ed87` |
| ZIP bytes | `28601655` |

Ryujinx is currently running the working native rider build. At the handoff check its window displayed TOTK v1.1.0 and 30 FPS. The previous autonomous test left the resident controller active, with Link mounted near Hyrule Castle Town Ruins. Exact current player position may have changed. No new emulator restart, guest-memory probe, asset installation, or controller edit was performed during the latest animation investigation.

Installed mod:

```text
~/Library/Application Support/Ryujinx/mods/contents/0100f2c0115b6000/KartLab_110/
```

Installed startup script:

```text
~/Library/Application Support/Ryujinx/sdcard/totk_lotuskit/autorun.as
```

That startup script exactly matches `runtime/candidates/native-rider-controls/autorun.as`. Both hashes were rechecked for this handoff:

```text
subsdk9  b0dc2c3bf8b19d95e43c8ad58d3e461d485a2e1ad0b9d2060f843a8a6d80ad06
autorun  e23aedeb74f48e3038562efcd57ab187a02286bbdd98c1df7523e3bf5abf06c4
```

**Normal startup is installed:** it waits for user input. It does not load a save or run the diagnostic automatically. The live process initially ran the final diagnostic and then handed over to the same resident controller. Rebooting uses the normal startup script.

## 2. What works, and what remains

Working and observed in the emulator:

- Mario standard kart body, Mario red/blue colors, dark tires, actual source suspension-arm geometry, and corrected neutral wheel placement.
- Native **A: Control** interaction; Link mounts, sits, drives, and dismounts with B.
- Native follow camera and manual camera orbit. No per-frame repositioning of Link.
- Left-stick forward/reverse and steering; neutral braking; an upright stabilizer.
- Parking on the sampled slope and same-actor recall/remounting.
- Normal keyboard driving after the automated test relinquished its simulated input.

Not finished:

- **Dynamic wheel spin, wheel steering, independent suspension, steering-wheel animation.** Wheels and arms currently have the correct neutral assembly but are visually static relative to the chassis.
- Polished hand placement, entry/exit animation, and transitions between standing and the seated pose.
- Full Mario Kart handling, acceleration curves, drift, boosts, jumps, air control, and kart-specific tuning.
- Mario characters, a dedicated custom actor instead of shared replacements, broad actor-lifetime/terrain stress testing, and Switch hardware validation.

Current handling is an authored gentle prototype controller, **not a recovered implementation of the complete MK8DX physics engine**. There is no evidence supporting a claim that the full handling engine or animation system has already been ported.

## 3. Controls and save used for tests

Normal controls:

1. Briefly press **ZL + ZR + D-pad Up**, then release all three: spawn or recall the existing unoccupied kart.
2. Approach the rear until **A: Control** appears, then press A.
3. Left stick drives and steers; release it to brake.
4. **B** dismounts. Dismount before recalling.

PS4 mapping described to the user: L2/R2/Up for spawn, Circle for Nintendo A, Cross for Nintendo B. Current Ryujinx config has also been tested using keyboard:

```text
WASD = left stick      IJKL = right stick
Q = ZL                 O = ZR
Z = Nintendo A         X = Nintendo B
E = L                  U = R
C = Nintendo X         V = Nintendo Y
F = L3                 H = R3
Arrow keys = D-pad
```

Older messages mentioned O+P or the Right shortcut. Those are obsolete. **There is no Right remote-drive test shortcut in the current production controller.**

Continue's top slot used by the final automatic test is actually an **autosave at Hyrule Castle Town Ruins, October 15, 2026, 5:43 PM**. Old comments called it a manual mainland save; do not repeat that error. Its loaded position was approximately `(-259.9605, 125.157, -196.1801)`. A Room of Awakening save also exists and is not the desired test slot.

Save container lives under Ryujinx `bis/user/save/0000000000000005/`. Backups include `.work/backups/before-autonomous-physics-matrix/save-container` and `.work/backups/totk-before-mainland-save`. Preserve account/save metadata; no new save import is needed.

## 4. Evidence for the working baseline

Start with these files:

| File | Purpose |
| --- | --- |
| `research/native-complete-regression-results.json` | Final 14 checks and metrics |
| `research/native-complete-regression.log` | Immutable final test log |
| `research/native-final-package-validation.json` | Installed/package identity, ZIP integrity, binary reproduction |
| `research/native-startup-restored.json` | Normal startup restoration receipt |
| `runtime/NATIVE-KART.md` | Current usage and limits |
| `runtime/candidates/native-rider-controls/autorun.as` | Actual readable production controller |

All 14 final checks passed: native ground mount, forward, both steering directions, neutral braking command to zero, reverse, native B exit, unmounted input isolation, parking on the sampled slope, same-actor recall/remount, shortcut queueing, and sampled upright/mounted state.

Selected metrics:

```text
Forward displacement:                  13.5555 world units
Minimum periodically sampled up-axis Y: 0.93102
Parking drift over 180 logical frames:  0.0031623 world units
Post-exit horizontal displacement:      0.01970 world units
```

These are one bounded route, not proof of stability on every surface. Up-axis values are periodic samples, not every rendered frame. Movement logs do not establish animation quality. Shader compilation/new views sometimes reduce FPS; do not confuse baseline MoltenVK shader warnings with demonstrated mod defects.

The final installed mod had 19 files, exactly matching the package. The manifest contains 61 files in total, including source/evidence. The final packaged runtime was rebuilt byte-identically in `/private/tmp/kart-native-final-runtime-proof-20261016/`.

## 5. Current actor and asset architecture

The prototype reuses native **`SpObj_ControlStick_A_01`**, retaining its native attention, AI, Ridable seat, Player riding behavior, and camera. ModelInfo adds the kart as a SubModel:

```text
Bone: Root
FmdbName: SpObj_Cart_A_01
ModelProjectName: SpObj_Cart_A
SearchModelKey: ""
```

The original Control Stick geometry is hidden with degenerate index buffers while keeping its skeleton intact. The Cart body is the imported Mario mesh. Physics uses one native rigid body and four tire-shaped convex contact hulls, **not four independently simulated wheels**.

Current installed asset sources/overlays, in addition to the runtime ROMFS support files:

| Asset | Current source |
| --- | --- |
| Cart model + Mario texture atlas | `assets/source-native-assembly-mod/romfs/` |
| ControlStick actor pack + RSTB | `assets/source-native-contacts-raised-chassis-seat-070-cart-dynamics/romfs/` |
| Hidden ControlStick model + adjusted steering animation | `assets/kart-grip-targets/romfs/` |
| Seated Player animation archive | `assets/native-seated-hybrid/romfs/` |

Important hashes:

```text
Cart model .mc:
c7cc6ce9ba2c62c03b47c3e1caa661d0e610faa5545de4f47d0d2cacec631abb
ControlStick actor pack:
e1314eeefa7ffa02180d61125b90eca914ee1418a2a254bfe2ecb1e05c3ba4a6
ControlStick hidden/grip model .mc:
d9e070fe3168033bdc4046364d20a3d11901b6178f6e92b3e65803bf2c90c895
ControlStick animation archive:
dc8fa7484f7261bacbbb85f85549f779336ac4046ff6ea54e659d23c51532327
Player hybrid animation archive:
3ec7ef44ba65f465bec28e60559478680f2695f4cd9689c7f8288667ecc973db
```

Seat `SaddleOffset.Y` is **0.7**. Chassis local hull bounds are `X ±0.70, Y 0.30..0.60, Z -1.25..1.35`; the original larger/low platform caught slopes. The entity rigid-body parameters are copied exactly from native Cart: mass 400 and `ComAssignMode=OffsetFromAuto`, Y offset -0.375. Original ControlStick used mass 100 and **Absolute** COM `(0,0,-0.4)`; that original COM must not be described as an offset.

There is **no Cart actor pack override** in the final installed build. An earlier ground-joint experiment was ineffective and removed.

This arrangement replaces shared ControlStick/Cart/Player vehicle resources globally. Other uses of those resources are affected. Keep this limitation explicit until a custom actor/resource arrangement is implemented.

## 6. Animation work: exact current position

### Kart skeleton and missing dynamic connection

The current Cart has native bone names:

```text
Root
Skl_Root
Wheel_00 = LF
Wheel_01 = RF
Wheel_02 = LB
Wheel_03 = RB
```

Its five rigid matrix indices map to bones `(1,2,3,4,5)`, with zero smooth matrices and no inverse skin matrices. Tires are rigid-bound to their individual Wheel bones. Body and suspension arms are currently bound to `Skl_Root`.

The ControlStick host skeleton does **not** contain these Wheel bones. Its native steering clips animate Root/Control/Root_Stand/Skl_Root/Handle_J. The current submodel renders, but no verified mechanism drives its unmatched Wheel bones. **Simply adding a Cart `.anim.bfres` is not established to bind or play on this submodel.** Determine the native model/AS binding path before claiming wheel animation is solved.

Steering ring is baked into the imported single-bone body mesh. A previous welded connected-component analysis identified a 78-vertex ring component. Its converted bounds are roughly `X ±0.2701, Y .7176..1.2285, Z .3575...6281`; center `(0,.97305,.4928)`. An animated rim likely needs extraction/rebinding to an appropriate bone, or a separate model piece. Do not rotate the entire body to imitate rim steering.

Current neutral Wheel bone positions, relative to Skl_Root:

```text
LF (+.7280, .00800007, +.704)
RF (-.7280, .00800007, +.704)
LB (+.7776, .04800007, -.704)
RB (-.7776, .04800007, -.704)
```

Skl_Root contributes another `Y .3765999973`. Tire radius is approximately `.28328` front and `.3683` rear. Source scale is `.16`; rear tire scale is `(1.4,1.3,1.3)`. These positions include source render axle offsets and are different from physical wheel-contact centers.

Builders to read:

```text
scripts/kart_assets_source_native_assembly.py
scripts/kart_assets_native_cart.py
scripts/kart_assets_colors.py
scripts/kart_assets_native_placement_probe.py
scripts/build_controlstick_hidden_host.py
scripts/build_controlstick_animation_root_trial.py
scripts/build_kart_grip_targets.py
scripts/build_source_native_contacts.py
```

### Host skeleton and native steering animation

ControlStick bones in the current grip-target model:

```text
Root          parent -1, translation (0,0,0)
Control       parent 0,  translation (0,1.27545,0)
Root_Stand    parent 0,  translation (0,.101635,-.7)
Skl_Root      parent 0,  translation (0,.3765999973,0)
Handle_J      parent 3,  translation (0,.2,.6137), Euler Z pi/2
Handle_L      parent 4,  approximately (.39645,-.2107,-.1209)
Handle_R      parent 4,  approximately (.39645,+.210737,-.12091265)
```

Original Handle child X was 1.1146 and raised Link's hands too high. Current hand targets are roughly `±.2107, .97305, .4928`; visible fit improved but is not polished.

`SpObj_ControlStick_A.anim.bfres.zs` has **LeftRight** and **UpDown** clips. Both explicitly reset Skl_Root translation to zero, even with zero curves. Changing only the model rest translation was therefore ineffective. Current fix sets the clips' Skl_Root constant Y to `.3766`, clears TRANSLATE_ZERO, and sets Handle_J constant Z to `.6137`. Keep model rest and animated transforms consistent.

### Player seated pose and transition research

Read `scripts/build_native_seated_hybrid.py` and `research/player-vehicle-animation-inventory.json`.

Current hybrid replaces lower-body tracks for **33 Vehicle_Wait variants**, preserving the original 63-bone binding, 48-frame duration, original upper body/hand curves, and all other clips. Ten lower-body bones use Horse_Wait data: Skl_Root, Waist, both Leg_1, Leg_2, Ankle and Toe. Per-bone global curve indices are rebased. Baked curve capacity is adjusted conservatively.

Full Horse_Wait substitution was a rejected experiment: it made Link's arms rise overhead. `assets/native-seated-pose-trial` is **not** the current installed pose.

Entry and exit motions remain original native actions. Initial latest-pass inventory found **eight Vehicle_Rideon entries** (16/23 frames), plus a Sled entry. No Vehicle_Rideoff/Dismount-named clips were found in that bounded animation-bank inventory. B exit may use a generic transition; its actual animation-state route is **not yet verified**. Avoid altering generic jumping/standing animations globally based on the name alone.

An independent worker investigated a possible isolated candidate that smoothly corrects existing entry lower-body curves toward the seated pose without adding pointers or changing frame counts. **No candidate was built.** Its observations and proposed method are recorded in `research/native-seated-transition-investigation.md`.

### File-format details already established

Library: `.tools/kart-assets/BlenderBfresImporter/io_scene_bfres/bfrespy/` loaded via synthetic `kartbf` package, without Blender UI. Dependencies are in `.tools/kart-assets/python`.

TOTK FSKA V10 header is 80 bytes:

```text
signature +0, flags +4
name +8, path +16, bindSkeleton +24, bindIndices +32
boneAnimArray +40, userData pointers +48/+56
frameCount u32 +64, curveCount u32 +68, bakedSize u32 +72
boneAnimCount u16 +76, userDataCount u16 +78
```

BoneAnim is 56 bytes: name ptr +0, curves ptr +8, base data ptr +16, flags +40, begin_rotate byte +44, begin_translate +45, curveCount +46, begin_base_translate +47, global flattened begin_curve i32 +48. **begin_curve is a cache index, not a pointer or per-bone zero.** Even constant tracks retain the current flattened cursor.

Inline base data contains optional scale3, rotate4, translate3 floats, controlled by flags 8/16/32. Curve result offsets: translate X/Y/Z =16/20/24, rotation X/Y/Z=32/36/40. Quantized sample values use `key*scale + offs`; the parser's `.offset` property is not the correct offset here. Cubic interpolation uses normalized segment time. Do not assume base data equals frame-zero animated values.

Flags of interest: TRANSLATE_ZERO bit27, cumulative translate-zero bit31 in rest bones, ROTATE_ZERO bit26. Typical clips use flags `0x1204` (Maya scale, Euler XYZ, looping).

Original Player archive is `extracted/totk/romfs/Model/Player_Animation.anim.bfres.zs`, 1,560 clips. A decoded copy is `.work/native-mount/Player_Animation.anim.bfres` (36,482,488 bytes). Use the original as the source of untouched clips.

## 7. Native animation/runtime investigation started, not completed

Pinned LotusKit currently exposes no verified high-level bone-animation API. Relevant source files:

```text
.tools/totk-runtime/lotuskit/src/program/structs/engineComponent.hpp
.tools/totk-runtime/lotuskit/src/program/structs/engineActor.hpp
.tools/totk-runtime/lotuskit/src/program/structs/as.hpp
.tools/totk-runtime/lotuskit/subrepo/nnheaders/include/nn/g3d2/ModelObj.h
.tools/totk-runtime/lotuskit/subrepo/nnheaders/include/nn/g3d2/SkeletonObj.h
.tools/totk-runtime/lotuskit/subrepo/nnheaders/include/nn/g3d2/ResSkeleton.h
```

Source-layout leads, **not validated animation-write APIs**:

- Actor component count at +0x220, component pointer array +0x228.
- ModelInfoRef component index 2; source ModelComponent `model` pointer +0x28.
- Source's incomplete Model class declares model matrix at +0x1f8.
- ASRef component index 8. ASComponent binder at +0x10, model accessor/handle fields, actor at +0x90.
- AS ControllerSet current controller +0x18; Controller blackboard +0x40.
- Included `nn::g3d::ModelObj`/SkeletonObj headers are TODO/incomplete and not proof of exact TOTK layouts.

Suggested next investigation: trace native model-unit/submodel skeleton ownership and the frame at which local bone transforms are consumed. A guarded read-only runtime snapshot plus pinned native disassembly can validate this. Do not start arbitrary pointer writes from these incomplete headers. No such snapshot or write was performed in this pass.

REA reverse-engineering tools are connected, but currently **opening a new binary is blocked by stale Hopper cleanup state**, not a new safety rejection. `binary_session` reported open=false. `open_binary` and then `close_binary` returned `cleanup_incomplete` for `hopper-document` and `/tmp/rea-DVNBIp`; authenticated shutdown acknowledgement was absent. macOS app inventory showed Hopper **not running**. The tool still retained that state. No repeated open was attempted after the close failure.

The retained directory contains ownership.json, bootstrap.py, and bridge.sock. Ownership claims the old Hopper PID 25100, created 2026-10-16T04:31:41.324Z. Do not delete ownership files or claim cleanup success without confirming the provider's lifecycle. Ghidra and IDA are not configured. Ordinary local Capstone analysis remains available; label it accurately, **not as REA Evidence**. Historical account-usage-limit failures are separate from this current cleanup error.

The REA skill is `the reverse-engineer-anything skill`. Its recovery guide is in `references/connection-and-recovery.md`. Read those if continuing that route.

## 8. Source MK wheel placement/animation evidence

`scripts/kart_assets_native_placement_probe.py` executes bounded ARM32 MK8DX routines in **Unicorn private emulated memory**, with modeled math/imports. It does not attach to MK8/TOTK or instantiate the source game's full renderer or physics world. Outputs:

```text
assets/source-native-placement/native-probe.json
research/placement/verified-scopes/manifest.json
research/placement/verified-scopes/  (raw verified ARM scopes)
```

Carrier `.work/native/mk8dx-main.elf` SHA-256:
`b45ced902a5ee66fb6ac08077f8aac0d807bae4223518442563f7f341a62a1e2`.

Routines already scoped:

```text
0x2db594..0x2dbcb8  part-combination data
0x149514            wheel physics constructor
0x15fec4..0x15ffc0  render-wheel constructor
0x15a6dc            wheel initialization
0x15d2f0            spring updater
0x15f7a8            position getter
0x160bb4..0x16105c  render-wheel transform
0x161468..0x16149c  inner axle-offset caller
0x15f878            source arm transform
0x15d9d4..0x15da18  source arm transform caller
```

Neutral source physical centers: front X±2.65,Y.0500004,Z4.4; rear X±2.6,Y.3000004,Z-4.4. **Render centers differ**: front X±4.55, rear X±4.86, after matrix-scaled axial offsets. Do not revert to physical centers for mesh placement. Source BODY0/TIRE0 selection gives spring rest3, stiffness.2, damping.9; other part IDs differ. Existing probe has steering0, antigravity0, zero camber selected through its input packet. Expanding it with verified nonzero angle/state inputs could guide correct animation axes and arm response.

Old `assets/source-placement-study` was rejected and must not be installed. BDTR flags `0xefff` are **not a steering angle**.

## 9. Controller and native runtime constraints

Production AS script compiles once and yields in one persistent loop. It reads pad input via a verified camera-hook module signature and the runtime's current record at module+`0x3d90b8`: held buttons u64,+8 left X s32,+12 left Y s32.

It queues the spawn shortcut through the native material menu, waits until all buttons are released for 15 frames, and waits for actor initialization before one-time orientation. Immediate orientation after the rigid body first appeared was overwritten by native initialization; the extra 30-frame wait fixed the backwards spawn/A-interaction failure.

Current parameters per logical frame:

```text
forward cap 2.5; reverse cap 1.0
acceleration increment .045; neutral braking increment .08
dead zone .15
yaw request = steer * .45 * (driveSpeed/2.5)
upright angular feedback = (-rot.a7*2, yaw, rot.a1*2)
```

Drive requests preserve native vertical velocity and native collision/gravity. Parking uses gentle XZ anchor feedback gain2, cap .5 per axis, preserves vertical velocity, resets anchor after displacement>2, and respects native body flag bit30 (velocity-request rejection). Simple zeroing/grounded-vY heuristics previously slid downhill and are not the current implementation.

Native seat identity is **read-only** and guards generation/state. Important correction: `seat+8` is **BaseProcLinkData**, not Player ActorBase. Compare seatID+0x10 and flags+0x18, cooldown+0x74, link data with known Player+0x1a8; only then verify linkData+0x40 equals Player and +0x48 equals ID. Ridable index129, seats count +0x20 and array +0x28. See:

```text
runtime/candidates/native-rider/player_seat_identity.as
scripts/verify_native_rider_identity.py
research/native-rider-identity-independent-check.json
```

Guarded raw pointers do not own actor lifetime; broad reload/destruction testing remains. **Do not keep Actor/RigidBody script handles across sleep; release and reacquire.** Disable ActorWatcher text and WS logs, and pause its slot after spawn: an earlier native getName/JSON path crashed. Clearing a watcher slot does not delete an actor.

Earlier per-shortcut script recompilation caused heap metadata crashes. This was not proven out-of-memory. Preserve the single resident module instead of increasing heaps or returning to per-key script compilation. Avoid `tas::awaitExecFile` (suspected argument declaration mismatch).

Runtime is GPL LotusKit pinned to commit `59dcfccd77b6d4bcfa718bff806bc55be640edb7`. Three patches are shipped with corresponding source/builders:

1. Spawn CreateArg initialization: clears formerly uninitialized bytes +0xd8/+0xe0.
2. Linear velocity address fix: upstream TOTK1.1.0 address `0x7a4cfc` is actually **angular**; correct linear setter is `0x6bf8f8`.
3. Adds explicit AngularVel AngelScript overloads bound to native `0x7a4cfc`.

Do not lose that address correction when changing handling. Native linear getter at `0x11bb3b8`, impulse at `0xccc234`. No unverified activation-bit writes/wake API are shipped. Bit35 research remains partial static inference.

Read `scripts/reproduce_native_runtime.py`, the three `scripts/patch_lotuskit_*` builders, and `runtime/candidates/angular-velocity-110/{binding.s,source.patch,validation.json}`. The package includes the pinned source archive/license and `source/reproduce_runtime.py`. No full devkitPro toolchain is installed; the existing patch workflow uses xcrun clang for small AArch64 assembly and preserves segment layout/hashes.

TOTK address-preserving carrier `.work/native/totk-main.elf` SHA-256:
`fdc607b7037562de10004f3af39f379a91790a53527186421658e7ff5097c8b3`.
Use `scripts/nso64_to_elf.py` for TOTK. The older `nso_to_elf.py` is ARM32 and is for MK8DX, not TOTK. Debug LotusKit symbols are in `.work/native/lotuskit-110-subsdk9.elf`.

## 10. Rebuilding and testing without user chores

Local Python dependencies: `.tools/kart-assets/python` (numpy, PIL, capstone5.0.7, pyelftools.33, lz44.4.5, zstandard.25, Unicorn2.1.4). Most scripts insert these paths themselves. C++/CMake and .NET are available.

Model verification must include the independent C++ MeshCodec decoder and **full decoded-buffer equality**, not just a successful parser read:

```text
.tools/kart-assets/MeshCodec/build/tests/mc_test <compressed-model-folder> <decoded-output-folder>
```

The current geometry workflow preserves material bytes and existing buffer allocations. `.tools/kart-assets/totk-meshcodec/mcpack.py` handles packing; parser code is in `kart_assets_native_cart.py`. Changes adding bones/matrices/animation payloads need explicit capacity/relocation/resource checks.

Controller test generation and compile check:

```sh
set -e
python3 scripts/build_native_controller_test.py
.work/rider/compile_physics runtime/diagnostics/native_controller_matrix.as
```

**Runtime file read limit is 8191 bytes.** The final diagnostic is 7,879 bytes, SHA `625881bc25c519e9861bebafc84f54e061a05ffe030f3fcfc550efc411a6e080`. `scripts/compact_native_script.py` renames only known internal identifiers; API names and strings stay intact. Use `set -e` so a generation failure cannot accidentally install a stale prior test. The host compile harness checks API/script syntax, not actual game ABI or physics. It registers `array`, catching accidental use as a variable name.

`scripts/build_native_controller_test.py` exercises the actual production `controllerFrame`, including simulated shortcut, native A, driving phases, native B, parking, recall and remount. Then it returns to resident input. Read the script before running: it autoloads the top mainland slot and takes control temporarily. `scripts/summarize_native_controller.py --help` gives log-to-result options. The older parking-only diagnostic is historical; use the combined regression for final proof.

To test new assets or startup code: back up installed files, stop the existing emulator cleanly, install only the staged candidate/diagnostic, launch, inspect logs and visuals, and restore normal `autorun.as` after successful or failed automatic tests. Do not leave an auto-driving script installed for the user's next launch.

Launch command used previously:

```sh
'/Applications/Ryujinx.app/Contents/MacOS/Ryujinx' '<repo>/totk.xci' > .work/ryujinx-CHOOSE-NEW-TEST-NAME.log 2>&1
```

Writes under Ryujinx Application Support require the current client's normal sandbox approval mechanism; the user has already authorized routine reversible installs/tests. Do not change permission settings to bypass a rejection. The current Codex exec session ID is `4799` (client-local; Claude may not have access). Its log is `.work/ryujinx-native-complete-regression.log`. Do not kill unrelated Ryujinx instances blindly.

For UI automation, the installed CUA API controls Ryujinx by bundle ID `org.ryujinx.Ryujinx`. Native key presses need about **150ms duration**; very brief presses can miss polling. Its pressKey API only permits one nonmodifier key per call; attempted multi-key Q+O+Up and parallel key calls were unreliable. Use the existing deterministic in-game test script for true controller chords. Do not substitute private keyboard event APIs.

Many Ryujinx logs contain NUL bytes. Use `rg -a` or Python. The test result parser selects drive sample labels with regex `p\d+f\d+|end\d+`; `startswith('p')` incorrectly includes parkStart/parkEnd and causes false mounted-state failures.

Package with `scripts/package_native_kart.py`; inspect `--help` for explicit base/ordered overlays/evidence/lab files. Keep GPL source patches and exact reproduction working. Build a new named package after real improvements; preserve the current working ZIP.

## 11. Mario Kart handling work after animations

Existing evidence:

```text
research/handling/                 Performance.bin: 17 sections, 395 rows
research/movement-code.md          Native acceleration helper/caller and registration evidence
research/placement/               Source wheel/arm/parts code scopes
```

The Performance.bin parser has exact byte roundtrip and a documented standard-parts reference. Runtime units and the complete application path remain incomplete. Existing acceleration-helper REA evidence is partial, not an entire controller reconstruction. Start with that evidence, identify which fields affect acceleration/turning/grip and when, then map them deliberately to TOTK's native body. Do not port arbitrary source units directly into world-unit velocities.

Suggested staged acceptance: first animation response to actual measured forward travel (forward/reverse/stop), both steering directions while stationary/moving, and clear mount/dismount; then controlled handling changes with acceleration/speed/turn radius/braking measurements; then drift/boost and harder terrain. Preserve the current native mount/camera/parking baseline throughout.

## 12. Handoff checklist

- Working installed module and normal script hashes rechecked: **yes**.
- Current ZIP and regression evidence available: **yes**.
- Animation changes installed during this latest pass: **none**.
- New wheel animation runtime route proved: **no**.
- New entry animation candidate validated in game: **no**.
- Full Mario Kart handling completed: **no**.
- Codex implementation paused for Claude takeover: **yes**.

Any worker addendum below describes isolated research/candidates, not an installed or validated replacement for the working build.

## 13. Final animation findings from the stopped workers

`research/animation-assets-handoff/README.md` and its accompanying reproducible inventory/topology probes contain the latest asset findings:

- Retail `SpObj_Cart_A.anim.bfres.zs` contains only **SpObj_Cart_Unlock**, eight frames. Its wheel rotations are constant identity, and wheel translations use the old native positions. It supplies no rolling or steering curves and could reset the corrected assembly if blindly bound.
- The four independent current tire rigid matrices are indices **1–4**; Skl_Root uses index0. Existing geometry is structurally ready for a wheel-bone transform, but the active runtime submodel update route remains unproved.
- Native ControlStick LeftRight drives Handle_J Euler Z roughly 70–110 degrees over parameter frames0–2; UpDown drives Euler Y roughly ±10 degrees. Actual AS selection still needs runtime verification.
- Hidden native host shape0 has enough existing vertex/index capacity for a first steering-rim transfer (close622 vertex slots/394 triangles; far78 slots/26 triangles). Source rim topology is 126 triangles/78 vertices at LOD0, 36/35 at LOD1, and12/24 at LOD2.
- The rim must turn about its own axis. Current Handle_J pivot lies below/behind the ring center. Merely inverse-transforming neutral geometry into that bone would preserve the neutral pose but swing incorrectly when turning. Consider a helper bone or a corrected handle frame with compensated hand targets; test material compatibility too.
- The likely rim/spoke components still need an isolated visual preview. Topology/location are evidence for a candidate component, not final visual confirmation of every rotating part.

`research/native-seated-transition-investigation.md` also records the decoded Player ASB strings. Their presence does not establish graph edges or active clip routing. A public ASB parser download attempt was previously rejected by automatic approval review because of account usage limits; it did not execute. This is distinct from the root's current stale Hopper cleanup issue.

Only documentation and research inventory outputs were added in this latest pass. The working baseline, installed mod, normal startup, and original game exports were not changed.
