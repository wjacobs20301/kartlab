# Kart asset investigation and first native visual candidate

Target inputs: locally extracted Mario Kart 8 Deluxe 1.7.1 and TOTK 1.1.0.
Read-only source dumps remain under `extracted/`; no source game image or extracted
resource was edited.

## What exists

- `assets/standard-kart/standard-kart.gltf` + `standard-kart.bin`: editable source
  conversion of the actual standard kart body plus four standard tires, 2,889
  LOD0 triangles in five rigid meshes. References Mario's 1024² body albedo and
  the 256² standard tire albedo. These glTF materials approximate base color;
  they do not reproduce Nintendo's shader.
- `assets/standard-kart/source/`: original decompressed BFRES and embedded BNTX
  files. All original LODs, materials, shader attachments and skeletons remain
  in the BFRES copies.
- `assets/standard-kart/textures/`: 16 decoded texture PNGs, including base color,
  emission, bake, dirt, specular masks and normal XY channels.
- `assets/standard-kart/manifest.json`: input hashes, exact source paths, BFRES
  version, bones, material/texture names, dimensions and format coverage.
- `assets/standard-kart/source-preview.png`: offline render using one color
  sample per triangle. Original tire rest transforms retained. The two vertical
  yellow-ended tubes are exhausts in the **body** mesh. This is no game capture.
- `assets/native-cart-mod/romfs/Model/SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc`:
  experimental native-format Cart replacement. It contains real MK8DX body/tire
  geometry bound to TOTK's original wheel bones, with the original TOTK material.
  No Mario red/blue atlas is installed in this native prototype yet.
- `assets/native-cart-mod/validation.json`: package sizes, hashes, checks and
  runtime limitations. `geometry-preview.png` reconstructs its decoded geometry
  with neutral illustrative colors, not actual game shading.

## Source observations

`Kart/Body/BodyK_Std.szs` is Yaz0-compressed BFRES, not a SARC. The parsed BFRES
version is `0x00050003` (0.5.0.3). Its single rigid body shape has 2,818 vertices
including three LODs with 5,211 / 1,785 / 1,191 indices. The body skeleton contains
one identity root. Its material `m_Body` uses shader archive `Turbo_UBER` and
shading model `turbo_uber`. The base atlas name is initially `Body_Dummy_Alb`;
`Kart/BodyTex/BodyK_Std_Mro_Alb.szs` supplies Mario's actual color variant.

`Kart/Tire/TireK_Std.szs` has four separately rigid tire shapes and bones named
`TireK_LB`, `TireK_LF`, `TireK_RB`, `TireK_RF`. Their bone translations are
(+5,0,-5), (+5,0,+5), (-5,0,-5), (-5,0,+5). These are observed source rest
transforms; runtime/body-parameter-dependent tire placement has not been traced.
The tire material also uses `Turbo_UBER`. The glTF preserves source units and
Y-up axes. Source dimensions are roughly 12.58 × 7.09 × 20.03, **not meters**.

Position/normal/UV/index buffers were decoded by format. Body positions are
float32 XYZ, tire positions are IEEE binary16, normals signed 10:10:10:2, UVs
binary16 or float32. The source conversion explicitly reads little endian and
respects attribute offsets and buffer strides. IEEE half decoding in our exporter
avoids the upstream importer's alternate ARM-half conversion.

BNTX textures were parsed, Tegra block layout deswizzled and BC1/3/4/5 decoded.
BC5 signed XY are stored as `(value + 1) / 2` in PNG; they are not applied as glTF
normal maps, because the intended tangent-space convention remains unverified.
Channel selectors are recorded but not applied to archival decoded channel PNGs.
Original BNTX files preserve original compressed data and swizzles exactly.

## Native Cart prototype

The supplied TOTK `SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc` starts with `MCPK` and
contains BFRES version 10 plus an `FMSH` mesh section. The main skeleton is:

