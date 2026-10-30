#!/usr/bin/env python3
"""Combine the tested-format kart visual with the pinned laboratory runtime."""
import hashlib
import json
from pathlib import Path
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'runtime/dist/KartLab-110'
VISUAL = ROOT / 'assets/native-cart-mod'
RUNTIME_FIX = ROOT / 'runtime/candidates/zero-create-arg'
DEST = ROOT / 'dist/KartLab-TOTK-1.1.0-prototype'


def main():
    if DEST.exists():
        raise SystemExit(f'Refusing to replace an existing package: {DEST}')
    validation = json.loads((VISUAL / 'validation.json').read_text())
    if not validation['independent_decoder_roundtrip']['byte_identical']:
        raise SystemExit('Kart candidate did not pass decoder validation')
    candidate = VISUAL / 'romfs/Model/SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc'
    if hashlib.sha256(candidate.read_bytes()).hexdigest() != validation['candidate_compressed_sha256']:
        raise SystemExit('Kart candidate hash mismatch')
    fix_validation = json.loads((RUNTIME_FIX / 'validation.json').read_text())
    if hashlib.sha256((SOURCE / 'mod/exefs/subsdk9').read_bytes()).hexdigest() != fix_validation['source_sha256']:
        raise SystemExit('Upstream runtime hash mismatch')
    if hashlib.sha256((RUNTIME_FIX / 'subsdk9').read_bytes()).hexdigest() != fix_validation['candidate_sha256']:
        raise SystemExit('Patched runtime hash mismatch')
    runtime_manifest = json.loads((SOURCE / 'manifest.json').read_text())
    for rel, expected in runtime_manifest['files_sha256'].items():
        if hashlib.sha256((SOURCE / rel).read_bytes()).hexdigest() != expected:
            raise SystemExit(f'Runtime staging hash mismatch: {rel}')
    shutil.copytree(SOURCE, DEST)
    shutil.copy2(SOURCE / 'mod/exefs/subsdk9', DEST / 'source/upstream-subsdk9')
    shutil.copy2(RUNTIME_FIX / 'subsdk9', DEST / 'mod/exefs/subsdk9')
    shutil.copy2(RUNTIME_FIX / 'source-fix.patch', DEST / 'source/spawn-fix.patch')
    shutil.copy2(RUNTIME_FIX / 'README.md', DEST / 'source/spawn-fix-README.md')
    (DEST / 'lab/tools').mkdir(exist_ok=True)
    shutil.copy2(ROOT / 'scripts/patch_lotuskit_spawn_init.py', DEST / 'lab/tools/patch_lotuskit_spawn_init.py')
    shutil.copytree(VISUAL / 'romfs', DEST / 'mod/romfs', dirs_exist_ok=True)
    notes = DEST / 'research'
    notes.mkdir()
    for source in [ROOT / 'research/kart-assets.md', ROOT / 'research/movement-code.md',
                   ROOT / 'research/handling/README.md', ROOT / 'research/handling/standard_reference.json',
                   ROOT / 'research/runtime-test-results.json', ROOT / 'research/native-pad-controller-test.json',
                   ROOT / 'research/zero-create-arg-runtime-test.json']:
        shutil.copy2(source, notes / ('handling-' + source.name if source.parent.name == 'handling' else source.name))
    shutil.copy2(VISUAL / 'validation.json', notes / 'kart-geometry-validation.json')
    shutil.copy2(RUNTIME_FIX / 'validation.json', notes / 'spawn-fix-validation.json')
    shutil.copy2(VISUAL / 'geometry-preview.png', DEST / 'geometry-preview.png')
    shutil.copy2(ROOT / 'runtime/README.md', DEST / 'runtime-guide.md')
    (DEST / 'README-FIRST.md').write_text('''# Kart Lab — TOTK 1.1.0 experimental prototype

This package combines the pinned lotuskit runtime with an actual Mario Kart standard-kart geometry replacement for TOTK's native Zonai cart. It is a development prototype. The kart retains TOTK's original materials and collision, and is not yet a separately selectable Mario Kart vehicle.

Copy `mod/exefs` and `mod/romfs` as described in runtime-guide.md, and copy `switch-sdcard` contents to the emulator/console SD-card root. This combined package includes the tested native spawn-initialization patch. Autorun registers local shortcuts without starting a network server or spawning automatically.

Near the current Lookout Landing test location, briefly press ZL+ZR+D-pad Right (PS4 L2+R2+Right), then release. Left stick drives/reverses and steers. B (PS4 Cross) exits; the test otherwise stops after 900 logical frames, approximately 30 seconds. Link stays at his starting position while the camera follows the kart. The kart spawns at a fixed nearby road position; this is not yet an anywhere-in-Hyrule controller. If slot 1 is occupied, briefly press ZL+ZR+Down to clear, release, then retry Right. Up separately spawns an uncontrolled cart. Clear does not delete actors.

In Ryujinx 1.3.3 / TOTK 1.1.0, imported model rendering, physical motion, native stick input and the following camera were observed. The full 900-frame session completed and restored the camera/Link controls. A seated rider, full Mario Kart physics, Mario colors, detailed wheels, drift/boost and characters remain unfinished. Native input still reaches Link; avoid loading/fast travel during the test. No Switch test has been performed. Upstream describes its 1.1.0 build as untested/unsupported.

See `research` and `dependencies.json` for provenance and limits. The upstream runtime's corresponding source archive, source fix, original module, exact binary patch tool and GPL-2.0 license are included. See source/spawn-fix-README.md for reproduction. A full native source rebuild was not performed. The kart geometry is derived from the user's locally extracted Mario Kart 8 Deluxe files. The geometry preview is an offline render.
''')
    previous = DEST / 'manifest.json'
    previous.rename(DEST / 'upstream-runtime-manifest.json')
    manifest = {'target_version': '1.1.0', 'status': 'bounded remote-driving prototype; render, motion, native input and camera restoration observed in Ryujinx; seated rider and hardware unverified',
                'patched_runtime_sha256': fix_validation['candidate_sha256'],
                'features': ['Native cart visual geometry replacement', 'Tested spawn-initialization derivative',
                             'Local native-gamepad remote driving with following camera and bounded exit',
                             'Local spawn/motion/clear scripts',
                             'Optional browser physics control panel'],
                'files': []}
    for p in sorted(DEST.rglob('*')):
        if p.is_file() and p.name != '.DS_Store':
            manifest['files'].append({'path': str(p.relative_to(DEST)), 'bytes': p.stat().st_size,
                                      'sha256': hashlib.sha256(p.read_bytes()).hexdigest()})
    (DEST / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    archive = DEST.parent / (DEST.name + '.zip')
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        for p in sorted(DEST.rglob('*')):
            if p.is_file() and p.name != '.DS_Store':
                z.write(p, str(p.relative_to(DEST.parent)))
    print(f'Packaged {len(manifest["files"])} files: {archive}')


if __name__ == '__main__':
    main()
