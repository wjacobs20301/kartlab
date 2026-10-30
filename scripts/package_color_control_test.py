#!/usr/bin/env python3
"""Build a separate test distribution without overwriting the earlier prototype."""
import hashlib,json,shutil,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'dist/KartLab-TOTK-1.1.0-prototype'
OUT=ROOT/'dist/KartLab-TOTK-1.1.0-assembly-test'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    if OUT.exists() or OUT.with_name(OUT.name+'.zip').exists():raise SystemExit('Preserve previous test package before rebuilding')
    old=json.loads((SOURCE/'manifest.json').read_text())
    for f in old['files']:assert sha(SOURCE/f['path'])==f['sha256'],f['path']
    shutil.copytree(SOURCE,OUT)
    (OUT/'manifest.json').rename(OUT/'previous-prototype-manifest.json')
    color=ROOT/'assets/native-cart-assembly-mod';v=json.loads((color/'validation.json').read_text())
    assert v['model_full_buffer_decoder_roundtrip']
    assert sha(color/'romfs/Model/SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc')==v['model_compressed_sha256']
    for t in v['textures']:assert sha(color/t['path'])==t['candidate_sha256']
    shutil.copytree(color/'romfs',OUT/'mod/romfs',dirs_exist_ok=True)
    sd=OUT/'switch-sdcard/totk_lotuskit';control=ROOT/'runtime/candidates/usable-controls'
    shutil.copy2(control/'autorun.as',sd/'autorun.as')
    for src,dst in [('spawn.as','spawn_v2.as'),('drive_pad.as','drive_pad_v2.as'),('clear.as','clear_v2.as')]:shutil.copy2(control/src,sd/'kart_lab'/dst)
    stable=ROOT/'runtime/candidates/stable-controls'
    shutil.copy2(stable/'autorun.as',sd/'autorun.as')
    shutil.copy2(stable/'clear.as',sd/'kart_lab/clear_v2.as')
    shutil.copy2(stable/'drive_pad.as',sd/'kart_lab/drive_pad_v3.as')
    shutil.copytree(stable,OUT/'lab/candidates/stable-controls')
    resident=ROOT/'runtime/candidates/resident-controls'
    shutil.copy2(resident/'autorun.as',sd/'autorun.as')
    shutil.copytree(resident,OUT/'lab/candidates/resident-controls')
    for p in (ROOT/'runtime/candidates/native-rider').glob('*.as'):shutil.copy2(p,sd/'kart_lab'/p.name)
    shutil.copytree(control,OUT/'lab/candidates/usable-controls')
    shutil.copytree(ROOT/'runtime/candidates/native-rider',OUT/'lab/candidates/native-rider')
    for p in ['research/color-control-v2-install.json','research/actor-watcher-crash.md','research/native-rider-evidence.json','research/stability-v3-install.json','research/kart-materials.json','research/resident-assembly-test.json','research/script-compile-crash.md']:
        shutil.copy2(ROOT/p,OUT/'research'/Path(p).name)
    shutil.copy2(color/'validation.json',OUT/'research/color-validation.json')
    shutil.copy2(color/'color-preview.png',OUT/'color-preview.png')
    for p in ['scripts/kart_assets_colors.py','scripts/inspect_native_rider.py','scripts/kart_assets_materials.py','scripts/kart_assets_assembly.py','scripts/build_resident_controller.py']:
        shutil.copy2(ROOT/p,OUT/'lab/tools'/Path(p).name)
    (OUT/'README-FIRST.md').write_text('''# Kart Lab — color/control test for TOTK1.1.0

This test revision adds the omitted actual MK8DX suspension arms, rounder source tires, and replaces the green TOTK appearance with Mario's original red/white/blue body and tire textures, downsampled into the original allocation. The retained TOTK shader is still used. The earlier body/tire color conversion was observed and confirmed by the user; see the resident-assembly receipt for this revision’s model/startup/motion results. Seated Link, automatic assembly and full MK handling are unfinished.

Use the same installation layout described in runtime-guide.md, but follow these revised controls. Briefly hold ZL+ZR plus a D-pad direction, then release: Up spawns a cart; Right adopts that nearby cart for a remote driving test; Down clears it. PS4 mapping is L2+R2+D-pad, left stick to drive/steer, Cross to exit. Remote driving holds Link at his starting position. It lasts at most9000logicalframes (~5minutes at30fps), with a0.8unit speed cap, lower acceleration and independent upright yaw. This is a flat-road stability test, not recovered MK terrain handling. All three controls now live in one yielding startup-compiled script; pressing Right does not compile another file. Native watcher telemetry is disabled/paused after selection as a mitigation for a later name-logging crash; lifetime handling still needs work.

The native-rider diagnostic sources are included for further research, but no Left shortcut is bound in this isolated startup-controller test. Native mounting and a seated kart pose remain unfinished. Do not combine the pinning remote controller with a mounted Link. Suspension shafts are rigidly attached to the chassis; independent native wheel movement can still open smaller gaps.

See research/color-control-v2-install.json and color-validation.json for the exact current test evidence and limits. Native-rider scripts and host checks do not establish observed mounting. The model and all texture allocations are unchanged in size. The previous-prototype-manifest and runtime-guide are historical base documentation; these revised controls supersede them. No network listener starts automatically. Switch hardware is untested.

Pinned GPL runtime source/archive, exact native spawn-patch tool, original module and license are included from the base prototype. This revision changes no executable module. Source textures/geometry derive from the user's local game exports. No game executable, keys or save is included.
''')
    manifest={'target':'TOTK1.1.0','status':'Development test: refer to included runtime receipts; seated rider/automatic assembly/hardware pending','module_sha256':sha(OUT/'mod/exefs/subsdk9'),'files':[]}
    for p in sorted(OUT.rglob('*')):
        if p.is_file() and p.name!='.DS_Store':manifest['files'].append({'path':str(p.relative_to(OUT)),'bytes':p.stat().st_size,'sha256':sha(p)})
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    archive=OUT.with_name(OUT.name+'.zip')
    with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED)as z:
        for p in sorted(OUT.rglob('*')):
            if p.is_file() and p.name!='.DS_Store':z.write(p,str(p.relative_to(OUT.parent)))
    with zipfile.ZipFile(archive)as z:assert z.testzip()is None
    print(archive)
if __name__=='__main__':main()
