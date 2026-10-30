# Handoff for Claude — October 16, 2026

Start with [CLAUDE_HANDOFF.md](CLAUDE_HANDOFF.md) in this folder. It records the working build, exact installed hashes, tests, file map, animation findings, tool limitations, and next steps. The user's next priority is **animations, then Mario Kart handling**. Codex implementation is paused for takeover; the installed prototype and normal startup remain unchanged. Companion research: [animation assets](research/animation-assets-handoff/README.md) and [seated transitions](research/native-seated-transition-investigation.md).

# Wheel animation update — October 16, 2026 (Claude)

The installed build now animates the kart's wheels: tires roll with measured travel (including reverse) and the front wheels steer with the left stick, even while stationary. All 14 regression checks pass with the animation active. Installed startup: `runtime/candidates/native-rider-wheels/autorun.as`; package `dist/KartLab-TOTK-1.1.0-native-wheels-2026-10-16.zip`. Mechanism, evidence and hazards: [research/native-wheel-animation.md](research/native-wheel-animation.md). Everything below this section describes the build before this update.

# Current development build — October 16, 2026

A working native riding prototype is installed for TOTK **1.1.0 / Ryujinx 1.3.3**. Link mounts with A, sits in the kart, drives with the left stick, and dismounts with B. Mario colors, source-positioned wheels and actual suspension arms render. The native camera follows Link. No per-frame Player positioning is used.

**ZL + ZR + Up**, then release all three, spawns or recalls the same unoccupied kart. The controller remembers the shortcut across the native material menu and waits for actor initialization before applying its direction. Recall does not duplicate the actor. Normal startup is restored; autonomous tests have ended and the live game runs the resident controller.

The final combined regression passed **14 checks**: queued spawning, ground entry, forward movement, both steering directions, neutral braking, reverse, native B exit, unmounted input isolation, sampled upright/mounted state, slope parking, same-actor recall and remounting. Parking drift was about **0.003 world units over 180 logical frames**. See `research/native-complete-regression-results.json` and its immutable log. Normal keyboard W driving and native camera orbit were also observed.

The core physics fix corrects an upstream linear setter that actually wrote angular velocity. The module adds a separate angular API and retains the spawn initialization fix. SHA256: `b0dc2c3bf8b19d95e43c8ad58d3e461d485a2e1ad0b9d2060f843a8a6d80ad06`. All three source patches apply to the pinned archive; exact binary reproduction passed.

Current package: `dist/KartLab-TOTK-1.1.0-native-rider-2026-10-16.zip` (28,601,655 bytes). The 19 installed mod files and normal startup script exactly match its manifest; ZIP integrity and packaged runtime reproduction pass.

The controller uses gentle authored handling rather than the complete Mario Kart engine. Dynamic tire spin/steering/suspension, entry/exit animation refinement, drift, boost, Mario characters, broad terrain/actor-lifetime stress and Switch hardware validation remain unfinished. Shared Cart/ControlStick/vehicle-animation resources are replaced in this isolated prototype. Guide: `runtime/NATIVE-KART.md`.

Everything below is a historical development record. Its older controls, hashes, test conclusions and ZIP references are superseded by the status and exact receipts above.

---

# Mario Kart vehicles in Tears of the Kingdom

## Intended result

Drive Mario Kart 8 Deluxe karts around TOTK, eventually including Mario Kart characters and handling. Test in Ryujinx and validate the resulting mod separately on a modded Switch.

## Observed inputs

- `mk8dx.xci` — 7,771,616,256 bytes. Ryujinx's game library displays version **1.7.1**.
- `totk.xci` — 17,536,620,544 bytes. Base game **1.0.0**.
- Ryujinx's selected TOTK update is `The Legend of Zelda Tears of the Kingdom [0100F2C0115B6800][v131072][Update].nsp`. Its extracted control metadata confirms **1.1.0**, the target requested by the user.
- Both files have an XCI `HEAD` signature at offset `0x100` and an HFS0 root at `0xF000`, with update, logo, normal, and secure partitions. This inspection read container headers only.
- REA `open_binary` rejected the Mario Kart image as an unsupported binary format. That initial container attempt opened no executable session. Later analysis used derived ELF carriers from the verified NSO exports, including native MK8DX function evidence.
- Python, .NET, CMake, and Clang are available. A project-local hactool was built in `.tools/hactool` for extraction.

## Completed extraction

