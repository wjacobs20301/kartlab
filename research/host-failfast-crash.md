# Ryujinx host exit at ~52 s ("Subgroup builtins" / .NET fail-fast)

Oct 18, 2026. Ryujinx 1.3.3, macOS, Apple Hypervisor, Vulkan/MoltenVK. Follow-up to the "separate host crash" note at the
bottom of research/heap-race.md.

## Summary

* **The MoltenVK "Subgroup builtins" error is not the cause.** It happens on every boot that reaches the world:
  in **186 of the 200** Ryujinx logs in the workspace (the other 14 never got past ~60 s), and in **55 of 55** test boots
  on Oct 18, all of which passed. It is always exactly one vertex-shader pipeline per boot, at ~50–55 s, logged
  `Background Compilation failed: Unexpected API error "ErrorInvalidShaderNV"`. MoltenVK cannot turn subgroup operations
  in a vertex function into Metal, so that one pipeline is never cached and fails again on the next boot. It lines up in
  time with the crash only because both fall in the world-load window.
* **The mod's new assets don't trigger it.** The same error is in the first logs on Oct 15 09:38
  (`.work/ryujinx-complete-save-test.log`, `ryujinx-vanilla-cart-comparison.log`), before any kart, glider or effect
  shaders existed. It is a game shader that this Ryujinx/MoltenVK build cannot compile.
* **What the crash is.** All three crash reports (`~/Library/Logs/DiagnosticReports/Ryujinx-2026-10-17-014858.ips`,
  `…160358.ips`, `…161803.ips`) show the same thing:
  `HandleHardwareException → … → FailFastIfCorruptingStateException → abort`. JIT-compiled (managed Ryujinx) code took a
  hardware memory fault at a non-null address. .NET treats that as an `AccessViolationException`, which it never lets
  code catch, so it kills the process on the spot. No guest exception is logged because the guest didn't fault.
  * The faulting thread is in each case a **.NET thread-pool worker**. Its outermost managed frames match a group of
    10–17 idle pool threads waiting in `WaitForMultiple`, not the guest (KThread) groups, the render thread
    (MoltenVK/AGX frames) or the hypervisor clock thread (`.work/failfast/ips7.py`). Ryujinx runs background shader and
    pipeline compilation, among other work, on those workers.
  * Process uptime at crash: 58.3 s (01:48), 55.7 s (16:18, = heapstress new-13), and 83.2 s (16:03, = old-8). In old-8
    the guest had stalled after 57 s ("GPU processing thread is too slow") and was still loading the world.
  * The test harness sent Ryujinx's stderr to /dev/null. That is where .NET prints the fatal exception and the managed
    stack trace that would name the faulting Ryujinx method. So the exact faulting code was never recorded.
* **Rate.** 3 crashes in about 175 world loads since Oct 16 evening (~2%). Oct 18: **0 in 55** boot-to-world launches on
  the installed runtime (malloc-lock-110 `0eb29953…`, controller `5a3d98d8…`) with stderr captured
  (`.work/failfast/results.jsonl`).
* **Shader cache.** The cache was still growing during the Oct 17 runs (1950 → 2324 shaders; last written 16:11). It has
  been 2324 since then, including today. The 16:03 crash happened in a run that added shaders (2310 → 2313). The 16:18
  crash had the full 2324 cache, so cache growth alone doesn't explain it.

## Verdict

This is a rare (~2%) host-side access violation in Ryujinx's own managed code on a thread-pool worker during world load
(shader or pipeline work is the likeliest candidate, but that isn't proven). It is not caused by the subgroup shader
error, the mod's assets, or the LotusKit heap race. At this rate the failing method can't be named without catching it
once with stderr. Proving any setting change helps would take hundreds of launches, so no workaround is proven.

**Do NOT purge the shader cache.** The cache is complete now, and the one crash with clear compile activity (16:03)
happened while new shaders were being added. A purge would put every boot back into that state for a while, and it
cannot remove the subgroup failure (that pipeline is never cached).

Practical advice: if it happens, relaunch (it is a ~2% boot event, not progressive). Keep the shader cache. Settings can
stay as they are (Vulkan, shader cache on, Hypervisor on, HostMappedUnsafe, backend threading Auto).

## Catching it next time

* Test boots: `.work/failfast/run_capture.py` is `scripts/run_ryujinx_script_test.py` with stdout/stderr kept as
  `<log>.out`. `.work/failfast/batch.sh <tag> <n>` (boot-to-world autorun `.work/failfast/boot_world.as`, ~75 s per
  launch) runs a batch, records `fatal=` per run, and restores Config.json and autorun. It does not switch the subsdk9 or
  restore the save, so back up the save first. If a run ends `emulator exited`, the `.out` file holds the
  `System.AccessViolationException` stack trace.
* Suggested follow-up: make the main harness keep stderr the same way, so every normal regression run can catch it.
* For the user's own play sessions, launching from Terminal keeps the trace:
  `/Applications/Ryujinx.app/Contents/MacOS/Ryujinx > ~/Desktop/ryujinx-stderr.txt 2>&1`
* Crash-report triage: `.work/failfast/ips3.py ~/Library/Logs/DiagnosticReports/Ryujinx-*.ips` marks fail-fast
  reports (`FAILFAST`). The other common signatures there are `SfiNext` (an unhandled managed exception after a guest
  crash, e.g. the heap race) and `AvnGlRenderingSession` destructor SIGSEGVs (Avalonia GL window teardown; probably the SIGTERM at test end, not checked).
