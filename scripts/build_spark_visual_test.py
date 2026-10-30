#!/usr/bin/env python3
"""Build runtime/diagnostics/native_spark_visual.as: drift sparks / boost flame visual check.

Drives a full-lock circle at the open field, then drifts right while holding each mini-turbo tier for 150
logical frames (test-only clamp on driftCharge so screenshots can catch each colour), releases into the
ultra mini-turbo boost, and keeps driving. Logs `SPK <phase>` lines; the screenshots are taken outside.
"""
from pathlib import Path
from build_native_wheels import minify, CAND

ROOT = Path(__file__).resolve().parents[1]

BODY = r'''
ptr_t tp=0;
void feed(uint64 k,int x,int y,int rx,int ry=0){
 simActive=true;simHeld=k;simLX=x;simLY=y;simRX=rx;simRY=ry;controllerFrame(tp);
 if(overrideActive)input(1,outButtons,outLX,outLY,outRX,outRY);else input(1,k,x,y,rx,ry);
}
void spk(const string &in l){ActorBase@ a=getKart();sys::debugLog("SPK "+l+(a is null?"":" pos="+a.pos_x+","+a.pos_y+","+a.pos_z)+" v="+driveSpeed+" tier="+driftTier+" charge="+driftCharge+" boost="+boostLeft+" live0="+(fxScr!=0 && fxLive(0)!=0)+" live1="+(fxScr!=0 && fxLive(1)!=0)+" ground="+groundMat+"/"+groundSlot+" d="+groundDist+" cam="+camFrozen+" ch="+camHx+","+camHz+" f="+camFx+","+camFz+" d="+camDist+" wb="+(a !is null && wheelBones(a)!=0)+" mounted="+playerIsRiding(a));}
void main(){
 initKart();devChords=true;tp=resolvePadInput();if(tp==0)return;
 input(180,0);
 for(uint n=0;n<35 && !(worldReady() && Player.pos_x< -100 && Player.pos_x> -400);n++){input(1,1);input(90,0);}
 input(60,0);if(!worldReady())return;
 matLog("start");input(30,0);matLog("start2");
 Player.setPos(-118,127.8,-62);input(90,0);for(uint w=0;w<200 && !(worldReady() && abs(Player.pos_x+118)<20);w++)input(10,0);input(60,0);if(!worldReady())return;
 Player.setRot(0,0,1,0,1,0,-1,0,0);input(10,0);   // face east, away from the kart chests at x -156
 matLog("field");
 controllerFrame(tp);feed(uint64(ZL|ZR|DUP),0,0,0);
 for(uint f=0;f<25;f++)feed(0,0,0,0);
 for(uint t=0;t<10 && !playerIsRiding(getKart());t++){
  ActorBase@ k=getKart();if(k is null){input(10,0);continue;}
  Matrix33f r=k.rot;float px=k.pos_x+1.4f*r.a0,pz=k.pos_z+1.4f*r.a6;
  float fx=k.pos_x-px,fz=k.pos_z-pz,n=sqrt(fx*fx+fz*fz);fx/=n;fz/=n;
  Player.setRot(fz,0,fx,0,1,0,-fx,0,fz);input(2,0);Player.setPos(px,k.pos_y+0.3f,pz);input(20,0);
  sys::debugLog("SPK try mount t="+t+" kart="+k.pos_x+","+k.pos_z+" player="+Player.pos_x+","+Player.pos_z);
  input(1,1);input(30,0);
 }
 if(!playerIsRiding(getKart())){sys::debugLog("SPK mount failed");return;}
 feed(0,0,0,0);
 for(uint f=0;f<60 && worldReady();f++){feed(uint64(A),0,0,0);if(f%30==0)spk("run"+f);}
 spk("drift-start");
 for(uint k=0;k<3;k++){
  bool told=false;
  for(uint f=0;f<220 && worldReady();f++){
   feed(uint64(A|R),32767,0,0);
   float cap=k==0?CHARGE_MT+1:k==1?CHARGE_SMT+1:CHARGE_UMT+1;if(driftCharge>cap)driftCharge=cap;
   if(!told && driftTier==int(k)+1){told=true;spk("hold"+(k+1));}
   if(f%30==0)spk("d"+k+"_"+f);
  }
 }
 spk("release");
 for(uint f=0;f<20 && worldReady();f++)feed(uint64(A),32767,0,0);
 spk("boosting");
 for(uint f=0;f<160 && worldReady();f++)feed(uint64(A),32767,0,0);
 spk("after");
 feed(uint64(X),0,0,0);for(uint f=0;f<30;f++)feed(0,0,0,0);
 spk("exit");
 sys::debugLog("SPK finished");simActive=false;input(1,0);runResident(tp);
}
'''

