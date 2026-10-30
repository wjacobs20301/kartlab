# Script compilation crash and resident-controller trial

After v2 drove but rolled, the first v3 Right test crashed before its first debug line. At 00:09:13.830 in .work/ryujinx-color-control-v2-test.log, actual guest PC is subsdk9+0x1ff850 inside _malloc_r, with invalid address 0x1ab2f9a0. The call stack includes _memalign_r, operator new, AngelScript::CStdStringFactory::GetStringConstant, compiler expression builders and asCModule::Build. This is a compilation/allocation failure, not execution evidence for the v3 steering code.

The pinned source routes AngelScript core allocation to the borrowed game heap, but ordinary std::string allocations still use the module's C++ allocator. A64KB fake heap is configured in src/lib/program/setting.hpp. This may contribute to pressure/fragmentation, but exhaustion or the corruption source has not been established. Native _memalign_r evidence: ev_255b103f6f4e40b9f8a972b0b64cfc11458cbe5e071ca48bcf30b6285341d8a5, exported .work/native/rea-script-compile-crash-evidence.json. Source inspection and the actual register PC establish _malloc_r as the faulting function; the first stack line is a return address, not the faulting instruction. REA session closed.

Important lifecycle correction: schedule.cpp caches a module while it is executing, then tryDiscardLastModuleForPop discards it when unused. Earlier notes claiming all scripts remain compiled for the full process lifetime were too broad. Repeated shortcut use can compile again.

The next trial compiles the bounded controller, spawn and clear functions together in one7432-byte startup script and retains it in a yielding polling loop. Right invokes its local driving function, so it does not compile another file. Up and Down are also local. All per-frame string concatenation/debug telemetry is removed. LoadingPause transitions clear watcher references. The trial starts no network service and creates no actor without a user shortcut. It keeps the independently integrated upright yaw and0.8speed cap. Native-rider diagnostics are not bound in this isolated stability test.

Host tests pass idle startup, direct Up/Right/Down dispatch, input release, speed/Y bounds, LoadingPause cleanup and bridge rejection. Native startup/steering acceptance is still pending. This removes the observed mid-game compilation path; it does not prove the underlying allocator defect has been repaired.

## Exact allocator fault (follow-up, static code plus recorded registers)

The instruction at module offset `0x1ff850` is `str x5, [x1, x4]` (bytes
`25 68 24 f8`). The recorded values establish its destination exactly:

```text
X1 = 0x0d597cd8
X4 = 0x0d597cc8
X1 + X4 = 0x1ab2f9a0   // recorded invalid write address
```

The earlier internal suggestion that the destination was twice X19 was wrong:
`X19=0x0d598fa0`, so twice X19 is `0x1ab31f40`, a different address. X19 is
the allocator's retained first argument at entry; it must not be called a
proven free-heap chunk pointer.

From recorded PC `0x0d4d9850` and module offset `0x1ff850`, the runtime module
base is `0x0d2da000`. The retained ELF symbol table gives:

| Object | Module range | Corresponding runtime range |
| --- | --- | --- |
| `__malloc_av_` | `0x2bdc78 .. 0x2be488` | `0x0d597c78 .. 0x0d598488` |
| `__fake_heap` | `0x2c3090 .. 0x2d3090` | `0x0d59d090 .. 0x0d5ad090` |

Both the candidate chunk address X1 and the value used as its size X4 are
inside the allocator's bin-state array, before the fake heap. In this branch,
`0x1ff3b0` loads X4 from `[candidate+8]`, masks its two low flag bits, subtracts
the normalized requested size, and branches to the split-chunk code ending in
the faulting footer write. That is inconsistent with an ordinary valid chunk
within the configured fake heap. **Invalid allocator/bin state is the supported
immediate diagnosis.** This does not identify the earlier bad write, invalid
free, race, or other event that produced that state.

Ordinary capacity exhaustion is not established. `_sbrk_r` compares the proposed
break against `fake_heap_end` and returns `-1` with error 12 when past the bound.
The ELF's GOT entries at `0x2c2380` and `0x2c1d40` point to `fake_heap_end` and
`fake_heap_start` respectively, matching the initialization source. C++ `new`
calls `malloc`, checks a null return and follows its new-handler/exception path.
This crash occurred while splitting a supposed existing chunk, before any
observed normal allocation-failure return. Raising the heap limit is therefore
not a demonstrated repair and was not attempted.

