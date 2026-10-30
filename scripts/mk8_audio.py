#!/usr/bin/env python3
"""MK8DX audio (BARS v1.1 with FWAV) -> WAV previews and TOTK BWAV/BARS v1.2 assets.

FWAV (NW4F): INFO section = encoding (0 PCM8, 1 PCM16, 2 DSP-ADPCM), loop flag, rate, loop start, sample count, channel
refs; DATA section holds samples. TOTK BWAV v1: header (BWAV, BOM, version 1, CRC32 of sample data, prefetch 0, channel
count) + 0x4c-byte channel infos (codec 0 PCM16 / 1 DSP, pan, rate, sample counts, DSP coefs, data offset, loop flag,
loop end, loop start, DSP context) + data. See research/kart-sound-notes.md.
"""
import struct, wave, zlib, sys
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]


def read_mk8_bars(path):
    d = Path(path).read_bytes()
    assert d[:4] == b'BARS'
    n = struct.unpack_from('<I', d, 0xc)[0]
    out = []
    for i in range(n):
        amta, fw = struct.unpack_from('<II', d, 0x10 + 4 * n + 8 * i)
        j = d.find(b'STRG', amta, amta + 0x400)
        name = d[j + 8:d.index(b'\0', j + 8)].decode() if j > 0 else f'asset{i}'
        out.append(dict(name=name, **read_fwav(d, fw)))
    return out


def read_fwav(d, off):
    w = memoryview(d)[off:]
    assert bytes(w[:4]) == b'FWAV'
    nsec = struct.unpack_from('<H', w, 0x10)[0]
    secs = {struct.unpack_from('<H', w, 0x14 + 12 * i)[0]: struct.unpack_from('<II', w, 0x14 + 12 * i + 4) for i in range(nsec)}
    io_, _ = secs[0x7000]; do, _ = secs[0x7001]
    enc, loop = w[io_ + 8], w[io_ + 9]
    rate, loop_start, count = struct.unpack_from('<III', w, io_ + 0xc)
    tbl = io_ + 0x1c
    nch = struct.unpack_from('<I', w, tbl)[0]
    chans = []
    for c in range(nch):
        _, _, ref = struct.unpack_from('<HHi', w, tbl + 4 + 8 * c)
        ci = tbl + ref
        _, _, so = struct.unpack_from('<HHi', w, ci)
        at, _, ao = struct.unpack_from('<HHi', w, ci + 8)
        data_at = do + 8 + so
        if enc == 1:
            pcm = np.frombuffer(bytes(w[data_at:data_at + count * 2]), dtype='<i2').copy()
            chans.append(dict(pcm=pcm))
        elif enc == 2:
            ai = ci + ao
            coefs = struct.unpack_from('<16h', w, ai)
            ps, h1, h2 = struct.unpack_from('<Hhh', w, ai + 32)
            lps, lh1, lh2 = struct.unpack_from('<Hhh', w, ai + 38)
            nbytes = (count + 13) // 14 * 8
            raw = bytes(w[data_at:data_at + nbytes])
            chans.append(dict(adpcm=raw, coefs=coefs, ps=ps, h1=h1, h2=h2, lps=lps, lh1=lh1, lh2=lh2,
                              pcm=dsp_decode(raw, coefs, count, h1, h2)))
        else:
            raise ValueError(f'encoding {enc}')
    return dict(encoding=enc, loop=bool(loop), rate=rate, loop_start=loop_start, count=count, channels=chans)


def dsp_decode(raw, coefs, count, h1=0, h2=0):
    out = np.zeros(count, dtype=np.int16)
    c = np.array(coefs, dtype=np.int64).reshape(8, 2)
    i = 0
    for f in range(0, len(raw), 8):
        ps = raw[f]; scale = 1 << (ps & 0xf); c1, c2 = c[ps >> 4]
        for b in raw[f + 1:f + 8]:
            for nib in (b >> 4, b & 0xf):
                if i >= count: return out
                s = nib - 16 if nib >= 8 else nib
                v = ((s * scale) << 11) + 1024 + c1 * h1 + c2 * h2
                v = max(-32768, min(32767, v >> 11))
                out[i] = v; h2, h1 = h1, v; i += 1
    return out


