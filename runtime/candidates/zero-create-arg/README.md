# Spawn-initialization test candidate

This trial patch has now been tested on Ryujinx 1.3.3 with TOTK 1.1.0 and the original cart model. The actor fell to the road and its position/velocity changed during the motion probe. A follow-up with the imported MK kart visibly rendered and moved; native gamepad input then drove it during a bounded remote test, with camera/control restoration at completion. Hardware compatibility and seated driving remain unverified. The original module is backed up; research/zero-create-arg-runtime-test.json records installation and results.

The pinned source declares two CreateArg objects without value initialization. In the shipped createAndWatchPosRot function, static analysis also observes no initialization of option bytes +0x48 through +0x57 before calling the game. These options may receive arbitrary previous stack values. Their precise game semantics and whether they caused the invisible/motionless actor are unresolved.

source-fix.patch value-initializes the two source declarations. This binary trial fixes only createAndWatchPosRot: one branch at module-relative 0x64bc8 enters a 16-byte stub at 0x21bd70, clears the option bytes, repeats the replaced MOV, and returns. The stub fits inside the existing page gap before read-only data; no original symbol addresses move. The module gets a distinct build ID.

Validation: pinned source module hash; exact original instruction; branch targets; no other original text changes; unchanged RO/data/BSS; recomputed and independently verified segment hashes; Clang AArch64 assembler matches the stub operations; hactool --verify reports all segments GOOD. These checks establish format and instruction integrity, not successful gameplay.

Reproduce with scripts/patch_lotuskit_spawn_init.py from the project root. validation.json records hashes. The corresponding pinned GPL-2.0 source archive, two-line source patch and license are included. Apply the source patch to the archived upstream tree with git apply source-fix.patch for a full source rebuild; that rebuild has not been performed here.

Native evidence: .work/native/rea-lotuskit-spawn-evidence.json, Evidence ev_1db4e4f5bba71d0e59fc94133843261936e0bf118eafbaa6ad9b6ac2a0e399c8. Static provider pseudocode/assembly is not execution evidence.

The combined distribution includes the original module and exact byte-patch tool. Reproduce from its root using Python with lz4 installed: `python3 lab/tools/patch_lotuskit_spawn_init.py --source source/upstream-subsdk9 --output /tmp/kart-spawn-reproduction`. Compare the output SHA-256 to validation.json. This reproduces the binary derivative; it does not perform a full source rebuild.
