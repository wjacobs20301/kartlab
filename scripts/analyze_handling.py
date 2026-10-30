#!/usr/bin/env python3
"""Measure handling from a native_handling_test.as Ryujinx log. Usage: analyze_handling.py LOG [OUT.json]

Logical frames are 1/30 s. Samples are every 10 frames.
"""
import json
import math
import re
import sys

PAT = re.compile(r'HDL (\w+) f=(\d+) pos=([-\d.e+,]+) vel=([-\d.e+,]+) heading=([-\d.e+,]+) up=([-\d.e+]+) '
                 r'cmd=([-\d.e+]+) drift=(-?\d+) charge=([-\d.e+]+) tier=(\d+) boost=(-?\d+) mounted=(\w+)')


def rows(text):
    out = []
    for m in PAT.finditer(text):
        pos = list(map(float, m[3].split(',')))
        vel = list(map(float, m[4].split(',')))
        h = list(map(float, m[5].split(',')))
        out.append(dict(phase=m[1], f=int(m[2]), pos=pos, vel=vel, heading=h, up=float(m[6]), cmd=float(m[7]),
                        drift=int(m[8]), charge=float(m[9]), tier=int(m[10]), boost=int(m[11]),
                        mounted=m[12] == 'true', speed=math.hypot(vel[0], vel[2])))
    return out


def yaw(h):
    return math.atan2(h[0], h[1])


def yaw_rate(a, b):
    d = (yaw(b['heading']) - yaw(a['heading']) + math.pi) % (2 * math.pi) - math.pi
    return d / ((b['f'] - a['f']) / 30.0)


def slip_deg(r):
    if r['speed'] < 1:
        return 0.0
    vh = math.atan2(r['vel'][0], r['vel'][2])
    return math.degrees((vh - yaw(r['heading']) + math.pi) % (2 * math.pi) - math.pi)


def main(log, out=None):
    text = open(log, 'rb').read().decode('utf-8', 'replace')
    rs = rows(text)
    by = {}
    for r in rs:
        by.setdefault(r['phase'], []).append(r)
    res = {'completed': 'HDL finished' in text, 'samples': len(rs)}
    c = by.get('circle', [])
    if c:
        top = max(r['speed'] for r in c)
        t0 = c[0]['f']
        t90 = next((r['f'] for r in c if r['speed'] >= 0.9 * top), None)
        tail = c[-4:]
        w = sum(yaw_rate(a, b) for a, b in zip(tail, tail[1:])) / (len(tail) - 1)
        v = sum(r['speed'] for r in tail) / len(tail)
        res['circle'] = dict(top_speed_ms=top, time_to_90pct_s=None if t90 is None else (t90 - t0) / 30.0,
                             end_speed_ms=v, end_yaw_rate_rad_s=w, turn_radius_m=abs(v / w) if w else None,
                             turn_direction='right' if w < 0 else 'left')
    b = by.get('brake', [])
    if b:
        stop = next((r['f'] for r in b if r['speed'] < 0.5), None)
        res['brake'] = dict(start_speed_ms=b[0]['speed'], time_to_below_0_5_s=None if stop is None else (stop - b[0]['f'] + 10) / 30.0)
    d = by.get('drift', [])
    if d:
        tiers = {}
        for r in d:
            tiers.setdefault(r['tier'], r['f'])
        start = d[0]['f']
        res['drift'] = dict(started=any(r['drift'] != 0 for r in d), max_tier=max(r['tier'] for r in d),
                            tier_first_seen_s={str(k): (v - start) / 30.0 for k, v in sorted(tiers.items())},
                            mean_slip_deg=sum(abs(slip_deg(r)) for r in d[3:]) / max(1, len(d[3:])),
                            mean_speed_ms=sum(r['speed'] for r in d[3:]) / max(1, len(d[3:])),
                            hop_peak_vy=max(r['vel'][1] for r in d[:3]),
                            yaw_rate_rad_s=sum(yaw_rate(a, b) for a, b in zip(d[3:], d[4:])) / max(1, len(d[4:])))
    bo = by.get('boost', [])
    if bo:
        res['boost'] = dict(boost_frames_at_release=bo[0]['boost'], peak_speed_ms=max(r['speed'] for r in bo),
                            peak_cmd_ms=max(r['cmd'] for r in bo))
    co = by.get('coast', [])
    if co:
        stop = next((r['f'] for r in co if r['speed'] < 0.5), None)
        res['coast'] = dict(start_speed_ms=co[0]['speed'], time_to_below_0_5_s=None if stop is None else (stop - co[0]['f'] + 10) / 30.0)
    driving = [r for r in rs if r['phase'] in ('circle', 'brake', 'prep', 'drift', 'boost', 'coast')]
    if driving:
        res['min_up'] = min(r['up'] for r in driving)
        res['mounted_throughout'] = all(r['mounted'] for r in driving)
    ex = by.get('exit', [])
    if ex:
        res['dismounted'] = not ex[-1]['mounted']
    res['faults'] = len(re.findall(r'InvalidMemory|Unhandled exception', text))
    res['tier_events'] = re.findall(r'KART (drift tier=\d+ charge=[-\d.e+]+|boost tier=\d+ frames=\d+|drift start dir=-?\d+)', text)
    print(json.dumps(res, indent=1))
    if out:
        open(out, 'w').write(json.dumps(res, indent=1) + '\n')


if __name__ == '__main__':
    main(*sys.argv[1:])
