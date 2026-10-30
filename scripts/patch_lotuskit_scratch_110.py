#!/usr/bin/env python3
"""Give kart scripts 20 KiB of private, writable memory by growing the pinned LotusKit module's .bss.

Native calls (native-call7-110) need guest memory the script owns: an nn::vfx effect handle, matrices passed by
pointer. The NSO header's bss size grows by 0x5000. The loader (Ryujinx and the console's loader alike) maps and
zero-fills the larger region. Nothing in the module references the new page, so the script uses it at
module_base + SCRATCH (the base is derived from the camera hook, as in runtime/diagnostics/native_call_test.as).
Only the header's bss field changes; segment payloads and hashes are untouched.
"""
from pathlib import Path
import hashlib, json, struct
from patch_lotuskit_spawn_init import decode
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'runtime/candidates/native-call7-110/subsdk9'
EXPECTED = '8d838a33fd3aeb84050cf3c5c10bc07308ee762156b96d7b66b23ea5e7b3e8af'
OUT = ROOT / 'runtime/candidates/native-scratch-110'
GROW = 0x5000


def main():
    original = SOURCE.read_bytes()
    assert hashlib.sha256(original).hexdigest() == EXPECTED
    data_mem, data_size, bss = struct.unpack_from('<III', original, 0x34)
    end = data_mem + data_size + bss
    assert end & 0xfff == 0, hex(end)
    out = bytearray(original)
    struct.pack_into('<I', out, 0x3c, bss + GROW)
    assert decode(bytes(out)) == decode(original)
    assert all(0x3c <= i < 0x40 for i in range(len(out)) if out[i] != original[i])
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / 'subsdk9'
    assert not dest.exists()
    dest.write_bytes(out)
    report = dict(status='Offline candidate pending runtime tests', source_sha256=EXPECTED,
                  candidate_sha256=hashlib.sha256(out).hexdigest(), bss_before=hex(bss), bss_after=hex(bss + GROW),
                  scratch_offset=hex(end), scratch_size=hex(GROW),
                  validation=['Only the NSO header bss size changes', 'Segments decode identically'])
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
