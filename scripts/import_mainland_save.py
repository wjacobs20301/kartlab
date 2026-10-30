#!/usr/bin/env python3
"""Back up the stopped TOTK account save and import the complete mainland slot."""
import argparse
import fcntl
import hashlib
import json
from pathlib import Path
import shutil
import struct

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'saves/mainland-starter'
STORAGE = Path.home() / 'Library/Application Support/Ryujinx/bis/user/save'
TITLE = 0x0100F2C0115B6000
REQUIRED = {'caption.sav', 'progress.sav', 'footprint.sav', 'direct_file_save_related.sav'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    metadata = json.loads((SOURCE / 'source.json').read_text())
    files = {Path(f['path']).name: f for f in metadata['files']}
    if set(files) != REQUIRED:
        raise SystemExit('A complete four-file slot is required')
    for name, info in files.items():
        if info['path'] != 'slot_00/' + name:
            raise SystemExit('Unexpected source path')
        data = (SOURCE / info['path']).read_bytes()
        if len(data) != info['bytes'] or hashlib.sha256(data).hexdigest() != info['sha256']:
            raise SystemExit('Downloaded save identity changed')
        if struct.unpack_from('<II', data) != (0x01020304, 0x0047e0f4):
            raise SystemExit('Unexpected save header')
    matches = []
    for entry in STORAGE.iterdir():
        extras = [entry / ('ExtraData' + str(i)) for i in [0, 1]]
        if not all(p.is_file() for p in extras):
            continue
        records = [p.read_bytes() for p in extras]
        if all(len(b) == 512 and struct.unpack_from('<Q', b)[0] == TITLE and b[0x20] == 1
               for b in records):
            matches.append(entry)
    if len(matches) != 1:
        raise SystemExit('Expected exactly one TOTK account save')
    target = matches[0]
    backup = ROOT / '.work/backups/totk-before-mainland-save'
    print('Target:', target)
    print('Backup:', backup)
    print('Replace only the four files in slot_00 of both directory journal branches.')
    if not args.apply:
        return
    if backup.exists():
        raise SystemExit('Backup already exists; refusing to replace it or reimport')
    copied = []
    with (target / '.lock').open('rb') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit('Save is in use; stop TOTK before import')
        shutil.copytree(target, backup)
        for branch in ['0', '1']:
            slot = target / branch / 'slot_00'
            if not slot.is_dir():
                raise SystemExit('Expected existing manual slot; backup preserved')
            for name, info in files.items():
                dest = slot / name
                shutil.copy2(SOURCE / info['path'], dest)
                assert hashlib.sha256(dest.read_bytes()).hexdigest() == info['sha256']
                copied.append(str(dest))
    receipt = {'source': str(SOURCE), 'target': str(target), 'backup': str(backup),
               'copied': copied, 'status': 'Imported and hash verified; in-game load pending',
               'preserved': 'Account metadata, album, cache, and other save slots'}
    (ROOT / 'research/mainland-save-import.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print('Mainland manual save imported; entire previous account save backed up.')


if __name__ == '__main__':
    main()
