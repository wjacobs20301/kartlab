# Kart sound — October 17, 2026 (v2 installed and tested in game; listening test by the user pending)

## TOTK side
* Sounds play through SLink (xlink2) keys per actor. AI node OneShotXLinkSearchAndEmit (exec 0x1f5e540):
  `xl = 0x10f0d34(actor)` = `*(actor+0x228)+0x68`; ELink user instance `*(xl+0x70)` → `0xd1b3a4(user, key, &handle)`;
  SLink user instance `*(xl+0x78)` (xl = `*(*(actor+0x228)+0x68)`, a deref) → `0xb2d620(user, key, &handle)` = tail call `0x809ee0(user, key, &handle, 0)` (search-and-play).
* SLink DB `SLink2/slink2.Product.110.bslnk.zs`: XLNK v0x21, 1660 users, hashes u32[] at 0x60 (sorted CRC32 of user name),
  offsets u64[] after them, name table at header+0x58 (0x7893b0).
  - SpObj_ControlStick_A_01 (the kart host; every ControlStick is the kart in this mod) @0x3166fc: local property
    ControlStick_StickSpeedXY; keys incl. TiltedStick, ReturnNeutralPosition, HoldOff/_01/_02, Land:*, DigOut, ...
    Bank Sound/Resource/SpObj_ControlStick_A_01.bars.zs: 6 assets (Steering_03/04/05, ReturnNeutralPosition_03/04/05),
    BWAV v1, DSP-ADPCM mono 48 kHz.
  - SpObj_Cart_A_02 @0x76761c: property Cart_RotateSpeed; keys WheelRoll, Roll:Obj/Mt, Drag:Obj/Mt, SurfFast (loops).
* Key → asset mapping is in the per-user call tables (48-byte entries); not decoded yet.
* BARS loader around 0xebd6c4 (magic 0x53524142). Asset lookup by name/CRC not found yet (CRC32 instructions: 7.7k uses).
* Foot IK setter (used for the seated pose): 0x1085b5c(physics, enable).

## MK8DX side
* Audio/Body/Body_K_Std.bars (BARS v1.1, 9 assets): pSE_EG_LOOP_K_STD (engine loop), pSE_EG_IDLE_K_STD, pSE_EG_FUKASHI_K_STD
  (rev), pSE_EG_UP_K_STD, pSE_EG_WSPIN_K_STD, pSE_EG_DASH_K_STD (boost), pSE_EG_DASHMINI_K_STD (mini-turbo),
  pSE_EG_DASHDOWN_K_STD, pSE_HORN_K_STD. Audio is BFWAV (FWAV, DSP-ADPCM, 32 kHz) inside the BARS.
* Audio/Ground/Ground_*.bars per surface (Grass, Dirt, Sand, Snow, Water, Asphalt, Stone, ...).

## Plan
1. Converter: FWAV DSP-ADPCM → BWAV (re-wrap frames + coefs, no re-encode); TOTK BARS v1.2 writer with AMTA from a TOTK
   template. Verify offline by decoding back to WAV.
2. Playback: either decode the SLink call tables (key → asset) and swap MK8 audio into the kart bank under existing asset
   names, or find Alto's play-by-asset-name below 0x809ee0.
3. Verification: audio cannot be captured here without changing the Mac's audio device; check handles/state in game and
   leave the listening test to the user.


## Built (Oct 17, ~02:30) — staged in `assets/kart-sound`, not installed

**Key → asset mapping (solved).** Call-table entries are 0x30 bytes at user+0xbc (SpObj_ControlStick_A_01: 0x3167b8):
keyNamePos u32 (pool 0x7893b0), 0, assetIndex u16 (0xffff = container) + flag u16, 1, parent s32, guid u32, CRC32(key) u32,
0, paramPos u64, condPos u64. Asset param = paramPos + 0x561c; its values are packed (type << 24 | value), type 1 = pool
string, so the asset name is the first type-1 value. The user's 26-entry u16 index (user+0x88) is sorted by key name and
includes child entries, so children are directly searchable:

| Key | Asset (own bank) | Now |
| --- | --- | --- |
| TiltedStick_00 | Steering_03 | SE_KT_DASH_MINI (mini/super mini-turbo, trick-landing boost) |
| TiltedStick_01 | Steering_05 | SE_KT_DASH_MINI_ULTRA |
| TiltedStick_02 | Steering_04 | SE_KT_DRIFT_HIBANA_BLUE (MK8 spark sizzle, a loop; restarted on each tier) |
| ReturnNeutralPosition_00 | ReturnNeutralPosition_03 | SE_KT_GLIDER_OPEN |
| ReturnNeutralPosition_01 | ReturnNeutralPosition_04 | SE_KT_JUMP_ACTION (trick) |
| ReturnNeutralPosition_02 | ReturnNeutralPosition_05 | pSE_EG_LOOP_K_STD (engine, loop body only) |

