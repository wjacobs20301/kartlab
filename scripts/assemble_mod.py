#!/usr/bin/env python3
"""Collect the built mod into build/ (git-ignored), ready to install.

  build/KartLab_110/exefs/   subsdk9 (modified LotusKit runtime, runtime/candidates/malloc-lock-110), main.npdm (LotusKit
                             release), <TOTK 1.1.0 build id>.ips (fall-release patch, scripts/build_fall_release_patch.py)
  build/KartLab_110/romfs/   every asset the builders made (FILES below) + LotusKit's Lib/sead fonts + one size table
  build/sdcard/totk_lotuskit/autorun.as   the kart controller (scripts/build_native_wheels.py)
The size table is the vanilla one with every builder's entries merged in (each builder only raises or inserts entries,
so the largest value per entry wins). Every collected file is checked against it.

Usage: assemble_mod.py [--install]   (--install copies into Ryujinx on macOS, backing up an existing KartLab_110)
"""
import argparse, bisect, shutil, struct, sys, time, zipfile, zlib
from pathlib import Path
import zstandard as zstd

ROOT = Path(__file__).resolve().parents[1]
A = ROOT / 'assets'
OUT = ROOT / 'build'
TABLE = 'System/Resource/ResourceSizeTable.Product.110.rsizetable.zs'
VANILLA = ROOT / 'extracted/totk/romfs'
# (asset folder, glob patterns inside its romfs/) -> the files that make up the mod, in install order
FILES = [
    ('source-native-assembly-mod', ['TexToGo/Etc_ZonauCart_A_Mtl.txtg', 'TexToGo/Etc_ZonauCart_A_Nrm.txtg']),
    ('kart-texture-hd', ['TexToGo/Etc_ZonauCart_A_Alb.txtg']),
    ('rim-transfer', ['Model/SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc']),
    ('kart-glider-v2', ['Model/SpObj_ControlStick_A.*', 'TexToGo/Rock_ControlStick_A_*']),
    ('kart-sound-v2', ['SLink2/*', 'Sound/Resource/*']),
    ('kart-seated-lean', ['Model/Player_Animation.anim.bfres.zs']),
    ('kart-grip', ['Pack/Actor/SpObj_ControlStick_A_01.pack.zs']),
    ('kart-variant-skl', ['Model/*', 'Pack/Actor/*', 'TexToGo/Etc_ZonauCart_6_Alb.txtg']),
    ('kart-variant-bds', ['Model/*', 'Pack/Actor/*', 'TexToGo/Etc_ZonauCart_5_Alb.txtg']),
    ('kart-variant-bike', ['Model/*', 'Pack/Actor/*', 'TexToGo/Etc_ZonauCart_4_Alb.txtg']),
    ('kart-rsdb', ['RSDB/*']),
    ('kart-capsules', ['Mals/*', 'Pack/Actor/SpObj_ControlStick_Capsule_*', 'UI/Tex/Icon/*']),
    ('kart-chests', ['Banc/MainField/*']),
]
# Every other build step that raises size-table entries without supplying files itself (e.g. the cart sub-model and
# physics steps raise entries for resources the kart actor loads). Their tables are merged too: leaving them out made
# every kart crash on creation (null+0x18 while loading the actor's resources).
TABLE_ONLY = ['kart-texture-hd', 'kart-grip-targets', 'rim-transfer', 'native-mount-submodel', 'native-mount-cart-physics',
              'source-native-contacts-raised-chassis-seat-070-cart-dynamics-fwd045', 'kart-sound']
LOTUSKIT = ROOT / '.tools/totk-runtime/lotuskit-110.zip'
RUNTIME = ROOT / 'runtime/candidates/malloc-lock-110/subsdk9'
IPS_DIR = ROOT / 'runtime/candidates/fall-release-110'
AUTORUN = ROOT / 'runtime/candidates/native-rider-wheels/autorun.as'
RYUJINX = Path.home() / 'Library/Application Support/Ryujinx'


def read_table(path):
    raw = zstd.ZstdDecompressor().decompress(path.read_bytes(), max_output_size=64 << 20)
    assert raw[:6] == b'RESTBL'
    n = struct.unpack_from('<I', raw, 14)[0]
    return raw, {struct.unpack_from('<I', raw, 22 + 8 * i)[0]: struct.unpack_from('<I', raw, 26 + 8 * i)[0] for i in range(n)}


