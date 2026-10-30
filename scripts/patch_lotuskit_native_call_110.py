#!/usr/bin/env python3
"""Add a generic native-call script binding to the pinned LotusKit module.

Registers two AngelScript functions after registerPtr:
    u64   ptr_call (ptr_t fn, u64 a0, u64 a1, u64 a2, u64 a3, u64 a4, u64 a5, float f0, float f1, float f2, float f3)
    float ptr_callf(ptr_t fn, u64 a0, u64 a1, u64 a2, u64 a3, u64 a4, u64 a5, float f0, float f1, float f2, float f3)
Both point at one trampoline that shifts x1..x6 down to x0..x5 and tail-calls fn. AArch64 passes float arguments in
s0..s7 independently of integer registers, so f0..f3 arrive in s0..s3 untouched; the return value (x0 or s0) passes
straight back. This lets kart scripts call TOTK functions (effects, collision queries) by address.

Patch: the tail branch `b registerPtr` at text 0x41ecc (end of the register-all function) becomes `b reg_stub`.
reg_stub calls registerPtr(engine) and then registers both functions through the engine vtable (+0x58,
RegisterGlobalFunction) with an asSFuncPtr laid out exactly as LotusKit's own calls do: func at +0, zero to +0x1f,
flag 2 (global function) at +0x20. Code goes in the text alignment gap (after the large-script stub); the two
declaration strings go in the RO alignment gap inside RO's last page. One original instruction changes.
"""
from pathlib import Path
import hashlib, json, struct, sys
import lz4.block
from patch_lotuskit_spawn_init import decode, branch, branch_target
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/kart-assets/python'))
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
OUT = ROOT / 'runtime/candidates/native-call-110'
SOURCE = ROOT / 'runtime/candidates/raw-input-110/subsdk9'
EXPECTED = '10b63b32991595f57c584c40d417ab4605cdc67f3af4753ee0eb443d6b60e2bb'
SITE = 0x41ecc
REGISTER_PTR = 0x40c60
DECL_U = b'u64 ptr_call(ptr_t, u64, u64, u64, u64, u64, u64, float, float, float, float)\0'
DECL_F = b'float ptr_callf(ptr_t, u64, u64, u64, u64, u64, u64, float, float, float, float)\0'


def adr(pc, target, rd):
    off = target - pc
    assert -(1 << 20) <= off < (1 << 20)
    imm = off & 0x1fffff
    return 0x10000000 | ((imm & 3) << 29) | ((imm >> 2) << 5) | rd


