#!/usr/bin/env python3
"""Install the local Kart Lab runtime as a separate Ryujinx mod; never overwrite.

Without --apply this only prints the proposed destinations. A receipt records
every installed file and its SHA-256. Existing emulator settings are untouched.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / 'runtime/dist/KartLab-110'
BASE = Path.home() / 'Library/Application Support/Ryujinx'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    copies = [
        (PACKAGE / 'mod', BASE / 'mods/contents/0100f2c0115b6000/KartLab_110'),
        (PACKAGE / 'switch-sdcard/totk_lotuskit', BASE / 'sdcard/totk_lotuskit'),
    ]
    files = []
    for source, destination in copies:
        if not source.is_dir():
            raise SystemExit(f'Package directory missing: {source}')
        if destination.exists():
            raise SystemExit(f'Refusing to overwrite existing directory: {destination}')
        for p in sorted(source.rglob('*')):
            if p.is_file():
                files.append({'source': str(p), 'destination': str(destination / p.relative_to(source)),
                              'bytes': p.stat().st_size,
                              'sha256': hashlib.sha256(p.read_bytes()).hexdigest()})
        print(f'{source} -> {destination}')
    print(f'{len(files)} files; {sum(f["bytes"] for f in files):,} bytes')
    if not args.apply:
        return
    for source, destination in copies:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(source, destination)
    for item in files:
        actual = hashlib.sha256(Path(item['destination']).read_bytes()).hexdigest()
        if actual != item['sha256']:
            raise RuntimeError(f'Installed file hash mismatch: {item["destination"]}')
    receipt = ROOT / 'research/ryujinx-install.json'
    receipt.parent.mkdir(parents=True, exist_ok=True)
    receipt.write_text(json.dumps({'files': files, 'status': 'installed and hash-verified',
                                   'settings_modified': False, 'network_server_autostart': False}, indent=2) + '\n')
    print(f'Installation verified; receipt: {receipt}')


if __name__ == '__main__':
    main()
