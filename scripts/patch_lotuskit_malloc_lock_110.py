#!/usr/bin/env python3
"""Give LotusKit's newlib malloc a real lock (it has none), on top of native-heap-110.

Cause of the "pointer overwritten with actor-name text" crashes (Horse_Li…, Weapon_S…, Kart_Gli…, HDL circ…): exlaunch
links newlib's __malloc_lock -> __libc_lock_acquire_recursive, whose only call is a weak-undefined lock hook that the
linker turned into `cbz; nop; ret` - malloc/free run unlocked. LotusKit allocates from several threads: the AngelScript
thread (strings) and every thread that calls ActorMgr::requestCreateActorAsync (OnRequestCreateActorAsyncHook builds a
by-value std::string of the actor name for querySpawnSelectorSlot, 0x206a0 -> 0x1a800 / delete 0x1954e0). Names of 16+
chars go to the heap. Two threads in malloc/free at once corrupt the bins; the crash is the next unlink writing
FD->bk at (text pointer)+0x18 - every logged fault address is 8 ASCII bytes + 0x18.

Patch (source = native-heap-110, fe1f0d79…), recursive spinlock in the 8-byte __malloc_recursive_mutex (0x3db088):
word = owner (TPIDRRO_EL0, the thread's TLS, 0x200-aligned) | nesting depth in bits 0-3 (realloc/memalign re-enter).
Contended: clrex + svcSleepThread(4 us) + retry, so a higher-priority spinner cannot starve a lower-priority owner.
  * __malloc_lock   0x203de0 (8 words, was adrp/add/b) -> acquire head, body in the padding after wcsxfrm (0x208044)
  * __malloc_unlock 0x203e00 (8 words)                  -> release, last-level path in the padding after iswalnum (0x20bf48)
Output: runtime/candidates/malloc-lock-110.
"""
from pathlib import Path
import hashlib, json, struct, sys
import lz4.block
from patch_lotuskit_spawn_init import decode
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/kart-assets/python'))
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
SOURCE = ROOT / 'runtime/candidates/native-heap-110/subsdk9'
EXPECTED = 'fe1f0d79'  # prefix checked below; full hash recorded in validation.json
import os
COUNT = bool(os.environ.get('COUNT'))  # test-only: count contended waits at module+0x3d8ff0 (controller scratch +0x7ff0)
OUT = ROOT / ('runtime/candidates/malloc-lock-count-110' if COUNT else 'runtime/candidates/malloc-lock-110')
COUNTER = 0x3d8ff0
MUTEX = 0x3db088
LOCK, UNLOCK, CAVE_A, CAVE_R = 0x203de0, 0x203e00, 0x208044, 0x20bf48


def b(pc, t, link=False):
    return (0x94000000 if link else 0x14000000) | (((t - pc) >> 2) & 0x3ffffff)


def bcond(pc, t, cond):
    return 0x54000000 | ((((t - pc) >> 2) & 0x7ffff) << 5) | cond


def cbz(pc, t, rt, nz=False):
    return (0xb5000000 if nz else 0xb4000000) | ((((t - pc) >> 2) & 0x7ffff) << 5) | rt


def cbnzw(pc, t, rt):
    return 0x35000000 | ((((t - pc) >> 2) & 0x7ffff) << 5) | rt


def adrp(pc, target, rd):
    off = (target >> 12) - (pc >> 12)
    imm = off & 0x1fffff
    return 0x90000000 | ((imm & 3) << 29) | ((imm >> 2) << 5) | rd


def add_imm(rd, rn, imm):
    return 0x91000000 | (imm << 10) | (rn << 5) | rd


EQ, NE = 0, 1


def build():
    w = {}
    # __malloc_lock: x9 = &mutex, x10 = me; then the cave
    w[LOCK + 0] = adrp(LOCK, MUTEX, 9)
    w[LOCK + 4] = add_imm(9, 9, MUTEX & 0xfff)
    w[LOCK + 8] = 0xd53bd06a              # mrs x10, tpidrro_el0
    w[LOCK + 12] = b(LOCK + 12, CAVE_A)
    for i in range(4, 8):
        w[LOCK + 4 * i] = 0               # keep padding as udf #0
    a = CAVE_A
    retry, store, busy = a, a + 28, a + 40
    w[a + 0] = 0xc85ffd2b                 # ldaxr x11, [x9]
    w[a + 4] = 0xaa0a03ec                 # mov x12, x10
    w[a + 8] = cbz(a + 8, store, 11)      # free -> take it
    w[a + 12] = 0x927ced6d                # and x13, x11, #~0xf
    w[a + 16] = 0xeb0a01bf                # cmp x13, x10
    w[a + 20] = bcond(a + 20, busy, NE)   # someone else owns it
    w[a + 24] = 0x9100056c                # add x12, x11, #1  (nested)
    w[a + 28] = 0xc80d7d2c                # stxr w13, x12, [x9]
    w[a + 32] = cbnzw(a + 32, retry, 13)
    w[a + 36] = 0xd65f03c0                # ret
    w[a + 40] = 0xd5033f5f                # clrex
    w[a + 44] = 0xd2820000                # mov x0, #0x1000 (ns)
    w[a + 48] = 0xd4000161                # svc #0xb  (svcSleepThread)
    w[a + 52] = b(a + 52, LOCK)           # recompute everything and retry
    # __malloc_unlock
    u = UNLOCK
    w[u + 0] = adrp(u, MUTEX, 9)
    w[u + 4] = add_imm(9, 9, MUTEX & 0xfff)
    w[u + 8] = 0xf940012a                 # ldr x10, [x9]
    w[u + 12] = 0xf2400d5f                # tst x10, #0xf
    w[u + 16] = bcond(u + 16, CAVE_R, EQ) # depth 0 -> release
    w[u + 20] = 0xd100054a                # sub x10, x10, #1
    w[u + 24] = 0xf900012a                # str x10, [x9]
    w[u + 28] = 0xd65f03c0                # ret
    w[CAVE_R + 0] = 0xc89ffd3f            # stlr xzr, [x9]
    w[CAVE_R + 4] = 0xd65f03c0            # ret
    if COUNT:
        c = CAVE_R + 8
        w[a + 40] = b(a + 40, c)
        for k in (44, 48, 52):
            w.pop(a + k)
        w[c + 0] = 0xd5033f5f             # clrex
        w[c + 4] = adrp(c + 4, COUNTER, 11)
        w[c + 8] = 0xf947f96c             # ldr x12, [x11, #0xff0]
        w[c + 12] = 0x9100058c            # add x12, x12, #1
        w[c + 16] = 0xf907f96c            # str x12, [x11, #0xff0]
        w[c + 20] = 0xd2820000            # mov x0, #0x1000
        w[c + 24] = 0xd4000161            # svc #0xb
        w[c + 28] = b(c + 28, LOCK)
    return w


