"""Shorten only known internal identifiers in generated diagnostic scripts.

Quoted strings and all registered game/runtime API names remain untouched.
Normal distributed controller source stays readable and unmodified.
"""
import re
NAMES=['playerOccupiesNativeSeat','riderHostIdentity','riderGuestPointer','worldReady','locationReady','controllerFrame','resolvePadInput','getKart','spawnKart','parkKart','stopKart','runResident','updateDrive','forgetKart','initKart','playerIsRiding','kartAddress','kartId','driveSpeed','wasRiding','parked','parkLocked','parkStable','spawnDelay','chordLatched','spawnPending','loadCleared','expectedHostID','playerLinkData','seatArray','playerID','playerState','linkData','cooldown','guestPointer']
ALIASES={name:'_k'+str(i)for i,name in enumerate(NAMES)}
def compact(source):
 # Our generated scripts have no block comments; strip full comment lines first.
 source='\n'.join(line.strip()for line in source.splitlines()if line.strip()and not line.lstrip().startswith('//'))+'\n'
 assert not any(alias in source for alias in ALIASES.values()),'Reserved diagnostic alias already in source'
 return re.sub(r'"(?:[^"\\]|\\.)*"|\b[A-Za-z_]\w*\b',lambda m:ALIASES.get(m[0],m[0])if not m[0].startswith('"')else m[0],source)