def write_wav(path, chans, rate):
    data = np.stack([c['pcm'] for c in chans], axis=1).astype('<i2')
    with wave.open(str(path), 'wb') as f:
        f.setnchannels(data.shape[1]); f.setsampwidth(2); f.setframerate(rate); f.writeframes(data.tobytes())


def make_bwav(asset):
    """TOTK BWAV v1. PCM16 sources -> codec 0; DSP sources -> codec 1 (frames re-wrapped, no re-encode)."""
    chans = asset['channels']; n = len(chans)
    codec = 1 if asset['encoding'] == 2 else 0
    count = asset['count']
    datas = [c['adpcm'] if codec == 1 else c['pcm'].astype('<i2').tobytes() for c in chans]
    head = 0x10 + 0x4c * n
    start = (head + 0x3f) & ~0x3f
    offsets, pos = [], start
    for k, dta in enumerate(datas):
        offsets.append(pos); pos += len(dta)
        if k < n - 1: pos = (pos + 0x3f) & ~0x3f
    body = bytearray(pos)
    for o, dta in zip(offsets, datas):
        body[o:o + len(dta)] = dta
    loop_end = count if asset['loop'] else 0xffffffff
    loop_start = asset['loop_start'] if asset['loop'] else 0
    for i, (c, o) in enumerate(zip(chans, offsets)):
        coefs = c.get('coefs', (0,) * 16)
        pan = 2 if n == 1 else i   # mono: centre (as in TOTK assets); stereo: 0 left, 1 right
        struct.pack_into('<HHIII16hIIIIIHhhH', body, 0x10 + 0x4c * i, codec, pan, asset['rate'], count, count, *coefs,
                         o, o, 1, loop_end, loop_start,   # retail one-shots also carry 1 here (loop end -1)
                         c.get('ps', 0), c.get('h1', 0), c.get('h2', 0), 0)
    crc = zlib.crc32(b''.join(datas[:1]))
    body[0:0x10] = b'BWAV' + struct.pack('<HHIHH', 0xfeff, 1, crc, 0, n)
    return bytes(body)


