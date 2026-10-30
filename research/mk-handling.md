# Mario Kart handling and controls — October 16, 2026

Status: **installed and tested in Ryujinx 1.3.3 / TOTK 1.1.0.** The kart drives with Mario Kart 8 Deluxe controls and
handling built from MK8DX 1.7.1 data for Mario + Standard Kart + Standard Tires + Super Glider. This is a model built on
recovered values and one recovered equation. It is **not** a port of the complete MK8DX physics engine, which was not
recovered.

Controller source: `runtime/candidates/native-rider-wheels/controller.src.as` (handling constants at the top, each tagged
`[table]`, `[native]` or `[chosen]`). Runtime: `runtime/candidates/raw-input-110/subsdk9` (`10b63b32…`).

## Controls

| Button | Action |
| --- | --- |
| ZL + ZR + D-pad Up, release | spawn or recall the kart (unchanged) |
| A (on foot) | get in (TOTK's own "Control" prompt) |
| A | gas (release A once after getting in) |
| B | brake; keep holding when stopped to reverse |
| Left stick | steer |
| R or ZR | hop; hold while steering to drift; release for a mini-turbo |
| X | get out |
| Right stick | camera (unchanged) |

While you are in the kart, the controller rewrites what the game sees, one frame (33 ms) later: A, B, R, ZR and X are
hidden from TOTK, and X is turned into TOTK's B dismount. On foot nothing is changed. After an X exit, X stays hidden
until released, so Link does not jump.

This needs the player's raw buttons. LotusKit used to overwrite `Record::currentInput` with the script-mutated input. The
`raw-input-110` runtime patch removes that one re-record (`0x19ad8`: `tbnz w22,#0,#0x19af0` → `nop`; builder
`scripts/patch_lotuskit_raw_input_110.py`). Verified: with the patch, the record read `pad=0,0` while injected test input
drove the kart. Before the patch it echoed the injection. Holding B for 2 s while braking kept Link seated, and X dismounted.

## Model

MK8DX simulates at 60 Hz. Each TOTK logical frame (30 Hz) runs two MK steps. Speed is kept in MK units/frame.

| Part | Source | Value / rule |
| --- | --- | --- |
| Acceleration | [native] `0x189644` + [table] PRAC | `v += min((T − v)·0.011, 0.09)` |
| Top speed | [table] PRSL ground, 0 coins | 7.775 MK units/frame |
| World scale | [chosen] | 1.8 m/s per MK unit/frame → about 14 m/s |
| Steering | [table] PRTL steer | 0.0118 rad/frame at full lock; scales in below 25% speed; reversed when backing up |
| Drift turning | [table] PRTL drift | 0.0196 rad/frame × (0.55 + 0.45 × inward steer); never reverses |
| Drift charge | [table] PRTL charge 0.9; [chosen] rate | `(2.5 + 3.5 × inward) × 0.9` per frame |
| Mini-turbo tiers | [table] PRMT | 252 / 534 / 816 charge |
| Boost | [table] PRMT | ×1.105 target speed; MT 31, SMT 92 frames; [chosen] ultra 153 frames, push G 0.05 / M 0.3 |
| Grip | [table] PRON 0.75; [chosen] mapping | sideways velocity × (1 − 0.35·0.75) per frame; drifting 0.08 instead of 0.35 |
| Brake / coast / reverse / hop | [chosen] | 0.11 and 0.07 per frame; reverse 2.7 units; hop 3 m/s |
| Walls | [chosen] | commanded speed stays within 0.6 units of the body's real forward speed (no wind-up) |
| Stopped, no pedal | [chosen] | the parking anchor holds the kart on slopes |

Column meanings follow the MK8 community format documentation (https://mk8.tockdom.com/wiki/Performance.bin).
The mapping of PRAC strength/limiter onto G/M in the recovered speed step is an interpretation. It is consistent:
(7.775 × 0.011) = 0.086 ≈ the 0.09 limiter. It was not traced in code.

## Measurements (`research/handling-final-results.json`, open field at (−150, −60))

| Measure | Result |
| --- | --- |
| Top speed (full-lock circle) | 14.06 m/s |
| 0 → 90% | 4.0 s (2.5–4.0 s across runs, depending on slope) |
| Full-lock turn radius | 18.7 m, correct direction |
| Braking 13.7 m/s → 0.5 m/s | about 1.3 s, then reverses while B is held |
| Drift | tiers at 1.0 / 1.67 / 2.67 s; slip angle 20°; yaw 1.25 rad/s; 14.5 m/s |
| Ultra mini-turbo | 153 frames, peak 15.46 m/s |
| Idle on slope | about 4 cm in 2 s |
| Stability | up ≥ 0.973; Link mounted throughout; no faults |

Regression on the same build (field start): drive 12/12, recall 8/8, signed direction 4/4 (`research/mk-*-results.json`,
`mk-signed-checks.json`).

Test site: `research/site-survey.log`. The kart was dropped onto candidate points and the site where a 30 m cross settled
within 1.8 m height was chosen. The Castle Town ruins start point is too cluttered for these speeds.

## Known issues

* **Intermittent crash in heavy-logging tests:** 1 of 9 handling runs faulted with a pointer overwritten by log-string
  text. This is consistent with corruption in LotusKit's unlocked C++ string heap (exlaunch 64 KiB fake heap, no
  `__malloc_lock`), which the handling test stresses with long log strings every few frames. Not seen in any regression
  run. The production controller only logs on events. The root cause is unproven.
* No off-road, terrain-type, or air handling (TOTK surface types are not read). Steering in the air works like on the ground.
* No item, coin, trick or glider mechanics. Weight is unused (Link drives).
* The steering-wheel rim follows TOTK's native stick animation (±20°), independent of this model.


## Update: drift recovered from MK8DX code, wheel spin, seat (October 16, late)

REA (Hopper) is usable again. Found via MK8DX's recorder debug labels (`p_mini_turbo_counter`, `p_mini_turbo_level`, `p_state`,
`p_ollie_pos_y`, registered at `0x2f1268` and called from the drift constructor `0x178050`):

