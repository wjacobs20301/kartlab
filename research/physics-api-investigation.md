# Physics API follow-up: source/asset boundary

This pass reads the pinned source and already extracted assets/logs only.
No runtime file, game data, executable patch or running emulator was changed.
REA's active TOTK session is reserved for the parent investigation.

## Superseding binding discovery and verification

The earlier main-body, wake/contact and Cart-controller explanations below were
investigation hypotheses. A concrete native binding error now explains the
principal velocity-only failure: the pinned upstream TOTK 1.1.0 entry named
`requestSetLinearVelocity` actually points to the **angular** request channel.

| Operation | Main offset | Observed channel |
| --- | --- | --- |
| Upstream mislabeled request | `0x7a4cfc` | request `+0x50/+0x58`, bit 8; cached body `+0x104..0x10c` |
| Correct linear request | `0x6bf8f8` | request `+0x44/+0x4c`, bit 7; cached body `+0xf8..0x100` |
| Existing linear getter | `0x11bb3b8` | request `+0x44/+0x4c`, bit 7; cached body `+0xf8..0x100` |
| Existing linear impulse | `0xccc234` | adds impulse divided by mass to linear channel, calls `0x6bf8f8` |

This worker independently checked 11 exact instructions and retained complete
bounded function ranges in `research/velocity-binding-independent-check.json`,
reproducible with `scripts/verify_velocity_binding.py`. Names here describe the
observed data flow, not recovered source symbols. Earlier tests that sent a
forward value to the old `setVel` must not be treated as tests of a functioning
linear setter or evidence that matrix forcing is necessary.

The parent runtime test with the corrected linear entry moved about 8.54 Z
units in 180 frames under the 1.5-speed request, versus roughly 0.02 Z in the
old binding test. The additive angular derivative exposes both
`setAngularVel(const Vector3f &in)` and `setAngularVel(float,float,float)` while
preserving existing methods. Its four recorded road cases completed; the
gentle curve accumulated path length about 7.998, final heading 1.474 radians,
and minimum up-Y 0.9983, without forcing the actor matrix. See the parent-owned
`research/angular-velocity-runtime-results.json` for measured values and limits.

The derivative module SHA-256 is
`b0dc2c3bf8b19d95e43c8ad58d3e461d485a2e1ad0b9d2060f843a8a6d80ad06`.
This worker's separate temporary build reproduced it byte-for-byte and reviewed
the registration/call ABI; see `research/angular-velocity-independent-audit.json`.
No installed file was changed by this audit. These tests cover sampled road
motion, not riding, seated animation, rough terrain or Switch hardware.

## Observations

The current `physics_matrix.as` waits 120 logical frames after spawning before
its 180-frame motion case. Its samples establish that a settled kart barely
moves under the current velocity request and 15-unit impulse experiment, while
repeated actor matrix forcing jolts it. The joint-disabled comparison remains
similar. The data does not demonstrate stable velocity driving.

The supplied `SpObj_Cart_A_01` ControllerSet explicitly defines Main as:

```text
AliasEntity=Main; ControllerName=Body; RigidBodyName=Physical
```

It contains one rigid-body entity (`Physical`), with `MotionType=Dynamic`,
`Mass=400`, and COM Y offset `-0.375`. Its body controller unit is also named
Physical and does not track an actor or another entity. Native grounding joints
are one element of the original configuration, but the ineffective override
comparison is not repeated or promoted as a solution here.

The native Cart AI contains `ExecuteCartFlyWheelMotionControl` and
`ExecutePhysicsSetNoRestitutionAutoReset`. Those names are observed in its AINB,
not recovered code behavior. Cart-specific velocity/friction changes remain a
possible explanation requiring code or a comparison actor to establish.

## Actual binding paths

Pinned `util/actor.cpp::getMainRigidBody` directly reads the actor's physics
component, its ControllerSet, and `mainRigidBody`; it does not call a native
validated alias lookup. The reconstructed layout puts ControllerSet's pointer
at `+0x150`. This is useful source evidence, not independent proof of the 1.1.0
layout at runtime.

`getRigidBody("Physical")`, also exposed to scripts, instead calls the native
`ActorBase::getRigidBodyEntityByName`. This provides an independent path to the
same expected body and can test the reconstructed main-body offset.