def read_bwav(b):
    assert b[:4] == b'BWAV'
    n = struct.unpack_from('<H', b, 0xe)[0]
    chans = []
    for i in range(n):
        f = struct.unpack_from('<HHIII16hIIIIIHhhH', b, 0x10 + 0x4c * i)
        codec, pan, rate, count = f[0], f[1], f[2], f[3]
        coefs = f[5:21]; off = f[21]; loop, le, ls = f[23], f[24], f[25]; h1, h2 = f[27], f[28]
        if codec == 0:
            pcm = np.frombuffer(b[off:off + count * 2], dtype='<i2')
        else:
            pcm = dsp_decode(b[off:off + (count + 13) // 14 * 8], coefs, count, h1, h2)
        chans.append(dict(pcm=pcm, codec=codec, rate=rate, loop=loop, loop_start=ls, loop_end=le))
    return chans


# ---- TOTK BARS v1.2 ----
def read_totk_bars(b):
    assert b[:4] == b'BARS' and struct.unpack_from('<H', b, 0xa)[0] == 0x0102
    n = struct.unpack_from('<I', b, 0xc)[0]
    crcs = struct.unpack_from('<%dI' % n, b, 0x10)
    out = []
    for i in range(n):
        a, w = struct.unpack_from('<II', b, 0x10 + 4 * n + 8 * i)
        asize = struct.unpack_from('<I', b, a + 8)[0]
        amta = b[a:a + asize]
        name = amta[0x4c:amta.index(b'\0', 0x4c)].decode()
        nch = struct.unpack_from('<H', b, w + 0xe)[0]
        end = 0
        for c in range(nch):
            f = struct.unpack_from('<HHIII16hI', b, w + 0x10 + 0x4c * c)
            codec, count, off = f[0], f[3], f[21]
            size = count * 2 if codec == 0 else (count + 13) // 14 * 8
            end = max(end, off + size)
        out.append(dict(name=name, crc=crcs[i], amta=amta, bwav=b[w:w + end]))
    return out


def make_amta(template, name):
    t = bytearray(template[:0x4c])
    nm = name.encode() + b'\0'
    nm += b'\0' * (-len(nm) % 4)
    struct.pack_into('<I', t, 8, 0x4c + len(nm))
    struct.pack_into('<I', t, 0x28, zlib.crc32(name.encode()))
    return bytes(t) + nm


def write_totk_bars(assets):
    """assets: list of dict(name, amta, bwav). Layout as in retail TOTK banks: header, CRC table (sorted), offset
    pairs, u32 0, AMTAs back to back, then each BWAV 0x40-aligned."""
    assets = sorted(assets, key=lambda a: zlib.crc32(a['name'].encode()))
    n = len(assets)
    pos = 0x10 + 12 * n + 4
    amta_at = []
    for a in assets:
        amta_at.append(pos); pos += len(a['amta'])
    bwav_at = []
    for a in assets:
        pos = (pos + 0x3f) & ~0x3f; bwav_at.append(pos); pos += len(a['bwav'])
    out = bytearray(pos)
    struct.pack_into('<4sIHHI', out, 0, b'BARS', pos, 0xfeff, 0x0102, n)
    for i, a in enumerate(assets):
        struct.pack_into('<I', out, 0x10 + 4 * i, zlib.crc32(a['name'].encode()))
        struct.pack_into('<II', out, 0x10 + 4 * n + 8 * i, amta_at[i], bwav_at[i])
        out[amta_at[i]:amta_at[i] + len(a['amta'])] = a['amta']
        out[bwav_at[i]:bwav_at[i] + len(a['bwav'])] = a['bwav']
    return bytes(out)


# ---- DSP-ADPCM encoder (for TOTK-native mono 48 kHz banks) ----
def dsp_coefs(x):
    """8 predictor pairs: per-frame least-squares order-2 predictors clustered by energy-weighted k-means."""
    x = x.astype(np.float64)
    pairs, weights = [], []
    for f in range(2, len(x) - 14, 14):
        y = x[f:f + 14]; A = np.stack([x[f - 1:f + 13], x[f - 2:f + 12]], 1)
        e = (y * y).sum()
        if e < 1e3: continue
        sol, *_ = np.linalg.lstsq(A, y, rcond=None)
        pairs.append(np.clip(sol, [-1.99, -0.99], [1.99, 0.99])); weights.append(np.sqrt(e))
    base = np.array([[0, 0], [1, 0], [2, -1], [1.8, -0.82], [1.5, -0.6], [1.9, -0.92], [0.9, 0], [1.2, -0.3]])
    if len(pairs) >= 8:
        P = np.array(pairs); W = np.array(weights); C = base.copy()
        for _ in range(20):
            lab = ((P[:, None, :] - C[None]) ** 2).sum(2).argmin(1)
            for k in range(8):
                m = lab == k
                if m.any(): C[k] = (P[m] * W[m, None]).sum(0) / W[m].sum()
        C[0] = (0, 0)
        base = C
    return tuple(int(v) for v in np.clip(np.round(base * 2048), -32768, 32767).astype(int).ravel())


def dsp_encode(pcm, coefs=None, h1=0, h2=0):
    """Brute force per 14-sample frame over 8 predictors x 12 scales, exact decoder arithmetic. Returns (raw, coefs)."""
    x = np.asarray(pcm, dtype=np.int64)
    coefs = coefs or dsp_coefs(x)
    c = np.array(coefs, dtype=np.int64).reshape(8, 2)
    ci = np.repeat(np.arange(8), 12); sc = np.tile(np.arange(12), 8)
    c1 = c[ci, 0]; c2 = c[ci, 1]; step = (1 << sc).astype(np.int64)
    out = bytearray()
    nfr = (len(x) + 13) // 14
    xp = np.zeros(nfr * 14, dtype=np.int64); xp[:len(x)] = x
    for f in range(nfr):
        seg = xp[f * 14:f * 14 + 14]
        a1 = np.full(96, h1, dtype=np.int64); a2 = np.full(96, h2, dtype=np.int64)
        err = np.zeros(96); nibs = np.zeros((96, 14), dtype=np.int64)
        for k in range(14):
            pred = c1 * a1 + c2 * a2 + 1024
            s = np.clip(np.round((seg[k] * 2048 - pred + 1024) / (step * 2048.0)), -8, 7).astype(np.int64)
            v = np.clip((((s * step) << 11) + pred) >> 11, -32768, 32767)
            err += (v - seg[k]) ** 2; nibs[:, k] = s; a2 = a1; a1 = v
        b = int(err.argmin())
        out.append((int(ci[b]) << 4) | int(sc[b]))
        n = nibs[b] & 0xf
        out += bytes(int(n[k] << 4 | n[k + 1]) for k in range(0, 14, 2))
        h1, h2 = int(a1[b]), int(a2[b])
    return bytes(out), coefs


def totk_sfx(pcm, rate, peak=0.35, loop_from=None, pitch=1.0):
    """Mono float/int pcm at `rate` -> normalised mono 48 kHz int16 + DSP data. Returns dict for make_bwav + stats.
    loop_from: keep only the source's loop body (loop_from..end) and loop all of it. It is resampled circularly and
    DSP-encoded with the body's own last two samples as start history, so the stored context (h1, h2) is also the
    exact context at every wrap."""
    from scipy.signal import resample_poly
    from fractions import Fraction
    x = np.asarray(pcm, dtype=np.float64)
    if x.ndim == 2: x = x.mean(1)
    if loop_from is not None: x = x[loop_from:]
    rate = int(round(rate * pitch))   # pitch > 1: fewer output samples, so it plays higher at 48 kHz
    if rate != 48000:
        fr = Fraction(48000, rate).limit_denominator(1000)
        if loop_from is not None:
            n = len(x); x = resample_poly(np.tile(x, 3), fr.numerator, fr.denominator)
            m = len(x) // 3; x = x[m:2 * m]
        else:
            x = resample_poly(x, fr.numerator, fr.denominator)
    x = x / max(1e-9, np.abs(x).max()) * peak * 32767
    x = np.clip(np.round(x), -32768, 32767).astype(np.int16)
    h1 = h2 = 0
    if loop_from is not None: h1, h2 = int(x[-1]), int(x[-2])
    raw, coefs = dsp_encode(x, None, h1, h2)
    dec = dsp_decode(raw, coefs, len(x), h1, h2)
    return dict(encoding=2, loop=loop_from is not None, loop_start=0, count=len(x), rate=48000,
                channels=[dict(adpcm=raw, coefs=coefs, ps=raw[0], h1=h1, h2=h2, pcm=dec)]), x, dec


if __name__ == '__main__':
    out = ROOT / 'assets/mk8-audio/preview'
    out.mkdir(parents=True, exist_ok=True)
    for rel in sys.argv[1:] or ['Audio/Body/Body_K_Std.bars']:
        for a in read_mk8_bars(ROOT / 'extracted/mk8dx/romfs' / rel):
            write_wav(out / (a['name'] + '.wav'), a['channels'], a['rate'])
            bw = make_bwav(a); back = read_bwav(bw)
            same = all(np.array_equal(x['pcm'], y['pcm']) for x, y in zip(a['channels'], back))
            print(f"{a['name']:28s} enc={a['encoding']} ch={len(a['channels'])} rate={a['rate']} "
                  f"len={a['count']/a['rate']:.2f}s loop={a['loop']}@{a['loop_start']} bwav={len(bw)} roundtrip={same}")
