# Development and distribution

## Local environment

Use the [Windows setup commands](../README.md#prepare-and-play).
[`Bootstrap.ps1`](../scripts/Bootstrap.ps1) pins the official Windows archive
and SHA-256 and verifies both executables. It reuses verified tools or extracts
the ZIP from `artifacts/`. `-Download` fetches the pinned archive when missing.
The editor and its `editor_data/` directory stay under `tools/godot/`, with `_sc_`
enabling self-contained editor mode. Project imports stay in `game/.godot/`.
Even in self-contained editor mode, Windows saves scores to `high_scores.json`
and runtime logs to `logs/` under `%APPDATA%\Godot\app_userdata\Pocket Invasion\`.
Web scores use browser-local IndexedDB, scoped to the site and browser profile.

The project uses the standard Godot editor and needs no additional Windows
runtime, compiler or SDK. The game window and exported executable use the
[original LCD fighter icon](../game/assets/icons/app-icon.svg). Share Tech Mono
ships with native and Web builds, with
[font provenance and checksums](../game/assets/fonts/share-tech-mono/SOURCE.md).

## Verification

Run `.\scripts\Validate.ps1` from the project root. It imports the project and
runs the headless rules checks in [`checks.gd`](../game/scripts/checks.gd).
See `artifacts/import.log` and `artifacts/checks.log`. Score fixtures stay in
`artifacts/high-scores-test.json`. For fresh-import regressions use a separate
source copy without `game/.godot/`.

Headless checks cover rules and state. Check readability, controls and affected
encounters in the real window, listen to audio changes, and smoke-test exports
on their target platforms. Measure the busiest intended encounter before making
performance claims. Store captures, measurements and verification notes in
`artifacts/`. Use `.\scripts\Run.ps1 -Seed 42` for repeatable encounters.
The enemy-tier preview shows all five score and Fleet sizes:

```powershell
& (& ./scripts/Get-GodotPath.ps1) --path ./game --script res://scripts/preview_targets.gd
```

Append `-- --capture` to save `artifacts/enemy-tiers.png` and exit.

## Local exports

```powershell
.\scripts\Export-Windows.ps1
.\scripts\Export-Web.ps1
.\scripts\Serve-Web.ps1
```

Add `-Download` to either export command if the shared official template ZIP
is missing. The archive is about 1.19 GiB and stays in `artifacts/`. The scripts
pin its source and SHA-256, extract only the required templates, and verify
their hashes on reuse. Logs are `artifacts/windows-export.log` and
`artifacts/web-export.log`.

- **Windows x64** ships under `artifacts/windows/`. Keep
  `PocketInvasion.exe` and `PocketInvasion.pck` together. The executable embeds
  the icon via Godot's resource editing. No install or signing step is needed.
- **Web** ships under `artifacts/web/`. Serve the complete directory over HTTP
  or HTTPS. The test server listens at [127.0.0.1:8060](http://127.0.0.1:8060/)
  by default. Serve `.wasm` as `application/wasm`. The supplied `web.config`
  sets IIS mappings for `.wasm` and `.pck`. Merge its `staticContent` entries
  when the directory already has a configuration. The WebGL 2.0 preset uses a
  single thread and needs no COOP/COEP headers.

## Distribution notices

Keep `LICENSE.txt`, `GODOT_LICENSE.txt`, `THIRD_PARTY_NOTICES.txt`,
`DISTRIBUTION.txt` and `build-info.json` with the exports. Web also includes
`licenses.html`, linked from the game page. Notices come from the pinned
engine's built-in license tables and the bundled font license.

When publishing, provide corresponding source, including project assets and
build scripts. GitHub Releases provide source archives for the matching tag.
The export scripts do not produce a source archive.

## GitHub Actions releases

Follow the [release rules](../AGENTS.md#releases-and-build-identity) to prepare
the version, changelog, commit and tag. For a local stable tag, run
`.\scripts\Test-Release.ps1 -Tag vMAJOR.MINOR.PATCH` with a clean checkout of
that exact commit. The check fails on a version mismatch, a different tag
commit or a dirty tree.

To publish on GitHub, push the stable version tag, or open **Actions → Release
→ Run workflow** on the default branch and supply an existing tag. The workflow
checks out that tag and rejects suffixed tags. A push using another workflow's
default `GITHUB_TOKEN` may require manual dispatch.

The [workflow](../.github/workflows/release.yml) runs on Ubuntu 24.04 x64,
verifies the pinned tools, checks the game and packages matching Web and Windows
builds with `SHA256SUMS.txt`. The separate publish job verifies the ZIPs against
those checksums, then uploads them to a draft and publishes it. It never
overwrites an existing release or asset. Inspect any draft left after a failure
before retrying. CI does not play the exports. Build logs and workflow artifacts
are retained for 14 days.

## Optional Linux development

Use Linux x64, PowerShell 7, Git and Godot's standard Linux system libraries.
Keep a separate checkout from Windows. Run the same scripts with `pwsh -File`,
for example:

```sh
pwsh -File scripts/Bootstrap.ps1 -Download
pwsh -File scripts/Validate.ps1
pwsh -File scripts/Run.ps1
```

Launch and editor use require a graphical desktop.
[`Bootstrap-Linux.ps1`](../scripts/Bootstrap-Linux.ps1) pins the official Linux
archive and SHA-256 and verifies the editor binary against the archive on reuse.
Keep that ZIP in `artifacts/` for offline checks. Distribution targets remain
Windows x64 and Web.
