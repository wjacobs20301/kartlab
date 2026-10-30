# Turning steering wheel — October 16, 2026

Status: **working and installed** (Ryujinx 1.3.3, TOTK 1.1.0). The kart's steering wheel turns
±20° with the stick, clockwise for right as seen from the driver's seat, and Link's hand targets turn
with it. No runtime memory writes are involved: the game's own ControlStick steering animation drives it.

Builder: `scripts/build_rim_transfer.py` → `assets/rim-transfer/` (validation in `validation.json`).
Analysis: `scripts/rim_analysis.py` → `research/rim-analysis.json`.

## How it works

1. **Native driver.** The host ControlStick's `LeftRight` clip already rotates bone `Handle_J` with the
   stick (read live: `.work/ryujinx-handle-probe.log`). `Handle_J` has a GPU rigid matrix (index 1) in the
   hidden host model, and `Handle_L`/`Handle_R` (Link's hand targets) are its children.
2. **Geometry move.** The steering-wheel pieces of the Cart near LOD are the ring (126 triangles), the hub
   (32) and four spokes (6 each), 182 triangles / 172 vertices. They are made degenerate in the Cart and
   written into hidden host shape 0 (`Metal_Handle_03`, 622 vertex / 394 triangle capacity), rigid-bound to
   `Handle_J`. The far LOD has the rim welded into the body and is left static (distance only).
3. **Pivot and axis.** `Handle_J` rest = rim centre (0, 0.5966, 0.4928) in Skl_Root space. Its rotation is
   Euler (α, β, γ) = (90°, −64.8°, −90°), so its local X is the steering-column axis (0, −0.426, 0.905),
   which is the rim-plane normal from PCA. `Handle_L`/`Handle_R` were re-expressed so their neutral world
   transforms are unchanged.
4. **Clips.** In `LeftRight`, the `Handle_J` curve is retargeted from rotate Z to rotate X (channel offset
   40 → 32, bone-anim flags `0x800` → `0x200`, keys unchanged: 90° ± 20°). In `UpDown`, the pitch curve
   is made constant (scale 0, offset β), so throttle no longer tilts the wheel. Both clips' base rotation and
   translation match the new neutral frame.

Euler convention (nn::g3d EULER_XYZ, column vectors): `R = Rz·Ry·Rx`, confirmed against the live
`Handle_J` record under `UpDown` pitch.

## Evidence

| Check | Result |
| --- | --- |
| Offline neutral pose | rim vertices within 1.0e-4 of their old world position (half floats); hands within 4e-9 |
| Independent decoder | MeshCodec `mc_test` byte-identical for both models; decoded sizes unchanged (no RSTB edit) |
| Live Handle_J (`research/rim-probe.log`) | local X stays (0, −0.426, 0.905) at neutral/right/left; right tips the up-vector toward −X (driver's right); forward identical to neutral |
| Visual (`research/rim-visual/`) | single rim in place from the front; hands move with steering |
| Regression with rim installed | drive 12/12, recall 8/8, signed direction 4/4, no faults (`research/rim-wheels-*-results.json`, `rim-signed-checks.json`) |

## Limits

* The rim uses the hidden host's metal-handle material at a constant UV (bronze-grey), not the Mario atlas.
* The native clip's steering is effectively ±20° and snaps quickly (half stick gave full lock in the probe).
* The far-LOD rim does not turn.
* Palm orientation is unchanged from the earlier hand fit.
