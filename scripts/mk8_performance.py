#!/usr/bin/env python3
"""Read the supplied MK8DX PERF tables without changing game resources.

All numbers come from the local file. Column interpretations are community
documentation, not recovered movement equations or a claim about time units.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'extracted/mk8dx/romfs/Common/Mush/Performance.bin'
STATS = ['weight', 'acceleration', 'on_road_traction', 'off_road_traction',
         'mini_turbo', 'speed_ground', 'speed_water', 'speed_antigravity',
         'speed_air', 'handling_ground', 'handling_water',
         'handling_antigravity', 'handling_air']
WIDTHS = dict(PRWG=3, PRAC=2, PRON=1, PROF=18, PRMT=12,
              PRSL=2, PRSW=2, PRSA=2, PRSG=1,
              PRTL=3, PRTW=3, PRTA=3, PRTG=2,
              PTBD=13, PTDV=13, PTTR=13, PTWG=13)
TABLE_STAT = dict(PRWG=0, PRAC=1, PRON=2, PROF=3, PRMT=4,
                  PRSL=5, PRSW=6, PRSA=7, PRSG=8,
                  PRTL=9, PRTW=10, PRTA=11, PRTG=12)
DOCUMENTATION = [
    'https://mk8.tockdom.com/wiki/BIN_(File_Format)',
    'https://mk8.tockdom.com/wiki/Performance.bin',
]


def record_format(tag: str, width: int) -> str:
    if tag.startswith('PT'):
        return '<' + 'i' * width
    if tag == 'PRMT':
        return '<iffiffifffff'
    return '<' + 'f' * width


def read_performance(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 16 or data[:4] != b'FREP':
        raise ValueError('Expected a little-endian MK8DX PERF file')
    declared_size, count, header_size, version = struct.unpack_from('<IHHI', data, 4)
    if declared_size != len(data) or version != 1000:
        raise ValueError('Unexpected PERF size or version')
    if not count or header_size != 16 + 4 * count or header_size > len(data):
        raise ValueError('Invalid PERF section directory')
    starts = [header_size + offset for offset in struct.unpack_from('<' + 'I' * count, data, 16)]
    if starts[0] != header_size or starts != sorted(set(starts)):
        raise ValueError('Invalid or overlapping PERF offsets')
    tables = {}
    rebuilt = bytearray(data[:header_size])
    for start, end in zip(starts, starts[1:] + [len(data)]):
        if start % 4 or end - start < 16:
            raise ValueError('Invalid PERF section bounds')
        magic, rows, repeat, reserved, parameter = struct.unpack_from('<4sHHII', data, start)
        tag = magic[::-1].decode('ascii')
        if tag not in WIDTHS or tag in tables or repeat != 1:
            raise ValueError(f'Unsupported or repeated PERF table: {tag}')
        width = WIDTHS[tag]
        if rows == 0 or end - start - 16 != rows * width * 4:
            raise ValueError(f'Unexpected record width in {tag}')
        fmt = record_format(tag, width)
        values = [list(struct.unpack_from(fmt, data, start + 16 + row * width * 4)) for row in range(rows)]
        rebuilt += data[start:start + 16]
        for row in values:
            rebuilt += struct.pack(fmt, *row)
        tables[tag] = {'offset': start, 'records': rows, 'fields_per_record': width,
                       'repeat': repeat, 'reserved': reserved, 'parameter': parameter,
                       'values': values}
    if set(tables) != set(WIDTHS) or bytes(rebuilt) != data:
        raise ValueError('Decoded records do not reproduce the complete source file')
    return {
        'source': str(path.resolve()), 'source_bytes': len(data),
        'source_sha256': hashlib.sha256(data).hexdigest(),
        'format': 'MK8DX little-endian PERF version 1000',
        'byte_roundtrip': 'All headers and typed records reconstruct the source byte for byte',
        'interpretation_sources': DOCUMENTATION,
        'limits': ['No movement equation or physical unit is inferred from table values.',
                   'PROF has 18 columns in this build; preserve their raw indices.',
                   'Part/driver names for a general selection require a separately verified ID mapping.'],
        'tables': tables,
    }


def make_reference(parsed: dict) -> dict:
    tables = parsed['tables']
    # Row-zero ordering is documented for Mario, standard body/tires and Super
    # Glider. The raw row indices remain explicit to avoid hiding that dependency.
    parts = [('PTDV', 'Mario'), ('PTBD', 'Standard Kart'),
             ('PTTR', 'Standard Tires'), ('PTWG', 'Super Glider')]
    rows = [{'table': tag, 'row': 0, 'documented_name': name,
             'points': tables[tag]['values'][0]} for tag, name in parts]
    points = [sum(row['points'][i] for row in rows) for i in range(len(STATS))]
    lookup = {}
    for tag, index in TABLE_STAT.items():
        row_index = points[index]
        if not 0 <= row_index < tables[tag]['records']:
            raise ValueError(f'Invalid combined stat index for {tag}: {row_index}')
        lookup[tag] = {'stat': STATS[index], 'row': row_index,
                       'raw_values': tables[tag]['values'][row_index]}
    return {
        'name': 'Mario / Standard Kart / Standard Tires / Super Glider',
        'source_sha256': parsed['source_sha256'], 'selection': rows,
        'combined_points': dict(zip(STATS, points)), 'lookup': lookup,
        'provenance': 'Raw rows and sums read from the supplied MK8DX 1.7.1 Performance.bin.',
        'interpretation': 'Names and point-column ordering follow the linked community documentation.',
        'limits': ['This is a numerical reference for a prototype, not a recovered physics implementation.',
                   'Native time base, world scale, acceleration integration, drift-charge accumulation,',
                   'braking, terrain contact, and boost state transitions remain to be established.',
                   'Link driving in TOTK does not imply a Mario Kart driver-weight mapping.'],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=SOURCE)
    parser.add_argument('--out', type=Path, default=ROOT / 'research/handling')
    args = parser.parse_args()
    parsed = read_performance(args.source)
    profile = make_reference(parsed)
    args.out.mkdir(parents=True, exist_ok=True)
    for name, content in [('performance_tables.json', parsed), ('standard_reference.json', profile)]:
        (args.out / name).write_text(json.dumps(content, indent=2, allow_nan=False) + '\n')
    with (args.out / 'performance_tables.tsv').open('w') as f:
        f.write('table\trow\tfield\tvalue\n')
        for tag, table in parsed['tables'].items():
            for row, values in enumerate(table['values']):
                for field, value in enumerate(values):
                    f.write(f'{tag}\t{row}\t{field}\t{value}\n')
    print(f'Decoded {len(parsed["tables"])} tables; exact byte roundtrip passed.')
    print('Reference points:', profile['combined_points'])
    print('Ground speed raw:', profile['lookup']['PRSL'])
    print('Ground handling raw:', profile['lookup']['PRTL'])
    print('Boost raw:', profile['lookup']['PRMT'])


if __name__ == '__main__':
    main()
