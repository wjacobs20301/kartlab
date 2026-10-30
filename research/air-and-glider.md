# Jumps, air handling, tricks and the MK8 glider — October 17, 2026

Status: installed and tested in Ryujinx (regression 12/12, recall 8/8, signed 4/4; `runtime/diagnostics/air_test.as`).

## Air
* Airborne = the ground ray (same game query as the ground effects, research/drift-sparks.md) finds nothing within
  0.7 m for 2+ frames. Landing = ground again.
* In the air: speed held (no accelerate/brake unless boosting), steering 30% of ground [chosen; MK8DX has no separate jump
  handling stat], no hop, drift continues but does not charge, no sideways grip.
* Trick: R within 8 frames after take-off, or up to 6 frames before (ramp lip pre-buffer). Landing after a trick gives a
  31-frame boost [chosen = MK8 mini-turbo length]. Measured: trick → landing boost 11.4 → 14.2 m/s.

## Glider
* Controls: **Y** while airborne and ≥ 2.5 m above ground opens it; Y again folds; landing folds it.
* Physics: speed eases to PRSG row 14 = 8.225 MK units/frame (14.8 m/s, measured 14.79). Descent eases to 1.6 m/s
  (stick back 0.6, stick forward 4.5 + 6% speed), with gravity compensation 0.95 m/s per frame [measured TOTK pull].
  Measured steady sink ~2.4 m/s; dive ~5 m/s. Steering 60% of ground [chosen].
* Model (`scripts/build_glider.py` → `assets/kart-glider`): MK8DX Wing_Std (Super Glider), Wing_Std_2mat sail LOD0
  (44 tris) + 30 of 43 frame LOD2 tris, in host shape pCylinder11 (material Mt_Rock_ControlStick_A, texture replaced by
  Wing_Std_Mro_Alb 512² BC1; normal map flat). Rigid-bound to host bone **Control** (matrix palette entry 0 re-pointed
  Skl_Root → Control; all other matrix-0 shapes are collapsed). Control's rest scale is 0 (folded on every ControlStick);
  the clips' "Control" track is renamed "Contro_" so animation no longer resets it.
* Runtime: the controller scans the host model object for Skl_Root's record (now at +2376; it moved with the model
  rebuild, so it is found by signature) and writes Control's record (two records earlier): scale eases 0 → 1 in ~6 frames,
  attach point (0, −0.15, −0.45) in kart space.
* Verified: bone record 0 before deploy, 0.34 → 1 opening, 0.8 → 0 after landing; screenshots show it hidden while driving
  and open while gliding.

## Not done
* No glider tilt/bank animation; the frame is the low-detail LOD (30 tris).
* No auto-deploy from ramps (MK8 deploys on glide ramps automatically).


## Oct 17 afternoon: glider v2, banking, camera (installed; controller `49015fe6…`)

* **Model v2** (`scripts/build_glider.py` → `assets/kart-glider-v2`): MK8's in-race glider `Wing_Std` (one shape, sail +
  frame, LOD0 336 / LOD1 188 tris, all kept) in the hidden host shape `Stand_010` (1152 + 505 vertex slots, same 8/12-byte
  layout, rigid, matrix 0 = Control); its shape record +0x52 (material index) set 3 → 1 (Mt_Rock_ControlStick_A = glider
  texture). The v1 slot pCylinder11 is emptied. RSTB unchanged (`58d9ba98…`). Backup of v1 model:
  `.work/backups/host-model-glider-v1.bfres.mc`.
* **Bank / pitch:** body tilt target while gliding: stick right → right side down (0.55 → ~29°), stick forward → nose down
  (0.35 → ~19°); angular velocity = 4 × (up × target), **world axes** (a body-axis version flipped the kart). Measured in
  game: bank converges to sin 0.48–0.52 each way, back to level when centred, no overshoot.
* **Left stick hidden from the game while riding** (outLX/outLY = 0): the vanilla control stick tilts a contraption with
  the left stick in the air; that is what rolled the kart to 56° and threw Link off in the first bank tests.
* **Sound:** engine, wheel run/slip, drift squeal and sizzle are silent while gliding (flutter only).
* **Camera** (`cameraFrame`): LotusKit `camera::freeze(up,pos,at)` every frame while riding, `camera::toggleFreeze()` to
  hand back (out of the kart, menus, loading). Follows the travel heading (lag 0.13/frame; 0.05 air, 0.06 glider), drift
  swings 0.16 rad outward, distance 4.6 m + speed, +0.8 m boosting, +0.7 m kick when a boost starts, −0.5 m braking;
  glider 6.4 m back, 3.8 m up. Right stick looks around (springs back). ZL+ZR+D-pad Left toggles it (default on).
  All values chosen; MK8DX camera tables not decoded. FOV is not reachable through this API.
* Offline compile checker `.work/rider/compile_wheels` rebuilt with the camera stubs (old: `compile_wheels.pre-camera`).
* Testing note: the PS4 controller was unplugged; tests use `.work/use_keyboard_input.py` and restore the PS4 config.


## Oct 17 late afternoon: user-test fixes (installed; controller `ae369bda…`)

