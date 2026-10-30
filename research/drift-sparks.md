# Drift sparks through TOTK's particle system — October 16, 2026

Status: **installed and tested in Ryujinx 1.3.3 / TOTK 1.1.0.** While drifting, sparks come off both rear wheels in
Mario Kart 8 Deluxe colours: blue (mini-turbo), orange (super mini-turbo) and pink-purple (ultra mini-turbo). They stop
when the drift ends. **Switch hardware is untested.** The method uses only the game's own code and memory that LotusKit
already reserves, so nothing in it is emulator-specific.

## Why not port MK8DX's effects

MK8DX effects are VFXB version 0x15 and TOTK uses 0x33, so the files are not compatible. Instead the controller plays
TOTK's own `Ply_ShockWave_Spark` (orange streak sparks, in the always-loaded resource) and recolours it.

## Runtime: `runtime/candidates/native-call7-110` (`8d838a33…`)

Built by `scripts/patch_lotuskit_native_call7_110.py` on top of `raw-input-110`. It changes one instruction, the tail
branch at 0x41ecc, which now goes to a stub that registers:

    u64   ptr_call (ptr_t fn, u64 x0..x6, float s0..s3)
    float ptr_callf(ptr_t fn, u64 x0..x6, float s0..s3)

Both point at one trampoline: `mov x16,x0; mov x0..x6,x1..x7; br x16`. In the emulator, the integer path and float
arguments/returns were verified (`sqrtf(2)`, `cosf(0.5)`; `runtime/diagnostics/native_call_test.as`). The earlier
6-argument version (`native-call-110`, `76dd75fb…`) is superseded: effect create needs 7 arguments.

**Script-owned memory:** the controller uses the last 32 KiB of LotusKit's 1 MiB WebSocket send queue (module +0x3d1000,
inside `.bss` symbol `sendQueueBuf` at 0x2d9000). LotusKit writes that buffer only after its debug server is started
(exact L+R+ZL+ZR+Plus+Minus combo, or `wsListen()`) and a client connects. Growing `.bss` was tried first
(`scripts/patch_lotuskit_scratch_110.py`, superseded) and dropped. The crashes seen during that work turned out not to
depend on it (see Known issues).

## TOTK 1.1.0 addresses (main module offsets)

