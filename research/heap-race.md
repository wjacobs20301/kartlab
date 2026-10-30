# "Pointer overwritten with actor-name text" crash — cause and fix

Oct 17, 2026. Runtime fix: `runtime/candidates/malloc-lock-110/subsdk9` (built by `scripts/patch_lotuskit_malloc_lock_110.py`
on top of `native-heap-110`). Test: `runtime/diagnostics/heap_stress_test.as` (`scripts/build_heap_stress_test.py`).

## Symptom

Ryujinx: `Unhandled exception … InvalidMemoryRegionException: va=<8 ASCII bytes>`, on a game thread (usually 96) or the
script thread, often right after mounting the kart or at the start of a test, once at the title screen. The Apple
Hypervisor backend logs no guest PC.

| Log | va | bytes (LE) |
| --- | --- | --- |
| `.work/ryujinx-handling-4.log` | `0x63726963204C4460` | `` `DL circ `` = "HDL circ" + 0x18 (a script log string) |
| `.work/ryujinx-vfx-spawn4.log` | `0x535F6E6F7061656F` | "oeapon_S" = "Weapon_S" + 0x18 |
| (reported) | `0x694C5F6573726F48`→…60 | "Horse_Li" + 0x18 |
| (reported, script thread) | | "Kart_Gli" + 0x18 |

**Every fault address is the first 8 bytes of a string plus 0x18.** In newlib (dlmalloc) a free chunk is
`{prev_size, size, fd, bk}`; `fd` is the first 8 bytes of the old user data. Taking a chunk off a bin does
`FD = P->fd; FD->bk = BK` — a write to `fd + 0x18`. So: a chunk sitting in a free list had a string written over its
`fd`. That is what two threads in malloc/free at the same time produce (one thread hands out or reuses a chunk the other
thread is still linking).

## Cause: LotusKit's malloc has no lock, and it is used from several threads

* `__malloc_lock` (0x203de0) → `__libc_lock_acquire_recursive` (0x21ac80) = `adrp; ldr x1,[GOT]; cbz x1; nop; ret`.
  The lock call was a weak-undefined hook; the linker made it a `nop`. `__malloc_unlock` is the same. **malloc, free and
  realloc run with no lock** (`.work/native/lotuskit-110-subsdk9.elf` has the symbols; addresses match the NSO).
* `OnRequestCreateActorAsyncHook::Callback` (0x206a0, `src/program/main.cpp`) calls
  `ActorWatcher::querySpawnSelectorSlot(const std::string actorName)` — **by value**: `bl 0x1a800` builds a
  `std::string` from the actor name, `bl 0x1954e0` frees it. This runs for every `ActorMgr::requestCreateActorAsync`
  call, on whichever game thread asks. Names of 16+ characters (`Horse_Link_…`, `Weapon_Sword_…`, `Kart_Glider…`) do
  not fit the small-string buffer and go to the heap — the exact texts found in the corrupted chunks.
* The AngelScript thread allocates constantly (every `string` concatenation, `debugLog`, toasts, JSON logging).

Actor requests come in bursts on area load, at kart spawn/mount and at the start of tests — when the crashes happen.
Two game threads requesting actors at once can corrupt the heap even with no script running (the title-screen crash).
The 64 KiB → 992 KiB heap move (`native-heap-110`) fixed a separate out-of-memory crash, not this one; the old
"16,000 strings in one frame" spark lookup made it more likely by widening the window.

## Fix: a real recursive lock (`malloc-lock-110`, 28 words changed)

`__malloc_recursive_mutex` (0x3db088, 8 zeroed bytes) becomes `owner | depth`: owner = `TPIDRRO_EL0` (the thread's TLS
pointer, 0x200-aligned), depth in bits 0–3 (newlib re-enters the lock from realloc/memalign).

* `__malloc_lock` 0x203de0: `x9 = &mutex; x10 = tpidrro_el0; b 0x208044`. Body in the alignment padding after
  `wcsxfrm` (0x208044, 14 words): `ldaxr`; free → `stxr` owner; mine → `stxr` depth+1; someone else's →
  `clrex; svcSleepThread(4 µs)` and retry from the top (a sleeping wait, so a high-priority thread cannot starve a
  lower-priority owner on the same core).
* `__malloc_unlock` 0x203e00: depth > 0 → `str` depth−1; else `stlr xzr` (padding after `iswalnum`, 0x20bf48).

Every patched word is checked by disassembly in the build script (`malloc-lock.asm`). Heap layout and everything else
are unchanged from `native-heap-110` (`fe1f0d79…` → `0eb29953…`).

Not changed: other newlib locks (stdio, env) are still no-ops; LotusKit's own unlocked shared state (ActorWatcher slots,
TextWriter queue) is not a heap issue. The LotusKit debug WebSocket server would still overwrite the heap.

## Results (Oct 17, Ryujinx 1.3.3, Apple Hypervisor, controller `5a3d98d8…`)

Stress test `heap_stress_test.as`: ~1,500 long (heap) strings allocated and freed between every frame from boot through
world load, kart mount and 1,800 frames of driving. Runs alternated old/new; logs and `results.jsonl` in `.work/heapstress/`.

| Runtime | Runs | Text-pointer crash | Other |
| --- | --- | --- | --- |
| `native-heap-110` (old, unlocked) | 8 | **1** — run 14, thread 96, `va=0x694C5F6573726F60` ("Horse_Li"+0x18) at world load, the reported crash | 1 host crash (below) |
| `malloc-lock-110` (fixed) | 9 | 0 | 1 host crash (below) |
| `malloc-lock-count-110` (fixed + counter) | 2 | 0 | — |

* **Contention counter** (`COUNT=1` build, waits counted at module +0x3d8ff0 = controller scratch +0x7ff0, logged as
  `contended=` by `heap_stress_count.as`): **2 and 15** contended lock acquisitions per run, all between boot and the
  mount, none while driving. Each one is a moment when two threads were inside malloc/free at once — on the unlocked
  runtime, a chance to corrupt the heap. This matches when the crash shows up (loading, spawn/mount, test start).
  (The count is only readable once the effect scratch is set up at mount, so "0" before that means "not read yet".)
* Normal tests on the fixed runtime: drive regression **12/12**, recall **8/8** (`.work/heapstress/lock-*-results.json`).
* The stress test does not make the race frequent (1/8 on the old runtime, vs the ~1/4 seen in today's normal tests): the
  window is the game's own actor-request bursts, which the script cannot force.

**Separate host crash (not this bug):** old run 8 and new run 13 both had Ryujinx abort with a .NET fail-fast
(`FailFastIfCorruptingStateException`, `~/Library/Logs/DiagnosticReports/Ryujinx-2026-10-17-160358.ips`, `…161803.ips`),
both ~1 s after a MoltenVK error at ~52 s: `VK_ERROR_INVALID_SHADER_NV … Subgroup builtins are not available in this type of
function`. No guest exception is logged; the emulator just exits. It happens on both runtimes, so it is a Ryujinx/MoltenVK
shader issue, not the heap. Same signature at Oct 17 01:48. **Update Oct 18:** the shader error is a red herring (it happens on every boot); the crash is a rare managed access
violation on a Ryujinx thread-pool worker. See research/host-failfast-crash.md.

## Rollback

Copy `runtime/candidates/native-heap-110/subsdk9` (`fe1f0d79…`) back to the mod's `exefs/subsdk9`.