Upstream exposed operations are nominal linear velocity requests, linear impulse, body
name/bounds, and read/write data properties for last/previous transforms. There
is no upstream registered activate/wake, torque, angular velocity or angular impulse API.
Source contains a commented 1.0.0 angular-velocity address; that is not a known
1.1.0 callable binding and must not be used by analogy. The current derivative's
new angular methods instead use the independently verified 1.1.0 offset above.

`phive.hpp` describes `RigidBodyBase+0x60` as its change-request pointer and
`+0x68` as flags. Comments label bit 6 static, bit 22 last-paused, bit 26
last-warped and bit 35 activate. The request structure labels its flags at
`+0xd4`. These are upstream reconstructed comments requiring native/version
validation before mutation. This pass recommends no flag writes.

The following existing bindings permit read-only diagnostic snapshots:

```text
ptr_from_RigidBody(body)
ptr_deref_ptr(bodyPointer + 0x60)
ptr_deref_u64(bodyPointer + 0x68)
body.lastTransform.pos
body.prevTransform.pos
body.vel
```

Any raw dereference still needs a current validated body and should not reuse a
pointer across loads or actor lifetime changes. Reacquire actor/body handles
after sleeps; merely checking a nonnull pointer is not a lifetime guarantee.

## Best next comparison

1. On a fresh actor, compare pointer identity returned by `getMainRigidBody()`
   and native `getRigidBody("Physical")`. Snapshot their transform positions
   against the actor position once. A mismatch would directly challenge the
   main-body layout or alias assumption without trying a new controller.
2. For a velocity-only case, capture velocity and request flags immediately
   before the call, immediately after it, and after the next frame. This
   separates a failed request from one accepted and later overwritten. Keep
   logging bounded and avoid the automatic ActorWatcher telemetry path.
3. Compare the same request immediately after a body becomes ready while
   airborne against the settled-after-120-frames case. Make no setRot calls.
   A difference isolates sleep/contact/controller state much better than
   repeatedly waking/warping it with forceSetMatrix.
4. Compare the same API on a known generic dynamic box. If it moves there,
   Cart-specific AI/contact behavior becomes more likely; if it fails there
   too, ABI/timing/request semantics remain central. This should precede
   assigning unrelated Cart data fields guessed meanings.

The 15-unit impulse result is weak evidence of failure on an actor whose mass
parameter is 400: ideal `impulse/mass` is only `0.0375` velocity units before
contact/friction, assuming the expected relation and units. No runtime mass or
impulse-unit measurement was made. A stronger bounded single impulse selected
from the actual mass, or the airborne comparison, would be more discriminating
than repeating 15 and concluding the API is inoperative.

Repeated `setRot` calls `ActorBase::forceSetMatrix`; it is not an angular
velocity controller. Its observed jolts could come from contact correction,
warp effects or waking. The comparison does not establish which. No stable
upright vehicle controller or full Mario Kart physics was established by those
earlier tests; the corrected native-channel tests supersede their integration
conclusions.

## Local evidence locations

- `runtime/diagnostics/physics_matrix.as`
- `.work/ryujinx-physics-matrix-baseline.log`, PHYS results at 00:01:06..00:01:40
- `.work/ryujinx-physics-matrix-free-joints.log`, PHYS results at 00:01:05..00:01:39
- `.work/kart-runtime/cart-pack/Phive/ControllerSetParam/SpObj_Cart_A_01.phive__ControllerSetParam.bgyml`
- `.work/kart-runtime/cart-pack/Phive/RigidBodyEntityParam/SpObj_Cart_A_01.phive__RigidBodyEntityParam.bgyml`
- `.work/kart-runtime/cart-pack/Phive/RigidBodyControllerEntityParam/SpObj_Cart_A_01.phive__RigidBodyControllerEntityParam.bgyml`
- `.work/kart-runtime/cart-pack/AI/SpObj_Cart_A_01.root.ainb`
- `.tools/totk-runtime/lotuskit/src/program/util/actor.cpp`
- `.tools/totk-runtime/lotuskit/src/program/structs/phive.hpp`
- `.tools/totk-runtime/lotuskit/src/program/script/globals.cpp::registerPhive/registerPtr`
- `.tools/totk-runtime/lotuskit/syms/exking/phive/RigidBodyBase.py`
