#!/usr/bin/env python3
"""Signed steering checks for a summarize_native_controller.py results file.

The original checks only test that the heading changes. TOTK is right-handed with Y up and the
kart's forward is local +Z, so a positive Y component of cross(old_heading, new_heading) is a
LEFT (counter-clockwise from above) turn. Stick right (phase 1) must turn right, stick left
(phase 4) must turn left. Wheel steer samples (log field w=bones,spin,steer) must point the
front wheels into the turn: negative steer for right, positive for left.
"""
import json
import re
import sys


def cross_y(a, b):
    # headings are [x, z]; (a x b).y = a.z*b.x - a.x*b.z
    return a[1] * b[0] - a[0] * b[1]


def main(results_path, log_path=None):
    rows = {r['label']: r for r in json.load(open(results_path))['samples']}
    checks = {}
    if {'end0', 'end1'} <= rows.keys():
        checks['stick_right_turns_right'] = cross_y(rows['end0']['heading'], rows['end1']['heading']) < -0.2
    if {'p4f30', 'end4'} <= rows.keys():
        checks['stick_left_turns_left'] = cross_y(rows['p4f30']['heading'], rows['end4']['heading']) > 0.2
    if log_path:
        text = open(log_path, 'rb').read().decode('utf-8', 'replace')
        steer = {}
        for m in re.finditer(r'DRIVE (\w+) .*? w=(\w+),([-\d.e+]+),([-\d.e+]+)', text):
            steer[m[1]] = float(m[4])
        if 'end1' in steer:
            checks['front_wheels_point_right_on_right'] = steer['end1'] < -0.3
        if 'end4' in steer:
            checks['front_wheels_point_left_on_left'] = steer['end4'] > 0.3
    print(json.dumps(checks, indent=2))
    return all(checks.values()) and bool(checks)


if __name__ == '__main__':
    sys.exit(0 if main(*sys.argv[1:]) else 1)