| What | Address / layout |
| --- | --- |
| nn::vfx System | `*(*(*(main+0x4631b98)) + 0x11b8)` |
| Resources | `*(sys+0x2ee8)[res]`; res 1 = static effects (651 sets). Per resource: count +0x558, set table +0x430 (stride 0x28), name = `*(entry)+0x10`, ready flag +0x571 |
| Name search (game's own) | `0x1f3f0(resource, name)`, `0x7da380(sys, name, res)` |
| Create | `0x229a0d0(sys, Handle*, setId, resId, group, userBuf, 0)`. Handle = {EmitterSet*, createId}, live when `eset+0x234 == createId` |
| Position | `0x229a164(eset, Matrix34 row-major*, scale vec3*, 0)` appends a 0x60-byte transform to `userBuf` (capacity 64 = 0x1800 bytes). nn::vfx emits at each queued transform and clears the queue every frame (`0x96b8`). |
| Kill | `0x28998(sys, eset)` (queued, thread-safe) |
| Colour | EmitterSet +0x40 = RGB multiplier on every emitter's colour, read each frame (`0x1182c`): colour = emitter +0x3fc/+0x408 × emitter anim × set +0x40 |
| Not colour | EmitterSet +0x180 (+flag 0x200) is the ELink "colour" uploaded to the shader; it has no visible effect on these sparks |
| Group | 0 (same as the game's own item-sparkle slots) |

Controller code: `fx*` / `sparkFrame` in `runtime/candidates/native-rider-wheels/controller.src.as`. One effect, two
transforms per frame (rear-left and rear-right contact points from the wheel bones). Tint per tier: blue (0.25,0.8,6),
orange (1,1,1), purple (2.2,0.4,6). Scale 0.35.

## Tests (keyboard Player 1, because no controller was attached)

| Test | Result |
| --- | --- |
| `native_spark_visual.as` (`scripts/build_spark_visual_test.py`): run-up, hold each tier 7 s, release into ultra boost | blue / orange / purple screenshots at the rear wheels; effect gone after release and after exit; 2 clean runs |
| Same drive with sparks compiled out (`native_spark_visual_nofx.as`) | clean |
| Drive regression | 12/12 (`research/sparks-regression-results.json`) |
| Signed direction | 4/4 |
| Recall | 8/8 (`research/sparks-recall-results.json`) |

Test mount: in the rainy load, the spawned kart rolls about 4 m before the first A press. The tests now face Link
toward the kart and press A again (`mountKart()` in `scripts/build_native_wheels.py`).

## Known issues / not done

* **Heap-corruption crash (pre-existing, more frequent with heavy script allocation):** a game pointer gets overwritten
  with actor-name text (`Horse_Li…`, `Weapon_S…`). It happened 3 times across about 15 runs today, including once at
  the title screen with no effect code running. The first spark lookup built about 16,000 small strings in one frame.
  It now compares bytes in place (no allocations), and the two runs since then were clean. **Cause found and fixed Oct 17:**
  LotusKit's malloc has no lock and is used from several threads — see research/heap-race.md (runtime `malloc-lock-110`).
* Boost flame: `Chm_Fire_BoostLoop` was live but not visible while driving (raining). It was left out.
* No dirt or ground-surface effects yet. The static set includes per-surface slide smoke (`Ply_SlipSmoke_Grass_*`,
  `_Stone`, `_Snow`) that would fit once the ground type is read.

## Later the same night: boost flame, ground effects, heap fix

**Boost flame:** `Chm_FlameThrower_ScraBuild` (the Zonai flame-emitter jet, fires along local −Z) at scale 0.15, two
transforms at the back of the kart while `boostLeft > 0`. `Chm_Fire_BoostLoop` (tried first) was live but not visible
while driving.

**Ground material:** the kart host has no ground-contact object (physics chain `+0x228→+0x50→+0x20→+0x10` is null for
it; for Link it gives `*(obj+0x20)+0x20+0x78` = material). Instead the controller runs the game's own
`QueryPhysicsRayCastDistanceToGroundFromPosition` evaluate (`0x20e4da4`) on a fake query object in scratch: vtable
`main+0x4578958`; params/outputs are plain pointers; `+8→+8→+0x1f8` = filter actor (Link). Outputs: hit byte, distance,
position, material int. Material names: `*(main+0x4637298)+0x250` (54 entries: 1 Soil, 2 Grass, 3 Sand, 4 HeavySand,
5 Snow, 6 HeavySnow, 7 Stone, … 38 Water, 42 Bog). Verified in game: Grass on the field, Stone on paths.

**Ground effects:** TOTK's ground effects are one-shot (per footstep), so they are re-triggered every 6 frames, rotating
4 handles that share one transform queue. Grass `ReFX_Grass_L`, soil/sand `ReFX_Sand_L`, snow `ReFX_Snow_L`, water
`Water_Splash01_Move`, mud `RctFld_Mud_Splash_S`, hard surfaces `Ply_SlipSmoke_Stone` (drift only). They were subtle in
the rainy test save; the choice is not final.

**Off-road (toggle):** ZL+ZR+D-pad Down, default off. MK8DX `PROF` columns 0..2 = 0.7 / 0.5 / 0.3. Light (soil, grass,
sand, snow) 0.7; heavy (deep sand/snow, bog, tar, water) 0.5; boosts ignore it. Measured on grass: on 9.8 m/s, off 13.7 m/s.

**Heap:** LotusKit/exlaunch malloc → `_sbrk_r` bounded by `fake_heap_start/end` (64 KiB `__fake_heap`). AngelScript
strings, LotusKit JSON and actor-name strings all live there. `native-heap-110` rewrites 9 instructions in `_sbrk_r` so the
heap is module +0x2d9000..+0x3d1000. Same address layout on console. The LotusKit debug WebSocket server (6-button combo)
would overwrite it.
