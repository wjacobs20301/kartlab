#!/usr/bin/env python3
"""Install reviewed local test candidates with hashes and a rollback backup."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[1]
BASE=Path.home()/'Library/Application Support/Ryujinx'
MOD=BASE/'mods/contents/0100f2c0115b6000/KartLab_110'
SD=BASE/'sdcard/totk_lotuskit'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    assert sha(MOD/'exefs/subsdk9')=='59d61add33f737325500a48eb94d35f0d4db59564a99cca60d07459d3fe82841'
    assert sha(MOD/'romfs/Model/SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc')=='47d6a655ca5f473433f288c9541ab9d472b23c1a71f3a102efd3f500367c5648'
    old=json.loads((ROOT/'research/native-pad-controller-test.json').read_text())
    assert sha(SD/'autorun.as')==old['autorun_sha256']
    backup=ROOT/'.work/backups/before-color-control-v2-test';assert not backup.exists()
    color=ROOT/'assets/native-cart-color-mod';v=json.loads((color/'validation.json').read_text())
    assert v['model_full_buffer_decoder_roundtrip']
    assert sha(color/'romfs/Model/SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc')==v['model_compressed_sha256']
    for t in v['textures']:assert sha(color/t['path'])==t['candidate_sha256']
    pairs=[(p,MOD/p.relative_to(color))for p in (color/'romfs').rglob('*')if p.is_file()]
    controls=ROOT/'runtime/candidates/usable-controls'
    pairs += [(controls/'autorun.as',SD/'autorun.as'),(controls/'spawn.as',SD/'kart_lab/spawn_v2.as'),(controls/'drive_pad.as',SD/'kart_lab/drive_pad_v2.as'),(controls/'clear.as',SD/'kart_lab/clear_v2.as')]
    pairs += [(p,SD/'kart_lab'/p.name)for p in (ROOT/'runtime/candidates/native-rider').glob('*.as')]
    # Preflight every destination before making changes.
    records=[]
    for src,dst in pairs:
        rel=dst.relative_to(BASE)
        if dst.exists() and dst not in [SD/'autorun.as',MOD/'romfs/Model/SpObj_Cart_A.SpObj_Cart_A_01.bfres.mc']:
            raise SystemExit('Preserve unexpected existing destination: '+str(dst))
        records.append({'source':str(src.relative_to(ROOT)),'destination':str(dst),'sha256':sha(src),'previous_sha256':sha(dst)if dst.exists()else None,'backup':str(backup/rel)if dst.exists()else None})
    backup.mkdir(parents=True)
    for (src,dst),rec in zip(pairs,records):
        if dst.exists():
            b=Path(rec['backup']);b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,b)
        dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst);assert sha(dst)==rec['sha256']
    receipt={'status':'Installed and hash-verified; game test pending.','module_sha256':sha(MOD/'exefs/subsdk9'),'backup':str(backup),'files':records,'limits':'Native mount candidate needs manual Ultrahand attachment and A-Control; standing pose, not seated. Remote v2 is separate and still pins Link. Color response, revised controls and watcher mitigation need runtime validation.'}
    (ROOT/'research/color-control-v2-install.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print('Installed '+str(len(records))+' reviewed candidate files; backups and hashes recorded.')
if __name__=='__main__':main()
