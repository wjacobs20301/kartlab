# Extra MK8 karts: Pipe Frame, B Dasher, Standard Bike, inventory capsules, kart chests (Oct 19, installed; controller `9b3b50cb…`)

**Getting karts:** four Zonai chests just outside Lookout Landing's east fence (about (−156, −54…−63), map section E-4)
hold five capsules each of Standard Kart, Pipe Frame, B Dasher and Standard Bike. Place one from Inventory → Zonai
Devices → Take out device, climb in with A. No button combos (the old spawn/pick/capsule chords only run in tests). Each body is its own actor:
Standard Kart `SpObj_ControlStick_A_01`, Pipe Frame `A_02`, B Dasher `A_03`. Built by `scripts/build_kart_variant.py
skl|bds` → `assets/kart-variant-<body>/romfs` (+ `--rstb` to chain the size table).

## How
* **Placement from MK8 itself:** `KART_BODY_INDEX=<row> scripts/kart_assets_native_placement_probe.py` runs MK8's own
  wheel/arm setup code on that body's Parts.bin rows (BODY row = inner index; BDTR [body][tire]; TRBD [tire][body]).
  Rows follow MK8's body table: 0 K_Std, 1 K_Skl (Pipe Frame), 14 B_Std (Standard Bike), 31 K_Bds (B Dasher).
  Pipe Frame wheels ±0.85/±0.82 m, B Dasher ±0.95/±1.01 m (Standard ±0.73/±0.70).
* **Cart model:** same assembly as the Standard Kart (body LOD0 all shapes + Standard tyres + ArmK_Std arms, sockets at
  the body's wheel centres), generic atlas (body tiles sized from its UV range), 2048² albedo.
* **Names:** model `SpObj_Cart_A.SpObj_Cart_A_K1` (Pipe Frame) / `K3` (B Dasher); albedo `Etc_ZonauCart_2_Alb` /
  `_3_Alb`; size-table entries inserted (CRC-sorted). **BFRES name dictionaries are bit-tries**: a one-entry dict tests
  bit 0 of the name's last character, so renamed models must end in an odd character ("K2"/"ZZ" never loaded).
* **Actor packs:** start from the vanilla A_02/A_03 pack (ActorParam with `$parent` A_01 + own AI/event members) and
  overlay every member of the installed kart pack, so the parent chain resolves to the modded kart (seat, sounds via the
  A_01 SLink user, glider host). A_02 has its own ModelInfoRef (→ cart K1). A_03 has none, so the A_01 ModelInfo inside
  its own pack carries cart K3 (works: actor resources resolve inside their own pack). A pack built only from the kart's
  A_01 members under the new name never finished creating (state 0).
* **Physics:** both use the kart's own physics chain. Repointing it to renamed ControllerSet/Shape members (to move the
  wheel contact hulls) crashed actor creation (null+0x18). So contact hulls sit at the Standard Kart positions.
* **Controller:** wheel-bone check accepts any mirrored kart-sized socket layout; spin uses each body's tyre scale;
  spawn waits until the component table/physics exist (a new pack can be visible to ActorWatcher before them —
  LotusKit getMainRigidBody reads *(actor+0x228)+0x50 unchecked) and sleeps 60 frames after createAndWatch.

## Tested
Orbit screenshots of both bodies with Link seated; drift test on each: drives, wheel bones found, no crash.

