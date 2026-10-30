# TOTK runtime integration finding ledger

Target: extracted TOTK **1.1.0**, main NSO build ID `D5AD6AC71EF53E3E52417C1B81DBC9B4142AA3B3000000000000000000000000`. Native REA session was reserved by the main investigator; this branch used primary source bindings and format-aware NSO checks, not a second disassembly session.

## Answered: an implementable experimental integration path

The open source [lotuskit project](https://github.com/aquacluck/totk-lotuskit/tree/59dcfccd77b6d4bcfa718bff806bc55be640edb7) supplies a prebuilt **TOTK_VERSION=110** native exlaunch module and an embedded AngelScript interface. Its README calls 1.1.0 untested and unsupported. Existence of the bindings/build is source evidence, not proof of correct behavior in our game.

The official [matching release](https://github.com/aquacluck/totk-lotuskit/releases/tag/2026-04-20-59dcfccd77b6d4bcfa718bff806bc55be640edb7) was downloaded into `.tools/totk-runtime/lotuskit-110.zip`. Its SHA-256 matches the GitHub asset digest `dc7b59413cf62e8a8c961aeb905debaacd111d53889fe5bfdd45d0c71cf33d2c`. ZIP CRCs passed. `main.npdm` has META magic; `subsdk9` has NSO0 magic. All three decompressed runtime segment hashes passed; see `totk-runtime-binary-validation.json`. This establishes file integrity, not runtime correctness.

The staged installable mod is `runtime/dist/KartLab-110/mod`; local-only SD sidecars and optional browser controller accompany it. The corresponding upstream source and GPL-2.0 license are included. No source game data is included in this runtime package.

## Source API chain and exact offsets

Primary source files are relative to the pinned repository:

- [`src/program/util/actor.cpp`](https://github.com/aquacluck/totk-lotuskit/blob/59dcfccd77b6d4bcfa718bff806bc55be640edb7/src/program/util/actor.cpp): fills `BaseProcMgr::CreateArg`, calls `ActorMgr::requestCreateActorAsync`, assigns returned `PreActor` to the watcher, forces transforms and retrieves the main rigid body.
- [`src/program/script/globals.cpp`](https://github.com/aquacluck/totk-lotuskit/blob/59dcfccd77b6d4bcfa718bff806bc55be640edb7/src/program/script/globals.cpp): exact AngelScript signatures used in the four authored scripts and browser-generated pulses.
- [`src/program/structs/phive.hpp`](https://github.com/aquacluck/totk-lotuskit/blob/59dcfccd77b6d4bcfa718bff806bc55be640edb7/src/program/structs/phive.hpp): request-set velocity wrapper and version-dependent structures.
- [`syms/output/TOTK_110/syms_exl_reloc.inc`](https://github.com/aquacluck/totk-lotuskit/blob/59dcfccd77b6d4bcfa718bff806bc55be640edb7/syms/output/TOTK_110/syms_exl_reloc.inc): upstream names/offsets below.
- [`src/program/script/hotkey.cpp`](https://github.com/aquacluck/totk-lotuskit/blob/59dcfccd77b6d4bcfa718bff806bc55be640edb7/src/program/script/hotkey.cpp): exact button-mask match with repeated cooldown; does not consume Link's native input.

| Upstream symbol | Main-relative offset | Used by |
| --- | ---: | --- |
| `engine::actor::ActorMgr::requestCreateActorAsync` | `0x00bde0ac` | spawn cart |
| `engine::actor::ActorBase::forceSetMatrix` | `0x0070e204` | shallow yaw test |
| `phive::RigidBodyBase::getNextLinearVelocity` | `0x011bb3b8` | preserve current Y velocity |
| `phive::RigidBodyBase::requestSetLinearVelocity` | `0x007a4cfc` | horizontal motion request |

`runtime/verify_target.py` confirmed local main build ID and enabled segment hashes, checked each cited code offset maps to nonzero text, and recorded 32-byte instruction windows with SHA-256 in `totk-runtime-symbols.json`. **Those checks do not independently establish semantic identities or calling conventions.** Names, structures and ABI remain upstream reverse engineering claims requiring execution/disassembly confirmation.

## Implemented prototype and tests

- `runtime/scripts/spawn.as`: pause/player/slot guards, async native wheeled cart spawn, waits at most 120 intended frames, validates actor name and body, enables telemetry.
- `runtime/scripts/drive_smoke.as`: 90 intended 30-fps frames, max experimental speed six, shallow yaw, zero final horizontal velocity. Preserves vertical velocity. No handle is retained across sleep.
- `runtime/scripts/clear.as`: stops the controlled cart where safe and clears slot 1.
- `runtime/scripts/autorun.as`: readiness toast and local-only chords. No actor creation and no network listener start.
- `runtime/panel`: optional manual WS connection, directional keyboard/pointer control with cap six and 30-second session limit. Uses experimental acceleration/steer; no MK table mapping claim.

Host verification passed: all four scripts compile in the actual pinned AngelScript engine; eleven simulated API scenarios passed; panel controller tests passed for forward/reverse caps, steering, braking, invalid numeric inputs and Y preservation. A generated negative-yaw controller pulse also compiled and executed against host stubs. This is meaningful syntax/control-flow verification, not game/emulator execution.

## Unresolved at initial staging (historical)

The native cart actor name exists in the extracted RomFS, but its main rigid body, orientation, driven collision response, per-frame units and scheduling have not been observed in game. The forced-transform turn is an integration probe, not a tire or suspension model. On a slope it can over-constrain orientation. Cart lifecycle during loads is not robust; explicit clearing is required because upstream acknowledges stale watcher crashes. Other exefs mods can conflict. Full controller input interception, mounting/dismounting, Link animation attachment, native follow camera, wheel animation, ground contact, drifting, boosts and hardware performance remain unresolved.

Upstream architecture assumes a script server if its frontend is used, but the supplied autorun does not start it. The optional panel requires explicit user activation of the server chord. It has not been used to execute scripts on the user's emulator in this branch.

Next acceptance evidence: boot exact 1.1.0 with isolated mod; readiness toast; successful async spawn; 90-frame probe recorded with body position/velocity; stop/clear then load/reload stability; manual directional pulses; hardware validation separately. A post-intro test save is needed for a useful world/vehicle test.

## Runtime observations — October 15, 2026

Ryujinx 1.3.3 launched TOTK 1.1.0 with the isolated KartLab_110 mod. The emulator log records replacement main.npdm/subsdk9 and RomFS files; in-game startup displayed the lotuskit 110 autorun toast and our Kart lab readiness message. The complete starter save was recognized by Continue and loaded Room of Awakening. Link movement was verified using the configured keyboard controls, and the save loaded successfully again after a restart. Logs: `.work/ryujinx-complete-save-test.log` and `.work/ryujinx-kart-test.log`.

This establishes startup and script autorun on this emulator/build. It does not yet establish successful cart creation, rendering, physics, or hardware execution. The user is taking Link outside for the next test. Our UI tool cannot send the three nonmodifier keys O+P+Up as a single chord, so no successful spawn input has been established yet.

### Mainland and first spawn

The shared complete mainland save loaded successfully in Ryujinx 1.3.3 / TOTK 1.1.0. The user moved Link and used the paraglider near Lookout Landing, then reached the open road. Save provenance and backup: `saves/mainland-starter/source.json`, `research/mainland-save-import.json`.

At log time 00:02:24.804 in `.work/ryujinx-mainland-save-test.log`, `actor::createAndWatch(1, SpObj_Cart_A_01, pos(-261.102142, 126.162460, -200.864029))` returned true, result code 0, with a non-null PreActor. UI telemetry subsequently showed the actor assigned to slot 1. The user reported the occupied-slot message on a repeated spawn chord. This establishes native actor creation/watcher assignment. The cart model was not visibly confirmed in the observed camera views; telemetry remained at its initial position. Do not infer successful render or physics from creation alone.

The installed motion probe was updated with sys::debugLog start/end position and velocity output after compiling it in the pinned AngelScript host and passing eleven logic scenarios. Its earlier installed version is backed up; see `motion-probe-telemetry-install.json`. The user was asked to press the Right chord for its first execution; runtime response is pending. The distribution ZIP predates these diagnostic changes.

### Initial failed test, recovery, and native candidate (historical)

The automated test executed its 90-frame motion probe. Persistent logs show exactly the same cart position (-261.102, 126.162, -200.864) and zero velocity before/after. The fixed camera aimed at that position showed an empty road; camera restoration and watcher clearing completed. This fails the render/motion acceptance criteria.

The original-model comparison stalled at 0 FPS while loading, before spawning. It does not establish whether geometry caused the failure. Recovery with the normal autorun loaded the mainland successfully at approximately 30 FPS; the visual replacement remains temporarily disabled and backed up. No network server was started.

The pinned native source declares CreateArg without value initialization. Shipped runtime ELF analysis (SHA256 c1b35edd9432dec974f94ce2a7fe017d174045800b1542861cad1c33cc2fe4db; REA Evidence ev_1db4e4f5bba71d0e59fc94133843261936e0bf118eafbaa6ad9b6ac2a0e399c8) at createAndWatchPosRot 0x64b30 corroborates missing initialization of CreateArg +0x48..+0x57. Those options reside at SP+0xd8..+0xe7 before the game call. Their precise semantics and their role in the observed failure remain unknown.

A separate offline candidate clears those bytes, preserving all surrounding instructions, RO/data, addresses and BSS. See runtime/candidates/zero-create-arg/validation.json and scripts/patch_lotuskit_spawn_init.py. Independent Clang AArch64 assembly matches the stub; hactool --verify reports all segment hashes GOOD. It has not been installed, rebuilt from source, or tested in-game. The candidate includes the matching base source archive, source fix patch and GPL license. No successful runtime fix is asserted. The native analysis session was closed.

## Current result: imported kart and native gamepad remote drive

Subsequent tests installed the initialized-spawn derivative (SHA256 59d61add33f737325500a48eb94d35f0d4db59564a99cca60d07459d3fe82841). With the original model, gravity and motion responded. With imported MK8DX geometry restored, the kart body, steering wheel, exhaust and four wheels visibly rendered, and the bounded motion probe changed cart position/velocity. A following camera tracked the moving kart and was restored afterward. This supersedes the earlier invisible/motionless result and the earlier uninstalled-candidate status.

The next native PS4-controller test validated a local input bridge using the pinned camera hook and ELF Record::currentInput symbol. Bridge code/provenance: runtime/scripts/drive_pad.as and .work/native/controller-bridge-symbols.json. Human left-stick input was logged at frame 90 (29141, -6489) and frame 120 (26040, -13592), with the cart changing position. The user confirmed the kart appeared. The test completed 900 frames; the log explicitly recorded camera/Link control restoration at 00:12:24.745. A subsequent UI observation showed normal Link gameplay with the kart visible at approximately 30 FPS. Log: .work/ryujinx-kart-model-patched-spawn-test.log; receipts: native-pad-controller-test.json and runtime-test-results.json.

The temporary spawn hot-load entry was restored. Normal autorun now binds ZL+ZR+Right to the 30-second remote driver. It requires the current Lookout Landing region and spawns at a fixed road position. Native input still reaches Link, whose position is held during the remote test. This does not implement a seated rider or recovered MK physics. Materials, wheels, mounting, robust actor lifetime/input interception, terrain handling, drift, boost and hardware validation remain unfinished. No network listener was started.