* **Thrown off on long falls:** TOTK releases the rider once he has been falling faster than ~10–13 m/s for ~1.5 s
  (free falls from ~240 m, `runtime/diagnostics/high_fall_test.as`: released with caps 12/18/32 m/s, never with 6 or
  9 m/s over 200 m; a 2.4 m/s glide for 60 s never). Fix tried: terminal fall speed 9 m/s; the user wants normal-speed free fall, so the cap now applies only while gliding
  (glide sink 2.4, dive ~5 m/s never reach it). Free fall again releases Link after ~1.5 s, as in vanilla TOTK. Not found: where the game tracks it (not a world-Y in the player actor; clamping Link's body velocity did
  nothing; the rule is data-driven, no code strings).
* **Glider left open on a respawned kart:** host model instances are pooled; a reused one kept Control's scale 1 while
  the controller thought it was closed. Now any new host model (or forgetKart) forces a rewrite of the glider state.
* **Menus:** the pause menu and map raise GamePause (Pre/PostGamePause while opening/closing) and pause target
  Custom_PhysicsUpdateWorld, not Actor. `menuOpen()` now hands back all buttons and the camera
  (`runtime/diagnostics/menu_probe.as`: override off during both menus, back on after closing, still riding).
* **Camera** further back per user: 6.2 m / 2.4 m up (was 4.6 / 1.8); glider 7.6 / 4.4.
* **Script-heap crash mitigation:** sound selection uses integer ids; key strings are built only when a sound starts
  (a "Kart_Gli…" text pointer crash on the script thread). The old "Horse_Li…" game-thread crash was seen once again
  before any kart action; still unresolved.


## Oct 17 evening: mid-glide release FIXED with a main-module patch (installed; controller `5a3d98d8…`)

* Cause (disassembly): AI node **ExecuteActorControlStickPlayerRiding** update 0x1b9e2b4 → 0x1b9e0bc reads the linear
  velocity of its actor's main rigid body (0xd34780 → 0x780b14) — Link's body, which jitters far past the kart while
  he rides the seat (logged −17…−55 m/s while the kart sank at 7). Release (0x1648e4c) when vy < −10 for 1.25 s, or at
  once when x²+z² > 1600 (40 m/s horizontal). Sustained glider turns tripped it (repro: `runtime/diagnostics/turn_test.as`,
  released at frames 133–148 every run; dive/bank/lean/fall-speed changes did not help).
* Fix: `scripts/build_fall_release_patch.py` → `runtime/candidates/fall-release-110/D5AD6AC71EF53E3E52417C1B81DBC9B4142AA3B3.ips`
  (IPS32, installed in the mod's `exefs/`): 0x1b9e1c0 `b.pl`→`b` (timer never counts), 0x1b9e15c `b.le`→`b` (no
  horizontal release). Ryujinx log: "Patching address offset 1b9e1c0 / 1b9e15c". Every ControlStick is the kart in this mod.
* Verified: 60 s glide holding full turns both ways — rider stays; turn + dive with the original 29°/19° tilt to
  landing — stays; normal-speed free fall from 240 m (to 89 m/s) — stays through landing.
* Reverted the temporary changes: free fall is uncapped (cap only while gliding, never reached), glide bank 0.55 /
  pitch 0.35 / dive 4.5 restored, combined lean cap 0.65 (~33°).
* The old "Horse_Li…" game-thread crash showed up in ~1 of 4 test launches today (right after mounting or at start).


## Oct 18: user feedback fixes (installed; controller `399a5a76…`)

* **Free-fall camera:** the camera height lagged and it aimed at that lagging height, so a fast fall left the kart
  below the frame. Now it aims at the kart's position led by CAM_LEAD = 0.07 s of vertical speed and stays within
  CAM_MAX_LAG = 3 m of it. Screenshots of a 240 m free fall (to 89 m/s): kart centred all the way.
* **Sideways slide while gliding:** air steering never removed sideways speed, so every glider turn converted forward
  speed into a slide that built up. Air drag on the sideways component: glider 0.08, plain air 0.01 per half-frame
  step. 60 s turning glide: sideways speed stays ±1.35 m/s, forward 14.8.
* **Link leans into turns:** the left stick goes to the game again on the ground (hidden only in the air, where the
  vanilla stick tilts the contraption), so Link plays his Turn_L / Turn_R clips, now with the lean pose
  `assets/kart-seated-lean` (LEAN="12,6,15" on the legs-b recipe; legs-only rebuild reproduces legs-b byte for byte).
  Player_Animation backup: `.work/backups/Player_Animation.legs-b.anim.bfres.zs`.
* **Crash null+0x8C06C (found because of that):** v1/v2 sound builds renamed the vanilla parent keys TiltedStick /
  ReturnNeutralPosition. The game's stick nodes (ExecuteControlStickPlayTiltedSound → 0x1351158 → 0x815154 → 0xb28048)
  resolve them once and keep the call-entry pointer, so the rename left a null entry that crashed when the stick
  tilted (2 of 3 runs with the stick passed). Now the names stay and their six bank assets are silent. DB `4449cc83…`.
  Two drive tests with the stick passed + one glide/trick test: clean.
