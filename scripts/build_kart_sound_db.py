#!/usr/bin/env python3
"""Kart sound v2: MK8DX engine / drift / surface sounds on new SLink keys appended to the kart's SLink user.

v1 (build_kart_sound_bank.py) could only reuse the 6 one-asset keys of user SpObj_ControlStick_A_01. v2 appends an
extended copy of that user block to the end of the SLink DB and points the user's offset-table entry at it:

  * user block (0x62c bytes at 0x3166fc): header 0x38 (isSetup, numLocalProperty, numCallTable, numAsset, ...,
    triggerTablePos u64 @0x30 = user-relative end), local property name refs (u64 each), 10 user params (u32),
    name-sorted u16 index over all call entries, call table (0x30 each), containers (offsets relative to the container
    table start, so unchanged), end = triggerTablePos.
  * call entry: keyNamePos u32, 0, assetIndex u16, flag u16, 1, parent s32, guid u32, CRC32(key), 0, paramPos u64,
    condPos u64. Asset param at paramPos + 0x5610: u64 mask over the 40 asset params, then one packed u32 per set bit
    (type << 24 | value; 0 direct-value index, 1 pool string, 2 curve index, 3 random index, 5 bitflag).
  * new strings are appended after the name pool (the pool is the last section), new params after the new user.
  * a 6th local property "Cart_RotateSpeed" lets the new keys use the Zonai cart's own pitch curve 512
    ((0, 0.6) .. (40, 1.0)); the controller sets it from the kart speed.
  * vanilla parent keys TiltedStick / ReturnNeutralPosition stay disabled (renamed, as in v1); the old 6 bank assets
    go back to their vanilla audio.

Output: assets/kart-sound-v2/romfs (bank, DB, RSTB on the installed glider RSTB) + preview WAVs. Nothing is installed.
"""
import hashlib, json, struct, sys, zlib
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/kart-assets/python')); sys.path.insert(0, str(ROOT / 'scripts'))
import zstandard as zstd
import mk8_audio as m
from build_kart_sound_bank import zsdic, amta_with_stats, RET, BANK, DB, TABLE, TABLE_SRC, CALLS, NT, RENAME

