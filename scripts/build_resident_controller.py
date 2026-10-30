#!/usr/bin/env python3
"""Bundle the bounded lab controls into one startup-compiled script."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
s=(ROOT/'runtime/candidates/stable-controls/drive_pad.as').read_text()
a=s.index('bool driving=false;');b=s.index('void runPadDrive()',a);s=s[:a]+s[b:]
a=s.index('        if (frame%120==0)');b=s.index('        @body=null;@cart=null;',a);s=s[:a]+s[b:]
s=s.replace('KartLab pad v3:','KartLab resident:')
a=s.index('bool padCartReady()');b=s.index('void releasePadCamera()',a)
s=s[:a]+'''ptr_t currentCart=0;
bool padCartReady() {
 if (!padWorldReady()) return false;
 ActorBase@ cart=ActorWatcher::get(1);
 if (cart is null || cart.getMainRigidBody() is null) return false;
 ptr_t id=ptr_from_ActorBase(cart);
 if (currentCart==0) {
  if (cart.getName()!="SpObj_Cart_A_01") return false;
  currentCart=id;
 }
 return currentCart==id;
}
'''+s[b:]
s=s.replace('void runPadDrive() {','void runPadDrive() {\n    currentCart=0;')

spawn=(ROOT/'runtime/candidates/usable-controls/spawn.as').read_text();spawn=spawn[spawn.index('void spawnCart()'):]
clear=(ROOT/'runtime/scripts/clear.as').read_text().replace('void main()','void clearKart()')
main='''
void main() {
 for (uint i=0;i<4;i++) {
  ActorWatcher::doTextWriter(i,false);ActorWatcher::doWSLog(i,false);ActorWatcher::clearSlot(i);
 }
 ptr_t pad=resolvePadInput();
 if (pad==0) { TextWriter::toast(300,"KartLab: input bridge mismatch.\\n");return; }
 sys::debugLog("KartLab resident controller: ready; all controls compiled.");
 TextWriter::toast(300,"KartLab: ZL+ZR+Up spawn; Right drive; Down clear. Left stick drives; B exits.\\n");
 bool latched=false,loadCleared=false;
 uint64 mask=uint64(ZL|ZR|DUP|DRIGHT|DDOWN);
 while (true) {
  if (Player is null || pause::isPauseRequest("LoadingPause")) {
   if (!loadCleared) { ActorWatcher::clearSlot(1);ActorWatcher::clearSlot(2);loadCleared=true; }
   latched=true;sleep(1);continue;
  }
  loadCleared=false;
  uint64 held=ptr_deref_u64(pad);
  if ((held & mask)==0) latched=false;
  if (!latched && padWorldReady()) {
   if (held==uint64(ZL|ZR|DUP)) { latched=true;spawnCart(); }
   else if (held==uint64(ZL|ZR|DRIGHT)) { latched=true;runPadDrive(); }
   else if (held==uint64(ZL|ZR|DDOWN)) { latched=true;clearKart(); }
  }
  sleep(1);
 }
}
'''
s=s+'\n'+spawn+'\n'+clear+'\n'+main
# Keep the readable source candidates separately. Compact only whitespace and
# full-line/comments here to fit the pinned loader's 8192-byte file buffer.
s=re.sub(r'//[^\n]*','',s);s='\n'.join(l.strip()for l in s.splitlines()if l.strip())+'\n'
assert len(s.encode())<8192,len(s.encode())
out=ROOT/'runtime/candidates/resident-controls/autorun.as';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(s)
print('Resident script bytes:',len(s.encode()))
if __name__!='__main__': raise RuntimeError('Run as script')
