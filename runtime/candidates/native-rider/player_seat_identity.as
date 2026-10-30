// Read-only TOTK 1.1.0 snapshot helper; no registered native calls or writes.
// Compile into a controller module, not execFile: this file has no main().
// A raw watcher pointer is NOT a lifetime-owning ActorBaseLink. These guards
// reject ID reuse/finalization but cannot make freed/unmapped memory safe.
bool riderGuestPointer(ptr_t p) {
 return p>=0x10000 && p<0x100000000000 && (p&7)==0;
}
bool riderHostIdentity(ActorBase@ host,uint expectedHostID) {
 if(host is null || expectedHostID==0xffffffff)return false;
 ptr_t p=ptr_from_ActorBase(host);
 if(!riderGuestPointer(p) || ptr_deref_u32(p+0x10)!=expectedHostID)return false;
 // Exact native resolver rejects states 7..11 (finalization/deletion).
 // This snapshot additionally rejects initialization and undefined states.
 uint state=ptr_deref_u32(p+0x24);
 return state>=2 && state<=6;
}
bool playerOccupiesNativeSeat(ActorBase@ host,uint expectedHostID) {
 if(Player is null || !riderHostIdentity(host,expectedHostID))return false;
 ptr_t actor=ptr_from_ActorBase(host),player=ptr_from_ActorBase(Player);
 if(!riderGuestPointer(player))return false;
 uint playerID=ptr_deref_u32(player+0x10);
 if(playerID==0xffffffff)return false;
 uint playerState=ptr_deref_u32(player+0x24);
 if(playerState<2 || playerState>6)return false;
 uint count=ptr_deref_u32(actor+0x220);ptr_t list=ptr_deref_u64(actor+0x228);
 if(count<=129 || count>512 || !riderGuestPointer(list))return false;
 ptr_t component=ptr_deref_u64(list+0x408);
 if(!riderGuestPointer(component))return false;
 uint seats=ptr_deref_u32(component+0x20);ptr_t seatArray=ptr_deref_u64(component+0x28);
 if(seats!=1 || !riderGuestPointer(seatArray))return false;
 ptr_t seat=ptr_deref_u64(seatArray);
 if(!riderGuestPointer(seat))return false;
 uint seatID=ptr_deref_u32(seat+0x10),flags=ptr_deref_u32(seat+0x18);
 float cooldown=ptr_deref_float(seat+0x74);
 if(seatID!=playerID || flags==0 || !(cooldown<=0 && cooldown>=-1000))return false;
 ptr_t linkData=ptr_deref_u64(seat+8),playerLinkData=ptr_deref_u64(player+0x1a8);
 // Never dereference an unknown occupant: require known Player link equality.
 if(linkData!=playerLinkData || !riderGuestPointer(playerLinkData))return false;
 if(ptr_deref_u32(playerLinkData+0x48)!=playerID || ptr_deref_u64(playerLinkData+0x40)!=player)return false;
 // Refresh identity after the component traversal. No handles cross a sleep.
 return riderHostIdentity(host,expectedHostID) && ptr_deref_u32(player+0x10)==playerID;
}