## Not done
Own steering wheel of each body is static (only the Standard Kart's rim turns, shared host); contact hulls not moved;


## Standard Bike (actor `SpObj_ControlStick_A_04`, model `SpObj_Cart_A_K5`, `build_kart_variant.py bike`)
* MK8's bike placement code isn't probed (the probe runs the kart path), so the parts are fitted by geometry
  (`bike_layout`): fork = ArmB_StdM ArmB_F + Sus (mirrored) hanging from the Jnt_Handle pivot along its −25° steering
  axis (axle 4.0 units down the fork); swingarm ArmB_B (mirrored) from Jnt_ArmB, angled so both axles are level; centred
  TireB_Std tyres ×1.2 on Wheel_00 (front) / Wheel_02 (rear), both sockets of an axle on the centre line. Everything is
  raised so the tyres sit on the Standard Kart's ground (physics hulls unchanged = invisible kart-width stance).
* Host budget (LOD0 2652 v / 2242 t, LOD1 1022 / 538): body LOD0 (rear shock LOD1), tyres LOD1, arms LOD2.
* **New actor:** no vanilla A_04, so the pack is the vanilla A_02 pack renamed A_02→A_04 + the kart overlay, and
  `scripts/build_kart_rsdb.py` adds rows (copies of A_02) to ActorInfo / GameActorInfo / AttachmentActorInfo (sorted by
  `__RowId`; `byml_rw.py` round-trips the tables). Not in the Tag table (bit matrix; ~3000 vanilla actors have no tags).
* **Seat:** own RidableParam (`RidableRef` added to the A_04 ActorParam), SaddleOffset Y 1.1 (kart 0.7), Z 0.45.
* **Lean:** the controller rolls the cart's Skl_Root record (wheel-bone record 0) about the forward axis through the
  ground: ~22° × stick × speed, ~29° drifting, upright in the air. Link keeps the kart pose (legs forward, inside the
  tank); a straddle pose would need per-kart animation switching (not done).

## Inventory karts (`scripts/build_kart_capsules.py`, rows from `build_kart_rsdb.py`)
* Capsules `SpObj_ControlStick_Capsule_A_02/03/04` = the vanilla Steering Stick capsule pack with every string renamed
  (CapsuleParam.Content, Replace AttachmentParam → A_0N); PouchActorInfo/ActorInfo/GameActorInfo/AttachmentActorInfo
  rows copied from Capsule_A_01 (ActorName, CapsuleContent overridden); A_0N `PushToPouchSpecialParts` → own capsule.
  The vanilla Steering Stick capsule already spawns A_01 and is renamed **Standard Kart**.
* Names/captions: Mals USen + EUen `ActorMsg/PouchContent.msbt` (<capsule>_Name/_Caption) and `Attachment.msbt`
  (<device>_Name/_Adjective), via `msbt_rw.py` (byte-identical round trip).
* Icons `UI/Tex/Icon/<capsule>.bntx`: vanilla capsule icon + MK8's own `tc_KP_*` part icon (B Dasher has none in MK8:
  `render_kart_icon.py` software-renders the built model). ASTC 4×4 sRGB via astc-encoder (`.tools/astc`, pip wheel),
  block-linear (block height 8) at +0x1000.
* **Adoption:** the controller takes over any ControlStick kart Link rides (placed from a capsule, a world Steering
  Stick): Player component 130 +0x28 = BaseProcLinkData of the ridden actor (+0x40 actor, +0x48 id; found by a memory
  scan, `RIDESCAN=1` in build_spark_visual_test.py); actor name read from ActorBase+0x218; `ActorWatcher::assignSlot`.
* **Glider on unadopted karts:** a ControlStick the controller hasn't touched draws bone Control at identity, not at its
  rest scale 0 — a full-size open glider (also the old "glider was just on after spawning" report). The glider mesh is
  now stored 1/1000 size (`build_glider.py` STORE) and opened with bone scale 1000·s.

Tested (Oct 18): bike orbit/drive/drift/glide; ZL+ZR+Y capsule; pickup popups (name, icon, caption) for Standard Kart
and Standard Bike; Zonai Devices tab lists them; Take out device → bike placed (glider folded) → mounted → adopted →
driven at 13 m/s (`scripts/build_capsule_test.py`).

## Kart chests (`scripts/build_kart_chests.py`)
* Four `TBox_Field_Stone_Zonau` entries appended to `Banc/MainField/E-4_Dynamic.bcett.byml` (same shape as vanilla
  Zonai chests: `Dynamic.Drop__DropActor`, `Hash` = `Phive.Placement.ID`, `SRTHash`; fresh hashes, fixed seed).
  Iron Zonai chests only occur in Static files (which carry Phive headers), so the stone kind is used.
* Drops: 5-capsule bundles. Bundles have no pack, only RSDB rows (vanilla `SpObj_ControlStick_Capsule_A_01_Bundle_B`,
  BundleActorNum 5); `build_kart_rsdb.py` adds `_A_02/03/04_Bundle_B`.
