# large-script-110 — runtime with a 65,535-byte script limit (INSTALLED 2026-10-16)

`subsdk9` SHA-256 `3e22fadc6db15f650ea5bfbe9bed33be79d0259ecdb0150026c5a305425431e2`, derived from the
installed `angular-velocity-110` (`b0dc2c3b…`). Startup/local scripts may be up to 65,535 bytes (was 8,191).
Built by `scripts/patch_lotuskit_large_script_110.py` from `scriptbuf.s`; source equivalent in `source.patch`.
Validated in Ryujinx (padded 24 KB regression 12/12, 24 KB controller, 70 KB clean rejection, stock regression 12/12).
Details: `research/large-script-runtime.md`. Install: copy `subsdk9` over the KartLab_110 exefs `subsdk9`;
roll back with `../angular-velocity-110/subsdk9`. Compile-check with `.work/rider/compile_wheels file.as 65535`.