def main():
    original = SOURCE.read_bytes()
    assert hashlib.sha256(original).hexdigest() == EXPECTED
    segments = decode(original)
    old_text = segments[0][1]
    old_ro = segments[1][1]
    ro_base = segments[1][0]
    data_base = segments[2][0]
    text = bytearray(old_text)
    ro = bytearray(old_ro)
    dis = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    asm = lambda buf, off: (lambda i: f'{i.mnemonic} {i.op_str}'.strip())(next(dis.disasm(bytes(buf[off:off + 4]), off)))
    for off, ins in {0x41ec0: 'mov x0, x19', 0x41ec4: 'ldr x19, [sp, #0x10]', 0x41ec8: 'ldp x29, x30, [sp], #0x50',
                     SITE: 'b #0x40c60', 0x40cb0: 'ldr x6, [x3, #0x58]', 0x40cb8: 'str x5, [sp, #0x38]',
                     0x40cc0: 'strb w22, [sp, #0x58]', 0x40cc4: 'strb wzr, [x20, #0x10]'}.items():
        assert asm(text, off) == ins, (hex(off), asm(text, off))
    # --- RO strings (inside RO's last page, before data) ---
    ro_start = (len(ro) + 7) & ~7
    ro.extend(b'\0' * (ro_start - len(ro)))
    decl_u = ro_base + len(ro); ro.extend(DECL_U)
    decl_f = ro_base + len(ro); ro.extend(DECL_F)
    assert ro_base + len(ro) <= ((ro_base + len(old_ro) + 0xfff) & ~0xfff) <= data_base
    # --- text stub ---
    start = (len(text) + 3) & ~3
    text.extend(b'\0' * (start - len(text)))
    words = []
    pc = lambda: start + 4 * len(words)
    W = lambda w: words.append(w)
    W(0xa9bb7bfd)            # stp x29, x30, [sp, #-0x50]!
    W(0x910003fd)            # mov x29, sp
    W(0xa90153f3)            # stp x19, x20, [sp, #0x10]
    W(0xaa0003f3)            # mov x19, x0
    W(branch(pc(), REGISTER_PTR) | 0x80000000)   # bl registerPtr
    call_stub_slot = len(words); W(0)            # adr x20, call_stub (filled below)
    for decl in (decl_u, decl_f):
        W(0xf90013f4)        # str x20, [sp, #0x20]
        W(0xa902ffff)        # stp xzr, xzr, [sp, #0x28]
        W(0xa903ffff)        # stp xzr, xzr, [sp, #0x38]
        W(0x52800049)        # mov w9, #2
        W(0x390103e9)        # strb w9, [sp, #0x40]
        W(0xaa1303e0)        # mov x0, x19
        W(adr(pc(), decl, 1))  # adr x1, decl
        W(0x910083e2)        # add x2, sp, #0x20
        W(0x52800003)        # mov w3, #0
        W(0xd2800004)        # mov x4, #0
        W(0xf9400269)        # ldr x9, [x19]
        W(0xf9402d29)        # ldr x9, [x9, #0x58]
        W(0xd63f0120)        # blr x9
    W(0xa94153f3)            # ldp x19, x20, [sp, #0x10]
    W(0xa8c57bfd)            # ldp x29, x30, [sp], #0x50
    W(0xd65f03c0)            # ret
    call_stub = pc()
    for w in (0xaa0003f0, 0xaa0103e0, 0xaa0203e1, 0xaa0303e2, 0xaa0403e3, 0xaa0503e4, 0xaa0603e5, 0xd61f0200):
        W(w)                 # mov x16,x0; mov x0..x5,x1..x6; br x16
    words[call_stub_slot] = adr(start + 4 * call_stub_slot, call_stub, 20)
    text.extend(struct.pack('<%dI' % len(words), *words))
    assert len(text) <= ro_base, (hex(len(text)), hex(ro_base))
    struct.pack_into('<I', text, SITE, branch(SITE, start))
    # --- verification ---
    changed = [i for i in range(0, len(old_text) & ~3, 4) if text[i:i + 4] != old_text[i:i + 4]]
    assert changed == [SITE], changed
    assert ro[:len(old_ro)] == old_ro
    assert branch_target(SITE, struct.unpack_from('<I', text, SITE)[0]) == start
    listing = [f'{SITE:08x} b #0x40c60  ->  {asm(text, SITE)}', '# stub']
    expect = ['stp x29, x30, [sp, #-0x50]!', 'mov x29, sp', 'stp x19, x20, [sp, #0x10]', 'mov x19, x0', f'bl #{REGISTER_PTR:#x}',
              f'adr x20, #{call_stub:#x}']
    for decl in (decl_u, decl_f):
        expect += ['str x20, [sp, #0x20]', 'stp xzr, xzr, [sp, #0x28]', 'stp xzr, xzr, [sp, #0x38]', 'mov w9, #2',
                   'strb w9, [sp, #0x40]', 'mov x0, x19', f'adr x1, #{decl:#x}', 'add x2, sp, #0x20', 'mov w3, #0',
                   'mov x4, #0', 'ldr x9, [x19]', 'ldr x9, [x9, #0x58]', 'blr x9']
    expect += ['ldp x19, x20, [sp, #0x10]', 'ldp x29, x30, [sp], #0x50', 'ret', 'mov x16, x0', 'mov x0, x1', 'mov x1, x2',
               'mov x2, x3', 'mov x3, x4', 'mov x4, x5', 'mov x5, x6', 'br x16']
    got = [f'{i.mnemonic} {i.op_str}'.strip() for i in dis.disasm(bytes(text[start:]), start)]
    assert got == expect, list(zip(got, expect))
    for i in dis.disasm(bytes(text[start:]), start):
        listing.append(f'{i.address:08x} {i.bytes.hex()} {i.mnemonic} {i.op_str}')
    listing.append(f'# RO {decl_u:#x}: {DECL_U[:-1].decode()}')
    listing.append(f'# RO {decl_f:#x}: {DECL_F[:-1].decode()}')
    output = bytearray(original[:256])
    flags = struct.unpack_from('<I', output, 12)[0]
    output[64:96] = hashlib.sha256(original[64:96] + text).digest()
    for i, (address, payload) in enumerate(segments):
        if i == 0:
            payload = bytes(text)
        elif i == 1:
            payload = bytes(ro)
        packed = lz4.block.compress(payload, store_size=False, mode='high_compression', compression=12) if flags & (1 << i) else payload
        struct.pack_into('<III', output, 16 + i * 16, len(output), address, len(payload))
        struct.pack_into('<I', output, 96 + i * 4, len(packed))
        output[160 + i * 32:192 + i * 32] = hashlib.sha256(payload).digest()
        output.extend(packed)
    checked = decode(output)
    assert checked[0][1] == text and checked[1][1] == ro and checked[2:] == segments[2:]
    assert output[0x3c:0x40] == original[0x3c:0x40]
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / 'subsdk9'
    assert not dest.exists()
    dest.write_bytes(output)
    (OUT / 'native-call-verified.asm').write_text('\n'.join(listing) + '\n')
    report = dict(status='Offline candidate pending runtime tests', source_sha256=EXPECTED,
                  candidate_sha256=hashlib.sha256(output).hexdigest(), patched_site=hex(SITE), stub=hex(start),
                  stub_bytes=4 * len(words), ro_strings=[hex(decl_u), hex(decl_f)], declarations=[DECL_U[:-1].decode(), DECL_F[:-1].decode()],
                  validation=['One original instruction changes (tail branch to stub)', 'Stub disassembly matches expected listing exactly',
                              'Original RO bytes unchanged; strings appended inside RO last page', 'Segment hashes recomputed and re-decoded'],
                  limits=['Calls arbitrary native code: callers must pass valid addresses/arguments',
                          'Integer arguments limited to 6 and float arguments to 4; no struct-by-value'])
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
