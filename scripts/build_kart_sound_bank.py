#!/usr/bin/env python3
"""MK8DX kart sounds in the kart's own TOTK sound bank, played by the controller through SLink keys.

SLink user SpObj_ControlStick_A_01 (every ControlStick is the kart in this mod) has 26 call-table entries. Six of them are
plain one-asset keys into its own bank Sound/Resource/SpObj_ControlStick_A_01.bars (asset param = call paramPos + 0x561c):

    key                       bank asset                                   MK8DX sound (this build)
    TiltedStick_00            SpObj_ControlStick_Steering_03               SE_KT_DASH_MINI        (mini-turbo release)
    TiltedStick_01            SpObj_ControlStick_Steering_05               SE_KT_DASH_MINI_ULTRA  (ultra mini-turbo)
    TiltedStick_02            SpObj_ControlStick_Steering_04               SE_KT_DRIFT_HIBANA_BLUE (spark tier up)
    ReturnNeutralPosition_00  SpObj_ControlStick_ReturnNeutralPosition_03  SE_KT_GLIDER_OPEN
    ReturnNeutralPosition_01  SpObj_ControlStick_ReturnNeutralPosition_04  SE_KT_JUMP_ACTION      (trick)
    ReturnNeutralPosition_02  SpObj_ControlStick_ReturnNeutralPosition_05  pSE_EG_LOOP_K_STD      (engine, looped body)

The parent keys TiltedStick / ReturnNeutralPosition (random containers over those children) are what vanilla fires when
the stick moves, so they would play boosts while steering. They are renamed in place (entry 7 -> "Skl_Root", entry 6 ->
"Lip_D_Root": existing pool strings that keep the user's name-sorted index in order; CRC32 field updated too) so the
vanilla calls find nothing. Nothing else in the 8 MB DB changes; same size, so its RSTB entry is unchanged.

Audio: MK8 32 kHz mono -> 48 kHz, peak 0.35, DSP-ADPCM (encoder in mk8_audio.py; BWAV/BARS layout verified byte-identical
on the retail bank). AMTA = retail header with peak / rms / loudness fields recomputed.
Output: assets/kart-sound/romfs/... + preview WAVs of the decoded result. Nothing is installed by this script.
"""
import hashlib, json, struct, sys, wave, zlib
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/kart-assets/python')); sys.path.insert(0, str(ROOT / 'scripts'))
import zstandard as zstd
import mk8_audio as m
from inspect_native_rider import sarc

OUT = ROOT / 'assets/kart-sound'
RET = ROOT / 'extracted/totk/romfs'
BANK = 'Sound/Resource/SpObj_ControlStick_A_01.bars.zs'
DB = 'SLink2/slink2.Product.110.bslnk.zs'
TABLE = 'System/Resource/ResourceSizeTable.Product.110.rsizetable.zs'
TABLE_SRC = ROOT / 'assets/kart-glider/romfs' / TABLE          # installed RSTB
SLOTS = {   # bank asset suffix -> (MK8 bank, MK8 asset, key the controller plays)
    'Steering_03': ('Audio/Static/StaticKart.bars', 'SE_KT_DASH_MINI', 'TiltedStick_00'),
    'Steering_05': ('Audio/Static/StaticKart.bars', 'SE_KT_DASH_MINI_ULTRA', 'TiltedStick_01'),
    'Steering_04': ('Audio/Static/StaticKart.bars', 'SE_KT_DRIFT_HIBANA_BLUE', 'TiltedStick_02'),
    'ReturnNeutralPosition_03': ('Audio/Static/StaticKart.bars', 'SE_KT_GLIDER_OPEN', 'ReturnNeutralPosition_00'),
    'ReturnNeutralPosition_04': ('Audio/Static/StaticKart.bars', 'SE_KT_JUMP_ACTION', 'ReturnNeutralPosition_01'),
    'ReturnNeutralPosition_05': ('Audio/Body/Body_K_Std.bars', 'pSE_EG_LOOP_K_STD', 'ReturnNeutralPosition_02'),
}
USER = 0x3166fc; CALLS = 0x3167b8; NT = 0x7893b0       # SpObj_ControlStick_A_01 user, its call table, name pool
RENAME = {7: (b'TiltedStick', b'Skl_Root'), 6: (b'ReturnNeutralPosition', b'Lip_D_Root')}


def zsdic():
    pk = sarc(zstd.ZstdDecompressor().decompress((RET / 'Pack/ZsDic.pack.zs').read_bytes()))
    return zstd.ZstdCompressionDict(pk['zs.zsdic'])


def pool_name(b, pos):
    s = NT + pos; return b[s:b.index(b'\0', s)]


def amta_with_stats(amta, pcm):
    t = bytearray(amta); x = pcm.astype(np.float64) / 32768
    rms = float(np.sqrt((x * x).mean()))
    db = 20 * np.log10(max(rms, 1e-6)) - 3.0    # retail loudness fields sit ~3-5 dB under 20log10(rms)
    struct.pack_into('<4f', t, 0x38, float(np.abs(x).max()), rms * 0.9, db, db)
    return bytes(t)