| Game | Exported version | RomFS files | ExeFS files | Output |
| --- | --- | ---: | ---: | --- |
| Mario Kart 8 Deluxe | 1.7.1 | 4,701 | 5 | `extracted/mk8dx` |
| Tears of the Kingdom | 1.1.0 | 304,469 | 5 | `extracted/totk` |

Each export combines its base program with its update using hactool's `--basenca` support. These are complete updated views, not just patch files. Mario Kart's update was embedded in its XCI; TOTK's update was read from the NSP selected in Ryujinx. The source images and emulator configuration were not modified.

Selected base program, update program, and update control NCA files matched their CNMT SHA-256 hashes. Extraction ran with section/signature verification enabled and reported no failures. Independent validation compares exported paths to the extraction log, checks file counts and sizes, and decompresses each NSO module to check every enabled segment hash. Finder `.DS_Store` files are excluded from the asset inventory.

Per-game `extraction.json` reports record the verified content hashes, executable build IDs, and module validation. `romfs-inventory.tsv` lists the exported assets. The main build IDs are:

- MK8DX: `FE1B230800D4933C617C691273CA597800000000000000000000000000000000`.
- TOTK 1.1.0: `D5AD6AC71EF53E3E52417C1B81DBC9B4142AA3B3000000000000000000000000`.

## Current milestone (October 15, 2026)

**User follow-up:** the visible kart had no entry/driving interaction and retained TOTK colors. The earlier remote-loop evidence did not establish a playable kart. Revised controls and a real Mario texture atlas are now installed for a fresh test; game results are pending. See `research/color-control-v2-install.json`. A separate native Control Stick mount diagnostic is staged/installed, requiring one manual Ultrahand bond; seated Link and automatic assembly remain unfinished. A later watcher crash was traced to actor-name JSON logging and is mitigated in the test scripts by disabling/pausing watcher telemetry. See `research/actor-watcher-crash.md`.


A complete mainland starter slot has now been imported at the user’s request, with the previous account save backed up to `.work/backups/totk-before-mainland-save`. Its stored position is MainField (-253.834, 131.938, -152.786), near Lookout Landing. Source/provenance: `saves/mainland-starter/source.json`; import receipt: `research/mainland-save-import.json`. Verified in-game: mainland terrain rendered, and the user moved Link and used the paraglider. The user has now reached an open area for kart testing.

The current prototype visibly renders the MK8DX standard kart body, steering wheel and four wheels in **Ryujinx 1.3.3 / TOTK 1.1.0**. Gravity, road contact, scripted motion, a following camera and native PS4-controller input have been observed. The 900-frame controller session completed and restored the camera and Link controls. Evidence: `research/runtime-test-results.json`, `research/native-pad-controller-test.json` and `.work/ryujinx-kart-model-patched-spawn-test.log`.

The first invisible/motionless spawn was followed by a native-module fix that initializes previously uninitialized spawn-option bytes. Both the original cart and imported model moved with the patched module. The exact derivative module, source patch, byte-patch tool, pinned upstream source and GPL license accompany the combined package at `dist/KartLab-TOTK-1.1.0-prototype.zip`. The original module is backed up. This supports the fix in this configuration; it does not establish general compatibility. Upstream describes its 1.1.0 build as untested/unsupported. Switch hardware remains untested.

Use **ZL+ZR+D-pad Right** (PS4 **L2+R2+Right**), then release, near the current Lookout Landing test area. Left stick controls throttle/reverse and steering. **B** (PS4 **Cross**) exits; the session otherwise ends after 900 logical frames, approximately 30 seconds. Link stays at his starting position while the camera follows the kart. This is remote driving, without a seated rider. The cart spawns at a fixed nearby road position, so this script deliberately accepts only the Lookout Landing area. Normal Up spawns an uncontrolled cart; Down stops and clears slot 1. Clear before another test if the slot is occupied. Clearing does not delete actors. No network listener starts automatically.

The visual retains TOTK materials and collision. Mario colors, improved wheels, mounting/entry/exit, rider animation, full input interception, recovered MK handling, drift, boost and characters remain unfinished. Avoid loading/fast travel during the test; native actor lifetime tracking still needs work.

### Reusable evidence and source

