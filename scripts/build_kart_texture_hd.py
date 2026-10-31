#!/usr/bin/env python3
"""Sharper kart: rebuild the Mario kart atlas (TexToGo/Etc_ZonauCart_A_Alb.txtg) at 2048x2048 instead of 256x256.

The old atlas squeezed MK8's 1024x1024 BodyK_Std_Mro_Alb into 128x95 texels (8x down) and Tire_Std_Alb (256x256) into
64x54. The layout is identical, scaled 8x (same normalized UVs, so the installed model is unchanged): body tile 1024x760 at
(0,0),(1024,0),(0,760),(1024,760); wrap rows; tire tile 512x432 x4 at y=1600. Full 12-level mip chain, BC1 (format 0x302,
as before), Tegra block-linear swizzle (kart_assets_colors.swizzle). Header: the installed file's, with width/height/mips
changed (vanilla TOTK textures of other sizes differ only in those fields and a hash the game does not check).
The mod's resource size table entry is set to align32(file size) + 256, the rule every vanilla texture entry follows.
Output: assets/kart-texture-hd/romfs/{TexToGo/..., System/Resource/...rsizetable.zs}
"""
from pathlib import Path
import hashlib, json, struct, zlib
import numpy as np
from PIL import Image
from kart_assets_colors import encode_bc1, swizzle, read_txtg, deswizzle  # also puts .tools/kart-assets/python on sys.path
import zstandard as zstd
from kartbf.bntx.pixelfmt.bcn.decompress_ import decomp_bc1

ROOT = Path(__file__).resolve().parents[1]
MOD = Path.home() / 'Library/Application Support/Ryujinx/mods/contents/0100f2c0115b6000/KartLab_110/romfs'
TEX = 'TexToGo/Etc_ZonauCart_A_Alb.txtg'
TABLE = 'System/Resource/ResourceSizeTable.Product.110.rsizetable.zs'
OUT = ROOT / 'assets/kart-texture-hd/romfs'
S = 8              # scale vs the old 256 atlas
SIZE = 256 * S


def atlas():
    body = Image.open(ROOT / 'assets/standard-kart/textures/BodyK_Std_Mro_Alb.png').convert('RGB')
    tire = Image.open(ROOT / 'assets/standard-kart/textures/Tire_Std_Alb.png').convert('RGB')
    canvas = Image.new('RGB', (SIZE, SIZE))
    bodytile = body.resize((128 * S, 95 * S), Image.Resampling.LANCZOS)
    for y in (0, 95 * S):
        for x in (0, 128 * S):
            canvas.paste(bodytile, (x, y))
    # Wrapped edge rows, as in kart_assets_colors.atlas_image (rows 190..200 at the old scale).
    canvas.paste(canvas.crop((0, 0, SIZE, 2 * S)), (0, 190 * S))
    canvas.paste(canvas.crop((0, 188 * S, SIZE, 190 * S)), (0, 192 * S))
    tiretile = tire.resize((64 * S, 54 * S), Image.Resampling.LANCZOS)
    for x in range(0, SIZE, 64 * S):
        canvas.paste(tiretile, (x, 200 * S))
    canvas.paste(canvas.crop((0, 200 * S, SIZE, 202 * S)), (0, 254 * S))
    return canvas


def main():
    ref = read_txtg((ROOT / 'assets/source-native-assembly-mod/romfs' / TEX).read_bytes())   # the 256^2 atlas it replaces
    assert (ref['width'], ref['height'], ref['format']) == (256, 256, 0x302)
    image = atlas()
    mips = SIZE.bit_length()          # 2048 -> 12 levels down to 1x1
    surfaces = []
    for i in range(mips):
        w = h = max(1, SIZE >> i)
        level = image if i == 0 else image.resize((w, h), Image.Resampling.LANCZOS)
        surfaces.append(swizzle(encode_bc1(level), w, h))
    header = bytearray(ref['header'])
    struct.pack_into('<HH', header, 8, SIZE, SIZE)
    header[14] = mips
    compressor = zstd.ZstdCompressor(level=19)
    frames = [compressor.compress(x) for x in surfaces]
    data = bytes(header) + b''.join(struct.pack('<HBB', 0, i, 1) for i in range(mips)) \
        + b''.join(struct.pack('<II', len(x), 6) for x in frames) + b''.join(frames)
    check = read_txtg(data)
    assert (check['width'], check['height'], check['mips']) == (SIZE, SIZE, mips) and check['surfaces'] == surfaces
    decoded = decomp_bc1(deswizzle(check['surfaces'][0], SIZE, SIZE), SIZE, SIZE)
    # Resource size table: copy the base table (vanilla unless $KART_RSTB_BASE), raise the one texture entry.
    from build_kart_variant import base_rstb
    raw = bytearray(zstd.ZstdDecompressor().decompress(base_rstb().read_bytes(), max_output_size=64 << 20))
    assert raw[:6] == b'RESTBL'
    count = struct.unpack_from('<I', raw, 14)[0]
    key = zlib.crc32(TEX.encode())
    hits = [22 + 8 * i + 4 for i in range(count) if struct.unpack_from('<I', raw, 22 + 8 * i)[0] == key]
    assert len(hits) == 1
    before = struct.unpack_from('<I', raw, hits[0])[0]
    after = max(before, ((len(data) + 31) & ~31) + 256)
    struct.pack_into('<I', raw, hits[0], after)
    (OUT / TEX).parent.mkdir(parents=True, exist_ok=True)
    (OUT / TABLE).parent.mkdir(parents=True, exist_ok=True)
    (OUT / TEX).write_bytes(data)
    (OUT / TABLE).write_bytes(zstd.ZstdCompressor(level=19).compress(bytes(raw)))
    assert zstd.ZstdDecompressor().decompress((OUT / TABLE).read_bytes(), max_output_size=64 << 20) == bytes(raw)
    image.save(ROOT / 'assets/kart-texture-hd/atlas-preview.png')
    report = dict(status='Offline candidate pending runtime test', texture=TEX, size=[SIZE, SIZE], mips=mips, format='0x302 BC1',
                  bytes=len(data), sha256=hashlib.sha256(data).hexdigest(), rstb_before=before, rstb_after=after,
                  table_sha256=hashlib.sha256((OUT / TABLE).read_bytes()).hexdigest(), decoded_mip0_bytes=len(decoded),
                  source='assets/standard-kart/textures BodyK_Std_Mro_Alb (1024^2) + Tire_Std_Alb (256^2)',
                  limits=['Also replaces the texture of every vanilla Zonai cart (as the old atlas already did)'])
    (OUT.parent / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
