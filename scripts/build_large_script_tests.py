#!/usr/bin/env python3
"""Build >8 KiB copies of the wheel controller and its regression for large-script-110 tests.

Each copy keeps the original script byte-for-byte, then appends compiled padding functions and
a tail function that main() calls first. The tail logs `LARGESCRIPT <label> tail ok bytes=<n>`,
so a truncated read cannot pass silently (a cut file fails to compile; a loaded one logs).
Also builds an over-limit (>65,535 byte) copy to check the error path.

Outputs (runtime/diagnostics/):
  large_controller_24k.as      padded native-rider-wheels controller (normal startup behaviour)
  large_regression_24k.as      padded native_wheels_regression (14 drive/recall checks)
  large_overlimit_70k.as       must be rejected with "file contents too long", no crash
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIAG = ROOT / 'runtime/diagnostics'
SOURCES = {'controller': ROOT / 'runtime/candidates/native-rider-wheels/autorun.as',
           'regression': DIAG / 'native_wheels_regression.as'}


def pad(source, label, target):
    assert source.count('void main(){') == 1
    body = source.replace('void main(){', 'void main(){_bigTail();', 1)
    pads, i = [], 0
    tail = lambda n: (f'void _bigTail(){{float s=_bigPad0(1);s=_bigPad{n-1}(s);'
                      f'sys::debugLog("LARGESCRIPT {label} tail ok bytes=XXXXX s="+s);}}\n')
    while len(body) + sum(map(len, pads)) + len(tail(i + 1)) < target:
        pads.append(f'float _bigPad{i}(float v){{return v*1.0001+{i}.5;}}// padding {i:05d}\n')
        i += 1
    text = body + ''.join(pads) + tail(i)
    text = text.replace('XXXXX', f'{len(text):05d}')
    assert len(text) >= target and text.endswith('}\n')
    return text


def main():
    outputs = {'large_controller_24k.as': pad(SOURCES['controller'].read_text(), 'controller', 24000),
               'large_regression_24k.as': pad(SOURCES['regression'].read_text(), 'regression', 24000),
               'large_overlimit_70k.as': pad(SOURCES['controller'].read_text(), 'overlimit', 70000)}
    for name, text in outputs.items():
        (DIAG / name).write_text(text)
        print(name, len(text.encode()))


if __name__ == '__main__':
    main()
