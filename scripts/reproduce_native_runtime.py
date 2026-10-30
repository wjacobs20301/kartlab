#!/usr/bin/env python3
"""Reproduce the packaged pinned native module offline; never install it."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-root', type=Path, default=Path(__file__).resolve().parent,
                        help='Package source/ directory containing tools/, upstream-subsdk9 and runtime-chain.json')
    parser.add_argument('--output', type=Path, required=True, help='New scratch directory, never an installed mod')
    args = parser.parse_args()
    source, output = args.source_root.resolve(), args.output.resolve()
    if output.exists():
        raise SystemExit(f'Refusing existing output: {output}')
    chain = json.loads((source / 'runtime-chain.json').read_text())
    for name, expected in chain['reproduction_inputs_sha256'].items():
        if sha(source / name) != expected:
            raise SystemExit(f'Reproduction input changed: {name}')
    if shutil.which('xcrun') is None:
        raise SystemExit('Exact assembly builder requires xcrun clang targeting aarch64-none-elf')
    # The original three tools retain their project-relative layout, unmodified.
    (output / 'scripts').mkdir(parents=True)
    for file in (source / 'tools').glob('patch_lotuskit_*.py'):
        shutil.copyfile(file, output / 'scripts' / file.name)
    upstream = output / 'runtime/dist/KartLab-110/mod/exefs'
    upstream.mkdir(parents=True)
    shutil.copyfile(source / 'upstream-subsdk9', upstream / 'subsdk9')
    angular = output / 'runtime/candidates/angular-velocity-110'
    angular.mkdir(parents=True)
    shutil.copyfile(source / 'angular/binding.s', angular / 'binding.s')
    tools = ['spawn_init', 'velocity_110', 'angular_110']
    # Optional fourth stage (larger script buffer); older three-stage chains are unchanged.
    if len(chain['steps']) > 3 and chain['steps'][3]['directory'] == 'large-script-110':
        large = output / 'runtime/candidates/large-script-110'
        large.mkdir(parents=True)
        shutil.copyfile(source / 'large-script/scriptbuf.s', large / 'scriptbuf.s')
        tools.append('large_script_110')
    # Optional fifth stage (raw controller input kept in Record::currentInput); a one-instruction patch.
    if len(chain['steps']) > 4 and chain['steps'][4]['directory'] == 'raw-input-110':
        (output / 'runtime/candidates/raw-input-110').mkdir(parents=True)
        tools.append('raw_input_110')
    if len(chain['steps']) != len(tools):
        raise SystemExit('Unrecognised runtime chain')
    env = dict(os.environ)
    # Never run Python with -O: the original builders use assertions as guards.
    env.pop('PYTHONOPTIMIZE', None)
    for tool, step in zip(tools, chain['steps']):
        subprocess.run([sys.executable, str(output / 'scripts' / f'patch_lotuskit_{tool}.py')],
                       cwd=output, env=env, check=True)
        actual = sha(output / 'runtime/candidates' / step['directory'] / 'subsdk9')
        if actual != step['candidate_sha256']:
            raise SystemExit(f'Byte identity failed for {step["directory"]}: {actual}')
    final = output / 'runtime/candidates' / chain['steps'][-1]['directory'] / 'subsdk9'
    report = {'byte_identical': True, 'sha256': sha(final),
              'output': str(final), 'installed': False}
    (output / 'reproduction.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
