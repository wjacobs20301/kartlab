# Larger startup scripts: `large-script-110` runtime candidate

Status: **validated in Ryujinx 1.3.3 and INSTALLED** as the normal runtime on 2026-10-16 at the user's request
(`subsdk9` `3e22fadc…`; the wheels autorun `a2529a6f…` is unchanged). Install receipt:
[large-script-install.json](large-script-install.json).
Machine-readable receipt: [large-script-runtime-results.json](large-script-runtime-results.json).

## Result

`runtime/candidates/large-script-110/subsdk9`, SHA-256
`3e22fadc6db15f650ea5bfbe9bed33be79d0259ecdb0150026c5a305425431e2`, raises the per-script limit
of `pushExecLocalFileModule` (startup `autorun.as`, hotkey scripts, and scripts that load other
script files) from **8,191 to 65,535 bytes**. It is derived from the installed runtime, so all
existing API (velocity, angular velocity and spawn fixes) is unchanged.

To install it, copy that file over
`~/Library/Application Support/Ryujinx/mods/contents/0100f2c0115b6000/KartLab_110/exefs/subsdk9`.
To roll back, copy `runtime/candidates/angular-velocity-110/subsdk9` (`b0dc2c3b…`) back.

## What the shipped code did

`pushExecLocalFileModule` (subsdk9 text `0x4b7c0`) has a fixed `0x2070` frame. The script buffer
is `char[0x2000]` at `sp+0x70`, and `readTextFile(buf, 0x2000, path)` is called at `0x4b9e8`. On
success, the text is copied into a heap `std::string` (`operator new` → `malloc`) and passed to
`buildOnceOrGetModule`. That function only calls `c_str()`, and `AddScriptSection` copies the text.

## Why not just a bigger stack buffer

* The stack fix would be four immediates, but it grows the frame by up to 56 KB on whichever thread
  builds the script. The runtime logs show that the **autorun read runs on a different guest thread
  (93) than the main loop (46)**: the startup build happens inside the title-screen AI query hook.
  That thread's stack size is unproven.
* `malloc`/`operator new` in this module come from exlaunch's **64 KiB fake heap**
  (`__fake_heap`, size `0x10000`). A malloc'd buffer plus the existing `std::string` copy would
  need 2× the script size from that small heap.

## Chosen design (heap buffer, no stack growth, no fake-heap use)

Source: `runtime/candidates/large-script-110/scriptbuf.s`. Verified listing: `scriptbuf-verified.asm`.

| Site | Original | Patched |
| --- | --- | --- |
| `0x4b9e8` | `bl readTextFile` | `bl read_stub`: `asAllocImpl(0x10000)` (AngelScript engine heap, `tryAlloc`), then read up to 65,535 bytes. On allocation failure, falls back to the original stack buffer and 0x2000 limit |
| `0x4ba1c`, `0x4ba28` | `add x0, sp, #0x70` | `mov x0, x23` (error message lives in the buffer) |
| `0x4ba30` | `mov x0, #0x34` | `bl error_stub`: free the heap buffer, then `mov x0, #0x34` |
| `0x4bab8` | `add x1, x24, #0x10` | `b success_stub`: non-owning `std::string{buf,len,len}` at `sp+0x50` → `buildOnceOrGetModule` → free → rejoin at `0x4bb28` |

`x23` is saved at `0x4b83c` and restored on every exit (`0x4b974`, `0x4bb2c`). It is otherwise unused
by the function, and the builder asserts this. It carries the buffer pointer. The 160-byte stub lies
in the existing text/RO alignment gap at `0x21beac`. RO/data/BSS, the segment layout and the frame
size are unchanged, and the segment hashes are recomputed as in the earlier three patches.

Builder: `scripts/patch_lotuskit_large_script_110.py`. It checks every replaced instruction by
disassembly, checks every call/branch target, and fails if any other original text byte changed.
Equivalent source change: `runtime/candidates/large-script-110/source.patch` (adds a
`const char*` overload of `buildOnceOrGetModule`). It applies cleanly on upstream plus patches
01–03 but was **not** compiled with the Switch toolchain.

## Reproduction

`scripts/reproduce_native_runtime.py` now runs an optional fourth stage when `runtime-chain.json`
lists `large-script-110`. It expects `large-script/scriptbuf.s` and
`tools/patch_lotuskit_large_script_110.py` in the source root. Verified on 2026-10-16 (scratch
outputs, nothing installed):

* the shipped `native-wheels` package source (three stages, unchanged) still gives `b0dc2c3b…` byte-identically
* that source plus the fourth stage gives `3e22fadc…` byte-identically

Run it with `PYTHONPATH=.tools/kart-assets/python` (pyelftools/capstone), or install the package's
`requirements.txt`.

## Runtime tests (Ryujinx 1.3.3, TOTK 1.1.0, patched runtime)

Test scripts are built by `scripts/build_large_script_tests.py`. Each keeps the original script
byte-for-byte and appends compiled padding functions plus a tail function that `main()` calls first.
The tail logs `LARGESCRIPT … tail ok`, so a truncated read fails to compile instead of passing.
Runner: `scripts/run_ryujinx_script_test.py`.

| Script | Bytes | Result |
| --- | --- | --- |
| `large_regression_24k.as` (padded wheels regression) | 24,061 | tail logged; `DRIVE finished`; **12/12 checks**, wheel spin/steer samples live |
| `large_controller_24k.as` (padded installed controller) | 24,042 | tail logged; no `[error]`; ran 40 s after load |
| `large_overlimit_70k.as` | 70,043 | `file contents too long 70043 > 65535`, clean abort, buffer freed, game ran 40 s |
| `native_wheels_regression.as` (unchanged) | 8,179 | `DRIVE finished`; **12/12 checks** |

Results: `large-script-regression-24k-results.json` and `large-script-runtime-stock-regression-results.json`.
Logs: `.work/ryujinx-large-*.log`.

## Compile harness

`.work/rider/compile_wheels script.as [max_bytes]` now takes an optional limit. The default stays
8,191 (stock runtime); pass `65535` for this candidate. The previous binary and source are kept as
`compile_wheels-8191` and `compile_wheels-8191.cpp`.

## Limits

* Only `pushExecLocalFileModule` changed. `.nxtas` files (`pushExecLocalFileModuleNXTas`), scripts
  sent over the WebSocket server, and `Logger::dumpTextFileIntoNS` keep their old limits.
* Each load takes a transient 64 KiB from the AngelScript engine heap. If that allocation fails,
  the load quietly falls back to the old 8 KiB limit; that path was not forced in testing.
* Emulator only. Not tested on Switch hardware. Exact pinned module and TOTK 1.1.0 only.
* The packaged ZIPs in `dist/` are unchanged. A new package would need a new `runtime-chain.json`
  stage and `patches/04-large-script.patch`.