MATPROBE = r'''
// Ground material probe: query 0x20e0540 reads *(*(obj+0x20)+0x20+0x78) and names it via *(main+0x4637298)+0x250.
string matName(int i){if(i<0||i>=54)return "?";ptr_t t=ptr_deref_u64(sys::mainOffset()+0x4637298);if(t==0)return "?";ptr_t s=ptr_deref_u64(t+0x250+8*i);string r="";for(int k=0;k<32&&s!=0;k++){u8 c=ptr_deref_u8(s+k);if(c==0)break;r+=" ";r[r.length()-1]=c;}return r;}
bool pok(ptr_t p){return p>0x1000000 && p<0x8000000000 && (p&7)==0;}
// actor+0x228 -> +0x50 -> +0x20 -> +0x10 = physics component (game 0xc40558); +8 -> obj; *(obj+0x20)+0x20 = ground info
ptr_t groundInfo(ActorBase@ a){if(a is null)return 0;ptr_t p=ptr_deref_u64(ptr_from_ActorBase(a)+0x228);if(!pok(p))return 0;p=ptr_deref_u64(p+0x50);if(!pok(p))return 0;
 p=ptr_deref_u64(p+0x20);if(!pok(p))return 0;p=ptr_deref_u64(p+0x10);if(!pok(p))return 0;p=ptr_deref_u64(p+8);if(!pok(p))return 0;p=ptr_deref_u64(p+0x20);if(!pok(p))return 0;return p+0x20;}
string matOf(ActorBase@ a){ptr_t g=groundInfo(a);if(g==0)return "none";int m=ptr_deref_s32(g+0x78);return ""+m+":"+matName(m)+" f="+ptr_deref_u8(g+0x110)+","+ptr_deref_u8(g+0x111);}
string chainOf(ActorBase@ a){if(a is null)return "null";string r="";ptr_t p=ptr_from_ActorBase(a);
 for(uint i=0;i<6;i++){uint o=i==0?0x228:i==1?0x50:i==2?0x20:i==3?0x10:i==4?8:0x20;p=ptr_deref_u64(p+o);r+=" "+formatInt(int64(p),"H");if(!pok(p))break;}return r;}
// Downward ray cast through the game's own query (QueryPhysicsRayCastDistanceToGroundFromPosition evaluate 0x20e4da4),
// run on a fake query object in scratch: vptr main+0x4578958, params/outputs are plain pointers into scratch.
string rayAt(float x,float y,float z){
 if(!fxReady())return "nofx";
 ptr_t q=fxScr+0x5000,v=fxScr+0x5100,p1=fxScr+0x5200,p2=fxScr+0x5300;
 for(uint i=0;i<0x100;i+=8){ptr_write_u64(q+i,0);ptr_write_u64(v+i,0);}
 ptr_write_u64(p1+8,p2);ptr_write_u64(p2+0x1f8,ptr_from_ActorBase(Player));
 ptr_write_u64(q,fxM+0x4578958);ptr_write_u64(q+8,p1);
 ptr_write_u64(q+0x20,v);ptr_write_u64(q+0x28,v);ptr_write_u64(q+0x30,v);ptr_write_u64(q+0x40,v);
 ptr_write_float(v+4,3.0f);ptr_write_u64(q+0x38,v+4);
 ptr_write_u64(q+0x48,v+0x10);ptr_write_u64(q+0x50,v+0x14);ptr_write_u64(q+0x58,v+0x18);ptr_write_u64(q+0x60,v+0x20);
 ptr_write_u64(q+0x68,v+0x30);ptr_write_u64(q+0x70,v+0x40);ptr_write_u64(q+0x78,v+0x44);
 ptr_write_float(v+0x50,x);ptr_write_float(v+0x54,y);ptr_write_float(v+0x58,z);ptr_write_u64(q+0x80,v+0x50);ptr_write_u64(q+0x88,v+0x60);
 ptr_call(fxM+0x20e4da4,q,0,0,0,0,0,0,0,0,0,0);
 int m=ptr_deref_s32(v+0x40);
 return "hit="+ptr_deref_u8(v+0x10)+" d="+ptr_deref_float(v+0x14)+" f58="+ptr_deref_float(v+0x18)+" n="+ptr_deref_float(v+0x20)+","+ptr_deref_float(v+0x24)+","+ptr_deref_float(v+0x28)+" m="+m+":"+matName(m)+" b="+ptr_deref_u8(v+0x44);
}
void matLog(const string &in l){ActorBase@ k=getKart();
 sys::debugLog("MAT "+l+" player="+matOf(Player)+" rayP="+rayAt(Player.pos_x,Player.pos_y+0.5f,Player.pos_z)+(k is null?"":" rayK="+rayAt(k.pos_x,k.pos_y+0.2f,k.pos_z)));}
'''
src = (CAND / 'controller.src.as').read_text()
import os
if os.environ.get('AIRTEST'):
    a=BODY.index(' spk("drift-start");');b=BODY.index(' sys::debugLog("SPK finished");')
    BODY=BODY[:a]+r'''
 // Glider first (flat field, right after the run-up): launch 24 m/s, open with Y near the top, glide, then push forward to dive.
 ActorBase@ k=getKart();Vector3f lv=k.getMainRigidBody().vel;k.getMainRigidBody().setVel(lv.x,24.0f,lv.z);
 for(uint f=0;f<14 && worldReady();f++){if(f<5){@k=getKart();lv=k.getMainRigidBody().vel;k.getMainRigidBody().setVel(lv.x,24.0f,lv.z);}feed(uint64(A),0,0,0);if(f%3==0)spk("launch"+f);}
 feed(uint64(A|Y),0,0,0);feed(uint64(A),0,0,0);spk("glider-pressed");
 for(uint f=0;f<240 && worldReady() && (f<5||airborne);f++){int gx=(f>=20&&f<55)?32767:(f>=55&&f<90)?-32767:0;feed(uint64(A),gx,(f>90?32767:0),0);if(f%5==0){Matrix33f gr=getKart().rot;spk("glide"+f+" up="+gr.a1+","+gr.a4+","+gr.a7+" stick="+gx);}}
 for(uint f=0;f<150 && worldReady();f++){feed(0,0,0,0);if(f%30==0)spk("afterglide"+f);}
 // Jump + trick: launch upward (6 m/s, ~1.8 m), press R just after take-off.
 @k=getKart();lv=k.getMainRigidBody().vel;k.getMainRigidBody().setVel(lv.x,12.0f,lv.z);
 for(uint f=0;f<60 && worldReady();f++){feed(uint64(A)|(f==0?uint64(R):0),0,0,0);if(f%3==0)spk("jump"+f);}
 for(uint f=0;f<40 && worldReady();f++){feed(uint64(A),0,0,0);if(f%10==0)spk("afterjump"+f);}
 for(uint f=0;f<180 && worldReady();f++){feed(uint64(A),0,0,0);if(f%30==0)spk("preglide"+f);}

'''+BODY[b:]
    BODY=BODY.replace('+" mounted="+playerIsRiding(a));}','+" air="+airborne+" glide="+gliding+" gscale="+gliderScale+" crec="+((a is null||hostBones(a)==0)?-1:ptr_deref_float(hostBones(a)-192))+","+((a is null||hostBones(a)==0)?-1:ptr_deref_float(hostBones(a)-192+52))+" trick="+trickDone+" vy="+(a is null?0:a.getMainRigidBody().vel.y)+" gd="+groundDist+" mounted="+playerIsRiding(a));}',1)
