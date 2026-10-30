#!/usr/bin/env python3
"""Recover the exact flag-selected standard body/tire settings; no installation.

Semantic names from the Parts converter are checked against MK8DX 1.7.1 ARM
loads and flag tests. This does not pretend the suspension's runtime state is
already known. Addresses are module VAs in the verified ARM32 ELF carrier.
"""
from __future__ import annotations
import hashlib, json, pathlib, struct, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'.tools/kart-assets/python'))
from elftools.elf.elffile import ELFFile


def inspect(body=0):
    """Rows for one body (Parts.bin BODY row; tire 0). BDTR is [body][tire], TRBD is [tire][body]."""
    path = ROOT / 'extracted/mk8dx/romfs/Common/Mush/Parts.bin'
    data = path.read_bytes()
    assert data[:4] == b'STRP'
    size, count, header, version = struct.unpack_from('<IHHI', data, 4)
    assert size == len(data) and header == 16 + 4 * count and version == 1000
    starts = [header + x for x in struct.unpack_from('<' + str(count) + 'I', data, 16)]
    sections = {}
    for start, end in zip(starts, starts[1:] + [len(data)]):
        magic, rows, repeat, reserved, parameter = struct.unpack_from('<4sHHII', data, start)
        sections[magic[::-1].decode()] = dict(offset=start, end=end, rows=rows,
            repeat=repeat, reserved=reserved, parameter=parameter)

    def record(name, primary=0, secondary=0):
        sec = sections[name]
        length = (sec['end'] - sec['offset'] - 16) // (sec['rows'] * sec['repeat'])
        assert length * sec['rows'] * sec['repeat'] == sec['end'] - sec['offset'] - 16
        # Directory row count is the inner dimension; repeat is outer dimension.
        at = sec['offset'] + 16 + (primary * sec['rows'] + secondary) * length
        return data[at:at + length], dict(file_offset=hex(at), bytes=length,
            primary_index=primary, secondary_index=secondary)

    body_index = body
    body, bm = record('BODY', 0, body_index); tire, tm = record('TIRE')
    bdtr, dm = record('BDTR', body_index, 0); trbd, rm = record('TRBD', 0, body_index)
    assert [len(x) for x in (body, tire, bdtr, trbd)] == [320, 144, 200, 108]
    f = lambda b, o: struct.unpack_from('<f', b, o)[0]
    v = lambda b, o: list(struct.unpack_from('<3f', b, o))
    flags = struct.unpack_from('<I', bdtr, 8)[0]
    tflags = struct.unpack_from('<I', trbd, 8)[0]
    assert body_index != 0 or (flags == 0xefff and tflags == 15)
    native = ROOT/'.work/native/mk8dx-main.elf'
    with native.open('rb') as stream:
        elf = ELFFile(stream)
        segments = [(s['p_vaddr'], s.data()) for s in elf.iter_segments() if s['p_type'] == 'PT_LOAD']
    def native_read(address, count):
        return next(b[address-base:address-base+count] for base,b in segments
                    if base <= address and address+count <= base+len(b))
    front_strategies = struct.unpack('<4I', native_read(0xc2e72c, 16))
    back_strategies = struct.unpack('<4I', native_read(0xc2e73c, 16))
    assert front_strategies == (2,1,2,1) and back_strategies == (2,1,1,2)
    assert native_read(0xc5ceac, 12) == bytes(12)
    vehicle_type = struct.unpack_from('<H', body)[0]
    # 0x2db594..0x2db5f0: original front tire scale and TRBD-adjusted back scale.
    front_scale = [f(bdtr, 0), f(bdtr, 4), f(bdtr, 4)]
    back_scale = [front_scale[0] * f(trbd, 0), front_scale[1] * f(trbd, 4),
        front_scale[2] * f(trbd, 4)]
    def choose(bit, boff, doff):
        return v(body, boff) if flags & (1 << bit) else v(bdtr, doff)
    def scale(bit, boff, doff):
        b = body if flags & (1 << bit) else bdtr
        o = boff if b is body else doff
        return [f(b, o), f(b, o + 4), f(b, o + 4)]

    return dict(source=str(path.relative_to(ROOT)), sha256=hashlib.sha256(data).hexdigest(),
        input_game='MK8DX 1.7.1', indices=dict(body=0, tire=0),
        records=dict(BODY=bm, TIRE=tm, BDTR=dm, TRBD=rm),
        native_source=dict(elf=str(native.relative_to(ROOT)),
            sha256=hashlib.sha256(native.read_bytes()).hexdigest(),
            front_strategy_table=dict(address='0xc2e72c', values=front_strategies),
            back_strategy_table=dict(address='0xc2e73c', values=back_strategies),
            strategy_selection='0x7d05a0..0x7d05c8, equivalent refreshed in 0x7d0e4c..0x7d0e74'),
        bdtr_flags=hex(flags), trbd_flags=hex(tflags),
        native_combiner=dict(address='0x2daf08', selected_rows='0x2db3f0..0x2db594',
            scale='0x2db594..0x2db5f0', shafts='0x2db698..0x2db8ac',
            arm_overrides='0x2db8b0..0x2db9cc', tire_offsets='0x2dbb48..0x2dbcB4'),
        combined=dict(front_tire_scale=front_scale, back_tire_scale=back_scale,
            front_shaft_scale=scale(0, 0x90, 0xc),
            back_shaft_scale=scale(1, 0x98, 0x14),
            front_shaft_anchor=choose(2, 0xa0, 0x1c),
            back_shaft_anchor=choose(3, 0xc4, 0x40),
            front_tire_suspension_endpoint=choose(8, 0x110, 0x8c),
            back_tire_suspension_endpoint=choose(9, 0x11c, 0x98),
            front_arm_inverse_scale_x=f(tire, 0x24) if tflags & 1 else f(trbd, 0xc),
            back_arm_inverse_scale_x=f(tire, 0x48) if tflags & 2 else f(trbd, 0x30),
            body_height=f(tire, 4), spring_rate=f(tire, 8),
            tire_axial_offset=f(tire, 0xc), antigravity_axial_offset=f(tire, 0x10),
            tire_front_arm_flag=tire[0x20], tire_back_arm_flag=tire[0x21],
            body_vehicle_type=vehicle_type,
            front_suspension_strategy=front_strategies[vehicle_type],
            back_suspension_strategy=back_strategies[vehicle_type],
            normal_axial_directions=[[1., 0., 0.], [-1., 0., 0.]]),
        interpretation=dict(
            flag_correction='BDTR offset 8 is a bit field used by native tst instructions. The converter labels it TireAngle; treating 0xefff as an angle is wrong.',
            scale_boundary='Native code proves front tire scale 1 and back tire scale (1.4,1.3,1.3). These are source part settings before runtime scale, transform and suspension.',
            position_boundary='BODY final triplets initialize suspension endpoints. They are not established static mesh centers. Per-wheel runtime interpolation, body-height shift and axle offset must also be followed.',
            standard_axial_direction='The getter 0x14ac04/0x14ac98 tests derived strategy a5c/a60, NOT TIRE arm flag bytes. 0x7d05a0..0x7d05c8 maps body type 0 via tables 0xc2e72c/0xc2e73c to strategy 2. The strategy-2 path returns +/-X; strategy 1 instead reads global zero vector 0xc5ceac. Do not confuse the two fields.',
            external_parser='https://github.com/KillzXGaming/MK8-Parts-Bin-Converter/tree/446d4a2b5c1bd569b872c04f2db73a19c509b83e/PartsLibrary/PartObjects'),
        installed=False, model_candidate_written=False)


if __name__ == '__main__':
    result = inspect()
    out = ROOT / 'research/kart-source-placement.json'
    out.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result['combined'], indent=2))
