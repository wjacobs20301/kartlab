# Native wheel animation (spin + steering) — October 16, 2026

Status: **working and installed** in Ryujinx 1.3.3 / TOTK 1.1.0. Wheels roll from the kart's
measured travel and the front wheels steer with the left stick. All 14 regression checks pass
with the animation running. Switch hardware remains untested.

Controller: `runtime/candidates/native-rider-wheels/controller.src.as` (readable source) →
`autorun.as` (minified, 7,698 bytes) via `scripts/build_native_wheels.py`.

## Mechanism (verified in game)

The Cart's wheel bones are driven by writing their local transforms every logical frame from the
resident controller. No LotusKit rebuild was needed: `ptr_write_float` is already registered
(`globals.cpp` `registerPtr`).

Pointer path from the kart actor (`SpObj_ControlStick_A_01`):

```text
list   = *(actor + 0x228)          component pointer array
mc     = *(list + 0x10)            component[2] = ModelInfoRef / ModelComponent
host   = *(mc + 0x28)              host gsys::Model  (modelMtx at +0x1f8 == actor position: verified)
x      = *(host + 0x18)            always host + 0x258 (embedded object) in every run observed
y      = *(x + 0x38)               Cart submodel object (separate allocation)
bones  = y + 0x580                 Cart bone record array
```

Bone record `i` (0 = Skl_Root, 1 = LF, 2 = RF, 3 = LB, 4 = RB) is 96 bytes starting at
`bones + 96*i - 24`:

| Offset | Content |
| --- | --- |
| +0, +16, +32 | 3x4 row-major rotation rows (first three floats of each row used; 4th float 0) |
| +48 / +52 / +56 | translate X / Y / Z (local to Skl_Root) |
| +64 | flags (u32) |
| +80 / +84 / +88 | scale (1,1,1) |

Neutral translates (signature): Skl_Root Y 0.3766; wheel X +0.728, -0.728, +0.7776, -0.7776.

Rotation written per wheel: `Ry(steer) * Rx(spin)` (axle = local X, forward = local +Z):

```text
[ cd   sd*sp   sd*cp ]
[ 0    cp     -sp    ]
[-sd   cd*sp   cd*cp ]
```

`spin += signed forward travel / tire radius` (front 0.28328, rear 0.3683), measured from the
actor's XZ displacement projected on its heading; reverse rolls backwards. Displacements of 1 unit
or more in a frame (recall teleports) are ignored and recall resets the tracker. Front-wheel steer
eases toward `stick * 0.45 rad` (same sign as the body yaw request); rear wheels never steer.

## Evidence

| Step | Result | Log / file |
| --- | --- | --- |
| Chain validation | modelMtx translate == kart position exactly | `.work/ryujinx-bone-probe-model-window.log` |
| Fingerprint locate | wheel translates found at 96-byte stride | `.work/ryujinx-bone-probe-wheels.log`, `-struct.log` |
| Write propagation | +2.0 Y local translate visibly lifts tires | `native-wheels-visual/2-*.jpg` |
| Rotation slot | 90 deg yaw in rows turns the left-rear tire | `native-wheels-visual/3-*.jpg` |
| Pointer path | `+0x18 -> +0x38 -> +0x580` agrees with independent 2-level scan | `.work/ryujinx-bone-probe-path.log` |
| Drive regression | 12/12 checks, no faults | `native-wheels-regression-final-results.json` |
| Recall regression | 8/8 checks (recall + remount), no faults | `native-wheels-recall-final-results.json` |
| Visual steering | front-left wheel turns opposite ways under left/right steer | `native-wheels-visual/4-*.jpg`, `5-*.jpg` |

Rolling is evidenced by logged spin values (advance forward, reverse in reverse, stop when
parked); single screenshots cannot resolve tread motion. Steering is visible in screenshots.

## Hazards found (do not repeat)

1. **The bone array is NOT at a fixed offset from the host model.** It sat at `host + 35280` in
   several runs only because the allocator placed the submodel next to the host. One run wrote
   there and corrupted a live heap pointer (crash, `va=0x3F99999A...` = 1.2f). Always resolve via
   the pointer path and validate the signature before writing.
2. **Record boundaries are offset by -24 from the translate-based guess.** Writing "entry+80..+92"
   of the last wheel overran the array (crash, `va=0x3F3504E6...` = 0.7071f).
3. **Blind multi-level pointer walks fault.** A value passing the loose guest-pointer check
   (`0x80204000020`) was unmapped. The production path only follows the known fields.
4. The original host harness `.work/rider/compile_physics` does not register `ptr_write_*` or the
   rest of `registerPtr`. Use `.work/rider/compile_wheels` (source `compile_wheels.cpp`), which adds
   them and enforces the 8,191-byte runtime limit. It caught three minifier bugs before any install.

## Guards in the shipped controller

* `x` must equal `host + 0x258`; `y` must be a guest pointer within ±256 MB of `host`.
* Five neutral translate values (never written by the controller) must match within 0.002.
* Any mismatch returns without writing. No hard-coded heap window (heap addresses differ on hardware).

## Limits and next steps

* Script budget: the runtime reads at most 8,191 bytes per script (`schedule.cpp` `scriptBuf[0x2000]`,
  no includes; modules do not share code). The controller is at 7,698 bytes minified. Future
  handling work will need either a runtime patch enlarging that buffer or tighter code.
* Suspension: arms are bound to Skl_Root and do not follow wheel translation; independent
  suspension would need geometry rebinding.
* The steering-wheel rim is still baked into the body mesh (see `animation-assets-handoff`).
* Rolling uses measured body travel, not per-wheel contact; wheelspin/skid are not modelled.
* `y + 0x580` and `x == host + 0x258` are empirical for this build; the guards make a mismatch
  harmless (no animation) rather than unsafe.