if os.environ.get('MENUTEST'):
    a=BODY.index(' spk("drift-start");');b=BODY.index(' sys::debugLog("SPK finished");')
    BODY=BODY[:a]+r'''
 for(uint f=0;f<30 && worldReady();f++)feed(0,0,0,0);
 pmLog("before");
 for(uint m=0;m<2;m++){
  uint64 btn=m==0?uint64(PLUS):uint64(MINUS);
  feed(btn,0,0,0);feed(btn,0,0,0);
  for(uint f=0;f<90;f++){feed(0,0,0,0);if(f%15==0)pmLog((m==0?"pausemenu":"map")+f);}
  feed(btn,0,0,0);feed(btn,0,0,0);
  for(uint f=0;f<90;f++){feed(0,0,0,0);if(f%30==0)pmLog((m==0?"closed-pause":"closed-map")+f);}
 }
'''+BODY[b:]
    BODY=BODY.replace('void spk(const string &in l){', 'string pr(const string &in n){return pause::isPauseRequest(n)?" R:"+n:"";}\nstring pt(const string &in n){return pause::isPauseTarget(n)?" T:"+n:"";}\nvoid pmLog(const string &in l){string r=pr("GamePause")+pr("GamePauseWithoutEvent")+pr("Pause")+pr("ClickPause")+pr("EventBancChangePause")+pr("PreGamePause")+pr("PostGamePause")+pr("AutoBuilderPause")+pr("LoadingPause")+pt("Actor")+pt("Custom_PhysicsUpdateWorld")+pt("Physics")+pt("Player")+pt("Event")+pt("UI")+pt("Camera");sys::debugLog("PM "+l+r+" ride="+wasRiding+" ov="+overrideActive);}\nvoid spk(const string &in l){',1)