```
Root
  Skl_Root (0, 0.3766, 0)
    Wheel_00 (+1.05, -0.1223, +1.0863)
    Wheel_01 (-1.05, -0.1223, +1.0863)
    Wheel_02 (+1.05, -0.1223, -1.0863)
    Wheel_03 (-1.05, -0.122309, -1.0863)
```

Rigid-matrix-to-bone indices are (1,2,3,4,5). The candidate fits all geometry into
existing allocations, retaining skeleton, material bytes, native texture names,
resource pointers, GPU buffer lengths and original draw counts. Unused index
slots/shapes become degenerate triangles. Bounding boxes and per-bone spheres
are conservatively expanded within the existing structures.

- Close LOD: body LOD0 at scale 0.16, four actual tire LOD2 meshes at scale 0.14365.
  1,929 non-degenerate triangles; native capacity 2,242 triangles / 2,652 vertices.
- Far LOD: body LOD2 plus authored six-sided capped wheel cylinders. 493
  non-degenerate triangles; native capacity 538 triangles / 1,022 vertices.
- Native original compressed file: 23,032 bytes. Candidate: 121,616 bytes
  (larger because geometry uses NullCodec frames).
- Decoded allocation: **139,264 bytes unchanged**. RESTBL model allocation does
  not need expansion for this candidate. Other mod files are outside this claim.

The candidate's fully decoded BFRES + GPU data compared byte-for-byte against
our expected patched buffer using the independent C++ MeshCodec decoder.
The decoder required documented fixes described below. This cross-implementation
check does not establish that the game will load/render/ride it correctly.

The candidate retains native cart collision, rider/control behavior and seating.
It replaces all Cart visuals using this resource; it is not a new actor. The
runtime controller work lives elsewhere. Native shader/texture sampling may look
like stone or green Zonai material on the new UVs. Rendering, wheel rotation,
culling, LOD transitions and Switch compatibility still need live tests.

## Concrete remaining asset integration work

1. Test this exact native candidate by replacing the Cart model resource on
   TOTK 1.1.0; check actor spawning and both LODs. The `romfs` path above is the
   complete visual prototype payload.
2. Convert Mario's body/tire images to the game's texture container layout and
   remap/rebuild the retained v10 material's shader parameters and sampler names.
   Reusing `Turbo_UBER` from MK8DX is not sufficient; the candidate currently
   retains native `Mt_Etc_ZonauCart_A` material and existing texture references.
3. Either split body/tire material slots or author a combined atlas and remap UVs.
   The native prototype currently uses one original Cart material for both.
4. Adjust host collision and rider attachment separately: our visual body scale
   is a design choice and is not a measurement of Mario Kart's physical units.
5. Add a character later: no Mario character/animation has been converted here.

## Tools and reproducibility

Used primary-source tools:

