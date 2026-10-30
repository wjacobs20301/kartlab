# Installed Ryujinx CLI launch investigation

No emulator process was launched and no emulator files/configuration were changed by this investigation. The installed binary was read and bundled managed code was copied into project-local tooling for static inspection.

## Exact installed artifact

- `/Applications/Ryujinx.app/Contents/MacOS/Ryujinx`, universal Mach-O (x86_64 and arm64), SHA-256 `13571b902014eb732f69a13cf62c0bc3d9da0ab1542a52cca337ad0f8299ebe4`.
- `Info.plist` `CFBundleLongVersionString`: `1.3.3-e2143d4"` (including the trailing quote). Embedded managed product version is `1.3.3+e2143d4`.
- The executable contains .NET single-file bundle format 6.0 inside each Mach-O architecture. It is not NativeAOT.
- ARM64 bundle `Ryujinx.dll` occupies outer-file offset `0x7d33000`, 5,768,704 bytes. Extracted to `.tools/totk-runtime/Ryujinx-100000c.dll`, SHA-256 `a49c7dd747ddd0d58c0a06ded1d4452bc055e2674a687f8dedd3aa4e4485ce72`.

## Static CIL result

`Ryujinx.Ava.Utilities.CommandLineState.ParseArguments`, metadata method token **`0x060001bb`**, RVA **`0x9c88`**, decoded using a local .NET8 tool based on `PEReader` and `MetadataReader`. The tool never loads or executes Ryujinx code. Complete listing: `.tools/totk-runtime/Ryujinx-ParseArguments.il.txt`.

- The parser recognizes `-r` and `--root-data-dir`. Its value-consuming branch increments the argv index, loads that next argument, then calls `set_BaseDirPathArg` at `IL_03a7`.
- `-f` and `--fullscreen` set `StartFullscreenArg` to true (`IL_04a2–IL_04a3`). No fullscreen option is needed for windowed testing.
- The default branch loads the current argument and calls **`set_LaunchPathArg` at `IL_07b3–IL_07b4`**. The game content path is therefore a **positional argument**, not `--launch-game` or `--start`.
- Keep the game path last. A later unknown option can overwrite LaunchPathArg.
- The parser also recognizes `-i` / `--application-id` if an archive contains multiple applications; TOTK's ordinary XCI launch does not require it.
- There is no `--help` case in this parser. An unknown `--help` becomes a positional path, so running it is not a safe assumption for a no-start help action.

Direct command, preserving the existing Ryujinx data root/selected per-title update:

```sh
/Applications/Ryujinx.app/Contents/MacOS/Ryujinx '<repo>/totk.xci'
```

Explicit isolated data-root variant, if separately prepared:

```sh
/Applications/Ryujinx.app/Contents/MacOS/Ryujinx -r '/chosen/prepared/ryujinx/data/root' '<repo>/totk.xci'
```

The variant requires a root already containing the needed firmware, keys, configuration, selected update and saves. This investigation does not create it or claim an isolated root is ready.

## Reproduction / limits

`.tools/totk-runtime/extract_ryujinx_dll.py` extracts only the named bundled DLL from an explicit supplied installed path to an explicit project output. `.tools/totk-runtime/cli-inspect/Program.cs` decodes only the relevant metadata/CIL. Its NuGet.Config clears package sources; it uses framework libraries already shipped with .NET8 and downloads no dependencies.

REA `inspect_managed_members` was attempted on the extracted managed PE. Evidence `ev_dceb6090a06885fa76d51c8781e5f2c7e630843fd8ccfe2049a18ce0eb5c8223` reported unavailable because the complete metadata representation exceeded its 67,108,864-byte budget. The focused local metadata reader resolves that operation's scope without claiming REA analysis succeeded.

The positional argument conclusion is from installed shipped CIL, not a potentially different web source. [Ryubing's setup guide](https://docs.ryujinx.app/guides/setup-guide/) separately documents the macOS `-r` form, but is supporting context, not the exact-build evidence. The installed project's git host was unreachable during an attempted source fetch.

Static parsing proves accepted argument forms; it does not prove a complete successful game boot, which still depends on process access, installed guest firmware/keys, configured updates, graphics and mod compatibility.
