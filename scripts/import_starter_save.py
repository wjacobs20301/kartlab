#!/usr/bin/env python3
"""Back up the identified TOTK account save, then add an empty manual slot.

Run only after the game process has stopped. This refuses existing progress
files and preserves the emulator's account/save metadata and journal copies.
"""
import argparse
import fcntl
import hashlib
import json
from pathlib import Path
import shutil
import struct

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'saves/starter-great-sky-island/slot_00/progress.sav'
STORAGE = Path.home() / 'Library/Application Support/Ryujinx/bis/user/save'
TITLE = 0x0100F2C0115B6000


def main():
    raise SystemExit("Obsolete: the isolated progress.sav failed in-game recognition. Use the complete save in saves/no-intro-complete; see research/complete-starter-save-import.json. No files changed.")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    matches = []
    for p in STORAGE.iterdir():
        extra = p / 'ExtraData0'
        if extra.is_file():
            data = extra.read_bytes()
            if len(data) == 512 and struct.unpack_from('<Q', data)[0] == TITLE and data[0x20] == 1:
                matches.append(p)
    if len(matches) != 1:
        raise SystemExit('Expected one TOTK account save; refusing ambiguous destination')
    save = matches[0]
    destinations = [save / journal / 'slot_00/progress.sav' for journal in ['0', '1']]
    if any(p.exists() for p in destinations):
        raise SystemExit('A manual save already exists; refusing overwrite')
    data = SOURCE.read_bytes()
    expected = json.loads((SOURCE.parents[1] / 'source.json').read_text())['sha256']
    if hashlib.sha256(data).hexdigest() != expected:
        raise SystemExit('Downloaded starter save identity changed')
    print('Identified TOTK account save:', save)
    print('Will add:', [str(p) for p in destinations])
    backup = ROOT / '.work/backups/totk-before-starter-save'
    print('Backup:', backup)
    if not args.apply:
        return
    if backup.exists():
        raise SystemExit('Backup already exists; refusing to replace it')
    with (save / '.lock').open('rb') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit('TOTK save is open by another process; stop the game first')
        shutil.copytree(save, backup)
        for dest in destinations:
            dest.parent.mkdir(parents=True, exist_ok=True)
            with dest.open('xb') as f:
                f.write(data)
            assert hashlib.sha256(dest.read_bytes()).hexdigest() == expected
    receipt = {'source': str(SOURCE), 'sha256': expected,
               'destinations': [str(p) for p in destinations],
               'backup': str(backup), 'existing_progress_overwritten': False,
               'status': 'Imported and hash-verified; in-game load not yet tested'}
    (ROOT / 'research/starter-save-import.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print('Starter save imported; original container backed up.')


if __name__ == '__main__':
    main()