Native observations were made against `.work/native/lotuskit-110-subsdk9.elf`,
SHA-256 `c1b35edd9432dec974f94ce2a7fe017d174045800b1542861cad1c33cc2fe4db`.
The previously installed derivative changes the unrelated CreateArg stub; this
investigation did not execute or patch the ELF. The complete follow-up bundle
is `.work/native/rea-allocator-followup-evidence.json`:

- `ev_ff6eb97f7c7e6fe6ae75ee5c5bb3e2d1a9777a689ee554e35ef7b2d32ef5bab2`: exact fault instruction bytes.
- `ev_f3c72c456f32aeba755f6a3cfefce459d6902a5aa2182658d70420f5a532dccb`: provider assembly containing the allocator branch. Hopper overmerges the containing procedure into `realloc`; the ELF symbol table and address-specific disassembly establish `_malloc_r`, so Hopper's containing-procedure name is not used as proof of function identity.
- `ev_7426f84488522eeb0ea1308ebb6c32932a31eededfdeacd007160964a7e0a875`: `_sbrk_r` bounds/error path.
- `ev_6db2eb1b21413a4955768d8c24acaeece492691e876618e3f10246374dea17fe`: C++ new allocation/null-return path; Hopper merges its array-new thunk, but the exact body is retained.

REA export succeeded. Session cleanup reported `cleanup_incomplete` because a
Hopper shutdown acknowledgement was not observed; its private runtime was
retained at `/tmp/rea-LL294x`. No further target was opened by this worker.

## Source allocation and cleanup ledger

- `src/lib/program/setting.hpp` defines `EXL_USE_FAKEHEAP` and
  `HeapSize=0x10000`. Exlaunch `source/lib/init/init.cpp` allocates that BSS
  array and assigns its start/end before C++ initializers.
- `src/program/script/engine.cpp::assignHeap` directs AngelScript's global
  memory callbacks to the borrowed `sead::Heap`. This is not a global override
  of ordinary C++ new/delete.
- `scriptstdstring.cpp::CStdStringFactory::GetStringConstant` constructs a
  temporary `std::string` and inserts into a standard string-keyed map. Its
  factory object, strings and map nodes use ordinary C++ allocation. Core AS
  allocation being on the game heap therefore does not remove fake-heap
  pressure from string constants or ordinary C++ strings/JSON.
- The factory increments a count on reuse and `ReleaseStringConstant` erases
  the map entry when its count reaches zero. AS function cleanup calls that
  release for bytecode string-constant pointers. This bounded source read did
  **not** demonstrate a factory reference-count bug, leaked constant pool or
  incorrect C++ allocator pairing.
- `buildOnceOrGetModule` reuses a module only while it exists. On completion,
  `calcCtx` unprepares the context, calls `tryDiscardLastModuleForPop`, and
  normally discards the module. A later shortcut can compile it again.
- A separate source defect exists in `tryDiscardLastModuleForPop`: with
  `getSP()=&moduleStack[moduleStackIndex]`, its loop computes
  `n=moduleStackIndex-1` and tests `i<n`. That omits the immediate parent from
  the same-module-in-use check. At depth 1 it checks no parent, so reentrant
  execution of the same module can discard a module still referenced by its
  parent context. AS `Discard()` immediately calls `CallExit()` to reset globals,
  then defers destruction while external function references remain. This
  source-level off-by-one was not patched and is **not established as the cause
  of the recorded allocator crash**; the log does not prove that reentrancy
  occurred. Sequential successful completions still discard/recompile.

The resident single-module trial reduces compiler/constant-pool churn,
per-frame string allocation and nested shortcut-module lifecycles. It does not
measure fake-heap occupancy or prove allocator integrity. No runtime heap dump,
free-list snapshot, allocation trace or first-corrupting-write evidence exists
in this pass. Those are the missing measurements needed to attribute a cause.

The resident driver also validates the actor name once per drive, then checks pointer identity/body availability rather than allocating a new actor-name string every frame. This reduces fake-heap churn; pointer identity does not prove actor lifetime.
