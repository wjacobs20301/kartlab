#!/usr/bin/env python3
"""Prepare an offline, uninstalled trial fix for the pinned lotuskit 110 NSO.

The source patch value-initializes both CreateArg instances. This binary trial
only fixes createAndWatchPosRot, the function used by our kart test. Causation
of the invisible actor has not been established. Never patch a different build.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import lz4.block

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'runtime/dist/KartLab-110/mod/exefs/subsdk9'
OUT = ROOT / 'runtime/candidates/zero-create-arg'
EXPECTED = '47190218a43b6000d646fe98931151cbc83c8b773c11d3e85310ef8b3c5d0b13'
HOOK = 0x64bc8
ORIGINAL = 0x528000e1  # mov w1, #7


def decode(data):
    assert data[:4] == b'NSO0'
    flags = struct.unpack_from('<I', data, 12)[0]
    result = []
    for i in range(3):
        offset, address, size = struct.unpack_from('<III', data, 16 + i*16)
        packed = struct.unpack_from('<I', data, 96 + i*4)[0]
        raw = data[offset:offset + (packed if flags & (1 << i) else size)]
        if flags & (1 << i):
            raw = lz4.block.decompress(raw, uncompressed_size=size)
        assert len(raw) == size
        if flags & (1 << (i+3)):
            assert hashlib.sha256(raw).digest() == data[160+i*32:192+i*32]
        result.append((address, raw))
    return result


def branch(source, target):
    delta = target - source
    assert delta % 4 == 0 and -(1 << 27) <= delta < (1 << 27)
    return 0x14000000 | ((delta // 4) & 0x03ffffff)


def branch_target(source, instruction):
    assert instruction >> 26 == 5
    imm = instruction & 0x03ffffff
    if imm & 0x02000000:
        imm -= 1 << 26
    return source + 4*imm


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=SOURCE)
    parser.add_argument('--output', type=Path, default=OUT)
    args = parser.parse_args()
    original = args.source.read_bytes()
    assert hashlib.sha256(original).hexdigest() == EXPECTED
    segments = decode(original)
    assert segments[0][0] == 0
    text = bytearray(segments[0][1])
    assert struct.unpack_from('<I', text, HOOK)[0] == ORIGINAL
    stub_address = len(text)
    assert stub_address % 4 == 0 and stub_address + 16 <= segments[1][0]
    # CreateArg is at SP+0x90 here. Clear its +0x48..+0x57 option bytes,
    # retain the replaced MOV, and return to the next original instruction.
    stub = struct.pack('<IIII', 0xf9006fff, 0xf90073ff, ORIGINAL,
                       branch(stub_address+12, HOOK+4))
    jump = branch(HOOK, stub_address)
    struct.pack_into('<I', text, HOOK, jump)
    text.extend(stub)
    assert branch_target(HOOK, jump) == stub_address
    assert branch_target(stub_address+12, struct.unpack_from('<I', stub, 12)[0]) == HOOK+4
    assert bytes(text[:HOOK]) == segments[0][1][:HOOK]
    assert bytes(text[HOOK+4:stub_address]) == segments[0][1][HOOK+4:]
    header = bytearray(original[:256])
    new_build_id = hashlib.sha256(original[64:96] + bytes(text)).digest()
    header[64:96] = new_build_id
    output = bytearray(header)
    flags = struct.unpack_from('<I', header, 12)[0]
    for i, (address, raw) in enumerate(segments):
        if i == 0:
            raw = bytes(text)
        packed = lz4.block.compress(raw, store_size=False, mode='high_compression', compression=12) if flags & (1 << i) else raw
        struct.pack_into('<III', output, 16+i*16, len(output), address, len(raw))
        struct.pack_into('<I', output, 96+i*4, len(packed))
        output[160+i*32:192+i*32] = hashlib.sha256(raw).digest()
        output.extend(packed)
    verified = decode(output)
    assert verified[0][1] == bytes(text)
    assert verified[1:] == segments[1:]
    assert original[0x3c:0x40] == output[0x3c:0x40]  # BSS unchanged
    args.output.mkdir(parents=True, exist_ok=True)
    dest = args.output / 'subsdk9'
    if dest.exists():
        raise SystemExit('Candidate already exists; refusing replacement')
    dest.write_bytes(output)
    report = {'status': 'Offline candidate only; NOT installed or tested in game',
              'source_sha256': EXPECTED, 'candidate_sha256': hashlib.sha256(output).hexdigest(),
              'candidate_build_id': new_build_id.hex().upper(),
              'hook': hex(HOOK), 'stub': hex(stub_address), 'stub_hex': stub.hex(),
              'source_evidence': 'ev_1db4e4f5bba71d0e59fc94133843261936e0bf118eafbaa6ad9b6ac2a0e399c8',
              'validation': ['Original module hash pinned', 'All original and new NSO segment hashes pass',
                             'Only one original instruction changes; 16-byte stub appended within existing alignment gap',
                             'Both branch destinations checked', 'RO/data bytes, virtual addresses and BSS unchanged'],
              'limits': ['Possible spawn defect; not proven cause of invisible actor',
                         'Binary trial fixes createAndWatchPosRot only; source patch also covers createSimplePosRot',
                         'No hardware compatibility or gameplay success asserted']}
    (args.output / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
