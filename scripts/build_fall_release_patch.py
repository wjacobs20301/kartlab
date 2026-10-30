#!/usr/bin/env python3
"""TOTK 1.1.0 main IPS32 patch: never drop the rider of a control stick for "falling" (every ControlStick is the kart).

AI node ExecuteActorControlStickPlayerRiding (vtable 0x43fc9e0 area), update 0x1b9e2b4 -> 0x1b9e0bc:
  v = linear velocity of the node actor's main rigid body (0xd34780 -> 0x780b14)
  if *(*(actor+0x228)+0x480)+0x28 == 0 and 0x6e6d38(...) == 1.0 and v.y < -10:  timer += dt
      timer > 1.25 s -> release (0x1648e4c)
  (else timer = 0); separately x^2+z^2 > 1600 (40 m/s horizontal) -> release.
While Link rides the seat his body's velocity jitters far past the kart's (logged -17..-55 m/s while the kart sank at
7), so sustained glider turns tripped it. Patch: 0x1b9e1c0 `b.pl 0x1b9e130` -> `b 0x1b9e130` (always take the "not
falling" branch, which zeroes the timer). That alone did not stop glide releases (Link's body velocity also spikes
horizontally), so 0x1b9e15c `b.le 0x1b9e174` -> `b 0x1b9e174` removes the 40 m/s horizontal release too.

Output: runtime/candidates/fall-release-110/<build id>.ips (Atmosphere/Ryujinx exefs patch; offset = text + 0x100).
"""
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NSO = ROOT / '.work/native/totk-main.uncompressed.nso'
PATCHES = [(0x1b9e1c0, 0x54fffb85, 0x17ffffdc),   # fall timer: b.pl -> b (never counts)
           (0x1b9e15c, 0x540000cd, 0x14000006)]   # 40 m/s horizontal: b.le -> b (never releases)


def main():
    d = NSO.read_bytes()
    assert d[:4] == b'NSO0'
    build_id = d[0x40:0x60].hex().upper().rstrip('0')
    text_off, text_addr = struct.unpack_from('<II', d, 0x10)
    ips = b'IPS32'
    for addr, old, new in PATCHES:
        assert struct.unpack_from('<I', d, text_off + addr - text_addr)[0] == old, hex(addr)
        ips += struct.pack('>IH', addr + 0x100, 4) + struct.pack('<I', new)
    ips += b'EEOF'
    out = ROOT / 'runtime/candidates/fall-release-110' / f'{build_id}.ips'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(ips)
    print(out, ips.hex())


if __name__ == '__main__':
    main()