- [ranidspace/BlenderBfresImporter](https://github.com/ranidspace/BlenderBfresImporter),
  commit `9fb84c24537a8a610b30be9c67bec7470638b71c`, GPL-3.0, `.tools/kart-assets/BlenderBfresImporter`.
  The Python format parser runs headless without Blender. Our adapter fixes
  Switch external-file records to pointer u64 + size u64 (upstream read u32 size,
  misaligning a BFRES's second external record). Retail v10 shader dictionaries
  fail in that parser, so native material content is explicitly not parsed;
  a geometry-only model route preserves material bytes instead.
- [dt-12345/MeshCodec](https://github.com/dt-12345/MeshCodec), commit
  `b3600954872dbc2893a1bcc9e851c1e364f303ab`, GPL-2.0, `.tools/kart-assets/MeshCodec`.
- [UltimateBomb/totk-meshcodec](https://github.com/UltimateBomb/totk-meshcodec),
  commit `032c41d18cb8399c7c01c04f0ab140689327431c`, MIT,
  `.tools/kart-assets/totk-meshcodec`. Uses NullCodec FMSH packing.

The C++ decoder builds on ARM64 macOS after applying
`scripts/kart_assets_meshcodec_arm64.patch`: restrict x86 intrinsic include to
x86; use 64-bit ARM FPCR registers; fix size_t/u64 template mismatch. Its upstream
NullCodec is explicitly marked untested and used `std::max(remaining,0x40000)`,
which overreads/overwrites when the stream is smaller than 256 KiB. The included
patch uses `std::min`; the initial unpatched candidate decode crashed, while
retail decoding (which uses the other codec) succeeded. The local min-size fix
permits exact full-buffer roundtrip but is an explicit verification limitation.
Build also needs `-include cstddef -include algorithm -include cstring` because
some upstream translation units miss standard includes.

```sh
python3 -m pip install --no-deps --target .tools/kart-assets/python \
  .tools/kart-assets/BlenderBfresImporter/io_scene_bfres/wheels/texture2ddecoder-1.0.6-cp311-abi3-macosx_11_0_arm64.whl
python3 -m pip install --target .tools/kart-assets/python zstandard
python3 scripts/kart_assets_export.py
python3 scripts/kart_assets_verify.py

# Native tools (source trees already present; apply the patch only once).
cmake -S .tools/kart-assets/MeshCodec -B .tools/kart-assets/MeshCodec/build \
  -DCMAKE_BUILD_TYPE=Release -DZSTD_BUILD_SHARED=OFF -DZSTD_BUILD_PROGRAMS=OFF \
  -DZSTD_BUILD_TESTS=OFF -DBUILD_TESTING=ON \
  -DCMAKE_CXX_FLAGS='-include cstddef -include algorithm -include cstring'
cmake --build .tools/kart-assets/MeshCodec/build --target mc_test -j 4
.tools/kart-assets/MeshCodec/build/tests/mc_test \
  assets/totk-cart-reference/compressed assets/totk-cart-reference/decoded
python3 scripts/kart_assets_native_cart.py
python3 scripts/kart_assets_native_verify.py
```

Python dependencies NumPy, Pillow and Matplotlib were already available. The
local `texture2ddecoder` wheel is loaded by the BNTX module but these selected
assets use the pure Python BC decoders. Every source hash and output package
hash is retained in the manifests. No handling behavior was inferred from these
model filenames, bones or buffers.

## Separate wheel refinement candidate

`assets/native-cart-mod-refined` leaves the original pinned geometry untouched.
Close LOD now fits actual tire LOD1 with the body LOD0: 1,973 vertices and 2,121
triangles against native capacities 2,652 / 2,242. Far LOD uses eight-sided capped
cylinders with body LOD2: 554 vertices / 525 triangles against capacities
1,022 / 538. The decoded allocation remains 139,264 bytes; complete independent
decoder roundtrip and parsed geometry checks passed. Model package SHA-256:
`b6da28bf4a70d0ec70f7552fa621c9b9f51e849a4454582c20ba38e10c9c38a2`.
Scripts accept `--refined` to write/check this separate directory.

## Separate actual-color candidate

`assets/native-cart-color-mod` is built from the original working geometry
SHA-256 `47d6a655ca5f473433f288c9541ab9d472b23c1a71f3a102efd3f500367c5648`.
It writes the modified model plus three native Cart `TexToGo` resources, without
installing files or changing runtime/controller scripts. Source geometry byte
comparison proves that only the 16-bit UV0 fields changed: positions, normals,
tangents, rigid matrix IDs, indices, metadata, materials and skeleton stay exact.

Actual MK8DX `BodyK_Std_Mro_Alb` and `Tire_Std_Alb` images are downsampled into one
256×256 atlas. Source UV wrapping is retained by physically tiling the body 2×2
(128×95 per tile) and tire 4×1 (64×54 per tile), followed by an affine UV remap.
Wrapped edge rows separate body/tire regions. Atlas minification can still mix
regions at very small mip levels and needs runtime appearance checks.

The TXTg format was read against the primary
[Switch Toolbox TXTG implementation](https://github.com/KillzXGaming/Switch-Toolbox/blob/master/File_Format_Library/FileFormats/Texture/TXTG.cs)
and its
[Tegra layout implementation](https://github.com/KillzXGaming/Switch-Toolbox/blob/master/Switch_Toolbox_Library/Texture%20Decoding/Switch/TegraX1Swizzle.cs).
Each surface index records array u16, mip u8 and marker1; its size entry is zstd
frame size u32 and codec6 u32. Cart resources are version0x11, header0x50.
**Zstd output is Tegra block-linear**, not linear BC1 order: a direct BC1 raster
decode produced scrambled rows, while deswizzling produces the complete Cart
atlas. All original mip surfaces roundtrip exactly through our layout mapping.
The new atlas uses Pillow's native BC1 encoder, the same Tegra block address map
and per-mip zstd frames. Original header bytes/path hash, dimensions, mip count,
format IDs, and every decompressed surface length are unchanged. There is no
RESTBL allocation increase.

- Albedo:256², nine mips, original format0x302. Actual MK8DX red/blue/yellow colors.
- Normal:128², eight mips, original format0x302. A neutral approximatelyRGB128
  map follows the observed flat regions of the native BC1 normal texture.
- Material mask:256², nine mips, original format0x606 BC4. Zero mask removes
  native Cart panel patterns. Shader interpretation still requires runtime test.

`validation.json` records all original/candidate texture hashes and byte sizes,
complete model decoder equality, exact UV-only differences, and atlas BC1 RMSE
11.46 on the0..255 scale. `encoded-atlas-check.png` and `color-preview.png` were
viewed: they show actual Mario red/blue body colors, yellow exhaust tips and
standard tire atlas colors. The latter reconstructs produced model+texture bytes
with approximate offline shading; it does not show game rendering.

Candidate model package SHA-256:
`02d29abc1dc451f2c01e94d8e094bc370a0a1f533fb9a82d2a01c9e89458ef14`.
Build/check: `python3 scripts/kart_assets_colors.py`, then
`python3 scripts/kart_assets_colors_verify.py`.

The native main shader has42 parameter descriptors, including one `TEX_SRT`
at source-parameter offset272 with scale100×100. Its hashed name and sampler
binding have not been resolved; it was retained rather than changed based on a
name guess. Native shader color-space handling, normal/mask response, filtering
and LOD appearance remain to be observed. No in-game success is claimed by these
host checks.

### Material name recovery and runtime color observation

The hashed parameter name is now resolved with format-aware evidence. The source
`Shader/ExternalBinaryString.bfres.mc` contains557 unsigned64 ID→name entries;
`scripts/kart_assets_materials.py` reads its actual resource dictionary and value
array. This resolves parameterID `0x75d8768c4e332776` to **`p_tex_srt3`**, descriptor
`0x3a98`, source-data offset272, absolute decoded BFRES offset`0x1c88`, mode0,
scale(100,100), rotation0, translation(0,0). The initial parser failures came from
signed ID loading, cached Node values instead of string keys, and a cached-array
lookup indexing an empty list; the evidence script fixes those issues locally.
The complete four materials now parse; `research/kart-materials.json` records
sampler assignments,42 main parameters and stored shader options.

Main material `_a0` maps to `_a0`, normal `_n0` to `_n0`, specular `_s0` to `_mt0`.
Main material's toon-spec SRT choice is stored as default, while the hidden
`Mt_SpObj_ZonauLight_A` explicitly selects3. It is an inference that the100×100
transform is auxiliary rather than the base-albedo transform; exact shader
sampling was not traced. No1×1 SRT variant was installed or needed.

On **October15,2026 (America/Vancouver)**, the parent agent installed this exact
color candidate modelSHA `02d29abc1dc451f2c01e94d8e094bc370a0a1f533fb9a82d2a01c9e89458ef14`
and its texture resources, then observed it in **Ryujinx1.3.3 / TOTK1.1.0**:
red/white/blue body, dark tires and yellow exhaust details rendered at30FPS. The
user subsequently confirmed the Mario Kart colors. This is runtime visual
loading/color evidence for that run, separate from host format checks. Receipt:
`research/color-control-v2-install.json`; log:
`.work/ryujinx-color-control-v2-test.log`. `validation.json.runtime_observation`
records that evidence and preserves it on identical candidate rebuilds.

This observation does not establish revised controller behavior, seated riding,
all mip/LOD/filtering conditions or Switch hardware compatibility.

## Suspension omission and connected assembly candidate

The user's October15 screenshot showed a disconnected rear wheel and gaps
between the wheel and chassis. Inspection found a concrete missing source
resource: `Kart/Arm/ArmK_Std.szs`. BFRES parsing gives two models, normal driving
`ArmK_StdN` and antigravity `ArmK_StdG`, each with four separate rigid meshes.
The normal shafts have96 /25 /12 triangles per LOD, with137 /61 /34 vertices.
All LODs preserve the measured local endpoint X=1.3564453125.

The selected BODY row in `Common/Mush/Parts.bin` is a320-byte record at26012.
The named `TireShaftTransform` front anchor is at record+0xa0:
(2.1,-0.1,5.6); rear anchor is at+0xc4:(2.18,0.34,-3.2). This field layout is
established by the primary source of
[MK8 Parts Bin Converter](https://github.com/KillzXGaming/MK8-Parts-Bin-Converter),
commit`446d4a2b5c1bd569b872c04f2db73a19c509b83e`, particularly
[BodyObject](https://github.com/KillzXGaming/MK8-Parts-Bin-Converter/blob/master/PartsLibrary/PartObjects/BodyObject/BodyObject.cs)
and
[TireShaftTransform](https://github.com/KillzXGaming/MK8-Parts-Bin-Converter/blob/master/PartsLibrary/PartObjects/BodyObject/TireShaftTransform.cs).
The full Part/Tire/Body placement equations remain unrecovered; those named
fields alone do not establish the complete source game's assembled wheel centers.

`assets/native-cart-assembly-mod` is a **separate**, color-preserving candidate.
`scripts/kart_assets_assembly.py` uses actual ArmK_StdN meshes, transforms their
source-derived chassis anchors at the existing body scale0.16, then stretches
and rotates the shafts to the retained native Cart axle centers. This is an
explicit geometry adaptation. It preserves native wheel bone translations and
wheel/actor collision; it does not move visual wheel centers away from the
native physics wheels. Rear arms become approximately0.923m long and front arms
0.747m under that adaptation. Measured transform endpoints equal native axle
centers, and selected close/far arm meshes preserve the measured shaft tip.

Close geometry is the full bodyLOD0(1,737 triangles), four tireLOD1 meshes(384),
and four armLOD1 meshes(100): **2,221 triangles /2,217 vertices**, below native
capacity2,242 /2,652. Far geometry contains bodyLOD2(397), four authored capped
five-sided wheels(80), four actual armLOD2 meshes(48): **525 triangles /666
vertices**, below capacity538 /1,022. Every original bodyLOD0 triangle is retained;
no body panel was deleted to fit the shafts. The steering wheel is already
included in that body mesh. Mario's separate emblem texture overlay remains
unbaked; glider, antigravity and character assets are outside this ground assembly.

The actual source `ArmK_StdN_Alb` texture is red/dark gray,96². It is extracted
and preserved with the source BFRES/BNTX, then reduced to64×2 per tile in an
otherwise unused4×2 tiled atlas shelf. Those red shafts in the offline candidate
preview are actual source colors, not a gray placeholder. Detail is substantially
reduced. Entire model and every texture mip retain original allocation sizes;
independent full decoder equality, exact texture layout checks, source geometry
index/metadata checks and offline preview inspection passed.

`assets/native-cart-assembly-mod/color-preview.png` was viewed: visible shafts
bridge the earlier chassis/wheel gaps, and all four close wheels use the rounder
source LOD1. It is a reconstruction from the produced model and decoded TXTg
with approximate shading, not an in-game screenshot. Model SHA-256:
`a1f4a791a18aafa9ff8603640434299dc75490a2b4b162ccf7418fd2c8ecbe68`.

Arms are rigid on Skl_Root matrix0; tires remain on native wheel matrices1..4.
Static axle alignment is established. Independent suspension translation may
open gaps during motion; binding a whole shaft to a spinning wheel matrix would
spin it, so this needs a proper animated constraint for robust suspension.
The current package does not supply that constraint. Native controller, sitting,
physics, installed resources and current emulator state were not changed by the
asset builder. Static and motion/suspension runtime tests remain necessary.

## Source wheel placement investigation, October 15

The connected assembly above remains frozen at `a1f4...`; its native Cart
wheelbase is an adaptation, not the MK8DX assembly. The next investigation
found actual code that combines the source part tables. No new native-wheel
rebinding candidate has been approved by host evidence or installed.

`scripts/kart_assets_parts_placement.py` reads the actual Parts records and
writes `research/kart-source-placement.json`. It checks the source ELF's
strategy tables as well as the Parts data. Native ARM32 module function
`0x2daf08` selects BODY/TIRE/BDTR/TRBD rows, then combines them at
`0x2db594..0x2dbcb4`. The verified carrier is
`.work/native/mk8dx-main.elf`, SHA-256
`b45ced902a5ee66fb6ac08077f8aac0d807bae4223518442563f7f341a62a1e2`.

Concrete observations:

- BDTR offset 8 is a **flags field**. Native `tst` instructions select between
  BODY defaults and BDTR overrides. The converter's `TireAngle` label is
  misleading here; `0xefff` must not be converted to a rotation.
- Front tire source scale is `(1,1,1)`. The native combiner multiplies the rear
  scale by TRBD's first two floats, giving **`(1.4,1.3,1.3)`**. The prototype's
  equal scale for all four tires does not reproduce that source relationship.
- Front/rear shaft scales select BODY `(1.1,1,1)` and `(1.3,1.2,1.2)`.
  Their named source chassis anchors are `(2.1,-0.1,5.6)` and
  `(2.18,0.34,-3.2)`.
- BODY's final normal tire triplets `(2.65,2.3,5.6)` and `(2.6,2.55,-3.2)`
  initialize **suspension endpoints**. Per-wheel initialization at `0x15a6dc`
  and settling at `0x15d2f0` show that these are not literal final mesh centers.
  The latter runs 100 spring iterations using the native gravity getter
  `0x173e54`, whose constant is `0.15`.
- The normal axial direction comes from derived strategy `a5c/a60`, **not**
  TIRE's arm flag bytes. For body vehicle type 0, native strategy tables at
  `0xc2e72c` / `0xc2e73c` select strategy 2. Getters `0x14ac04` /
  `0x14ac98` return +/-X for that branch. Strategy 1 reads a global zero vector
  at `0xc5ceac`; confusing these branches produced a rejected hypothesis.
- Tire model update `0x160bb4` combines the physical position, normal/axial
  direction, source scale, and interpolated offset. TIRE `OffsetX=0.9` is not
  established as a direct `+0.9` addition to the BODY triplet.

`scripts/kart_assets_arm_evidence.py` records eight **narrow** byte-addressed
ARM disassembly scopes in `research/placement/verified-scopes/`, with hashes
and a manifest. This local Capstone fallback does not change the parent's
shared REA session. It is raw linear decoding: literal-pool words in these
files are data, even where Capstone prints instruction mnemonics. Branch and
load sequences described above were followed explicitly; they are not claims
of provider-decompiled C++ types.

`assets/source-placement-study` is a **rejected offline experiment**, not an
installable mod. It contains the full source body and four tires in editable
glTF plus a labeled PNG. Direct BODY endpoints with one nominal settled spring
state visibly tuck tires inside the body. The omitted strategy/frame transform
and unverified constructor branch make these centers invalid as a replacement
for the native wheel bones. This negative result is retained to prevent
accidentally packaging that shortcut.

Remaining concrete step: corroborate the selected `0x149514` suspension-config
constructor inputs for this exact body/tire/driver combination, then follow
`0x160bb4`'s final model-frame transform. Only after that should an offline
native-bone/collision proposal be produced. Moving vertices alone would leave
the native physical wheel centers elsewhere; moving bones may affect physics
and needs a distinct runtime test. The already working color candidate and
frozen assembly were not changed during this investigation.