* Vanilla chest hashes are listed in GameDataList (big-endian BYML); the new ones are not, so whether a chest stays
  open after a reload is untested (it may close again and refill).
* Tested: all four open with "<kart> ×5" popups, Zonai Devices tab lists them, Take out device places the kart
  (`scripts/build_chest_test.py`). An autosave during the test changed the save; the pre-test save was restored.

## Oct 19 fixes (user report: Standard Kart and B Dasher would not place; Link badly seated on the variants; parked
karts slid away). Controller `9b3b50cb…`.
* **Actor numbers changed.** Every variant is now a NEW actor cloned from the vanilla A_02 pack: Pipe Frame
  `SpObj_ControlStick_A_06`, B Dasher `A_05`, Standard Bike `A_04`; vanilla `A_02`/`A_03` are untouched again. Capsules
  keep their names (Capsule_A_02 = Pipe Frame, _03 = B Dasher, _04 = Bike) and point at the new actors
  (`CONTENT` in build_kart_capsules.py / build_kart_rsdb.py). Why: (1) B Dasher (vanilla A_03, no ModelInfoRef) had
  overridden the A_01 ModelInfo inside its pack; resources are cached by path, so a Standard Kart created after a B
  Dasher got the B Dasher model or failed (pair test: two B Dashers). (2) Adding any component reference to a vanilla
  actor's ActorParam (ModelInfoRef on A_03, RidableRef on A_02) crashed actor creation (a component allocation returned
  null: main+0xaf141c / BYML reader main+0x872fa0); bigger RSDB heaps did not help. New actors take the same edits.
* **Standard Kart never created:** a stray test file in assets/kart-variant-skl/romfs (Etc_ZonauCart_A_Alb.txtg from a
  VARIANT_KEEP_TEX experiment, 230 KB) had been installed over the Standard Kart's albedo, larger than its size-table
  entry (101 KB), so the texture (and the kart) failed to load. Restored from assets/kart-texture-hd;
  `scripts/check_mod_sizes.py` now checks every installed file against the RSTB. Variant build folders are rebuilt
  from scratch (`scripts/rebuild_all_karts.sh`).
* **Heap / bounds:** every kart's ActorInfo row: InstanceHeapSize 262144 (A_01 was 160680), ModelAabb kart-sized.
* **Parked karts slid:** the four wheel contact hulls used Material_Cart (rail cart, frictionless). Now
  Material_Stone_ZonauLight (`build_kart_grip.py`, the normal Zonai-device material): placed karts did not move at all
  in 10 s on an ~8 degree slope; driving unchanged (6.8 m/s after 1 s, 13 top, 15 boosting). Material_StoneNoSlip was
  tried first and stopped the karts from driving (~1 m/s: the controller caps commanded speed at measured + margin).
* **Seats:** the variants' own static steering wheels are removed from their meshes (islands inside a box around the
  wheel, 128/132 triangles; `drop_wheel`), so the turning rim Link holds is the only wheel. Pipe Frame saddle Y 0.66,
  Z 0.37 (was the kart's 0.7/0.45: Link floated ahead of the seat). Bike: Link's hand targets (host bones
  Handle_L/R, children of the rim, never animated) are written every frame onto the handlebar grips, turned with the
  front wheel about the bike's steering axis, leaned with the bike, and expressed in the rim's live frame
  (`handTargets` in the controller); karts get their rest values back.
* **No more button combos for karts** (`devChords` test-only); kart chests at Lookout Landing (see above).
* Tests (all in game, Oct 19): pair test B Dasher + Standard Kart in one session (each its own model); every kart
  placed from the inventory, none moved in 10 s; Standard Kart and B Dasher placed and ridden (adopted, correct model);
  orbit screenshots of all four with Link seated, hands on wheel/bars; Standard Kart and bike drive/drift/boost;
  Standard Kart glider + trick. Two Ryujinx-internal crashes (GPU texture flush during world load) in ~30 launches.
* Known: karts placed before this update as A_02/A_03 come back as plain Steering-Stick actors; place new ones.
  Script spawning (createAndWatch) is only used by tests.