EXPECT_ASM = [
    'adrp x9, #0x3db000', 'add x9, x9, #0x88', 'mrs x10, tpidrro_el0', 'b #0x208044',
    'ldaxr x11, [x9]', 'mov x12, x10', 'cbz x11, #0x208060', 'and x13, x11, #0xfffffffffffffff0', 'cmp x13, x10',
    'b.ne #0x20806c', 'add x12, x11, #1', 'stxr w13, x12, [x9]', 'cbnz w13, #0x208044', 'ret', 'clrex',
    'mov x0, #0x1000', 'svc #0xb', 'b #0x203de0',
    'adrp x9, #0x3db000', 'add x9, x9, #0x88', 'ldr x10, [x9]', 'tst x10, #0xf', 'b.eq #0x20bf48', 'sub x10, x10, #1',
    'str x10, [x9]', 'ret', 'stlr xzr, [x9]', 'ret']


def main():
    original = SOURCE.read_bytes()
    src_sha = hashlib.sha256(original).hexdigest()
    assert src_sha.startswith(EXPECTED), src_sha
    segments = decode(original)
    old = segments[0][1]
    text = bytearray(old)
    dis = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    asm = lambda buf, off: (lambda i: f'{i.mnemonic} {i.op_str}'.strip())(next(dis.disasm(bytes(buf[off:off + 4]), off)))
    # source checks: the two lock wrappers, the no-op lock stubs they reach, and empty caves
    assert [asm(old, LOCK + i) for i in (0, 4, 8)] == ['adrp x0, #0x3db000', 'add x0, x0, #0x88', 'b #0x21ac80']
    assert [asm(old, UNLOCK + i) for i in (0, 4, 8)] == ['adrp x0, #0x3db000', 'add x0, x0, #0x88', 'b #0x21aca0']
    assert [asm(old, 0x21ac80 + i) for i in range(0, 20, 4)] == ['adrp x1, #0x2c1000', 'ldr x1, [x1, #0xf10]',
                                                                 'cbz x1, #0x21ac90', 'nop', 'ret']
    for lo, n in ((LOCK + 12, 5), (UNLOCK + 12, 5), (CAVE_A, 15), (CAVE_R, 14)):
        assert old[lo:lo + 4 * n] == bytes(4 * n), hex(lo)
    words = build()
    for off, val in words.items():
        struct.pack_into('<I', text, off, val)
    expect = EXPECT_ASM
    if COUNT:
        expect = EXPECT_ASM[:14] + ['b #0x20bf50'] + EXPECT_ASM[18:] + [
            'clrex', 'adrp x11, #0x3d8000', 'ldr x12, [x11, #0xff0]', 'add x12, x12, #1', 'str x12, [x11, #0xff0]',
            'mov x0, #0x1000', 'svc #0xb', 'b #0x203de0']
    got = [asm(text, o) for o in list(range(LOCK, LOCK + 16, 4)) + list(range(CAVE_A, CAVE_A + (44 if COUNT else 56), 4)) +
           list(range(UNLOCK, UNLOCK + 32, 4)) + list(range(CAVE_R, CAVE_R + (40 if COUNT else 8), 4))]
    assert got == expect, '\n'.join(f'{g!r} != {e!r}' for g, e in zip(got, expect) if g != e)
    changed = [i for i in range(0, len(old), 4) if text[i:i + 4] != old[i:i + 4]]
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
    assert not dest.exists(), 'already built'
    dest.write_bytes(output)
    (OUT / 'malloc-lock.asm').write_text('\n'.join(expect) + '\n')
    report = dict(status='candidate', source_sha256=src_sha, candidate_sha256=hashlib.sha256(output).hexdigest(),
                  mutex=hex(MUTEX), changed_words=[hex(c) for c in changed],
                  note='recursive spinlock in __malloc_lock/__malloc_unlock; heap layout unchanged from native-heap-110')
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
