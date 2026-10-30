#!/usr/bin/env python3
"""Export the local game containers using a project-local hactool build.

Reads existing Ryujinx keys locally; never prints keys or modifies emulator data.
Run stages in order: containers, metadata, export, verify.
"""
import json
import hashlib
import os
from pathlib import Path
import re
import subprocess
import struct
import sys
from collections import Counter

ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / '.tools/hactool/hactool'
OUT = ROOT / 'extracted'
WORK = ROOT / '.work/extraction'
KEYDIR = Path.home() / 'Library/Application Support/Ryujinx/system'
ENV = dict(os.environ, TOTK_MOD_KEY_DIR=str(KEYDIR))


def run(label, args):
    log = WORK / 'logs' / f'{label}.log'
    log.parent.mkdir(parents=True, exist_ok=True)
    print(label, flush=True)
    with log.open('w') as f:
        proc = subprocess.run([str(TOOL), '--suppresskeys', '--disablekeywarns',
                               *map(str, args)], env=ENV, stdout=f,
                              stderr=subprocess.STDOUT)
    text = log.read_text(errors='replace')
    if proc.returncode:
        raise RuntimeError(f'{label} failed with exit code {proc.returncode}; see {log}')
    return text


def metadata(path):
    text = run(f'info-{path.stem}', ['-i', '-t', 'nca', path])
    result = {'path': str(path.relative_to(ROOT)), 'bytes': path.stat().st_size}
    for label, field in [('Title ID', 'title_id'), ('Content Type', 'content_type'),
                         ('Encryption Type', 'encryption_type')]:
        match = re.search(r'^' + re.escape(label) + r':\s*(.+)$', text, re.M)
        if match:
            result[field] = match[1].strip()
    if 'title_id' not in result or 'content_type' not in result:
        raise RuntimeError(f'NCA metadata could not be decrypted: {path.name}')
    return result


def containers():
    sources = {
        'mk8dx': Path(os.environ.get('MK8DX_XCI', ROOT / 'mk8dx.xci')),        # your own dump
        'totk-base': Path(os.environ.get('TOTK_XCI', ROOT / 'totk.xci')),     # your own dump
    }
    update_config = (Path.home() / 'Library/Application Support/Ryujinx/games/'
                     '0100f2c0115b6000/updates.json')
    sources['totk-update'] = Path(json.loads(update_config.read_text())['selected'])
    if not sources['totk-update'].is_file():
        raise RuntimeError('The selected TOTK update is unavailable')
    manifest = {}
    for label, path in sources.items():
        dest = WORK / label
        marker = dest / '.container-complete.json'
        source = {'path': str(path), 'bytes': path.stat().st_size,
                  'mtime_ns': path.stat().st_mtime_ns}
        if marker.exists():
            if json.loads(marker.read_text()) != source:
                raise RuntimeError(f'Source changed; choose a new output directory for {label}')
            print(f'{label}: container already exported', flush=True)
        else:
            if dest.exists() and any(dest.iterdir()):
                raise RuntimeError(f'Refusing to overwrite incomplete export {dest}')
            dest.mkdir(parents=True, exist_ok=True)
            args = ['-x', '-t', 'xci', f'--securedir={dest}', path] if path.suffix == '.xci' else [
                '-x', '-t', 'pfs0', f'--outdir={dest}', path]
            run(f'container-{label}', args)
            if not list(dest.glob('*.nca')):
                raise RuntimeError(f'No NCA files exported for {label}')
            marker.write_text(json.dumps(source, indent=2) + '\n')
        manifest[label] = {'source': source,
                           'contents': [metadata(p) for p in sorted(dest.glob('*.nca'))]}
    (WORK / 'containers.json').write_text(json.dumps(manifest, indent=2) + '\n')
    for label, item in manifest.items():
        print(label, json.dumps(item['contents'], indent=2), flush=True)