Other keys (HoldOff_*, Land:*, DigOut, Death_Vanishing, Life_Alerted) use shared banks (ZonauGear etc.) and shared,
deduplicated asset params, so they are left alone.

**Vanilla stick sounds disabled:** parents TiltedStick (entry 7) / ReturnNeutralPosition (entry 6) are random containers
that vanilla fires on stick movement. Their name refs are pointed at existing pool strings `Skl_Root` / `Lip_D_Root`
(chosen to keep the sorted index sorted, and never used as keys), CRC32 field updated. DB size unchanged.

**Formats:** `scripts/mk8_audio.py` now has `read_totk_bars` / `write_totk_bars` (byte-identical rebuild of the retail
bank), `make_bwav` (byte-identical rebuild of all 6 retail BWAVs), a DSP-ADPCM encoder (k-means predictors, brute-force
per frame, 28–40 dB SNR) and `totk_sfx` (48 kHz, mono, peak 0.35 / engine 0.25; loops keep only the loop body, resampled
circularly, start history = the body's last two samples so every wrap is exact). AMTA: retail header with peak/rms/
loudness floats (+0x38..+0x44) recomputed. RSTB: retail banks are size + 576.

**Playback (controller `sndPlay` / `sndFade` / `soundFrame`):** `0x809ee0(user, key, Handle*, 0)`; fade `0xb226a4(Handle*,
-1)` (from OneShotXLinkFadeByKey exec 0x1f5df20; 0 = kill; 0x1d25b98(user, Handle*, key) finds a live event by key).
Handle = {s8 pool, s16 index, u32 id}, empty {-1,-1,0}. Engine starts on mount, fades on exit; sizzle while sparks show.

Build: `python3 scripts/build_kart_sound_bank.py` → `assets/kart-sound/romfs` (bank, SLink DB, RSTB on top of the glider
RSTB) + `preview/*.wav` (decoded results; the engine also as x3 through the wrap).

**Not done:** in-game test (screen locked all night); engine pitch does not follow speed (one constant loop); no idle,
landing, horn or surface sounds (no free slots — more would need new asset names in the pool or DB growth).


## v2 (Oct 17, midday) — INSTALLED, tested in game (no crash; every key returns a live handle)

`scripts/build_kart_sound_db.py` → `assets/kart-sound-v2/romfs`. The kart's SLink user block is copied to the end of the
DB with 36 new call entries ("Kart_*", 62 total, 55 assets), new asset params after it and new strings after those
(the name pool is the last section, so string refs stay pool-relative); the user offset table entry and the DB size
field (+4) point at the new layout. Asset param base = paramPos + 0x5610 (mask u64 then values). Param names come from
the define table at 0x4e48 (59 x 0x18: name u64, type u32, default u64; strings at 0x53d0). Value types: 0 direct
(table 0x925e0), 1 string, 2 curve (0x938c0, 0x18 each: pointStart u16, numPoints u16, type, isGlobal, propName u64),
3 random (0x92f18, min/max floats), 5 bitflag. Curve points at 0x96920.

Keys: Kart_Engine / Kart_EngineDash (boost) / Kart_Idle (< 0.6 m/s), Kart_MiniTurbo, Kart_UltraTurbo, Kart_Sizzle1-3
(MK8 HIBANA blue/red/purple), Kart_DriftSteer, Kart_Hop, Kart_Land, Kart_Trick, Kart_GliderOpen/Close/Flutter, and per
surface Kart_Run_/Kart_Slip_/Kart_Land_ + Grass, Dirt, Sand, Snow, Water, Stone, Wood (MK8 Ground_* RUN/SLIP/LAND).
TOTK material → surface: grass, soil, sand, snow, water as named; mud → Dirt; other: name contains "Wood" → Wood, else Stone.
Engine peak 0.12 (was 0.25; user asked for quieter). The 6 vanilla bank assets are back to vanilla audio.

Speed: engine/run pitch = curve 213 on the kart actor's property ControlStick_StickSpeedXY ((0, 0.65)..(1, 1.0)); engine
pre-pitched x1.5 offline. Property holder X = *(*(*(actor+0x228))+0x10) (0xe195cc); names +0x118 (count +0x110; the kart
has 14, StickSpeedXY = 7), values +0x128, setter 0x11acb98(X, idx, float*). A 6th local property (Cart_RotateSpeed) did
not resolve: property names bind to the actor's own list. **The game clears the value every frame** (lock flag +0x168
does not survive), so the controller writes it every frame; whether that lands before the sound update is not
verifiable without listening.

Crash fixed on the way: a blind scan of the actor for the holder read unmapped memory (crash at mount). Use the chain.
Installed: controller `b1b8d382…`, bank/DB/RSTB from assets/kart-sound-v2 (validation.json lists hashes).
Rollback: delete romfs/Sound and romfs/SLink2 from the mod, restore RSTB from assets/kart-glider/romfs and the autorun
from .work/backups/before-sound-111133.
