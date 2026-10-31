#!/bin/bash
# Fetch and build every third-party tool the KartLab build uses, pinned to the exact versions it was developed with,
# into .tools/ (git-ignored). Safe to re-run: finished steps are skipped.
#
# Needs: git, curl, make, cmake, a C/C++ compiler (Xcode command line tools on macOS), Python 3.11+ with numpy and
# Pillow. Tested on macOS (Apple silicon). No game files are downloaded; see docs/BUILDING.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$ROOT/.tools"
mkdir -p "$T/kart-assets" "$T/totk-runtime"

say() { printf '\n== %s\n' "$*"; }

clone() {  # clone <url> <dest> <commit>
  local url="$1" dest="$2" commit="$3"
  if [ -d "$dest/.git" ] && [ "$(git -C "$dest" rev-parse HEAD)" = "$(git -C "$dest" rev-parse "$commit^{commit}" 2>/dev/null || echo none)" ]; then
    echo "ok: $dest @ ${commit:0:7}"; return
  fi
  rm -rf "$dest"
  git clone --quiet --recursive "$url" "$dest"
  git -C "$dest" checkout --quiet "$commit"
  git -C "$dest" submodule update --quiet --init --recursive
  echo "cloned: $dest @ ${commit:0:7}"
}

patch_once() {  # patch_once <repo dir> <patch file>
  if git -C "$1" apply --reverse --check "$2" 2>/dev/null; then echo "ok: $(basename "$2") already applied"
  else git -C "$1" apply "$2"; echo "applied: $(basename "$2")"; fi
}

say "Checking prerequisites"
for c in git curl make cmake cc c++ python3; do command -v "$c" >/dev/null || { echo "missing: $c"; exit 1; }; done
python3 - <<'EOF'
import sys
assert sys.version_info >= (3, 11), 'Python 3.11 or newer is needed'
try:
    import numpy, PIL
except ImportError as e:
    sys.exit(f'missing Python package: {e.name} (pip3 install numpy pillow)')
print('python', sys.version.split()[0], 'numpy', numpy.__version__, 'pillow', PIL.__version__)
EOF

say "hactool (game container extraction)"
clone https://github.com/SciresM/hactool.git "$T/hactool" 1d64a83
patch_once "$T/hactool" "$ROOT/scripts/hactool_keys.patch"   # read keys from TOTK_MOD_KEY_DIR; tolerate duplicate title keys
[ -f "$T/hactool/config.mk" ] || cp "$T/hactool/config.mk.template" "$T/hactool/config.mk"
[ -x "$T/hactool/hactool" ] || make -C "$T/hactool" -j4 >/dev/null
[ -x "$T/hactool/hactool" ] || { echo "hactool failed to build"; exit 1; }
echo "built: $T/hactool/hactool"

say "MeshCodec (TOTK .mc model compression)"
clone https://github.com/dt-12345/MeshCodec.git "$T/kart-assets/MeshCodec" b360095
patch_once "$T/kart-assets/MeshCodec" "$ROOT/scripts/kart_assets_meshcodec_arm64.patch"   # arm64 build fixes
if [ ! -x "$T/kart-assets/MeshCodec/build/tests/mc_test" ]; then
  # newer libc++ no longer includes <cstddef>/<algorithm> implicitly; MeshCodec relies on that
  cmake -S "$T/kart-assets/MeshCodec" -B "$T/kart-assets/MeshCodec/build" -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON \
    -DCMAKE_CXX_FLAGS="-include cstddef -include algorithm" >/dev/null   # mc_test (the decoder the build uses) is a test target
  cmake --build "$T/kart-assets/MeshCodec/build" -j4 >/dev/null
fi
[ -x "$T/kart-assets/MeshCodec/build/tests/mc_test" ] || { echo "MeshCodec mc_test failed to build"; exit 1; }
echo "built: $T/kart-assets/MeshCodec/build/tests/mc_test"

say "Python format libraries"
clone https://github.com/UltimateBomb/totk-meshcodec.git "$T/kart-assets/totk-meshcodec" 032c41d
clone https://github.com/ranidspace/BlenderBfresImporter.git "$T/kart-assets/BlenderBfresImporter" 9fb84c2
python3 -m pip install --quiet --upgrade --target "$T/kart-assets/python" \
  capstone==5.0.9 pyelftools==0.33 texture2ddecoder==1.0.6 unicorn==2.1.4 zstandard==0.25.0
python3 -m pip install --quiet --upgrade --target "$T/astc" astc-encoder-py==0.1.12 archspec==0.2.6
echo "installed: $T/kart-assets/python, $T/astc"

say "LotusKit runtime (scripting runtime the mod runs on)"
clone https://github.com/aquacluck/totk-lotuskit.git "$T/totk-runtime/lotuskit" 59dcfccd77b6d4bcfa718bff806bc55be640edb7
ZIP="$T/totk-runtime/lotuskit-110.zip"
URL=https://github.com/aquacluck/totk-lotuskit/releases/download/2026-04-20-59dcfccd77b6d4bcfa718bff806bc55be640edb7/totk110-lotuskit-59dcfccd77b6d4bcfa718bff806bc55be640edb7.zip
SHA=dc7b59413cf62e8a8c961aeb905debaacd111d53889fe5bfdd45d0c71cf33d2c
if [ ! -f "$ZIP" ] || [ "$(shasum -a 256 "$ZIP" | cut -d' ' -f1)" != "$SHA" ]; then curl -fsSL "$URL" -o "$ZIP"; fi
[ "$(shasum -a 256 "$ZIP" | cut -d' ' -f1)" = "$SHA" ] || { echo "LotusKit release checksum mismatch"; exit 1; }
echo "downloaded: $ZIP (sha256 ok)"

say "Done. Next: docs/BUILDING.md step 2 (extract your games)."
