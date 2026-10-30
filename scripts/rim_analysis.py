#!/usr/bin/env python3
"""Read-only analysis for the steering-rim transfer.

Finds the steering-rim connected component in the INSTALLED Cart model buffers (high and low LOD)
and reports the hidden ControlStick host shape layout/capacities. Writes research/rim-analysis.json.
"""
import io, json, struct
import numpy as np
import kart_assets_native_cart as n

ROOT = n.ROOT
CART = ROOT / 'assets/source-native-assembly-mod/expected-decoded.bfres'
HOST = ROOT / 'assets/kart-grip-targets/decoded-check/SpObj_ControlStick_A.SpObj_ControlStick_A_01.bfres'


def mesh_arrays(shape, li):
    vb = shape.vtx_buffer
    at = n.k.attributes(vb)
    m = shape.meshes[li]
    first = m.first_vtx
    nxt = shape.meshes[li + 1].first_vtx if li + 1 < len(shape.meshes) else vb.vtx_count
    ind = np.frombuffer(m.index_buffer.data[0], dtype='<u2').astype(np.int64)
    return at, first, nxt, ind


def components(p, tri):
    _, w = np.unique(np.round(p, 4), axis=0, return_inverse=True)
    w = w.reshape(-1)
    parent = np.arange(w.max() + 1)

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    for t in w[tri]:
        r = find(t[0])
        for v in t[1:]:
            parent[find(v)] = r
    groups = {}
    for ti, t in enumerate(tri):
        groups.setdefault(find(w[t[0]]), []).append(ti)
    return groups


def main():
    report = {}
    cart = list(n.parse_host(CART.read_bytes()).models.values())[0]
    shape = list(cart.shapes.values())[0]
    report['cart_attributes'] = sorted(n.k.attributes(shape.vtx_buffer).keys())
    for li in range(len(shape.meshes)):
        at, first, nxt, ind = mesh_arrays(shape, li)
        tri = ind.reshape(-1, 3)
        tri = tri[~((tri[:, 0] == tri[:, 1]) & (tri[:, 1] == tri[:, 2]))]
        p = at['_p0'][:, :3]
        rigid = at['_i0'][:, 0] if '_i0' in at else None
        groups = components(p, tri)
        found = []
        for key, tids in groups.items():
            ids = np.unique(tri[tids])
            pts = p[ids]
            lo, hi = pts.min(0), pts.max(0)
            c = (lo + hi) / 2
            # Rim: centred on X=0, about 0.5 wide, in front of the seat, high above the floor.
            if abs(c[0]) < 0.05 and 0.4 < hi[0] - lo[0] < 0.7 and c[2] > 0.2 and c[1] > 0.3:
                found.append(dict(triangles=len(tids), vertices=len(ids), min=lo.tolist(), max=hi.tolist(),
                                  rigid=sorted(set(int(x) for x in rigid[ids])) if rigid is not None else None,
                                  triangle_ids=[int(t) for t in tids], vertex_ids=[int(v) for v in ids]))
        found.sort(key=lambda d: -d['triangles'])
        report[f'cart_lod{li}'] = dict(first_vtx=first, next_first=nxt, index_count=len(ind),
                                     live_triangles=int(len(tri)), components=len(groups),
                                     rim_candidates=[{k: v for k, v in d.items() if k not in ('triangle_ids', 'vertex_ids')} for d in found],
                                     rim=found[0] if found else None)
    host = list(n.parse_host(HOST.read_bytes()).models.values())[0]
    hs = []
    for s in host.shapes.values():
        vb = s.vtx_buffer
        hs.append(dict(name=s.name, vtx_count=vb.vtx_count, strides=[b.stride for b in vb.buffers],
                       attributes=[(a.name, str(a.format_), a.buffer_idx, a.offset) for a in vb.attributes.values()],
                       meshes=[dict(first_vtx=m.first_vtx, index_capacity=len(m.index_buffer.data[0]) // 2) for m in s.meshes],
                       skin_count=getattr(s, 'vtx_skin_count', None), bone_idx=getattr(s, 'bone_idx', None)))
    report['host_shapes'] = hs
    report['cart_mtx_to_bone'] = list(cart.skeleton.mtx_to_bone_list)
    report['host_mtx_to_bone'] = list(host.skeleton.mtx_to_bone_list)
    out = ROOT / 'research/rim-analysis.json'
    out.write_text(json.dumps(report, indent=1) + '\n')
    for li in range(len(shape.meshes)):
        r = report[f'cart_lod{li}']
        print('cart lod', li, {k: r[k] for k in ('first_vtx', 'next_first', 'index_count', 'live_triangles', 'components')})
        for c in r['rim_candidates'][:4]:
            print('   cand', c)
    for s in hs:
        print('host', s)


if __name__ == '__main__':
    main()
