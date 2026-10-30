# Native seated transitions: handoff snapshot

Implementation stopped at the user's handoff request. **No transition asset
candidate has been built or installed by this investigation.** The current
observed seated baseline is the parent agent's `assets/native-seated-hybrid`,
built by `scripts/build_native_seated_hybrid.py`; see its validation receipt.

## Verified local inventory

The supplied TOTK 1.1.0 `Model/Player_Animation.anim.bfres.zs` parses into 1,560
skeletal animations with the existing project-local BFRES parser. The original
compressed source SHA-256 is
`dd5c90b02f33f7828758cedcb35f1125a7bd2ecde3c252537676f23be6921537`.
The complete decoded bank is 36,482,488 bytes.

`research/player-vehicle-animation-inventory.json` records the relevant clip
inventory. Thirty-three `Vehicle_Wait*` clips are the parent baseline's edited
standing-to-seated targets. Original durations are 48 frames, with 63 bones.
The baseline redirects only ten pelvis/leg/foot bone headers to `Horse_Wait`
data and retains each variant's original arm, torso, head and hand animation.
Its authored source is an existing native horse pose, not a custom kart pose.

Eight ordinary entry clips exist:

| Clip | Frames |
| --- | ---: |
| Vehicle_Rideon_B | 16 |
| Vehicle_Rideon_L | 16 |
| Vehicle_Rideon_R | 16 |
| Vehicle_Rideon_B_Far | 23 |
| Vehicle_Rideon_L135 | 23 |
| Vehicle_Rideon_L_Far | 23 |
| Vehicle_Rideon_R135 | 23 |
| Vehicle_Rideon_R_Far | 23 |

There is also `Vehicle_Sled_Rideon_B` (16 frames). These entries retain their
original standing destination in the current hybrid baseline. This is a
plausible source of a mount pose discontinuity, but no transition change has
been observed in game.

The bounded bank inventory found **no** clip whose name starts `Vehicle_` and
contains `Rideoff` or `Dismount`. That is not proof of the native B-exit graph:
it may use shared animation/actions. Do not edit global jump/standing clips
on the assumption they are kart-specific.

`AS/Player.root.asb.zs` was decompressed locally (1,171,796 bytes). Its bounded
string inventory includes `RideControlStick`, `ControlStick`, `VehicleRideon`,
`NonAnimalRide`, `Vehicle_Wait` variants and `IsStandingRide`. Strings establish
names only, not node edges or the runtime-selected graph path. No ASB graph
parser ran successfully in this investigation.

## Possible next isolated entry improvement — not implemented

Each of the eight ordinary entries has existing curves for waist, both upper
legs, both knees and both ankles. The original lower-body channels are:

- `Waist`: three rotation curves.
- `Leg_1_L`, `Leg_1_R`: three rotation curves each.
- `Leg_2_L`, `Leg_2_R`: Z rotation curve each.
- `Ankle_L`, `Ankle_R`: three rotation curves each.
- `Skl_Root`: three translation curves; far/135 entries additionally have
  three rotation curves. Near side entries have one root rotation curve.
- Toe rotation curves vary by clip and side; some toes are constant.

A potential bounded edit is a smooth correction of those existing lower-body
curve coefficients, beginning at zero correction and ending at the seated
`Horse_Wait` starting pose. Keep clip duration, bone bindings, names, curve
counts, frame times, relocation layout, upper-body animation and external
BAEV events unchanged. Missing toe channels require an explicit decision;
they cannot be animated by merely modifying nonexistent curve payloads.

Before implementing, audit ownership of all curve key payloads across the
entire bank: existing resource pools may share bytes. Rewriting a shared key
array could affect unrelated animations. The source parser exposes curve
record layout and quantized formats in
`.tools/kart-assets/BlenderBfresImporter/io_scene_bfres/bfrespy/common.py`.
Switch curve headers are 48 bytes: frame pointer +0, key pointer +8, flags +16,
key count +18, channel offset +20, first/last frame +24/+28, scale +32,
value offset +36, delta +40. This is parser-source evidence; a new writer must
validate actual retail offsets, lengths and parse/roundtrip results.

There is no final curve writer, endpoint correction, sampling validation,
transition package or new runtime test for this idea. Native hand IK/grip
targets also remain unmodified.

## Tool blocker

The public primary format parser is
[dt-12345/asb](https://github.com/dt-12345/asb). A download attempt with
`git clone --depth 1 https://github.com/dt-12345/asb.git .tools/asb-analysis`
was rejected before execution because automatic approval review hit an
account usage limit. The message said retry at 1:16 PM. It explicitly said this
was a review failure, not an unsafe-action determination. The review was not
bypassed; `.tools/asb-analysis` was not created by that attempt.

## Local files produced by this agent

- `scripts/build_controlstick_hidden_host.py`: separate original-root and
  raised-root host models with original draw indices made degenerate;
  mounting bones and allocations preserved; independent C++ decoding passes.
- `assets/controlstick-hidden-host/{original-root,raised-root}/`: offline
  outputs and validation receipts. Parent subsequently tested/used the raised
  variant; this agent performed no installed writes.
- `scripts/build_controlstick_animation_root_trial.py` and
  `assets/controlstick-animation-root-trial/`: fixes zero `Skl_Root` constants
  in two native steering clips; unchanged decoded allocation. Parent reports
  the model-plus-animation comparison restored clean wheel height.
- `research/controlstick-submodel-root-evidence.json`: static clip/bone
  evidence and the parent-reported failed model-only height comparison.
- `scripts/verify_native_rider_identity.py` and
  `research/native-rider-identity-independent-check.json`: 15 exact Capstone
  checks against the verified local main ELF carrier; real Player identity
  and A/B seat-ID transition from the ground-hidden runtime log are recorded.
- `runtime/candidates/native-rider/player_seat_identity.as`: read-only helper,
  compiled with the pinned host engine; parent integrated it into its native
  controller. It checks Player ID/link identity, host generation/state and
  native occupied seat state. A raw watcher is not lifetime-safe: the upstream
  `ActorWatcher.hpp` `getSlotActor()` explicitly says
  `FIXME don't return/draw destroyed actors`. This helper cannot make a freed
  pointer safe to read.
- `runtime/diagnostics/native_control_mount.as`: earlier standalone A/B probe,
  compiled only, superseded by the parent agent's tested `native_mount.as`.
- `.work/rider/compile_native_control{,.cpp,.dSYM}`: compile-only host helper
  adding the real position/rotation actor-create overload.
- `.work/rider/player_seat_identity_compile.as`: temporary helper compilation
  wrapper with empty `main()`.
- `.work/native-mount/{Player.root.asb,Player_Animation.anim.bfres,Link.anim.bfres,
  SpObj_ControlStick_A.anim.bfres,SpObj_Animation.anim.bfres}`: local decoded
  analyst copies, not installed overrides.

No emulator was launched or stopped by this agent. All its short-lived shell
jobs finished; it has no pending process or REA session.