if os.environ.get('HIGHTEST'):
    a=BODY.index(' spk("drift-start");');b=BODY.index(' sys::debugLog("SPK finished");')
    BODY=BODY[:a]+r'''
 // High launch: ~45 m/s up for 12 frames, open the glider near the top, glide straight until landing or dismount.
 ActorBase@ k=getKart();float y0=k.pos_y;
 for(uint f=0;f<HIGHFRAMES && worldReady();f++){@k=getKart();Vector3f lv=k.getMainRigidBody().vel;k.getMainRigidBody().setVel(lv.x,60.0f,lv.z);feed(uint64(A),0,0,0);}
 for(uint f=0;f<150 && worldReady();f++){feed(uint64(A),0,0,0);@k=getKart();if(k.getMainRigidBody().vel.y<2)break;}
 feed(uint64(A|Y),0,0,0);feed(uint64(A),0,0,0);
 for(uint f=0;f<1800 && worldReady();f++){
  feed(uint64(A),0,0,0);@k=getKart();
  if(f%15==0 || !playerIsRiding(k))sys::debugLog("HI f="+f+" h="+(k.pos_y-y0)+" vy="+k.getMainRigidBody().vel.y+" pvy="+Player.getMainRigidBody().vel.y+" py="+(Player.pos_y-y0)+" glide="+gliding+" air="+airborne+" ride="+playerIsRiding(k));
  if(!playerIsRiding(k) || (!airborne && f>30))break;
 }
'''+BODY[b:]
if os.environ.get('HIGHTEST'): BODY=BODY.replace('HIGHFRAMES',os.environ.get('HIGHFRAMES','12'))
if os.environ.get('NOGLIDE'): BODY=BODY.replace(' feed(uint64(A|Y),0,0,0);feed(uint64(A),0,0,0);\n for(uint f=0;f<1800',' feed(uint64(A),0,0,0);feed(uint64(A),0,0,0);\n for(uint f=0;f<1800',1).replace('if(f%15==0 || !playerIsRiding(k))sys::debugLog("HI','if(f%3==0 || !playerIsRiding(k))sys::debugLog("HI',1)
if os.environ.get('FALLPROBE'):
    BODY=BODY.replace(' for(uint f=0;f<1800 && worldReady();f++){',' float pmax=-99999;\n for(uint f=0;f<1800 && worldReady();f++){if(Player.pos_y>pmax)pmax=Player.pos_y;if(f==27){ptr_t P=ptr_from_ActorBase(Player);for(uint o=0;o<0x4000;o+=4){float v=ptr_deref_float(P+o);if(abs(v-pmax)<2.0f)sys::debugLog("FP A+"+o+"="+v+" max="+pmax+" now="+Player.pos_y);}}',1)
