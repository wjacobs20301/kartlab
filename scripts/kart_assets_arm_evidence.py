#!/usr/bin/env python3
"""Record scoped ARM32 byte disassembly without changing a shared REA target.

Ranges are deliberately explicit. Linear decoding includes literal pools, so
disassembled words in those pools are data, not evidence of executable paths.
Call and PIC-load candidates require inspection of the surrounding instructions.
"""
import argparse, hashlib, json, pathlib, sys
ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/kart-assets/python'))
from capstone import Cs, CS_ARCH_ARM, CS_MODE_ARM
from elftools.elf.elffile import ELFFile

RANGES = {
    'parts-reader': (0x796210, 0x796b44),
    'kart-combination': (0x2daf08, 0x2dbd00),
    'placement-getters': (0x14a7ec, 0x14ad68),
    'wheel-placement': (0x15a6dc, 0x15b050),
    'suspension-endpoint-transform': (0x15f6a4, 0x15f878),
    'wheel-mesh-transform': (0x16088c, 0x1609e4),
    'spring-settling': (0x15d2f0, 0x15d4d4),
    'wheel-model-update': (0x160bb4, 0x16105c),
}

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--out', type=pathlib.Path, default=ROOT/'research/placement/verified-scopes')
    a = p.parse_args(); a.out.mkdir(parents=True, exist_ok=True)
    elf = ROOT / '.work/native/mk8dx-main.elf'
    with elf.open('rb') as f:
        e = ELFFile(f)
        assert e['e_machine'] == 'EM_ARM'
        text = next(s.data() for s in e.iter_segments()
                    if s['p_type'] == 'PT_LOAD' and s['p_vaddr'] == 0)
    m = Cs(CS_ARCH_ARM, CS_MODE_ARM); m.skipdata = True
    report = dict(tool='Capstone 5.0.9 ARM mode', elf=str(elf.relative_to(ROOT)),
        elf_sha256=hashlib.sha256(elf.read_bytes()).hexdigest(),
        interpretation='Raw linear ARM decoding only; literal-pool words must not be interpreted as instructions. Not REA provider function analysis.', ranges={})
    for name, (start, end) in RANGES.items():
        raw = text[start:end]
        rows = [f'{x.address:08x}  {x.bytes.hex():8}  {x.mnemonic:11} {x.op_str}'
                for x in m.disasm(raw, start)]
        (a.out/(name+'.txt')).write_text('\n'.join(rows)+'\n')
        report['ranges'][name] = dict(start=hex(start), end_exclusive=hex(end),
            bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(),
            file=name+'.txt')
    (a.out/'manifest.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(dict(scopes=len(RANGES), output=str(a.out))))

if __name__ == '__main__': main()
