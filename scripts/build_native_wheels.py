#!/usr/bin/env python3
"""Build the wheel-animated native rider controller and its regression test.

Source (readable): runtime/candidates/native-rider-wheels/controller.src.as
Outputs:
  runtime/candidates/native-rider-wheels/autorun.as        installed startup script
  runtime/diagnostics/native_wheels_regression.as          14-check regression + wheel samples

The runtime reads at most 8191 bytes per script, so both outputs are minified:
the shared internal-identifier compactor, extra aliases for the controller's
own names, and removal of whitespace not between two word characters. Quoted
strings and registered API names are never altered.
"""
import re
from pathlib import Path
from compact_native_script import compact, NAMES

ROOT = Path(__file__).resolve().parents[1]
CAND = ROOT / 'runtime/candidates/native-rider-wheels'
EXTRA = ['steerInput', 'wheelSteer', 'spinFront', 'spinRear', 'lastX', 'lastZ', 'haveLast',
         'wheelBones', 'wheelRotation', 'animateWheels', 'throttle', 'change', 'limit',
         'length', 'parkX', 'parkZ', 'sampleTest', 'phase', 'frames', 'oldId', 'riding',
         'component', 'player', 'target', 'state', 'steer', 'seatID', 'seats', 'delta', 'count', 'every']
EXTRA_ALIASES = {n: '_w' + str(i) for i, n in enumerate(EXTRA)}
assert not set(EXTRA) & set(NAMES)

TOKEN = re.compile(r'"(?:[^"\\]|\\.)*"|[A-Za-z_]\w*|\s+|.', re.S)


WRAPPERS = {  # API -> (alias, one-line pass-through definition); used only when a build needs the bytes
    'ptr_deref_float': ('_pf', 'float _pf(ptr_t p){return ptr_deref_float(p);}'),
    'ptr_deref_u64': ('_pq', 'uint64 _pq(ptr_t p){return ptr_deref_u64(p);}'),
    'ptr_deref_u32': ('_pu', 'u32 _pu(ptr_t p){return ptr_deref_u32(p);}'),
    'ptr_deref_s32': ('_ps', 'int _ps(ptr_t p){return ptr_deref_s32(p);}'),
    'ptr_write_float': ('_pw', 'void _pw(ptr_t p,float v){ptr_write_float(p,v);}'),
    'ptr_from_ActorBase': ('_pa', 'ptr_t _pa(ActorBase@ a){return ptr_from_ActorBase(a);}'),
    'sys::debugLog': ('_L', 'void _L(const string &in s){sys::debugLog(s);}'),
    'ActorWatcher::get': ('_ag', 'ActorBase@ _ag(uint64 i){return ActorWatcher::get(i);}'),
    'TextWriter::toast': ('_T', 'void _T(u32 t,const string &in s){TextWriter::toast(t,s);}'),
}


def wrap_api(source):
    """Route repeated API calls through pass-through wrappers, only where that saves bytes."""
    pattern = r'"(?:[^"\\]|\\.)*"|(?<![\w.])[A-Za-z_]\w*(?:::[A-Za-z_]\w*)?(?=\s*\()'
    counts = {}
    for m in re.finditer(pattern, source):
        if m[0] in WRAPPERS:
            counts[m[0]] = counts.get(m[0], 0) + 1
    use = {k for k, n in counts.items() if n * (len(k) - len(WRAPPERS[k][0])) > len(WRAPPERS[k][1]) + 1}
    body = re.sub(pattern, lambda m: WRAPPERS[m[0]][0] if m[0] in use else m[0], source)
    return ''.join(WRAPPERS[k][1] + '\n' for k in WRAPPERS if k in use) + body


DECL = re.compile(r'(?:\b(?:ptr_t|uint|int|float|bool|int64|uint64|u32|void|string)|@)\s*(?:&\s*in\s+)?([A-Za-z_]\w*)\s*(?=[=;,)(]|\[)')
KEEP = {'main', 'in', 'is', 'null', 'true', 'false', 'return'}


def alias_declared(source):
    """Alias every identifier the script declares (3+ chars), never member names or strings."""
    names = sorted({n for n in DECL.findall(re.sub(r'"(?:[^"\\]|\\.)*"', '""', source))
                    if len(n) >= 3 and n not in KEEP and not n.startswith('_')})
    table = {n: '_d' + str(i) for i, n in enumerate(names)}
    return re.sub(r'"(?:[^"\\]|\\.)*"|(?<!::)(?<![\w.])[A-Za-z_]\w*\b(?!\s*::)',
                  lambda m: m[0] if m[0].startswith('"') else table.get(m[0], m[0]), source)


