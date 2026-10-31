# Building KartLab

KartLab ships no game content. You build the mod yourself from your own copies of both games; the scripts convert the
Mario Kart 8 Deluxe karts, sounds and glider into Tears of the Kingdom files on your machine. Nothing you build should
be shared — it contains Nintendo's assets.

Tested on macOS (Apple silicon) with Ryujinx 1.3.3. Linux should work for building with small path changes; Windows is
untested. Playing on Switch hardware is untested.

## What you need

| | |
| --- | --- |
| **Tears of the Kingdom** | Base game dump (`.xci`) **and the 1.1.0 update** (`.nsp`). The mod only works on 1.1.0. |
| **Mario Kart 8 Deluxe** | A dump at **version 1.7.1** (an `.xci` that includes the 1.7.1 update). |
| **Keys** | `prod.keys` and `title.keys` dumped from your own Switch. |
| **Tools** | git, curl, make, cmake, a C/C++ compiler (`xcode-select --install` on macOS), Python 3.11+ with numpy and Pillow (`pip3 install numpy pillow`). About 40 GB of free disk space. |
| **To play** | Ryujinx 1.3.3 with TOTK updated to 1.1.0. |

## 1. Fetch the tools

```bash
scripts/setup_tools.sh
```

This downloads and builds the third-party tools into `.tools/` (git-ignored), each pinned to the exact version the mod
was made with:

| Tool | Version | Used for |
| --- | --- | --- |
| [hactool](https://github.com/SciresM/hactool) | `1d64a83` + `scripts/hactool_keys.patch` | extracting your game files |
| [MeshCodec](https://github.com/dt-12345/MeshCodec) | `b360095` + `scripts/kart_assets_meshcodec_arm64.patch` | TOTK's compressed `.mc` models |
| [totk-meshcodec](https://github.com/UltimateBomb/totk-meshcodec) | `032c41d` | packing `.mc` models (Python) |
| [BlenderBfresImporter](https://github.com/ranidspace/BlenderBfresImporter) | `9fb84c2` | reading BFRES models and BNTX textures |
| [totk-lotuskit](https://github.com/aquacluck/totk-lotuskit) | `59dcfcc` + release `2026-04-20` | the scripting runtime the mod runs on |
| Python packages | capstone 5.0.9, pyelftools 0.33, unicorn 2.1.4, texture2ddecoder 1.0.6, zstandard 0.25.0, astc-encoder-py 0.1.12 | decoding and encoding game data |

## 2. Extract your games

Put your dumps in the repository folder as `totk.xci` and `mk8dx.xci` (copies or symlinks), or point to them:

```bash
export TOTK_XCI=/path/to/totk.xci MK8DX_XCI=/path/to/mk8dx.xci
export TOTK_UPDATE=/path/to/totk-1.1.0-update.nsp   # optional on macOS: defaults to the update selected in Ryujinx
export SWITCH_KEYS_DIR=/path/to/keys                 # optional on macOS: defaults to Ryujinx's key folder
```

Then run the four extraction stages:

```bash
python3 scripts/extract_games.py containers
python3 scripts/extract_games.py metadata
python3 scripts/extract_games.py export
python3 scripts/extract_games.py verify
```

This writes `extracted/totk` and `extracted/mk8dx` (both git-ignored) and checks the versions are TOTK 1.1.0 and MK8DX
1.7.1.

## 3. Build

```bash
scripts/build_mod.sh
```

This runs every step from your extracted games to a finished mod in `build/` (15–30 minutes):

1. Prepares inputs from the games (decompressed executables, TOTK's cart and Steering Stick models, the MK8 glider
   texture).
2. Exports the MK8 Standard Kart and runs MK8's own wheel-placement code (in an emulator) for each kart body.
3. Builds the Standard Kart model inside TOTK's cart, its HD texture, the turning steering wheel and the glider.
4. Builds the kart actor (seat, physics, wheel contacts, grippy tyres), MK8 sounds and Link's seated pose.
5. Builds Pipe Frame, B Dasher and Standard Bike, their inventory capsules, and the kart chests at Lookout Landing.
6. Builds the controller script and the runtime patch, then collects everything into `build/` and checks every file
   fits its entry in the game's resource size table.

If a step fails you can fix it and resume, e.g. `FROM="Kart variant" scripts/build_mod.sh`.

## 4. Install

On macOS with Ryujinx:

```bash
scripts/build_mod.sh --install
```

(or `python3 scripts/assemble_mod.py --install` after a build). This copies `build/KartLab_110` to
`~/Library/Application Support/Ryujinx/mods/contents/0100f2c0115b6000/KartLab_110` (backing up any existing copy) and the
controller to `~/Library/Application Support/Ryujinx/sdcard/totk_lotuskit/autorun.as`.

Elsewhere, copy them by hand: `build/KartLab_110` into your emulator's TOTK mod folder, and
`build/sdcard/totk_lotuskit/autorun.as` to `totk_lotuskit/autorun.as` on the emulated SD card.

## 5. Play

Load a save that has reached Lookout Landing. Open the four Zonai chests just outside its east fence (Standard Kart, Pipe
Frame, B Dasher, Standard Bike — five of each). Then **Inventory → Zonai Devices → Take out device**, walk up and press A.

Controls: A gas, B brake/reverse, left stick steer, R or ZR hop and drift, L horn, X get out, Y in the air opens the
glider, right stick down looks behind. Optional toggles: ZL+ZR+D-pad Left (Mario Kart camera), Right (auto glider),
Down (off-road handling).

## Troubleshooting

* **`mc_test failed to build`** — update the Xcode command line tools; setup already works around newer libc++ headers.
* **Extraction says a version is wrong** — the mod needs exactly TOTK 1.1.0 and MK8DX 1.7.1.
* **A kart does not appear when taken out, or the game crashes on load** — run `python3 scripts/assemble_mod.py`
  again and read its size-table check; a file larger than its size-table entry stops the game loading it.
* Development notes: `CLAUDE_HANDOFF.md` (newest state at the top) and `research/`.