def inspect_metadata():
    manifest = json.loads((WORK / 'containers.json').read_text())
    result = {}
    for label, item in manifest.items():
        records = []
        for nca in item['contents']:
            path = ROOT / nca['path']
            if nca['content_type'] == 'Meta':
                dest = WORK / 'metadata' / path.stem
                dest.mkdir(parents=True, exist_ok=True)
                run(f'meta-{path.stem}', ['-x', '-y', f'--section0dir={dest}', path])
                cnmts = list(dest.glob('*.cnmt'))
                if len(cnmts) != 1:
                    raise RuntimeError(f'Expected one CNMT in {dest}')
                data = cnmts[0].read_bytes()
                tid, version = struct.unpack_from('<QI', data)
                ext_size, count = struct.unpack_from('<HH', data, 0xe)
                assert len(data) >= 0x20 + ext_size + count * 0x38
                entries = []
                for i in range(count):
                    rec = data[0x20+ext_size+i*0x38:0x20+ext_size+(i+1)*0x38]
                    content_id = rec[0x20:0x30].hex()
                    file = path.parent / f'{content_id}.nca'
                    size = int.from_bytes(rec[0x30:0x35], 'little')
                    present = file.is_file() and file.stat().st_size == size
                    if not present and rec[0x36] != 6:
                        raise RuntimeError(f'CNMT content missing or wrong size: {file.name}')
                    entries.append({'content_id': content_id, 'sha256': rec[:32].hex(),
                                    'size': size, 'type': rec[0x36], 'id_offset': rec[0x37],
                                    'present': present, 'path': str(file.relative_to(ROOT))})
                records.append({'title_id': f'{tid:016x}', 'version': version,
                                'meta_type': data[0xc], 'contents': entries})
            elif nca['content_type'] == 'Control':
                dest = WORK / 'control' / path.stem
                dest.mkdir(parents=True, exist_ok=True)
                run(f'control-{path.stem}', ['-x', '-y', f'--romfsdir={dest}', path])
                data = (dest / 'control.nacp').read_bytes()
                nca['display_version'] = data[0x3060:0x3070].split(b'\0', 1)[0].decode()
                nca['application_name'] = data[:0x200].split(b'\0', 1)[0].decode()
                nca['control_nacp'] = str((dest / 'control.nacp').relative_to(ROOT))
        result[label] = {'source': item['source'], 'content_metadata': records,
                         'controls': [n for n in item['contents'] if n['content_type'] == 'Control']}
    (WORK / 'metadata.json').write_text(json.dumps(result, indent=2) + '\n')
    for label, item in result.items():
        print(label, 'metadata:', [(r['meta_type'], r['version']) for r in item['content_metadata']],
              'control versions:', [(r['path'], r['display_version']) for r in item['controls']], flush=True)


def export_games():
    metadata = json.loads((WORK / 'metadata.json').read_text())

    def one_record(label, kind):
        matches = [r for r in metadata[label]['content_metadata'] if r['meta_type'] == kind]
        if len(matches) != 1:
            raise RuntimeError(f'Ambiguous metadata selection: {label}, {kind}')
        return matches[0]

    def one_content(record, kind):
        matches = [r for r in record['contents'] if r['type'] == kind and r['id_offset'] == 0]
        if len(matches) != 1:
            raise RuntimeError(f'Ambiguous content selection: {record["title_id"]}, {kind}')
        return matches[0]

    plans = [
        ('mk8dx', '1.7.1', one_record('mk8dx', 0x80), one_record('mk8dx', 0x81), 'mk8dx'),
        ('totk', '1.1.0', one_record('totk-base', 0x80), one_record('totk-update', 0x81), 'totk-update'),
    ]
    for label, expected_version, base_meta, patch_meta, control_source in plans:
        base = one_content(base_meta, 1)
        patch = one_content(patch_meta, 1)
        control = one_content(patch_meta, 3)
        control_info = next(n for n in metadata[control_source]['controls'] if n['path'] == control['path'])
        if control_info['display_version'] != expected_version:
            raise RuntimeError(f'Unexpected version for {label}: {control_info["display_version"]}')
        dest = OUT / label
        complete = dest / 'extraction.json'
        if complete.exists():
            print(f'{label}: completed export already exists; leaving it unchanged', flush=True)
            continue
        if dest.exists() and any(dest.iterdir()):
            raise RuntimeError(f'Refusing to overwrite incomplete export: {dest}')
        verified = []
        for content in [base, patch, control]:
            path = ROOT / content['path']
            print(f'{label}: checking SHA-256 of {path.name}', flush=True)
            with path.open('rb') as f:
                digest = hashlib.file_digest(f, 'sha256').hexdigest()
            if digest != content['sha256']:
                raise RuntimeError(f'CNMT SHA-256 mismatch for {path.name}')
            verified.append({'path': content['path'], 'sha256': digest})
        for folder in ['romfs', 'exefs']:
            (dest / folder).mkdir(parents=True, exist_ok=True)
        text = run(f'export-{label}', ['-x', '-y', f'--basenca={ROOT / base["path"]}',
                                     f'--romfsdir={dest / "romfs"}',
                                     f'--exefsdir={dest / "exefs"}', ROOT / patch['path']])
        issues = [line.strip() for line in text.splitlines()
                  if re.search(r'\b(?:FAIL|Failed|Unable|Error):?\b', line)]
        if issues:
            raise RuntimeError(f'{label}: extractor reported an error; see export log')
        main = dest / 'exefs/main'
        with main.open('rb') as f:
            header = f.read(0x100)
        if header[:4] != b'NSO0' or not (dest / 'exefs/main.npdm').is_file():
            raise RuntimeError(f'{label}: invalid ExeFS export')
        files = sorted(p for p in (dest / 'romfs').rglob('*') if p.is_file())
        if not files:
            raise RuntimeError(f'{label}: empty RomFS export')
        report = {
            'game': control_info['application_name'], 'display_version': expected_version,
            'title_id': base_meta['title_id'], 'patch_version': patch_meta['version'],
            'main_build_id': header[0x40:0x60].hex().upper(),
            'main_sha256': hashlib.sha256(main.read_bytes()).hexdigest(),
            'romfs_files': len(files), 'romfs_bytes': sum(p.stat().st_size for p in files),
            'exefs_files': sorted(p.name for p in (dest / 'exefs').iterdir() if p.is_file()),
            'verified_content': verified,
            'verification': 'Selected base program, update program, and update control match CNMT SHA-256. Update NCA section verification ran with no FAIL/error lines. ExeFS NSO header and RomFS file inventory checked.',
            'extractor': {'project': 'https://github.com/SciresM/hactool',
                          'commit': '1d64a83450e025622f3468c28fc4164dad2c5ef6',
                          'local_changes': ['TOTK_MOD_KEY_DIR reads existing Ryujinx key directory',
                                            'Ignore identical duplicate title-key entries']},
        }
        complete.write_text(json.dumps(report, indent=2) + '\n')
        print(json.dumps(report, indent=2), flush=True)