if os.environ.get('TIMERPROBE'):
    BODY=BODY  # TPW0/TPW1 set below
    BODY=BODY.replace(' for(uint f=0;f<1800 && worldReady();f++){',' for(uint f=0;f<1800 && worldReady();f++){tpFrame(f);',1)
    BODY=BODY.replace('void spk(const string &in l){',"""uint n=0;
bool tpg(ptr_t p){return p>0x1000000 && p<0x8000000000 && (p&7)==0;}
void tpAdd(ptr_t a){if(n>=1400)return;ptr_write_u64(fxScr+0x1000+16*n,a);ptr_write_u64(fxScr+0x1008+16*n,uint64(ptr_deref_u32(a)));n++;}
void tpScan(ptr_t base,uint len){for(uint o=0;o<len;o+=4){float v=ptr_deref_float(base+o);int iv=ptr_deref_s32(base+o);if((abs(v)>0.05f&&abs(v)<5.0f)||(iv>=-200&&iv<=200&&iv!=0))tpAdd(base+o);}}
void tpFrame(uint f){
 if(f==35){n=0;for(uint w=TPW0;w<TPW1;w++){ptr_t A=w==0?ptr_from_ActorBase(Player):ptr_from_ActorBase(getKart());tpScan(A,0x4000);ptr_t tbl=ptr_deref_u64(A+0x228);
  if(tpg(tbl)){for(uint k=0;k<48;k++){ptr_t c=ptr_deref_u64(tbl+8*k);if(tpg(c))tpScan(c,0x1000);}}}
  sys::debugLog("TPN cand="+n);}
 if(f==36 || f==37){uint keep=0;for(uint i=0;i<n;i++){ptr_t a=ptr_deref_u64(fxScr+0x1000+16*i);float fo=ptr_deref_float(fxScr+0x1008+16*i),fn=ptr_deref_float(a);int io=ptr_deref_s32(fxScr+0x1008+16*i),inw=ptr_deref_s32(a);
   float df=abs(fn-fo);int di=inw-io;if(di<0)di=-di;bool ok=(abs(df-0.0333f)<0.006f)||(abs(df-0.0167f)<0.004f)||(di==1)||(di==2);
   if(ok){ptr_write_u64(fxScr+0x1000+16*keep,a);ptr_write_u64(fxScr+0x1008+16*keep,uint64(ptr_deref_u32(a)));keep++;}}
  n=keep;sys::debugLog("TPN f="+f+" keep="+n);
  if(f==37){ptr_t K=ptr_from_ActorBase(getKart());ptr_t A=ptr_from_ActorBase(Player);ptr_t tbl=ptr_deref_u64(A+0x228);for(uint i=0;i<n && i<40;i++){ptr_t a=ptr_deref_u64(fxScr+0x1000+16*i);string where="?";if(a>=A && a<A+0x4000)where="P+"+(a-A);else if(tpg(tbl)){for(uint k=0;k<48;k++){ptr_t c=ptr_deref_u64(tbl+8*k);if(tpg(c)&&a>=c&&a<c+0x1000){where="C"+k+"+"+(a-c);break;}}}
   if(where=="?" && a>=K && a<K+0x4000)where="K+"+(a-K);sys::debugLog("TP "+where+" f="+ptr_deref_float(a)+" i="+ptr_deref_s32(a));}}}
}
void spk(const string &in l){""",1)
if os.environ.get('TIMERPROBE'):
    w=os.environ.get('TPWHO','K'); BODY=BODY.replace('TPW0','0' if w=='P' else '1').replace('TPW1','1' if w=='P' else '2')