def merged_table(tables):
    raw, base = read_table(VANILLA / TABLE)
    merged = dict(base)
    for t in tables:
        for crc, size in read_table(t)[1].items(): merged[crc] = max(merged.get(crc, 0), size)
    n = struct.unpack_from('<I', raw, 14)[0]
    keys = sorted(merged)
    out = bytearray(raw[:22]) + b''.join(struct.pack('<II', k, merged[k]) for k in keys) + raw[22 + 8 * n:]
    struct.pack_into('<I', out, 14, len(keys))
    return bytes(out), merged


def decompressed_size(data, dicts):
    for d in [None] + dicts:
        try: return len((zstd.ZstdDecompressor(dict_data=d) if d else zstd.ZstdDecompressor()).decompress(data, max_output_size=512 << 20))
        except zstd.ZstdError: pass
    raise ValueError('cannot decompress')


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--install', action='store_true'); args = ap.parse_args()
    mod = OUT / 'KartLab_110'
    if mod.exists(): shutil.rmtree(mod)
    rom = mod / 'romfs'; exefs = mod / 'exefs'; exefs.mkdir(parents=True); rom.mkdir()
    tables = []; count = 0
    for folder, patterns in FILES:
        src = A / folder / 'romfs'
        assert src.is_dir(), f'missing build output {src.relative_to(ROOT)} (run scripts/build_mod.sh)'
        for pat in patterns:
            hits = [p for p in src.glob(pat) if p.is_file()]
            assert hits, f'{folder}: nothing matches {pat}'
            for p in hits:
                dst = rom / p.relative_to(src); dst.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(p, dst); count += 1
        if (src / TABLE).exists(): tables.append(src / TABLE)
    for folder in TABLE_ONLY:
        t = A / folder / 'romfs' / TABLE
        if t.exists() and t not in tables: tables.append(t)
    data, entries = merged_table(tables)
    (rom / TABLE).parent.mkdir(parents=True, exist_ok=True); (rom / TABLE).write_bytes(zstd.ZstdCompressor(level=19).compress(data))
    with zipfile.ZipFile(LOTUSKIT) as z:
        for name in z.namelist():
            if name.startswith('totk110-lotuskit/romfs/Lib/') and not name.endswith('/'):
                dst = rom / name.removeprefix('totk110-lotuskit/romfs/'); dst.parent.mkdir(parents=True, exist_ok=True); dst.write_bytes(z.read(name))
        (exefs / 'main.npdm').write_bytes(z.read('totk110-lotuskit/exefs/main.npdm'))
    shutil.copy2(RUNTIME, exefs / 'subsdk9')
    ips = sorted(IPS_DIR.glob('*.ips')); assert len(ips) == 1, 'run scripts/build_fall_release_patch.py'
    shutil.copy2(ips[0], exefs / ips[0].name)
    sd = OUT / 'sdcard/totk_lotuskit'; sd.mkdir(parents=True, exist_ok=True); shutil.copy2(AUTORUN, sd / 'autorun.as')
    # every collected file must fit its size-table entry (a file larger than its entry fails to load in game)
    sys.path.insert(0, str(ROOT / 'scripts')); from inspect_native_rider import sarc
    dicts = [zstd.ZstdCompressionDict(v) for v in sarc(zstd.ZstdDecompressor().decompress((VANILLA / 'Pack/ZsDic.pack.zs').read_bytes())).values()]
    bad = []
    for p in rom.rglob('*'):
        rel = p.relative_to(rom).as_posix()
        if not p.is_file() or rel == TABLE or rel.endswith('.bfres.mc') or rel.startswith('Lib/'): continue
        key = rel.removesuffix('.zs'); size = decompressed_size(p.read_bytes(), dicts) if rel.endswith('.zs') else p.stat().st_size
        if size > entries.get(zlib.crc32(key.encode()), 0): bad.append((key, size, entries.get(zlib.crc32(key.encode()))))
    assert not bad, f'files larger than their size-table entry: {bad}'
    print(f'assembled {count} asset files + runtime into {mod.relative_to(ROOT)}; size table checked')
    if args.install:
        dest = RYUJINX / 'mods/contents/0100f2c0115b6000/KartLab_110'
        if dest.exists():
            backup = ROOT / f'.work/backups/KartLab_110-{time.strftime("%Y%m%d-%H%M%S")}'; shutil.copytree(dest, backup); shutil.rmtree(dest)
            print('backed up the installed mod to', backup.relative_to(ROOT))
        shutil.copytree(mod, dest)
        auto = RYUJINX / 'sdcard/totk_lotuskit/autorun.as'; auto.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(sd / 'autorun.as', auto)
        print('installed into', dest)


if __name__ == '__main__':
    main()