OUT = ROOT / 'assets/kart-sound-v2'
USER_IDX_NAME = b'SpObj_ControlStick_A_01'
NUSERS = 1660
PARAM_BASE = 0x5610
PREFIX = 'SpObj_ControlStick_'
CURVE_PITCH = 0x020000d5      # curve 213: ControlStick_StickSpeedXY (0, 0.65) .. (1, 1.0) (the kart actor has it)
RAND_PITCH = 0x03000006       # random 6: 0.95 .. 1.0 (what the vanilla stick sounds use)
VOL_1 = 0x00000004            # direct value 4 = 1.0
GROUP_ACTOR = 0x0100204b; BONE_HANDLE = 0x0104077a; BITFLAG = 0x05000009
ST = 'Audio/Static/StaticKart.bars'; BODY = 'Audio/Body/Body_K_Std.bars'
G = lambda s: f'Audio/Ground/Ground_{s}.bars'
ENGINE_PITCH = 1.5            # [chosen] curve gives 0.65..1.0 -> engine plays 0.98..1.5 of the original pitch
# key -> (MK8 bank, MK8 asset, peak, pitch value, pre-pitch)
SOUNDS = {
    'Kart_Engine':       (BODY, 'pSE_EG_LOOP_K_STD', 0.12, CURVE_PITCH, ENGINE_PITCH),
    'Kart_EngineDash':   (BODY, 'pSE_EG_DASH_K_STD', 0.14, CURVE_PITCH, ENGINE_PITCH),
    'Kart_Idle':         (BODY, 'pSE_EG_IDLE_K_STD', 0.10, VOL_1, 1.0),
    'Kart_Horn':         (BODY, 'pSE_HORN_K_STD', 0.3, VOL_1, 1.0),
    'Kart_MiniTurbo':    (ST, 'SE_KT_DASH_MINI', 0.35, RAND_PITCH, 1.0),
    'Kart_UltraTurbo':   (ST, 'SE_KT_DASH_MINI_ULTRA', 0.35, RAND_PITCH, 1.0),
    'Kart_Sizzle1':      (ST, 'SE_KT_DRIFT_HIBANA_BLUE', 0.25, VOL_1, 1.0),
    'Kart_Sizzle2':      (ST, 'SE_KT_DRIFT_HIBANA_RED', 0.25, VOL_1, 1.0),
    'Kart_Sizzle3':      (ST, 'SE_KT_DRIFT_HIBANA_PURPLE', 0.25, VOL_1, 1.0),
    'Kart_DriftSteer':   (ST, 'SE_EG_DRIFT_STEER', 0.18, VOL_1, 1.0),
    'Kart_Hop':          (ST, 'SE_KT_MINI_JUMP', 0.3, RAND_PITCH, 1.0),
    'Kart_Land':         (ST, 'SE_KT_LAND_SKID_1', 0.3, RAND_PITCH, 1.0),
    'Kart_Trick':        (ST, 'SE_KT_JUMP_ACTION', 0.35, RAND_PITCH, 1.0),
    'Kart_GliderOpen':   (ST, 'SE_KT_GLIDER_OPEN', 0.35, RAND_PITCH, 1.0),
    'Kart_GliderClose':  (ST, 'SE_KT_GLIDER_CLOSE', 0.3, RAND_PITCH, 1.0),
    'Kart_GliderFlutter': (ST, 'SE_KT_GLIDER_FLUTTER_LOW', 0.2, VOL_1, 1.0),
}
SURFACES = ['Grass', 'Dirt', 'Sand', 'Snow', 'Water', 'Stone', 'Wood']
for s_ in SURFACES:
    up = s_.upper()
    SOUNDS[f'Kart_Run_{s_}'] = (G(s_), f'pSE_GND_RUN_{up}', 0.2, CURVE_PITCH, 1.0)
    SOUNDS[f'Kart_Slip_{s_}'] = (G(s_), f'pSE_GND_SLIP_{up}', 0.2, VOL_1, 1.0)
    SOUNDS[f'Kart_Land_{s_}'] = (G(s_), f'pSE_GND_LAND_{up}', 0.3, RAND_PITCH, 1.0)