if os.environ.get('DIVETURN'):
    BODY=BODY.replace('  feed(uint64(A),0,0,0);@k=getKart();\n  if(f%15==0','  int sx=(f/150)%2==0?32767:-32767,sy=f>60?32767:0;feed(uint64(A),sx,sy,0);@k=getKart();Matrix33f kr=k.rot;\n  if(f%15==0',1).replace('+" ride="+playerIsRiding(k));','+" up="+kr.a1+","+kr.a4+","+kr.a7+" stick="+sx+","+sy+" lat="+(k.getMainRigidBody().vel.x*kr.a0+k.getMainRigidBody().vel.z*kr.a6)+" fwd="+(k.getMainRigidBody().vel.x*kr.a2+k.getMainRigidBody().vel.z*kr.a8)+" ride="+playerIsRiding(k));',1)
if os.environ.get('CAMTEST'):
    a=BODY.index(' spk("drift-start");');b=BODY.index(' sys::debugLog("SPK finished");')
    BODY=BODY[:a]+r'''
 for(uint f=0;f<60 && worldReady();f++)feed(0,0,0,0);
 for(uint f=0;f<70 && worldReady();f++)feed(0,0,0,32767,0);spk("side-right");for(uint f=0;f<40;f++)feed(0,0,0,32767,0);
 for(uint f=0;f<70 && worldReady();f++)feed(0,0,0,-32767,0);spk("side-left");for(uint f=0;f<40;f++)feed(0,0,0,-32767,0);
 for(uint f=0;f<40 && worldReady();f++)feed(0,0,0,0,0);spk("behind");for(uint f=0;f<40;f++)feed(0,0,0,0,0);
 for(uint f=0;f<40 && worldReady();f++)feed(0,0,0,0,-32767);spk("front");for(uint f=0;f<40;f++)feed(0,0,0,0,-32767);
'''+BODY[b:]
if os.environ.get('RIDESCAN'):
    # Where does the Player keep the actor he rides? Scan Player and his components for the kart pointer / its link data.
    BODY=BODY.replace('void spk(const string &in l){',r"""void scanBlock(ptr_t base,uint len,ptr_t k,ptr_t kl,const string &in tag){
 for(uint o=0;o<len;o+=8){ptr_t v=ptr_deref_u64(base+o);if(v==k)sys::debugLog("RSCAN "+tag+" +"+formatInt(o,"H")+" = kart");else if(v==kl)sys::debugLog("RSCAN "+tag+" +"+formatInt(o,"H")+" = kartLink");}
}
void rideScan(){
 ActorBase@ a=getKart();if(a is null || Player is null)return;ptr_t k=ptr_from_ActorBase(a),kl=ptr_deref_u64(k+0x1a8),p=ptr_from_ActorBase(Player);
 sys::debugLog("RSCAN start kart="+formatInt(int64(k),"H")+" link="+formatInt(int64(kl),"H")+" name="+a.getName()+" player="+formatInt(int64(p),"H"));
 scanBlock(p,0x1800,k,kl,"player");
 uint n=ptr_deref_u32(p+0x220);ptr_t list=ptr_deref_u64(p+0x228);if(n>600 || !gptr(list))return;
 for(uint i=0;i<n;i++){ptr_t c=ptr_deref_u64(list+8*i);if(!gptr(c))continue;scanBlock(c,0x200,k,kl,"comp"+i);}
 sys::debugLog("RSCAN done n="+n);
}
void spk(const string &in l){""",1).replace(' spk("drift-start");',' rideScan();sys::debugLog("SPK finished");simActive=false;input(1,0);runResident(tp);return;\n spk("drift-start");',1)
if os.environ.get('KARTTYPE'): BODY=BODY.replace('controllerFrame(tp);feed(uint64(ZL|ZR|DUP),0,0,0);','kartType='+os.environ['KARTTYPE']+';controllerFrame(tp);feed(uint64(ZL|ZR|DUP),0,0,0);',1)
if os.environ.get('OFFROADTEST'):
    a=BODY.index(' spk("drift-start");');b=BODY.index(' sys::debugLog("SPK finished");')
    BODY=BODY[:a]+r'''
 feed(uint64(ZL|ZR|DDOWN),0,0,0);feed(0,0,0,0);spk("toggled-on offroad="+offroadOn);
 for(uint f=0;f<150 && worldReady();f++){feed(uint64(A),0,0,0);if(f%30==0)spk("on"+f+" factor="+terrainSpeedFactor());}
 feed(uint64(ZL|ZR|DDOWN),0,0,0);feed(0,0,0,0);spk("toggled-off offroad="+offroadOn);
 for(uint f=0;f<150 && worldReady();f++){feed(uint64(A),0,0,0);if(f%30==0)spk("off"+f+" factor="+terrainSpeedFactor());}
'''+BODY[b:]
if os.environ.get('STRAIGHT'): BODY = BODY.replace('for(uint f=0;f<60 && worldReady();f++){feed(uint64(A),0,0,0);', 'for(uint f=0;f<'+os.environ['STRAIGHT']+' && worldReady();f++){gcycle(f);feed(uint64(A),0,0,0);')
GCYCLE = r'''
void gcycle(uint f){
 if(f%75!=0)return;uint k=f/75;
 string n=k==0?"Ply_SlipSmoke_Grass_Green":k==1?"ReFX_Grass_M":k==2?"HorseStep_Grass_Tmp":k==3?"Ply_FootEffect_Grass_Green":"ReFX_Grass_L";
 groundEffectTest=n;gid0=-2;groundStopAll();groundSlot=-1;
sys::debugLog("GRASS "+n);
}
void gstate(){ptr_t e=fxScr==0?0:fxLive(3);if(e==0){sys::debugLog("GSTATE none");return;}
 sys::debugLog("GSTATE e8="+ptr_deref_s16(e+0xe8)+" f38="+ptr_deref_u32(e+0x38)+" 4c="+ptr_deref_float(e+0x4c)+" 5c="+ptr_deref_float(e+0x5c)+" 24c="+ptr_deref_float(e+0x24c)+" 250="+ptr_deref_float(e+0x250)+" 254="+ptr_deref_float(e+0x254)+" 25c="+ptr_deref_float(e+0x25c)+" 260="+ptr_deref_float(e+0x260));}
'''
BODY = GCYCLE + BODY.replace('void spk(const string &in l){', 'void spk(const string &in l){gstate();')
BODY = BODY.replace('void spk(const string &in l){', MATPROBE + 'void spk(const string &in l){' + ('matLog(l);' if os.environ.get('MATPROBE') else ''))
if os.environ.get('NOFX'): src = src.replace(' sparkFrame(getKart());\n', '')
prefix = src[:src.index('void main(){')]
text = minify(prefix + BODY, wrap=True)
assert len(text.encode()) < 65536
out = ROOT / ('runtime/diagnostics/native_spark_visual_nofx.as' if os.environ.get('NOFX') else os.environ.get('OUTFILE','runtime/diagnostics/native_spark_visual.as'))
out.write_text(text)
print(out, len(text.encode()))
