#!/usr/bin/env python3
"""Stage a pinned TOTK1.1.0 native-kart development package, offline.

The controller and visual are explicit inputs. Later ROMFS overlays win; every
replacement is recorded. Staging is the default; ZIP creation is opt-in.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
COMMIT = '59dcfccd77b6d4bcfa718bff806bc55be640edb7'
UPSTREAM_SHA = '47190218a43b6000d646fe98931151cbc83c8b773c11d3e85310ef8b3c5d0b13'
ARCHIVE_SHA = '2fab0165fd62fa5c138fe0de80a28a2c9792ad1374930617915e5e873dea94c6'
LICENSE_SHA = '7579d5d7cf96b431b94c38d344ee75f132fe45ef3a702c5efe6bbe7785d48a24'
STEPS = [
    ('zero-create-arg', '59d61add33f737325500a48eb94d35f0d4db59564a99cca60d07459d3fe82841',
     'source-fix.patch', '01-spawn-init.patch', 'spawn_init'),
    ('linear-velocity-110', '42f1c503f317df24591482291a4591fbd4a069946e8aeef34ee00b348911980f',
     'source.patch', '02-linear-velocity.patch', 'velocity_110'),
    ('angular-velocity-110', 'b0dc2c3bf8b19d95e43c8ad58d3e461d485a2e1ad0b9d2060f843a8a6d80ad06',
     'source.patch', '03-angular-velocity.patch', 'angular_110'),
    ('large-script-110', '3e22fadc6db15f650ea5bfbe9bed33be79d0259ecdb0150026c5a305425431e2',
     'source.patch', '04-large-script.patch', 'large_script_110'),
    ('raw-input-110', '10b63b32991595f57c584c40d417ab4605cdc67f3af4753ee0eb443d6b60e2bb',
     'source.patch', '05-raw-input.patch', 'raw_input_110'),
]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def checked(path, expected):
    if not path.is_file() or sha(path) != expected:
        raise ValueError(f'Missing or changed pinned input: {path}')
    return path


def files(root):
    if not root.is_dir():
        raise ValueError(f'Missing input directory: {root}')
    for path in sorted(root.rglob('*')):
        if path.is_symlink():
            raise ValueError(f'Symlinks are not package inputs: {path}')
        if path.is_file() and path.name != '.DS_Store':
            yield path


def validate_assets(root):
    """Check hash fields used by the current visual/native-pack validators."""
    data = json.loads((root / 'validation.json').read_text())
    if 'model_compressed_sha256' in data:
        checked(root / 'romfs/Model/SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc', data['model_compressed_sha256'])
        if data.get('model_full_buffer_decoder_roundtrip') is not True:
            raise ValueError(f'Visual decoder validation missing: {root}')
    elif 'candidate_compressed_sha256' in data:
        checked(root / 'romfs/Model/SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc', data['candidate_compressed_sha256'])
    if 'candidate_sha256' in data:
        checked(root / 'romfs/Pack/Actor/SpObj_ControlStick_A_01.pack.zs', data['candidate_sha256'])
    for item in data.get('textures', []):
        checked(root / item['path'], item['candidate_sha256'])
    return data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--autorun', type=Path, required=True, help='Exact startup controller .as file')
    parser.add_argument('--visual-root', type=Path, required=True, help='Visual candidate containing romfs/ and validation.json')
    parser.add_argument('--native-mount-root', type=Path, default=ROOT / 'assets/native-mount-cart-physics')
    parser.add_argument('--overlay', type=Path, action='append', default=[], help='Additional root containing romfs/; applied in argument order')
    parser.add_argument('--sd-overlay', type=Path, action='append', default=[], help='Additional SD-root files; cannot override selected autorun')
    parser.add_argument('--evidence', type=Path, action='append', default=[], help='Additional evidence file to include in research/')
    parser.add_argument('--lab-file', type=Path, action='append', default=[], help='Workspace-relative source to retain under lab/')
    parser.add_argument('--readme', type=Path, help='Reviewed README-FIRST.md override describing this controller')
    parser.add_argument('--output', type=Path, required=True, help='New package directory; never replaced')
    parser.add_argument('--dry-run', action='store_true', help='Validate inputs and print planned manifest; write nothing')
    parser.add_argument('--zip', action='store_true', help='Also create deterministic output-name.zip after staging')
    args = parser.parse_args()
    dest = args.output.resolve()
    archive = dest.with_name(dest.name + '.zip')
    if dest.exists() or (args.zip and archive.exists()):
        raise ValueError('Output already exists; choose a new output path')
    if not args.autorun.is_file() or args.autorun.suffix != '.as':
        raise ValueError('--autorun must select an existing .as controller')
    # The packaged runtime chain includes large-script-110, which reads scripts up to 65,535 bytes.
    limit = 65536 if any(step[0] == 'large-script-110' for step in STEPS) else 8192
    if args.autorun.stat().st_size >= limit:
        raise ValueError(f'Selected startup controller exceeds the {limit - 1}-byte file limit of the packaged runtime')
    base = ROOT / 'runtime/dist/KartLab-110'
    upstream_manifest = json.loads((base / 'manifest.json').read_text())
    plan, overrides, generated = {}, [], {}

    def add(src, rel, layer):
        src = src.resolve()
        if not src.is_file():
            raise ValueError(f'Missing package input: {src}')
        key = str(Path(rel).as_posix())
        if key in plan:
            previous = plan[key]
            overrides.append({'path': key, 'previous_layer': previous['layer'],
                              'previous_sha256': previous['sha256'], 'layer': layer, 'sha256': sha(src)})
        plan[key] = {'source': src, 'layer': layer, 'sha256': sha(src), 'bytes': src.stat().st_size}

    def generate(rel, data):
        if rel in plan or rel in generated:
            raise ValueError(f'Duplicate generated path: {rel}')
        generated[rel] = data.encode()

    # Copy only required runtime files, never the historical controller bundle.
    for src in files(base / 'mod'):
        rel = src.relative_to(base).as_posix()
        checked(src, upstream_manifest['files_sha256'][rel])
        if rel != 'mod/exefs/subsdk9':
            add(src, rel, 'upstream-runtime')
    checked(base / 'mod/exefs/subsdk9', UPSTREAM_SHA)
    add(base / 'mod/exefs/subsdk9', 'source/upstream-subsdk9', 'upstream-runtime')
    chain = {'upstream_commit': COMMIT, 'upstream_sha256': UPSTREAM_SHA,
             'candidate_sha256': STEPS[-1][1], 'steps': [], 'reproduction_inputs_sha256': {}}
    previous = UPSTREAM_SHA
    for directory, expected, patch, patchname, tool in STEPS:
        folder = ROOT / 'runtime/candidates' / directory
        checked(folder / 'subsdk9', expected)
        validation = json.loads((folder / 'validation.json').read_text())
        if validation['source_sha256'] != previous or validation['candidate_sha256'] != expected:
            raise ValueError(f'Broken runtime chain: {directory}')
        chain['steps'].append({'directory': directory, 'source_sha256': previous, 'candidate_sha256': expected,
                               'source_patch': 'patches/' + patchname, 'tool': f'tools/patch_lotuskit_{tool}.py'})
        add(folder / patch, 'source/patches/' + patchname, 'source-patches')
        add(ROOT / f'scripts/patch_lotuskit_{tool}.py', f'source/tools/patch_lotuskit_{tool}.py', 'exact-binary-tools')
        add(folder / 'validation.json', f'research/runtime-{directory}.json', 'historical-offline-validation')
        previous = expected
    add(ROOT / 'runtime/candidates' / STEPS[-1][0] / 'subsdk9', 'mod/exefs/subsdk9', 'runtime-current')
    add(ROOT / 'runtime/candidates/angular-velocity-110/binding.s', 'source/angular/binding.s', 'assembly-source')
    add(ROOT / 'runtime/candidates/large-script-110/scriptbuf.s', 'source/large-script/scriptbuf.s', 'assembly-source')
    add(ROOT / 'scripts/reproduce_native_runtime.py', 'source/reproduce_runtime.py', 'reproduction-helper')
    add(Path(__file__), 'source/tools/package_native_kart.py', 'packaging-source')
    source_archive = base / f'source/lotuskit-{COMMIT}.tar.gz'
    checked(source_archive, ARCHIVE_SHA)
    add(source_archive, 'source/' + source_archive.name, 'upstream-source')
    license_file = checked(base / 'LICENSE-lotuskit-GPL-2.0', LICENSE_SHA)
    add(license_file, 'LICENSE-lotuskit-GPL-2.0', 'license')
    add(license_file, 'source/LICENSE-lotuskit-GPL-2.0', 'license')
    for rel, item in plan.items():
        if rel.startswith('source/') and rel != 'source/tools/package_native_kart.py':
            chain['reproduction_inputs_sha256'][rel.removeprefix('source/')] = item['sha256']
    generate('source/runtime-chain.json', json.dumps(chain, indent=2, sort_keys=True) + '\n')

    asset_roots = [('visual', args.visual_root), ('native-mount-cart-physics', args.native_mount_root)]
    asset_roots += [(f'overlay-{i:02}', root) for i, root in enumerate(args.overlay, 1)]
    for layer, root in asset_roots:
        root = root.resolve()
        if layer in ('visual', 'native-mount-cart-physics'):
            validate_assets(root)
        if (root / 'validation.json').is_file():
            add(root / 'validation.json', f'research/{layer}-validation.json', layer)
        for src in files(root / 'romfs'):
            add(src, 'mod/romfs/' + src.relative_to(root / 'romfs').as_posix(), layer)
    for required in ('Pack/Actor/SpObj_ControlStick_A_01.pack.zs',
                     'System/Resource/ResourceSizeTable.Product.110.rsizetable.zs',
                     'Model/SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc'):
        if 'mod/romfs/' + required not in plan:
            raise ValueError(f'Required native vehicle resource absent: {required}')
    for i, root in enumerate(args.sd_overlay, 1):
        for src in files(root):
            rel = src.relative_to(root).as_posix()
            if rel == 'totk_lotuskit/autorun.as':
                raise ValueError('SD overlay cannot replace --autorun')
            add(src, 'switch-sdcard/' + rel, f'sd-overlay-{i:02}')
    add(args.autorun, 'switch-sdcard/totk_lotuskit/autorun.as', 'selected-controller')
    add(args.autorun, 'source/controller/autorun.as', 'selected-controller')
    evidence = [ROOT / 'research/angular-velocity-runtime-results.json',
                ROOT / 'research/angular-velocity-independent-audit.json'] + args.evidence
    for src in evidence:
        rel = 'research/' + src.name
        if rel in plan:
            raise ValueError(f'Evidence basename collision: {src.name}')
        add(src, rel, 'runtime-evidence')
    for src in args.lab_file:
        src = src.resolve()
        relative = src.relative_to(ROOT)
        add(src, 'lab/' + relative.as_posix(), 'lab-source')
    add(ROOT / 'runtime/dependencies.json', 'dependencies.json', 'upstream-pins')
    generate('source/requirements.txt', 'lz4==4.4.5\npyelftools==0.33\ncapstone==5.0.7\n')
    generate('source/README.md', SOURCE_README)
    if args.readme:
        add(args.readme, 'README-FIRST.md', 'reviewed-readme')
    else:
        generate('README-FIRST.md', DEFAULT_README)
    manifest = {'format': 1, 'target_version': '1.1.0', 'title_id': '0100F2C0115B6000',
                'runtime_sha256': chain['candidate_sha256'], 'upstream_commit': COMMIT,
                'status': 'Experimental development package; consult selected controller and included evidence',
                'overlay_order': [name for name, _ in asset_roots], 'overrides': overrides, 'files': []}
    for rel, entry in sorted(plan.items()):
        manifest['files'].append({k: v for k, v in dict(path=rel, **entry).items() if k != 'source'})
    for rel, data in sorted(generated.items()):
        manifest['files'].append({'path': rel, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(), 'layer': 'generated'})
    manifest['files'].sort(key=lambda item: item['path'])
    if args.dry_run:
        print(json.dumps(manifest, indent=2))
        return
    dest.mkdir(parents=True)
    for rel, entry in sorted(plan.items()):
        target = dest / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(entry['source'], target)
    for rel, data in sorted(generated.items()):
        target = dest / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    for entry in manifest['files']:
        checked(dest / entry['path'], entry['sha256'])
    (dest / 'manifest.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
    if args.zip:
        with zipfile.ZipFile(archive, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
            for src in files(dest):
                info = zipfile.ZipInfo(dest.name + '/' + src.relative_to(dest).as_posix(), (1980, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.create_system = 3
                info.external_attr = 0o100644 << 16
                output.writestr(info, src.read_bytes(), compresslevel=9)
        with zipfile.ZipFile(archive) as output:
            if output.testzip() is not None:
                raise ValueError('ZIP integrity check failed')
    print(json.dumps({'staged': str(dest), 'files': len(manifest['files']),
                      'runtime_sha256': chain['candidate_sha256'], 'zip': str(archive) if args.zip else None}, indent=2))


DEFAULT_README = '''# Native Kart Lab — TOTK1.1.0 development candidate

Experimental native vehicle assets and an explicitly selected startup controller.
The exact controller is switch-sdcard/totk_lotuskit/autorun.as; consult its controls
and limits before testing. Install mod/exefs and mod/romfs as one mod for title
0100F2C0115B6000, and copy switch-sdcard contents to the emulator or console SD root.
This builder does not install files. Existing installs require a clean game restart.

This package includes native ControlStick actor physics and the selected Cart visual.
Native Control uses a standing pose; seated Mario Kart animation and complete MK8DX
handling are unfinished. Included runtime receipts cover sampled Ryujinx tests,
not general terrain robustness or Switch hardware. Upstream marks its1.1.0 build
untested/unsupported. Validation JSON files are historical receipts with their
original scope; they do not establish success for every selected controller/overlay.

The executable is pinned to the spawn-init → corrected linear velocity → additive
angular API → 64 KiB script buffer → raw-input record chain ending 10b63b32 (startup
scripts up to 65,535 bytes; scripts read the player's raw buttons while remapping controls).
manifest.json records every packaged input and ROMFS replacement. Runtime GPL license, complete pinned source archive, modifications,
assembly and byte-identical offline reproduction tools are included under source/.
No game executable, keys or save is included. Visuals derive from local game exports.
'''

SOURCE_README = '''# Runtime source and exact derivative reproduction

lotuskit upstream: https://github.com/aquacluck/totk-lotuskit
Commit59dcfccd77b6d4bcfa718bff806bc55be640edb7, GPL-2.0 (license included).
Modified derivative: spawn initialization, corrected TOTK1.1.0 linear lookup,
additive setAngularVel vector/XYZ methods, a heap-allocated 64 KiB script read buffer, and
Record::currentInput kept as raw human input. runtime-chain.json pins all stages.

Byte-identical offline binary reproduction requires Python3.10+, the packages in
requirements.txt, and Apple's xcrun clang with aarch64-none-elf support. No network,
game files, keys, emulator or installation is used by the reproduction helper.
From this source directory, using a new scratch output path:

    python3 reproduce_runtime.py --output /tmp/kart-native-reproduction

It runs the five included binary builders in order and verifies each
expected SHA-256. It preserves the original upstream module and appends native
assembly only within the existing text alignment gap. It never modifies installed
files. Dependencies must already be available in that Python environment.

For corresponding C++ source, extract the included upstream archive into a new
directory, then apply patches/01-spawn-init.patch, 02-linear-velocity.patch,
03-angular-velocity.patch, 04-large-script.patch and 05-raw-input.patch in order with ordinary `git apply` (normal context).
All other upstream source remains in the included archive. Use upstream's build
instructions/toolchain for a source rebuild. A full native source rebuild has not
been performed and is not claimed byte-identical. The source spawn fix initializes
both CreateArg objects; the exact binary fix patches createAndWatchPosRot only.
The angular C++ patch expresses the same API; exact binary construction is instead
provided by angular/binding.s and tools/patch_lotuskit_angular_110.py.

The original offline validation receipts retain their original status wording;
later runtime observations are separate under ../research/. Package generation
does not constitute emulator or hardware validation of the selected controller.
'''


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, FileNotFoundError) as error:
        raise SystemExit(str(error)) from error
