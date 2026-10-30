# MK8DX 1.7.1 native movement investigation

This is a partial static investigation of the supplied game executable. No
game code was executed and no original source code was recovered. The native
integration equations below are narrower than a complete driving model.

## Reproducible input and analysis carrier

Input: `extracted/mk8dx/exefs/main`, SHA-256
`79ec426d0c1ddca84b252e2b8d8502324ef2a32fb14b00ca06eb79e35b30d934`.
NSO build ID: `FE1B230800D4933C617C691273CA5978` followed by 16 zero bytes.
The supplied MK8DX executable is ARM32 little endian, unlike TOTK's AArch64
executable. The original NSO is compressed and is unsupported as a direct REA
native input.

Commands run from the project root:

```sh
.tools/hactool/hactool -t nso0 --verify --uncompressed=.work/native/mk8dx-main.uncompressed.nso extracted/mk8dx/exefs/main
python3 scripts/nso_to_elf.py extracted/mk8dx/exefs/main .work/native/mk8dx-main.uncompressed.nso .work/native/mk8dx-main.elf
```

All three NSO segment hash checks passed. The wrapper validates those hashes
again, preserves each decompressed byte, and maps ELF virtual addresses to NSO
module offsets. This produces an analysis carrier, not an original or runnable
ELF. Runtime module base is unknown. `.work/native/mk8dx-main.elf.json` records
all source/carrier identities and segment mapping. The carrier SHA-256 is
`b45ced902a5ee66fb6ac08077f8aac0d807bae4223518442563f7f341a62a1e2`.

REA used Hopper with the `ELF --armv7` loader. Its static analysis completed.
The session is closed. Saved evidence and an immutable snapshot are local at:

- `.work/native/rea-mk8dx-native-evidence.json` (32 retained observations)
- `.work/native/rea-mk8dx-native.snapshot.json`

The NSO module-offset address scheme is used throughout this report.

## Performance tables are consumed by executable code

Observed: string `/Common/Mush/Performance.bin` at `0xc14d4b` is referenced
by the constructor at `0x796b44`. At `0x796b54..0x796b80`, that constructor
passes `0x50455246` (`PERF` as a numeric ID) and `0x11` (17) to `0x796080`.
This confirms that the file parsed elsewhere in this project is used by this
executable, rather than being an unused asset.

The virtual reader at `0x796de0` calls `0x796118` for 17 named sections.
In particular:

| Numeric section ID | Section | Pointer slot in Performance object |
| --- | --- | --- |
| `0x50524143` | PRAC | `+0x1c` |
| `0x5052544c` | PRTL | `+0x20` |
| `0x50524d54` | PRMT | `+0x28` |

For these sections it passes a row count of 21 in the call's stack arguments.
The reader likewise uses row counts 41 for PTBD, 44 for PTDV, 22 for PTTR,
and 15 for PTWG. These observations corroborate the asset parser's structure.
They do not establish the meaning of every table column.

Evidence:

- `ev_d6f04b08e68d82a75b492e40224e8165aca28a9eb65838128da36f5bb8535005`: string search
- `ev_e8f66dfa23be419927d75bcd84062a7062dac9bd4c0f99407e9989a2afd3b7b3`: string xref
- `ev_91a4411d6aad89422f328cae51e5a9adcb61640d456ae010b5b83f1c346ba8ef`: constructor assembly
- `ev_1b3750b4627f40379f09822f80a718ba5ab22f1bb5514e06e3fe2c8e96c9a37a`: section reader assembly

## Movement state fields have shipped debug labels

Observed: `0x17e3f4` constructs a movement object and optionally registers its
fields through `0x2f1828`. The actual names retained in the executable and the
pointers supplied by the constructor establish this mapping:

| Label | Offset from movement object |
| --- | --- |
| `p_drive_speed` | `+0x324` |
| `p_drive_speed_ratio` | `+0x328` |
| `p_gravity_vec` | `+0x224` |
| `p_move_mtx` | `+0x004` |
| `p_collided_ground` | `+0x1bd` (byte) |
| `p_collided_wall` | `+0x1c0` (byte) |
| `p_ground_pos` | `+0x144` |
| `p_air_counter` | `+0x214` |
| `mOnDirtRate` | `+0x1dc` |
| `mbAntiGColSpin` | `+0x394` |
| `p_collided_wall_object` | `+0x1c1` (byte) |