def main():
    OUT.mkdir(parents=True, exist_ok=True); (OUT / 'preview').mkdir(exist_ok=True)
    report = {'slots': {}}
    # ---- bank ----
    bank = m.read_totk_bars(zstd.ZstdDecompressor().decompress((RET / BANK).read_bytes()))
    mk8 = {}
    for a in bank:
        suffix = a['name'].removeprefix('SpObj_ControlStick_')
        src, name, key = SLOTS[suffix]
        if src not in mk8: mk8[src] = {x['name']: x for x in m.read_mk8_bars(ROOT / 'extracted/mk8dx/romfs' / src)}
        s = mk8[src][name]
        asset, pcm, dec = m.totk_sfx(s['channels'][0]['pcm'], s['rate'], peak=0.25 if s['loop'] else 0.35,
                                     loop_from=s['loop_start'] if s['loop'] else None)
        a['bwav'] = m.make_bwav(asset); a['amta'] = amta_with_stats(a['amta'], dec)
        back = m.read_bwav(a['bwav'])[0]
        assert back['codec'] == 1 and back['rate'] == 48000 and np.array_equal(back['pcm'], dec)
        assert bool(back['loop']) and back['loop_end'] == (len(dec) if s['loop'] else 0xffffffff)
        snr = 10 * np.log10((pcm.astype(float) ** 2).sum() / max(1, ((pcm.astype(float) - dec) ** 2).sum()))
        m.write_wav(OUT / 'preview' / f'{key}__{name}.wav', [dict(pcm=dec)], 48000)
        report['slots'][key] = dict(asset=a['name'], mk8=name, seconds=round(len(dec) / 48000, 2), snr_db=round(snr, 1),
                                    loop=bool(s['loop']))
        if s['loop']:   # preview: the body three times, through the wrap
            m.write_wav(OUT / 'preview' / f'{key}__{name}__x3.wav', [dict(pcm=np.tile(dec, 3))], 48000)
    bars = m.write_totk_bars(bank)
    chk = m.read_totk_bars(bars)
    assert sorted(x['name'] for x in chk) == sorted(x['name'] for x in bank)
    # ---- SLink DB: disable the vanilla parent keys ----
    dic = zsdic()
    db = bytearray(zstd.ZstdDecompressor(dict_data=dic).decompress((RET / DB).read_bytes(), max_output_size=16 << 20))
    for idx, (old, new) in RENAME.items():
        e = CALLS + 0x30 * idx
        assert pool_name(db, struct.unpack_from('<I', db, e)[0]) == old
        assert struct.unpack_from('<I', db, e + 0x18)[0] == zlib.crc32(old)
        pos = db.find(b'\0' + new + b'\0', NT) + 1 - NT
        struct.pack_into('<I', db, e, pos); struct.pack_into('<I', db, e + 0x18, zlib.crc32(new))
    # the user's name-sorted index (26 u16 after the property block) must still be sorted
    order = struct.unpack_from('<26H', db, 0x316784)
    names = [pool_name(db, struct.unpack_from('<I', db, CALLS + 0x30 * i)[0]) for i in order]
    assert names == sorted(names), names
    report['sorted_keys'] = [n.decode() for n in names]
    # ---- RSTB ----
    raw = bytearray(zstd.ZstdDecompressor().decompress(TABLE_SRC.read_bytes(), max_output_size=64 << 20))
    count = struct.unpack_from('<I', raw, 14)[0]
    key = zlib.crc32(BANK.removesuffix('.zs').encode())
    hit = [22 + 8 * i + 4 for i in range(count) if struct.unpack_from('<I', raw, 22 + 8 * i)[0] == key]
    assert len(hit) == 1
    before = struct.unpack_from('<I', raw, hit[0])[0]
    struct.pack_into('<I', raw, hit[0], max(before, ((len(bars) + 31) & ~31) + 576))   # retail banks: size + 576
    report['rstb_bank'] = [before, struct.unpack_from('<I', raw, hit[0])[0]]
    # ---- write ----
    rom = OUT / 'romfs'
    for rel, data in [(BANK, zstd.ZstdCompressor(level=19).compress(bars)),
                      (DB, zstd.ZstdCompressor(level=19, dict_data=dic).compress(bytes(db))),
                      (TABLE, zstd.ZstdCompressor(level=19).compress(bytes(raw)))]:
        (rom / rel).parent.mkdir(parents=True, exist_ok=True); (rom / rel).write_bytes(data)
    assert zstd.ZstdDecompressor(dict_data=dic).decompress((rom / DB).read_bytes(), max_output_size=16 << 20) == db
    report['outputs'] = {p.relative_to(OUT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                         for p in rom.rglob('*') if p.is_file()}
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
