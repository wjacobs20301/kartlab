# Native mount diagnostic (not installed)

These three scripts investigate the actual TOTK **Control** interaction using
`SpObj_ControlStick_A_01`. They are separate from the remote kart lab. The
scripts compile with the project's pinned AngelScript host engine; none has
been executed in TOTK. The native mount prompt, rider attachment and pose still
need in-game observation with the patched 1.1.0 module.

`prepare_native_mount.as` requires an existing nearby kart in watcher slot 1
and an empty slot 2. It creates a steering stick beside the kart, waits for its
asynchronous spawn, disables its watcher telemetry and pauses that watcher's
calculation. It changes neither Link nor the camera and supplies no input.
It creates no extra cart and performs no continuous transforms.

If run manually for diagnostics:

1. Stand near the slot 1 kart in an unpaused world, then run the prepare script.
2. Use the game's Ultrahand to attach the new steering stick to a clear place
   on the kart. This manual native bond is required for this diagnostic.
3. Approach the stick and check for its native **Control** action. Press A;
   observe whether Link becomes a native rider and whether B dismounts.
4. Run `drive_native_mount.as` (ZL+ZR+Right after preparation) only after the
   native Control action has mounted Link. The candidate uses the left stick
   and native camera without moving Link directly. B/Plus/Minus, pause, invalid
   input, separating by over 3 units, or 900 logical frames end the test.
   Speed is capped at 1.5 experimental TOTK units. Native bond behavior under
   forced kart yaw remains untested and could jitter or break the bond.
5. Dismount, then run `clear_native_mount.as` (ZL+ZR+Down) before loading or
   traveling. It drops watchers 1 and 2 without dereferencing the actors.

Preparation rebinds Right to the native candidate and Down to its watcher
cleanup. Right stays in native mode after the test; both watchers are cleared
on driver completion, so spawn/reprepare before repeating. This avoids running
the remote driver, which pins Link to his starting position, while he is
mounted. No actor is deleted by watcher cleanup. The script cannot verify a
native bond or mounted state: its name/body/distance guards are only sanity
checks. This is a manual native mounting diagnostic, not an automatic seated
kart system or full Mario Kart physics.

## Why this actor

The supplied actor pack contains a real `Ridable` component with one
`ControlStick` seat at skeleton bone `Root_Stand`, a `Manipulate` attention
action, and AI strings including `ExecuteActorControlStickPlayerRiding`,
`QueryRidableIsRidden`, and `QueryRidableGetRiderInput`. These establish the
native mounting route statically; they are not runtime observations.

Its `ConstraintControllerPath` is empty. Its bond pivot describes native
connection geometry, not an automatic association with a separate cart.
Its `SLink` parameter only names the sound user. The pinned script interface
exposes no create-constraint/glue, force-mount, rider-state query or animation
command. No imaginary API is used in these scripts.

For a single actor without a manual bond, a promising next design is to use a
native Control Stick actor as the host for a kart-shaped model and collision.
That requires preserving the native `Root_Stand` seat bone, mounting components
and actor logic while changing the body geometry and physics. It has not been
built here. A seated pose additionally requires a known animation/ride action
or a suitable new player animation, not only an offset to Link's position.

## Input suppression limitation

In pinned lotuskit `src/program/main.cpp`, the NinJoy input hook records the
human input, applies TAS playback, then records the **mutated** input again.
Therefore `tas::input(1,0)` neutralizes both vanilla Link movement and the input
read through the current `Record::currentInput` bridge. A controller using that
bridge must preserve native passthrough, or a native module change must capture
raw input into a separate field before suppression. Native mounting offers a
route to passthrough without Link walking independently, but it still needs a
real mounted-state check before continuous custom driving is safe.

## Evidence and reproduction

- `scripts/inspect_native_rider.py`: reads the supplied compressed pack and
  generates `research/native-rider-evidence.json` with source/member SHA-256,
  typed BYML parameters and bounded AI-string inventory.
- `.tools/totk-runtime/lotuskit/src/program/script/globals.cpp`: actual ActorBase,
  ActorWatcher, TAS and PlayerUtil registrations. Actor animation/blackboard
  mutation, attachment and rider-state APIs are not registered.
- `.tools/totk-runtime/lotuskit/src/program/util/actor.cpp`: `setPosRot` calls
  native `ActorBase::forceSetMatrix`; it does not establish a rider relation.
- `.tools/totk-runtime/lotuskit/src/program/main.cpp`: input hook ordering.
- `.tools/totk-runtime/lotuskit/src/program/tas/Playback.cpp`: neutral/TAS input
  replacement and passthrough implementations.

From project root, `python3 scripts/inspect_native_rider.py` reproduces the
asset evidence. The compile-only harness used here is
`.work/rider/compile_rider.cpp`, linked to the existing pinned
`libangelscript_host.a`. This checks syntax and registered contract, not game
ABI, the rider action, pointer lifetime or behavior. There is no runtime test
result for this candidate, and no new REA native session was opened.

`.work/rider/test_native_driver.cpp` also runs ten host scenarios: normal exit,
900-frame bound, wrong bridge, wrong actor, distant stick, missing Player/body,
invalid axes, pause and release timeout. Those pass with no actor creation,
Player pins or camera writes and bounded horizontal velocity. They do not
simulate native riding or constraints.