def main():
    OUT.mkdir(parents=True, exist_ok=True); (OUT / 'preview').mkdir(exist_ok=True)
    for f in (OUT / 'preview').glob('*.wav'): f.unlink()
    report = {'keys': {}}
    dic = zsdic()
    db = bytearray(zstd.ZstdDecompressor(dict_data=dic).decompress((RET / DB).read_bytes(), max_output_size=16 << 20))
    assert struct.unpack_from('<I', db, 4)[0] == len(db)
    # ---- locate the user ----
    hashes = struct.unpack_from(f'<{NUSERS}I', db, 0x60)
    ui = hashes.index(zlib.crc32(USER_IDX_NAME)); off_at = 0x60 + 4 * NUSERS + 8 * ui
    u = struct.unpack_from('<Q', db, off_at)[0]
    nprop, ncall, nasset = struct.unpack_from('<3I', db, u + 4)
    end = struct.unpack_from('<Q', db, u + 0x30)[0]
    assert (nprop, ncall, nasset, end) == (5, 26, 19, 0x62c) and u + 0x38 + 8 * nprop + 0x28 + 2 * ncall == CALLS
    old = bytes(db[u:u + end])
    # The vanilla parent keys TiltedStick / ReturnNeutralPosition stay as they are: the game's stick nodes
    # (e.g. ExecuteControlStickPlayTiltedSound -> 0x1351158 -> 0x815154 -> 0xb28048) look them up once and keep the
    # call-entry pointer, so renaming them (v1) left a null entry and crashed (null + 0x8C06C) when the stick tilted.
    # Their six bank assets are made silent below instead.
    # ---- strings ----
    rot = db.find(b'\0Cart_RotateSpeed\0', NT) + 1 - NT
    assert rot > 0
    keys = sorted(SOUNDS)
    if (ncall + len(keys)) % 2: keys.append('Kart_Spare')          # keep the index even-sized (4-byte alignment)
    # ---- new user block ----
    nprop2, ncall2, nasset2 = nprop, ncall + len(keys), nasset + len(keys)   # (a 6th property did not resolve: names bind to the actor's own property list)
    hdr = bytearray(old[:0x38]); struct.pack_into('<3I', hdr, 4, nprop2, ncall2, nasset2)
    props = old[0x38:0x38 + 8 * nprop]
    uparams = old[0x38 + 8 * nprop:0x38 + 8 * nprop + 0x28]
    calls_old = old[CALLS - u:CALLS - u + 0x30 * ncall]
    containers = old[CALLS - u + 0x30 * ncall:]
    head_len = 0x38 + 8 * nprop2 + 0x28 + 2 * ncall2
    # place the user so its call table is 8-byte aligned in the file (as the original is)
    start = (len(db) + 7) & ~7
    while (start + head_len) % 8: start += 4
    user_len = head_len + 0x30 * ncall2 + len(containers)
    struct.pack_into('<Q', hdr, 0x30, user_len)
    params_at = (start + user_len + 7) & ~7
    strings = bytearray()
    base = params_at + 40 * len(keys) - NT                    # strings go right after the new params

    def add_str(s):
        p = base + len(strings); strings.extend(s.encode() + b'\0'); return p
    key_pos = {k: add_str(k) for k in keys}
    run_pos = {k: add_str(PREFIX + k) for k in keys}
    params = bytearray(); new_calls = bytearray(); pp_of = {}
    for k_i, k in enumerate(keys):
        bank_, name, peak, pitch, pre = SOUNDS.get(k, (ST, 'SE_KT_MINI_JUMP', 0.3, RAND_PITCH, 1.0))
        at = params_at + len(params)
        vals = [0x01000000 | key_pos[k], 0x01000000 | run_pos[k], GROUP_ACTOR, VOL_1, pitch, BONE_HANDLE, BITFLAG]
        params += struct.pack('<Q', 0x5001f) + struct.pack('<7I', *vals) + b'\0' * 4    # keep 8-byte alignment
        pp = at - PARAM_BASE; pp_of[k] = pp
        new_calls += struct.pack('<IIHHIiIIIQQ', key_pos[k], 0, nasset + k_i, 0, 1, -1,
                                 zlib.crc32(('kartsnd/' + k).encode()), zlib.crc32(k.encode()), 0, pp, 0xffffffff)
    calls = calls_old + bytes(new_calls)

    def key_of(i):
        p = struct.unpack_from('<I', calls, 0x30 * i)[0]
        if p >= base: return bytes(strings[p - base:]).split(b'\0')[0]
        return bytes(db[NT + p:]).split(b'\0')[0]
    order = sorted(range(ncall2), key=key_of)
    index = struct.pack(f'<{ncall2}H', *order)
    user = bytes(hdr) + props + uparams + index + calls + containers
    assert len(user) == user_len
    # ---- assemble ----
    out = bytearray(db)
    out += b'\0' * (start - len(out)); out += user
    out += b'\0' * (params_at - len(out)); out += params
    assert len(out) - NT == base, 'string base moved'
    out += strings
    out += b'\0' * ((-len(out)) % 8)
    struct.pack_into('<Q', out, off_at, start)
    struct.pack_into('<I', out, 4, len(out))
    report['user'] = dict(old_at=hex(u), new_at=hex(start), calls=ncall2, assets=nasset2, props=nprop2,
                          size=hex(user_len), db_size=len(out))
    # sanity: re-read new call entries
    cstart = start + head_len
    for i in range(ncall2):
        kp, _, ai, fl = struct.unpack_from('<IIHH', out, cstart + 0x30 * i)
        name = bytes(out[NT + kp:]).split(b'\0')[0]
        assert name == key_of(i)
        if i >= ncall:
            ppv = struct.unpack_from('<Q', out, cstart + 0x30 * i + 0x20)[0]
            mask, a0, a1 = struct.unpack_from('<QII', out, ppv + PARAM_BASE)
            assert mask == 0x5001f and bytes(out[NT + (a0 & 0xffffff):]).split(b'\0')[0] == name
    names = [key_of(i) for i in order]; assert names == sorted(names)
    # ---- bank: vanilla 6 + new assets ----
    bank = m.read_totk_bars(zstd.ZstdDecompressor().decompress((RET / BANK).read_bytes()))
    tmpl = bank[0]['amta']
    silent, _, sdec = m.totk_sfx(np.zeros(2400), 48000, peak=0.0)   # 50 ms of silence
    for a in bank:   # vanilla stick creaks (TiltedStick / ReturnNeutralPosition children): silent
        a['bwav'] = m.make_bwav(silent); a['amta'] = amta_with_stats(a['amta'], sdec)
    mk8 = {}
    for k in keys:
        bank_, name, peak, pitch, pre = SOUNDS.get(k, (ST, 'SE_KT_MINI_JUMP', 0.3, RAND_PITCH, 1.0))
        if bank_ not in mk8: mk8[bank_] = {x['name']: x for x in m.read_mk8_bars(ROOT / 'extracted/mk8dx/romfs' / bank_)}
        s = mk8[bank_][name]
        asset, pcm, dec = m.totk_sfx(s['channels'][0]['pcm'], s['rate'], peak=peak,
                                     loop_from=s['loop_start'] if s['loop'] else None, pitch=pre)
        bw = m.make_bwav(asset)
        assert np.array_equal(m.read_bwav(bw)[0]['pcm'], dec)
        bank.append(dict(name=PREFIX + k, amta=amta_with_stats(m.make_amta(tmpl, PREFIX + k), dec), bwav=bw))
        m.write_wav(OUT / 'preview' / f'{k}.wav', [dict(pcm=np.tile(dec, 3) if s['loop'] else dec)], 48000)
        report['keys'][k] = dict(mk8=name, loop=bool(s['loop']), seconds=round(len(dec) / 48000, 2), peak=peak,
                                 pitch={CURVE_PITCH: 'speed curve 512', RAND_PITCH: 'random 0.95-1', VOL_1: '1.0'}[pitch],
                                 prepitch=pre)
    bars = m.write_totk_bars(bank)
    assert len(m.read_totk_bars(bars)) == 6 + len(keys)
    report['bank_bytes'] = len(bars)
    # ---- RSTB ----
    raw = bytearray(zstd.ZstdDecompressor().decompress(TABLE_SRC.read_bytes(), max_output_size=64 << 20))
    count = struct.unpack_from('<I', raw, 14)[0]
    for rel, size, extra in ((BANK, len(bars), 576), (DB, len(out), 280)):
        key = zlib.crc32(rel.removesuffix('.zs').encode())
        hit = [22 + 8 * i + 4 for i in range(count) if struct.unpack_from('<I', raw, 22 + 8 * i)[0] == key]
        assert len(hit) == 1, rel
        before = struct.unpack_from('<I', raw, hit[0])[0]
        struct.pack_into('<I', raw, hit[0], max(before, ((size + 31) & ~31) + extra))
        report['rstb_' + rel.split('/')[-1]] = [before, struct.unpack_from('<I', raw, hit[0])[0]]
    rom = OUT / 'romfs'
    for rel, data in [(BANK, zstd.ZstdCompressor(level=19).compress(bars)),
                      (DB, zstd.ZstdCompressor(level=19, dict_data=dic).compress(bytes(out))),
                      (TABLE, zstd.ZstdCompressor(level=19).compress(bytes(raw)))]:
        (rom / rel).parent.mkdir(parents=True, exist_ok=True); (rom / rel).write_bytes(data)
    report['outputs'] = {p.relative_to(OUT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                         for p in rom.rglob('*') if p.is_file()}
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=1))


if __name__ == '__main__':
    main()
