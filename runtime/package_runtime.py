#!/usr/bin/env python3
"""Stage a pinned upstream runtime and authored scripts without installing it."""
import hashlib,json,shutil,struct,zipfile,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
ZIP=ROOT/'.tools/totk-runtime/lotuskit-110.zip'
OUT=ROOT/'runtime/dist/KartLab-110'
DIGEST='dc7b59413cf62e8a8c961aeb905debaacd111d53889fe5bfdd45d0c71cf33d2c'
def main():
    if hashlib.sha256(ZIP.read_bytes()).hexdigest()!=DIGEST: raise ValueError('Release digest mismatch')
    with zipfile.ZipFile(ZIP) as z:
        if z.testzip() is not None: raise ValueError('Corrupt release ZIP')
        for name in z.namelist():
            rel=Path(name).relative_to('totk110-lotuskit')
            if '..' in rel.parts or rel.is_absolute(): raise ValueError('Unsafe member')
            if not rel.parts or name.endswith('/'): continue
            if rel.parts[0] not in {'romfs','exefs','runtime_patches','frontend'}: continue
            if rel.suffix=='.elf': continue
            target=OUT/('mod' if rel.parts[0] in {'romfs','exefs'} else 'upstream')/rel
            target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(name))
    nso=(OUT/'mod/exefs/subsdk9').read_bytes()
    if nso[:4]!=b'NSO0': raise ValueError('Runtime is not NSO')
    npdm=(OUT/'mod/exefs/main.npdm').read_bytes()
    if npdm[:4]!=b'META': raise ValueError('Missing META NPDM')
    # NSO metadata only here; decompressed segment hashes checked separately by verifier.
    sd=OUT/'switch-sdcard/totk_lotuskit';(sd/'kart_lab').mkdir(parents=True,exist_ok=True)
    for script in (ROOT/'runtime/scripts').glob('*.as'):
        shutil.copy2(script,sd/('autorun.as' if script.name=='autorun.as' else 'kart_lab/'+script.name))
    for d in ['scripts','panel']:
        shutil.copytree(ROOT/'runtime'/d,OUT/'lab'/d,dirs_exist_ok=True)
    for fname in ['dependencies.json','README.md']:
        if (ROOT/'runtime'/fname).exists(): shutil.copy2(ROOT/'runtime'/fname,OUT/fname)
    shutil.copy2(ROOT/'.tools/totk-runtime/lotuskit/LICENSE',OUT/'LICENSE-lotuskit-GPL-2.0')
    source=OUT/'source';source.mkdir(parents=True,exist_ok=True)
    subprocess.run(['git','-C',str(ROOT/'.tools/totk-runtime/lotuskit'),'archive','--format=tar.gz','--output='+str(source/'lotuskit-59dcfccd77b6d4bcfa718bff806bc55be640edb7.tar.gz'),'HEAD'],check=True)
    files={str(p.relative_to(OUT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.rglob('*') if p.is_file() and p.name!='manifest.json'}
    (OUT/'manifest.json').write_text(json.dumps({'release_archive_sha256':DIGEST,'upstream_runtime_build_id':nso[0x40:0x60].hex().upper(),'status':'Original upstream dependency; combined prototype applies tested spawn-initialization patch. Use combined prototype for remote driving.','files_sha256':files},indent=2)+'\n')
    print(OUT)
if __name__=='__main__': main()