def minify(source, wrap=False):
    source = compact(source)
    if wrap:
        source = alias_declared(wrap_api(source))
    source = re.sub(r'"(?:[^"\\]|\\.)*"|(?<!::)(?<![\w.])[A-Za-z_]\w*\b(?!\s*::)',
                    lambda m: m[0] if m[0].startswith('"') else EXTRA_ALIASES.get(m[0], m[0]), source)
    out = []
    for line in source.splitlines():
        toks = TOKEN.findall(line.strip())
        kept = []
        for i, t in enumerate(toks):
            if t.isspace():
                prev = kept[-1] if kept else ''
                nxt = toks[i + 1] if i + 1 < len(toks) else ''
                word = lambda s: bool(s) and (s[-1].isalnum() or s[-1] == '_')
                word0 = lambda s: bool(s) and (s[0].isalnum() or s[0] == '_')
                pair = (prev[-1:] + nxt[:1]) if prev and nxt else ''
                if (word(prev) and word0(nxt)) or pair in ('--', '++', '-+', '+-', '&&', '||', '<<', '>>'):
                    kept.append(' ')
                continue
            kept.append(t)
        if kept:
            out.append(''.join(kept))
    return '\n'.join(out) + '\n'


MOUNT_HELPER = r'''
// Get in like a player: stand beside the kart facing it and press A. On wet grass the parked kart can roll a few
// metres before the first press, so later tries move Link next to it again.
void mountKart(){
 for(uint t=0;t<10 && worldReady() && !playerIsRiding(getKart());t++){
  ActorBase@ k=getKart();if(k is null){input(10,0);continue;}
  if(t>0){Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6,fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);
   fx/=n;fz/=n;Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,k.pos_y+0.3f,pz);input(20,0);}
  input(1,1);input(t==0?90:30,0);
 }
}
'''


def test_body():
    return MOUNT_HELPER + r'''
ptr_t tp=0;
void sampleTest(const string &in phase){
 ActorBase@ a=getKart();if(a is null)return;
 Matrix33f r=a.rot;
 sys::debugLog("DRIVE "+phase+" pos="+a.pos_x+","+a.pos_y+","+a.pos_z+" up="+r.a4+" heading="+r.a2+","+r.a8+" mounted="+playerIsRiding(a)+" speed="+driveSpeed+" pad="+ptr_deref_s32(tp+8)+","+ptr_deref_s32(tp+12)+" w="+(wheelBones(a)!=0)+","+spinFront+","+wheelSteer);
}
// Simulated player: the controller sees it via its test hook; the game sees the controller's output.
void feed(uint64 k,int x,int y,int rx){
 simActive=true;simHeld=k;simLX=x;simLY=y;simRX=rx;simRY=0;controllerFrame(tp);
 if(overrideActive)input(1,outButtons,outLX,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
// Mario Kart controls: positive "throttle" holds A, negative holds B.
uint64 pedal(int y){return y>0?uint64(A):y<0?uint64(B):0;}
void step(uint n,uint64 k,int x,int y,const string &in l,uint every){
 for(uint f=0;f<n && worldReady();f++){feed(k,x,y,0);k&=uint64(A|B);if(every>0 && f%every==0)sampleTest(l+f);}
}
void main(){
 initKart();tp=resolvePadInput();if(tp==0)return;
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady())return;
 // Mario Kart speeds need open ground: surveyed field south of Lookout Landing (research/site-survey.log).
 Player.setPos(-150,127.8,-62);input(90,0);if(!worldReady())return;
 controllerFrame(tp);step(166,uint64(ZL|ZR|DUP),0,0,"",0);
 sampleTest("beforeA");mountKart();sampleTest("afterA");
 if(!playerIsRiding(getKart()))return;
 feed(0,0,0,0); // release A after getting in, as a player does
 for(uint phase=0;phase<6;phase++){
  uint frames=phase==0?180:phase==2?60:phase==4?90:120;
  int x=phase==1?24000:phase==4?-24000:0;
  int y=phase%3==2?0:phase==3?-32767:32767;
  step(frames,pedal(y),x,0,"p"+phase+"f",30);sampleTest("end"+phase);
 }
 step(61,uint64(X),0,0,"",0);sampleTest("afterB");
 step(90,0,0,32767,"",0);sampleTest("unmountedEnd");sampleTest("parkStart");
 step(180,0,0,0,"",0);sampleTest("parkEnd");
 RECALL_PART
 sys::debugLog("DRIVE finished");simActive=false;input(1,0);runResident(tp);
}
'''


