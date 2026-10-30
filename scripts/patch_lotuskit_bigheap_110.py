#!/usr/bin/env python3
"""Move LotusKit's C/C++ heap from the 64 KiB exlaunch fake heap to the unused WebSocket send buffer (~992 KiB).

Why: AngelScript `string`, LotusKit's JSON logging and actor-name strings all allocate through newlib malloc -> _sbrk_r,
bounded by fake_heap_start/end = __fake_heap (0x2c3090, 64 KiB). Larger kart scripts ran out: a deterministic crash in
nlohmann::json construction at kart spawn (null+0x21), and earlier pointers overwritten with actor-name text.

Patch (on native-call7-110), inside _sbrk_r (0x21abc0) only:
  * first-use initialisation of the sbrk cursor (0x21ac0c..) -> cursor = module + 0x2d9000
    (lotuskit::server::WebSocketImpl::SendQueue::sendQueueBuf, 1 MiB, page aligned)
  * limit (0x21abd0..0x21abe8) -> module + 0x3d1000, where the kart controller's 32 KiB effect scratch begins
LotusKit only writes sendQueueBuf after its debug WebSocket server is started (exact L+R+ZL+ZR+Plus+Minus or wsListen())
- that would now clobber the heap. Output: runtime/candidates/native-heap-110.
"""
from pathlib import Path
import hashlib, json, struct, sys
import lz4.block
from patch_lotuskit_spawn_init import decode
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/kart-assets/python'))
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
SOURCE = ROOT / 'runtime/candidates/native-call7-110/subsdk9'
EXPECTED = '8d838a33fd3aeb84050cf3c5c10bc07308ee762156b96d7b66b23ea5e7b3e8af'
OUT = ROOT / 'runtime/candidates/native-heap-110'
HEAP_START, HEAP_LIMIT = 0x2d9000, 0x3d1000
NOP = 0xd503201f


def adrp(pc, target, rd):
    off = (target >> 12) - (pc >> 12)
    assert -(1 << 20) <= off < (1 << 20)
    imm = off & 0x1fffff
    return 0x90000000 | ((imm & 3) << 29) | ((imm >> 2) << 5) | rd


def branch(pc, target):
    return 0x14000000 | (((target - pc) >> 2) & 0x3ffffff)


def main():
    original = SOURCE.read_bytes()
    assert hashlib.sha256(original).hexdigest() == EXPECTED
    segments = decode(original)
    old_text = segments[0][1]
    text = bytearray(old_text)
    dis = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    asm = lambda buf, off: (lambda i: f'{i.mnemonic} {i.op_str}'.strip())(next(dis.disasm(bytes(buf[off:off + 4]), off)))
    expect = {0x21abd0: 'adrp x2, #0x2c2000', 0x21abd4: 'ldr x2, [x2, #0x380]', 0x21abd8: 'mov x5, sp',
              0x21abdc: 'add x1, x0, x1', 0x21abe0: 'ldr x2, [x2]', 0x21abe4: 'cmp x2, #0',
              0x21abe8: 'csel x2, x2, x5, ne', 0x21abec: 'cmp x1, x2', 0x21abf0: 'b.hi #0x21abfc',
              0x21ac0c: 'adrp x0, #0x2c1000', 0x21ac10: 'ldr x0, [x0, #0xd40]', 0x21ac14: 'ldr x0, [x0]',
              0x21ac18: 'cbz x0, #0x21ac24', 0x21ac1c: 'str x0, [x4, #0x328]', 0x21ac20: 'b #0x21abd0'}
    for off, ins in expect.items():
        assert asm(old_text, off) == ins, (hex(off), asm(old_text, off))
    words = {
        0x21abd0: adrp(0x21abd0, HEAP_LIMIT, 2),   # limit = module + 0x3d1000
        0x21abd4: NOP, 0x21abe0: NOP, 0x21abe4: NOP, 0x21abe8: NOP,
        0x21ac0c: adrp(0x21ac0c, HEAP_START, 0),   # first sbrk: cursor = module + 0x2d9000
        0x21ac10: NOP, 0x21ac14: NOP, 0x21ac18: NOP,
    }
    for off, w in words.items():
        struct.pack_into('<I', text, off, w)
    got = {off: asm(text, off) for off in range(0x21abd0, 0x21ac24, 4)}
    assert got[0x21abd0] == f'adrp x2, #{HEAP_LIMIT:#x}' and got[0x21ac0c] == f'adrp x0, #{HEAP_START:#x}'
    assert got[0x21abec] == 'cmp x1, x2' and got[0x21ac1c] == 'str x0, [x4, #0x328]' and got[0x21ac20] == 'b #0x21abd0'
    changed = [i for i in range(0, len(old_text), 4) if text[i:i + 4] != old_text[i:i + 4]]
    assert changed == sorted(words), [hex(c) for c in changed]
    output = bytearray(original[:256])
    flags = struct.unpack_from('<I', output, 12)[0]
    output[64:96] = hashlib.sha256(original[64:96] + text).digest()
    for i, (address, payload) in enumerate(segments):
        if i == 0:
            payload = bytes(text)
        packed = lz4.block.compress(payload, store_size=False, mode='high_compression', compression=12) if flags & (1 << i) else payload
        struct.pack_into('<III', output, 16 + i * 16, len(output), address, len(payload))
        struct.pack_into('<I', output, 96 + i * 4, len(packed))
        output[160 + i * 32:192 + i * 32] = hashlib.sha256(payload).digest()
        output.extend(packed)
    checked = decode(output)
    assert checked[0][1] == text and checked[1:] == segments[1:]
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / 'subsdk9'
    assert not dest.exists()
    dest.write_bytes(output)
    listing = [f'{off:08x} {got[off]}' for off in sorted(got)]
    (OUT / 'sbrk-verified.asm').write_text('\n'.join(listing) + '\n')
    report = dict(status='Offline candidate pending runtime tests', source_sha256=EXPECTED,
                  candidate_sha256=hashlib.sha256(output).hexdigest(), heap_start=hex(HEAP_START), heap_limit=hex(HEAP_LIMIT),
                  heap_bytes=HEAP_LIMIT - HEAP_START, changed_instructions=[hex(c) for c in changed],
                  limits=['LotusKit debug WebSocket server (6-button combo / wsListen) would overwrite the heap'])
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