- `research/kart-assets.md`: source resources, conversion, and geometry validation; `assets/standard-kart/standard-kart.gltf` is the source model preview asset.
- `research/handling/`: Performance.bin parsed into 17 sections and 395 rows, exact byte roundtrip, documented standard combination reference. Units and full runtime interpretation remain incomplete.
- `research/movement-code.md`: native MK8DX acceleration scalar helper and caller recovered with retained REA evidence, plus observed field registrations. This is partial executable analysis, not the complete handling engine.
- `research/totk-runtime.md` and `runtime/README.md`: pinned runtime, target instructions, host checks, and integration limits.
- `runtime/scripts/`: local spawn/motion/clear AngelScript sources; `scripts/package_prototype.py` combines the runtime and geometry.
- `.work/ryujinx-complete-save-test.log`: successful startup/load test log. UI observation established Continue entries and controllable Link in Room of Awakening.

This is a mod in development; the first playable driving milestone below is not complete.

## Proposed implementation stages

1. **Complete:** export each game's RomFS (assets/data) and ExeFS (executable files), including the selected updates. Record executable build IDs before choosing patch locations. Keep exports separate from mod output.
2. Select one kart and inventory its model, textures, skeleton, wheel animations, and associated parameters. Trace acceleration, braking, steering, drift, boost, and ground contact in Mario Kart's executable where needed. Distinguish measured behavior, static evidence, and unknowns.
3. Investigate TOTK's actor, physics, player interaction, input, and camera interfaces on the exact target build. Choose between adapting an existing vehicle assembly and implementing a custom vehicle actor/controller based on evidence.
4. First playable milestone: one kart driven by Link, with spawning, entry/exit, acceleration, braking, steering, terrain collision, and a usable camera. This is a proposed milestone, not an established supported feature set.
5. Recreate Mario Kart handling in that controller using recovered parameters and behavior. Tune for TOTK's terrain and timing. Add drift and boost after basic driving is stable.
6. Convert and integrate Mario Kart characters, including animation/rigging work and rider attachment. Add other karts and advanced features after the prototype passes testing.
7. Package for Ryujinx and Atmosphere and test both. Emulator success alone does not establish hardware compatibility.

Importing a model does not transfer its gameplay behavior. A direct transplant of Mario Kart's executable routines has not been established as feasible; those routines may depend on that game's engine and surrounding systems.

## Next investigation

Next, implement mounting and rider attachment, then improve steering, terrain response and input isolation beyond the bounded remote test. Convert materials and wheel detail separately. Validate repeatability and Switch execution before claiming a playable release.

Export layout:

```text
extracted/
  mk8dx/
    romfs/
    exefs/
  totk/
    romfs/
    exefs/
```

## Extraction tooling

`scripts/extract_games.py` has four stages: `containers`, `metadata`, `export`, and `verify`. Invoke with `python3 scripts/extract_games.py <stage>` from this folder. Completed program exports are not overwritten. Intermediate NCAs, control metadata, and logs remain in `.work/extraction` for further investigation.

The local extractor is [SciresM/hactool](https://github.com/SciresM/hactool), commit `1d64a83450e025622f3468c28fc4164dad2c5ef6`, built with bundled mbedTLS. Two small local changes read Ryujinx's existing key directory through `TOTK_MOD_KEY_DIR` and accept identical duplicate title-key entries. Key material was read locally, without printing it or changing the emulator's key files. Decrypted key output was suppressed.

The metadata reader follows the [CNMT format documentation](https://switchbrew.org/wiki/CNMT). MK8DX's patch metadata also lists absent incremental-install delta fragments; those are not needed to reconstruct the complete game from the included program NCAs.

## Candidate references, not compatibility guarantees

- [Switch Toolbox](https://github.com/KillzXGaming/Switch-Toolbox): model and resource tooling to evaluate against the actual exported assets.
- [TOTK SortFixer](https://github.com/MediaMoots/TOTK_SortFixer): an existing TOTK executable mod using exlaunch; evidence that executable modifications are possible, not evidence that vehicle interfaces are already available.
- [TOTK TAS documentation](https://github.com/aquacluck/totk-tas-docs): examples of reproducible movement investigations and measurements.

## Unresolved questions

- Any enabled runtime mods that should be considered during later gameplay testing; extraction used the source containers and selected updates directly.
- Which kart and character to use first; the proposed default is a standard kart with Link initially driving.
- Remaining texture/material conversion, character rigs, steering/drift/boost behavior, and mapping source parameter tables to the runtime.
- A seated rider, robust input isolation, terrain handling and lifecycle tracking, plus hardware resource budget.
- Whether TOTK 1.1.0 exposes sufficient integration points for the proposed vehicle controller; no later update is assumed.
