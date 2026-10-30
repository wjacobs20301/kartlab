#!/usr/bin/env python3
"""Keep lotuskit::tas::Record::currentInput as the player's RAW controller input.

NinJoyNpadDevice_calcHook::Callback (text 0x19a60) copies the polled human input into
Record::currentInput, lets script playback mutate what the game sees, and then, only when the input
was mutated, copies the mutated state over Record::currentInput again (branch at 0x19ad8 ->
0x19af0). The kart controller needs to override what the game sees while driving (Mario Kart
controls: A gas, B brake, X exit, with B hidden from TOTK's native dismount) while still reading the
player's real buttons from Record::currentInput. This derivative replaces that one branch with NOP.
Game-side mutation, gyro handling and every other byte are unchanged.

Consequence: scripts can no longer observe their own injected input() through Record::currentInput
(the input display shows the human input too). The kart test diagnostics simulate the player instead.
"""
from pathlib import Path
import hashlib, json, struct
import lz4.block
from patch_lotuskit_spawn_init import decode, branch_target
ROOT = Path(__file__).resolve().parents[1]
import sys
sys.path.insert(0, str(ROOT / '.tools/kart-assets/python'))
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM
OUT = ROOT / 'runtime/candidates/raw-input-110'
SOURCE = ROOT / 'runtime/candidates/large-script-110/subsdk9'
EXPECTED = '3e22fadc6db15f650ea5bfbe9bed33be79d0259ecdb0150026c5a305425431e2'
SITE = 0x19ad8
NOP = 0xd503201f


def main():
    original = SOURCE.read_bytes()
    assert hashlib.sha256(original).hexdigest() == EXPECTED
    segments = decode(original)
    old = segments[0][1]
    text = bytearray(old)
    dis = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
    asm = lambda off: (lambda i: f'{i.mnemonic} {i.op_str}'.strip())(next(dis.disasm(bytes(text[off:off + 4]), off)))
    expect = {
        0x19a60: 'stp x29, x30, [sp, #-0x30]!',
        0x19a98: 'stp x2, x3, [x19]',            # first copy: human buttons/sticks -> currentInput
        0x19ac4: 'bl #0x5e210',                  # Playback::applyCurrentInput (mutates game input)
        0x19ac8: 'and w22, w0, #0xff',
        SITE: 'tbnz w22, #0, #0x19af0',          # if mutated: re-record mutated input  <- patched
        0x19adc: 'tbnz w0, #0, #0x19b04',        # gyro re-record (unchanged)
        0x19af0: 'ldp x2, x3, [x21, #0x60]',
        0x19af8: 'stp x2, x3, [x19]',
        0x19b00: 'tbz w0, #0, #0x19ae0',
    }
    for off, ins in expect.items():
        assert asm(off) == ins, (hex(off), asm(off))
    struct.pack_into('<I', text, SITE, NOP)
    changed = [i for i in range(0, len(old) & ~3, 4) if text[i:i + 4] != old[i:i + 4]]
    assert changed == [SITE], changed
    assert asm(SITE) == 'nop'
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
    assert output[0x3c:0x40] == original[0x3c:0x40]
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / 'subsdk9'
    assert not dest.exists()
    dest.write_bytes(output)
    (OUT / 'source.patch').write_text('''--- a/src/program/main.cpp
+++ b/src/program/main.cpp
@@ NinJoyNpadDevice_calcHook::Callback
         bool isInputMutate = lotuskit::tas::Playback::applyCurrentInput(state); // mutate input using current script settings (eg apply user passthrough)
         bool isGyroMutate = lotuskit::tas::Playback::applyCurrentGyro(state_gyro);
-        // inject mutated states back into record, so we can re-log final inputs during playback (eg simultaneously playback AS while flattening into nxtas recording)
-        // FIXME i think recording injected inputs lags+extends inputs a frame due to AS calc interaction with Framework draw/calc frame boundary?
-        if (isInputMutate) { lotuskit::tas::Record::applyCurrentInput(state); }
+        // KartLab: Record::currentInput stays the player's raw input so scripts can remap controls.
+        (void)isInputMutate;
         if (isGyroMutate)  { lotuskit::tas::Record::applyCurrentGyro(state_gyro); }
''')
    report = dict(status='Offline candidate pending runtime tests', source_sha256=EXPECTED,
                  candidate_sha256=hashlib.sha256(output).hexdigest(), patched_sites={hex(SITE): 'tbnz w22,#0,#0x19af0 -> nop'},
                  validation=['One original instruction changes; every other text byte identical',
                              'RO/data/BSS and layout unchanged', 'Segment hashes recomputed and re-decoded'],
                  effect='Record::currentInput (module+0x3d90b8) holds raw human input even while scripts mutate game input',
                  limits=['TAS recording/flattening of injected input no longer captures the injection',
                          'Scripts that read their own input() back through Record::currentInput must simulate instead'])
    (OUT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
