#!/bin/bash
# Build the whole mod from your extracted games, in dependency order, then collect it into build/.
#   scripts/build_mod.sh            build everything
#   scripts/build_mod.sh --install  ... and install into Ryujinx (macOS), backing up any existing KartLab_110
# Needs scripts/setup_tools.sh and scripts/extract_games.py first (docs/BUILDING.md). Takes roughly 15-30 minutes.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PYTHONPATH="$ROOT/.tools/kart-assets/python"
export MPLCONFIGDIR="${TMPDIR:-/tmp}/kartlab-matplotlib"
for d in extracted/totk/romfs extracted/mk8dx/romfs; do [ -d "$d" ] || { echo "missing $d: extract your games first (docs/BUILDING.md)"; exit 1; }; done

# FROM="<part of a step name>" resumes at that step (earlier outputs must already exist)
started=${FROM:+no}; started=${started:-yes}
step() {
  if [ "$started" = no ]; then case "$1" in *"$FROM"*) started=yes ;; *) printf 'skip: %s\n' "$1"; return ;; esac; fi
  printf '\n== %s\n' "$1"; shift; "$@"
}
py() { python3 "$@"; }

# Intermediate inputs straight from the games
step "Prepare inputs (executables, TOTK cart model, glider texture, cart pack)" py scripts/prepare_inputs.py
step "Export the MK8 Standard Kart" py scripts/kart_assets_export.py
for b in 0 1 14 31; do   # MK8 body rows: Standard Kart, Pipe Frame, Standard Bike, B Dasher
  step "MK8 wheel placement, body row $b" env KART_BODY_INDEX=$b python3 scripts/kart_assets_native_placement_probe.py
done
# Standard Kart model, textures, steering rim, glider
step "Standard Kart model in the TOTK cart" py scripts/kart_assets_source_native_assembly.py
step "HD kart texture" py scripts/build_kart_texture_hd.py
step "Steering Stick host model (raised root)" py scripts/build_controlstick_root_trial.py
step "Steering Stick host model (stick hidden)" py scripts/build_controlstick_hidden_host.py
step "Steering animation (root trial)" py scripts/build_controlstick_animation_root_trial.py
step "Hand targets on the kart" py scripts/build_kart_grip_targets.py
step "Turning steering rim" py scripts/build_rim_transfer.py
step "MK8 glider" py scripts/build_glider.py
# Kart actor: seat, physics, contacts
step "Kart actor (cart sub-model)" py scripts/build_native_mount_submodel.py
step "Kart physics" py scripts/build_native_mount_cart_physics.py
step "Wheel contacts and seat" py scripts/build_source_native_contacts.py --raised-chassis --saddle-height 0.7 --cart-dynamics --saddle-forward 0.45
step "Grippy tyres" py scripts/build_kart_grip.py
# Sounds and Link's pose
step "MK8 sound bank" py scripts/build_kart_sound_bank.py
step "MK8 sounds (speed and surface)" py scripts/build_kart_sound_db.py
step "Link's seated pose" env LEGS="-4.79,6.88,68.23,-41.91,77.33,-8.43,81.77,-5.62,6.86,248.09,-41.47,-196.41,188.62,-98.15" LEAN="12,6,15" \
  python3 scripts/build_kart_seated_pose.py A_Pose_RaumiGolem_Ride assets/kart-seated-lean full
# Extra karts and inventory items
for v in skl bds bike; do step "Kart variant $v" py scripts/build_kart_variant.py $v; done
step "Actor database rows" py scripts/build_kart_rsdb.py
step "Inventory capsules (names, icons)" py scripts/build_kart_capsules.py
step "Kart chests at Lookout Landing" py scripts/build_kart_chests.py
# Runtime
step "Fall-release patch" py scripts/build_fall_release_patch.py
step "Kart controller script" py scripts/build_native_wheels.py
step "Assemble build/" py scripts/assemble_mod.py "$@"
