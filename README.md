# KartLab — Mario Kart in Tears of the Kingdom (TOTK 1.1.0)

A fan-made TOTK mod that turns Zonai Steering Sticks into Mario Kart 8 Deluxe karts: MK8DX-style handling (drifting,
mini-turbos, tricks, hops), the MK8 glider, MK8 sounds and effects, and an MK8-style chase camera. Four vehicles —
Standard Kart, Pipe Frame, B Dasher and Standard Bike — come as inventory items: open the four Zonai chests just outside
Lookout Landing's east fence, then place a kart from **Inventory → Zonai Devices → Take out device** and climb in with A.

Built on the [totk-lotuskit](https://github.com/aquacluck/totk-lotuskit) AngelScript runtime plus a few small patches.
Tested in Ryujinx 1.3.3 on macOS; Switch hardware is untested.

## No game content in this repository

This repository holds only the mod's own code, build scripts and research notes. It contains **no files from Tears of
the Kingdom or Mario Kart 8 Deluxe** — no models, textures, sounds, game data or code. Every game-derived asset is
generated locally by the build scripts from **your own legally dumped copies** of both games (TOTK 1.1.0 and MK8DX),
which you place yourself and which are never committed (`*.xci`, `extracted/`, `assets/` are git-ignored).

This is an unofficial fan project, not affiliated with or endorsed by Nintendo. Mario Kart, The Legend of Zelda and
related names are trademarks of Nintendo.

## Building

1. Put your game dumps in the repo root as `totk.xci` and `mk8dx.xci` (or set `TOTK_XCI` / `MK8DX_XCI`), then run
   `scripts/extract_games.py` (needs [hactool](https://github.com/SciresM/hactool) and your own keys).
2. Build the assets: `scripts/rebuild_all_karts.sh` (karts, capsules, chests, size table) plus the
   `scripts/build_*.py` steps it relies on (glider, sounds, pose, textures); `scripts/check_mod_sizes.py` checks the
   result.
3. Controller script: `runtime/candidates/native-rider-wheels/controller.src.as`, built into `autorun.as` with
   `scripts/build_native_wheels.py`.

Start with `CLAUDE_HANDOFF.md` (newest state at the top) for the full picture; it and `PROJECT.md` are development
logs. Research notes are in `research/` (raw logs, test receipts and extracted-data dumps are kept out of the repo, so
some notes mention files that are not here).

## Third-party code

* `runtime/candidates/malloc-lock-110/subsdk9` is a modified build of totk-lotuskit (GPL-2.0, commit
  `59dcfcc`; license in `COPYING` next to it). Its source changes are `runtime/patches/*.patch`,
  `runtime/candidates/*/source.patch` and the binary patch scripts `scripts/patch_lotuskit_*.py`.
* Format knowledge comes from community tools credited in the notes (Switch-Toolbox, MK8-Parts-Bin-Converter,
  BlenderBfresImporter, MeshCodec, the TOTK modding community).

## License

GPL-2.0 (see `LICENSE`), the same license as totk-lotuskit, which this mod is built on. You are free to use, change and
share it; if you share a modified version, share its source under the same license. The license covers this
repository's code only: game files and anything converted from them belong to Nintendo and are not covered.