def verify_exports():
    for label in ['mk8dx', 'totk']:
        root = OUT / label
        report = json.loads((root / 'extraction.json').read_text())
        files = sorted(p for p in (root / 'romfs').rglob('*') if p.is_file() and p.name != '.DS_Store')
        assert len(files) == report['romfs_files']
        assert sum(p.stat().st_size for p in files) == report['romfs_bytes']
        prefix = f'Saving {root / "romfs"}/'
        with (WORK / 'logs' / f'export-{label}.log').open() as f:
            saved_paths = {line.rstrip()[len(prefix):-3] for line in f if line.startswith(prefix)}
        assert saved_paths == {str(p.relative_to(root / 'romfs')) for p in files}
        with (root / 'romfs-inventory.tsv').open('w') as f:
            f.write('path\tbytes\n')
            for p in files:
                f.write(f'{p.relative_to(root / "romfs")}\t{p.stat().st_size}\n')
        exefs = []
        for p in sorted((root / 'exefs').iterdir()):
            if not p.is_file():
                continue
            with p.open('rb') as f:
                header = f.read(0x100)
            item = {'name': p.name, 'bytes': p.stat().st_size,
                    'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
            if header[:4] == b'NSO0':
                text = run(f'verify-{label}-{p.name}', ['-t', 'nso', '-y', p])
                if 'FAIL' in text or 'Error:' in text or 'Failed' in text:
                    raise RuntimeError(f'NSO verification failed for {p}')
                flags = int.from_bytes(header[0xc:0x10], 'little')
                expected = ((flags >> 3) & 7).bit_count()
                if text.count('(GOOD)') != expected:
                    raise RuntimeError(f'Unexpected NSO verification coverage for {p}')
                item['build_id'] = header[0x40:0x60].hex().upper()
                item['verified_segments'] = expected
            exefs.append(item)
        report['independent_export_validation'] = {
            'exefs': exefs,
            'romfs_extensions': dict(Counter(p.suffix.lower() for p in files).most_common()),
            'romfs_inventory': str((root / 'romfs-inventory.tsv').relative_to(ROOT)),
            'status': 'File paths/counts/sizes match extraction (ignoring Finder .DS_Store files); every NSO decompresses and all enabled segment hashes pass.',
        }
        (root / 'extraction.json').write_text(json.dumps(report, indent=2) + '\n')
        print(label, report['display_version'], 'verified:', len(files), 'RomFS files;', len(exefs), 'ExeFS files', flush=True)


if __name__ == '__main__':
    WORK.mkdir(parents=True, exist_ok=True)
    stage = sys.argv[1] if len(sys.argv) > 1 else 'containers'
    if stage == 'containers':
        containers()
    elif stage == 'metadata':
        inspect_metadata()
    elif stage == 'export':
        export_games()
    elif stage == 'verify':
        verify_exports()
    else:
        raise SystemExit('Expected containers, metadata, export, or verify')