RECALL_PART = (' uint oldId=kartId;step(181,uint64(ZL|ZR|DUP),0,0,"",0);sampleTest("recall");\n'
               ' step(91,1,0,0,"",0);sampleTest("remounted");sys::debugLog("RECALL same="+(oldId==kartId));')


def recall_body():
    """Short second test: spawn, mount, drive, B, recall, remount (recall checks + wheel safety)."""
    body = test_body()
    a = body.index(' for(uint phase=0;')
    b = body.index(' RECALL_PART')
    drive = ' step(90,uint64(A),0,0,"p0f",30);sampleTest("end0");step(61,uint64(X),0,0,"",0);sampleTest("afterB");\n'
    return body[:a] + drive + RECALL_PART + body[b + len(' RECALL_PART'):]


def visual_body():
    """Visual check: slow forward roll, then stationary alternating steer with the camera orbited."""
    return MOUNT_HELPER + r'''
ptr_t tp=0;
// Simulated player: the controller sees it via its test hook; the game sees the controller's output.
void feed(uint64 k,int x,int y,int rx){
 simActive=true;simHeld=k;simLX=x;simLY=y;simRX=rx;simRY=0;controllerFrame(tp);
 if(overrideActive)input(1,outButtons,outLX,outLY,outRX,outRY);else input(1,k,x,y,rx,0);
}
// Mario Kart controls: positive "throttle" holds A, negative holds B.
uint64 pedal(int y){return y>0?uint64(A):y<0?uint64(B):0;}
// Turn the parked kart in place (yaw, radians) so the trailing camera sees Link from the side / front.
void turnKart(float d){ActorBase@ k=getKart();if(k is null)return;Matrix33f r=k.rot;float y=atan2(r.a2,r.a8)+d;
 k.setRot(cos(y),0,sin(y),0,1,0,-sin(y),0,cos(y));}
void tilt(uint n,int ry,const string &in l){
 sys::debugLog("VIS "+l);
 for(uint f=0;f<n && worldReady();f++){simActive=true;simHeld=0;simLX=0;simLY=0;simRX=0;simRY=ry;controllerFrame(tp);
  if(overrideActive)input(1,outButtons,outLX,outLY,outRX,ry);else input(1,0,0,0,0,ry);}
}
void hold(uint n,int x,int y,int rx,const string &in l){
 sys::debugLog("VIS "+l+" spin="+spinFront+" steer="+wheelSteer);
 for(uint f=0;f<n && worldReady();f++)feed(pedal(y),x,0,rx);
}
void main(){
 initKart();tp=resolvePadInput();if(tp==0)return;
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady())return;
 controllerFrame(tp);feed(uint64(ZL|ZR|DUP),0,0,0);
 for(uint f=0;f<165;f++)feed(0,0,0,0);
 mountKart();
 if(!playerIsRiding(getKart())){sys::debugLog("VIS mount failed");return;}
 feed(0,0,0,0);
 hold(60,0,9000,0,"forward");
 hold(90,0,0,0,"stop");
 hold(25,0,0,32767,"camera");hold(200,0,0,0,"pose-side");
 tilt(20,32767,"tilt-a");hold(150,0,0,0,"pose-top-a");tilt(40,-32767,"tilt-b");hold(150,0,0,0,"pose-top-b");
 tilt(20,32767,"tilt-c");hold(150,32767,0,0,"lean-right");hold(150,-32767,0,0,"lean-left");
 while(true){hold(90,32767,0,0,"right");hold(90,-32767,0,0,"left");}
}
'''


def main():
    src = (CAND / 'controller.src.as').read_text()
    autorun = minify(src)
    n = len(autorun.encode())
    assert n < 65536, ('autorun', n)
    (CAND / 'autorun.as').write_text(autorun)
    print(CAND / 'autorun.as', n)

    prefix = src[:src.index('void main(){')]
    for long in ('Kart ready: approach and press A. Left stick drives; B dismounts.\\n',
                 'Dismount before recalling the kart.\\n', 'KartLab: spawn unavailable.\\n'):
        assert long in prefix, long
        prefix = prefix.replace(long, 'K')  # test build only: toast text is not under test
    for name, body in (('native_wheels_regression.as', test_body().replace(' RECALL_PART\n', '')),
                       ('native_wheels_recall.as', recall_body()),
                       ('native_wheels_visual.as', visual_body())):
        test = minify(prefix + body, wrap=True)
        n = len(test.encode())
        assert n < 65536, (name, n)
        out = ROOT / 'runtime/diagnostics' / name
        out.write_text(test)
        print(out, n)


if __name__ == '__main__':
    main()
