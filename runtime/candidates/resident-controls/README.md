# Startup-compiled remote controller trial

This7432-byte script combines the v3 flat-road driver, spawn and clear into one module. A yielding startup loop watches exact ZL+ZR+Up/Right/Down masks and dispatches locally. Right does not load or compile a separate script. No actor is created without a user shortcut; no network listener starts. The prior native-rider diagnostics are not bound by this test.

The active drive retains independent upright yaw,0.8speed cap, reduced acceleration/turn rate, B exit and a9000frame bound. Link stays at his starting position. The cart name is checked once per drive; later checks use actor pointer identity/body availability instead of allocating a name string every frame. Pointer identity does not establish object lifetime. Native watcher displays/logging are disabled and resolved watchers paused.

Host checks passed idle startup, direct dispatch, shortcut release, reduced speed/Y preservation, simulated LoadingPause cleanup and invalid-bridge rejection. A fresh Ryujinx1.3.3/TOTK1.1.0 startup logged `resident controller: ready; all controls compiled` at00:00:30.903. Driving stability remains pending. The live test includes the separate suspension-arm model repair.

The loader normally blocks TAS execution during LoadingPause; therefore simulated pause handling does not prove the loop can clear references during native loading. Clear before loading/travel and do not infer robust actor lifecycle handling. A later build can explicitly configure nonblocking loading once that behavior is tested.

Build from the readable stable-controls/usable-controls source candidates using `python3 scripts/build_resident_controller.py`. Whitespace/comments are compacted to fit the pinned8192-byte loader buffer. Research: research/script-compile-crash.md and research/resident-assembly-test.json. This removes the observed mid-game compilation path, not the underlying allocator corruption's proven cause.