`mGndAttr` is a field of the debug wrapper rather than a direct supplied
movement-field pointer; no movement offset is claimed for it here.

Evidence:

- `ev_b798dffcc413ba372772f8b47fab57877be3a35b05db72637c8e1721ed0516a1`: constructor and pointer assembly
- `ev_00a96ea8e90649d193ed480da6c4eaa1b6c08740c532a3d5e1a833714f88a732`: corresponding label registrations

## A concrete speed integration equation

Observed: function `0x189644`, called by `0x181e9c`, reads and writes the
established speed field `+0x324`. The relevant native float arguments are passed
in VFP registers, so Hopper's inferred integer-only C signature is incomplete.
Interpret register inputs as:

| Register | Symbol used here | Meaning established by its arithmetic |
| --- | --- | --- |
| `s0` | T | target speed |
| `s1` | G | gain applied to remaining speed gap |
| `s2` | M | cap on the increase before scale/alignment |
| `s3` | S | scale applied to increase, or speed when at/above target |
| `s4` | D | direction multiplier applied before and after integration |

After other state-dependent calculations set `A` (an alignment/contact factor),
the tail at `0x1897e8..0x189820` performs the following scalar arithmetic:

```text
v = movement.drive_speed * D                  // 0x189664..0x18966c
if v < T:
    increment = min((T - v) * G, M) * S
    v = v + A * increment
else:
    v = v * S
movement.drive_speed = v * D
```

This is a description of the observed finite ordinary float path, not a claim
that the game uses these variable names. In the normal branch reaching the
call at `0x182128`, the caller supplies:

```text
T = float(move + 0x3d0) * float(move + 0x3e0)
G = float(move + 0x474) or float(move + 0x478), selected by state
M = float(move + 0x47c)
S = float(move + 0x3e8)
D = 1.0
```

The helper computes a velocity-like vector from offsets `0x2f8..0x30c`, the
speed field, and the vector at `0x2a4..0x2ac`; it normalizes that vector when
its magnitude is positive. In one ordinary path `A` starts at 1. Under
additional conditions it becomes the absolute dot product of that normalized
vector with the vector at `0x1c..0x24`, clamped to `[0.1, 1.0]`. Another path
sets `A=0` when wall/contact conditions apply. Full state flag meanings remain
unknown. A special state also overrides T/G/M before the tail; it must not be
omitted in a purported full recreation.

The surrounding caller `0x181e9c` further applies state changes, an additional
speed multiplier from `+0x330`, speed cap logic, and computes other derived
speed values. The helper equation alone is therefore not the entire movement
update and must not be presented as exact Mario Kart handling.

Evidence:

- `ev_b0558827cfe9795cb357682e41e26abaf946768c97b04437e33e406375ea799d`: complete provider assembly and CFG for helper `0x189644`
- `ev_6b2e76ae283c941525b720fad1aea5c17074fbc1a62ed4c6785cd56e61654222`: caller `0x181e9c`, including exact VFP argument loads

## Limits and next evidence needed

Answered: native container mapping, Performance file use, table binding slots,
and one actual scalar speed integration helper with named speed-state mapping.
Partially answered: acceleration shape. The helper approaches a target with
a capped proportional increase, but the PRAC columns have not been traced all
the way to the caller fields. Do not assign PRAC columns to G or M by guess.

Still unresolved: mapping from Performance rows into movement fields; frame
rate/time units; world scale; steering update equation; drift charge update
and release transitions; braking; gravity/contact response; boost transitions;
runtime reproduction. Those remain required for fidelity.

Hopper does not expose complete function body ranges through its public API.
Some functions reached only indirectly are not discovered (`0x186578` is just
a `bx lr` stub, not a recovered update function). Pseudocode is especially
unreliable for VFP and jump-table control flow; the equation above is derived
from assembly rather than accepting the pseudocode as source.
