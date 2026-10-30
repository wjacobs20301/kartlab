#!/usr/bin/env python3
"""Install one test autorun (and optionally a subsdk9), boot TOTK in Ryujinx, wait, stop, keep the log.

Never restores anything itself: callers back up first and restore afterwards
(see research/large-script-runtime.md). Waits until every --until pattern has appeared,
any --fail pattern appears, the emulator exits, or the timeout passes.
"""
import os, argparse,hashlib,json,re,shutil,signal,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SUPPORT=Path.home()/'Library/Application Support/Ryujinx'
MOD=SUPPORT/'mods/contents/0100f2c0115b6000/KartLab_110/exefs/subsdk9'
AUTORUN=SUPPORT/'sdcard/totk_lotuskit/autorun.as'
LOGS=Path.home()/'Library/Logs/Ryujinx'
APP='/Applications/Ryujinx.app/Contents/MacOS/Ryujinx'
GAME=Path(os.environ.get('TOTK_XCI',ROOT/'totk.xci'))   # your own TOTK 1.1.0 dump
FAIL=[r'Unhandled exception',r'InvalidMemoryRegion',r'Guest stack trace',r'PrintGuestStackTrace',r'CPU exception']
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()


def main():
    p=argparse.ArgumentParser();p.add_argument('--autorun',type=Path,required=True);p.add_argument('--subsdk9',type=Path)
    p.add_argument('--until',action='append',default=[]);p.add_argument('--fail',action='append',default=[])
    p.add_argument('--settle',type=float,default=0,help='seconds to keep running after all --until patterns')
    p.add_argument('--timeout',type=float,default=480);p.add_argument('--log',type=Path,required=True);a=p.parse_args()
    if subprocess.run(['pgrep','-f',APP],capture_output=True).returncode==0:raise SystemExit('Ryujinx already running')
    if a.subsdk9:shutil.copyfile(a.subsdk9,MOD)
    shutil.copyfile(a.autorun,AUTORUN)
    installed={'subsdk9':sha(MOD),'autorun':sha(AUTORUN),'autorun_bytes':AUTORUN.stat().st_size}
    before=set(LOGS.glob('*.log'));proc=subprocess.Popen([APP,str(GAME)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    start=time.time();log=None;text='';outcome='timeout';fails=FAIL+a.fail;done_at=None
    while time.time()-start<a.timeout:
        time.sleep(3)
        if log is None:
            new=sorted(set(LOGS.glob('*.log'))-before,key=lambda x:x.stat().st_mtime)
            log=new[-1]if new else None
        if log:text=log.read_text(errors='replace')
        hit=[f for f in fails if re.search(f,text)]
        if hit:outcome='fail:'+hit[0];break
        if a.until and all(re.search(u,text)for u in a.until):
            done_at=done_at or time.time()
            if time.time()-done_at>=a.settle:outcome='passed';break
        if proc.poll()is not None:outcome='emulator exited';break
    if proc.poll()is None:
        proc.send_signal(signal.SIGTERM)
        try:proc.wait(30)
        except subprocess.TimeoutExpired:proc.kill();proc.wait()
    time.sleep(2)
    if log:text=log.read_text(errors='replace');a.log.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(log,a.log)
    found={u:bool(re.search(u,text))for u in a.until}
    print(json.dumps(dict(outcome=outcome,seconds=round(time.time()-start),installed=installed,until=found,log=str(a.log),
                          source_log=str(log)),indent=2))


if __name__=='__main__':main()