| Piece | Recovered | Now in controller |
| --- | --- | --- |
| Mini-turbo charge `0x17b744` (evidence `ev_509156fa…`) | `counter += (inward >= 0.71 ? 5 : 2) * k`, with k = 1 in normal drift (`0x17a14c`) and 0.4 in drift state 6 (`0x17a828`, not yet identified); tier promotes when `counter > T` | exact (k = 1) |
| Tier thresholds | per-kart fields `+0x6c/+0x70/+0x74` (alternate set at `+0x78..`); taken as PRMT 252/534/816 (assignment site not traced) | table values |
| Drift body angle (`0x179c74`, evidence `ev_f0518d87…`) | approaches ±0.53 rad at 7% of the gap per frame, minimum step 0.001 (kart; bikes 0.1) | exact; velocity follows a separate travel heading |
| Drift steer state | approaches ±0.8 at 10%/frame, step ≤ 0.07; turn = rate × intensity² × dir; rate swaps per MT level (`+0x38/+0x3c`) | structure exact; the mapping from inward stick to intensity is still [chosen] (0.75 + 0.25·inward) |
| Field layout | counter `+0x68`, level `+0x84`, hop height `+0xcc`, body angle `+0x50`, steer state `+0x1c`, max `+0x28`=0.8 | — |

Measured (`research/handling-drift2-results.json`): slip angle 33.9° (target 30.4°); tiers at counter 255/535/820; boost 15.4 m/s.

**Wheel spin:** each tire has 16 tread blocks (0.393 rad). True rolling at top speed (1.65 rad per 30 Hz frame) strobes,
so the wheels looked frozen or backwards. Visual spin now scales with speed, capped below half a block per frame.

**Seat:** the saddle bone `Root_Stand` sits at Z −0.70, behind the Mario seat back (Z ≈ −0.5). `SaddleOffset` is now
(0, 0.70, 0.45) (`assets/source-native-contacts-raised-chassis-seat-070-cart-dynamics-fwd045`).

Regression on this build: drive 12/12, recall 8/8, signed 4/4.
