#!/usr/bin/env python3
"""Software render of a built kart variant (decoded cart model + its atlas) for an inventory icon, in the style of MK8's
tc_KP_* part icons (3/4 front view from above, soft light, dark outline). Used for bodies MK8 has no icon file for.
render(variant_dir) -> RGBA PIL image (200x128, the MK8 icon size).
"""
import io, json, struct
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter
import kart_assets_native_cart as n
k = n.k


def model_triangles(variant):
    data = (variant / 'color/expected-decoded.bfres').read_bytes()
    shape = list(list(n.parse_host(data).models.values())[0].shapes.values())[0]
    at = k.attributes(shape.vtx_buffer); mesh = shape.meshes[0]
    ind = np.frombuffer(mesh.index_buffer.data[0], '<u2').astype(np.int64) + mesh.first_vtx
    tri = ind.reshape(-1, 3); tri = tri[(tri[:, 0] != tri[:, 1]) & (tri[:, 1] != tri[:, 2]) & (tri[:, 0] != tri[:, 2])]
    p = at['_p0'][:, :3].astype(float).copy(); nn = at['_n0'][:, :3].astype(float); uv = at['_u0'][:, :2].astype(float)
    rig = at['_i0'][:, 0]
    sockets = json.loads((variant / 'validation.json').read_text())['wheel_sockets']
    for m in range(1, 5): p[rig == m] += np.array(sockets[m - 1])
    return p, nn, uv, tri


def render(variant, yaw=-0.62, pitch=0.42, size=(200, 128), ss=4):
    variant = Path(variant)
    p, nn, uv, tri = model_triangles(variant)
    atlas = np.asarray(Image.open(variant / 'atlas-preview.png').convert('RGB')).astype(float) / 255
    cy, sy, cp, sp = np.cos(yaw), np.sin(yaw), np.cos(pitch), np.sin(pitch)
    ry = np.array([[cy, 0, -sy], [0, 1, 0], [sy, 0, cy]]); rx = np.array([[1, 0, 0], [0, cp, -sp], [0, sp, cp]])
    R = rx @ ry
    q = p @ R.T; nq = nn @ R.T
    W, H = size[0] * ss, size[1] * ss
    lo, hi = q[:, :2].min(0), q[:, :2].max(0); scale = 0.92 * min(W / (hi[0] - lo[0]), H / (hi[1] - lo[1]))
    sx = (q[:, 0] - (lo[0] + hi[0]) / 2) * -scale + W / 2      # +X is the kart's left: mirror so its nose points left
    syy = (q[:, 1] - (lo[1] + hi[1]) / 2) * -scale + H / 2
    z = q[:, 2]
    zbuf = np.full((H, W), -1e9); col = np.zeros((H, W, 3)); alpha = np.zeros((H, W))
    light = np.array([0.35, 0.8, 0.5]); light /= np.linalg.norm(light)
    for a, b, c in tri:
        xs = np.array([sx[a], sx[b], sx[c]]); ys = np.array([syy[a], syy[b], syy[c]])
        x0, x1 = int(max(0, np.floor(xs.min()))), int(min(W - 1, np.ceil(xs.max())))
        y0, y1 = int(max(0, np.floor(ys.min()))), int(min(H - 1, np.ceil(ys.max())))
        if x1 < x0 or y1 < y0: continue
        den = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(den) < 1e-9: continue
        X, Y = np.meshgrid(np.arange(x0, x1 + 1) + .5, np.arange(y0, y1 + 1) + .5)
        w0 = ((ys[1] - ys[2]) * (X - xs[2]) + (xs[2] - xs[1]) * (Y - ys[2])) / den
        w1 = ((ys[2] - ys[0]) * (X - xs[2]) + (xs[0] - xs[2]) * (Y - ys[2])) / den
        w2 = 1 - w0 - w1; inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not inside.any(): continue
        zz = w0 * z[a] + w1 * z[b] + w2 * z[c]
        sub = zbuf[y0:y1 + 1, x0:x1 + 1]; win = inside & (zz > sub)
        if not win.any(): continue
        u = w0 * uv[a, 0] + w1 * uv[b, 0] + w2 * uv[c, 0]; v = w0 * uv[a, 1] + w1 * uv[b, 1] + w2 * uv[c, 1]
        tx = np.clip((u % 1) * atlas.shape[1], 0, atlas.shape[1] - 1).astype(int); ty = np.clip((v % 1) * atlas.shape[0], 0, atlas.shape[0] - 1).astype(int)
        nrm = w0[..., None] * nq[a] + w1[..., None] * nq[b] + w2[..., None] * nq[c]
        nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True) + 1e-9
        shade = 0.5 + 0.6 * np.clip(np.abs(nrm @ light), 0, 1)
        sub[win] = zz[win]
        col[y0:y1 + 1, x0:x1 + 1][win] = np.clip(atlas[ty, tx] * shade[..., None], 0, 1)[win]
        alpha[y0:y1 + 1, x0:x1 + 1][win] = 1
    img = Image.fromarray(np.dstack([col * 255, alpha * 255]).astype(np.uint8), 'RGBA').resize(size, Image.Resampling.LANCZOS)
    # MK8-style outline: dark grey band around the silhouette
    a = img.getchannel('A'); ring = a.filter(ImageFilter.MaxFilter(5))
    out = Image.new('RGBA', size, (70, 70, 74, 0)); out.putalpha(ring); out.alpha_composite(img)
    return out


if __name__ == '__main__':
    import sys
    render(sys.argv[1]).save(sys.argv[2])
