# Development and distribution

See [README](../README.md) for the pinned self-contained Godot environment,
bootstrap, launch, export and validation commands and existing limitations.

## Distribution notices

Run `scripts/Export-Windows.ps1` or `scripts/Export-Web.ps1` from the project root.
Both scripts verify the existing local environment, capture build identity, export
the game and call `scripts/Write-DistributionNotices.ps1` to add:

- `LICENSE.txt`: the project GNU GPLv3 text, copied from the root `LICENSE`.
- `GODOT_LICENSE.txt`: Godot's copyright and MIT license text.
- `THIRD_PARTY_NOTICES.txt`: component copyright notices and full license texts.
- `DISTRIBUTION.txt`: project copyright, license, warranty disclaimer and source
  access information, together with the build's source commit when available.
- `build-info.json`: the same identity snapshot bundled in the game package.

The generator uses `Engine.get_license_text()`, `Engine.get_copyright_info()`
and `Engine.get_license_info()` from the pinned local engine. It does not download
license files or introduce another runtime. The engine's tables can list components
unused by the exported target; they are retained to preserve the supplied notices.
Generated intermediate data and logs stay under `artifacts/`.

The notices also include the bundled Share Tech Mono font's copyright and full
SIL OFL 1.1 text from `game/assets/fonts/share-tech-mono/OFL.txt`. Its pinned source
and file hashes are recorded in that directory's `SOURCE.md`.

Web outputs also contain `licenses.html`, linked from the exported game HTML.
Keep this page and all companion notices when uploading the Web directory.
The local server serves `.txt` as UTF-8 plain text and `.json` as JSON.

Windows packages must retain the notices alongside `PocketInvasion.exe` and
`PocketInvasion.pck`. The two game files suffice for execution, while distribution
also requires the accompanying legal files.

## Source access when publishing

No source archive is generated and no source directory is added to binary outputs.
Publish the packages on a GitHub Release alongside GitHub's automatic source ZIP
and tarball downloads for the corresponding tag. Make clear in the release notes
where recipients can obtain the corresponding source, including project assets
and build scripts. The approved project URL is
`https://github.com/barmassimo/pocket-invasion`. Identity capture includes it only
when `origin` matches this repository (HTTPS or SSH); the HUD version opens the
repository root. Each export regenerates the snapshot, so missing Git identity or
an absent/unapproved remote cannot reuse a stale link. A different repository URL
requires the user's approval.

License files do not replace the obligation to provide corresponding source.
Exporting does not publish or create a release, commit, tag or application version.

## Verification

For first-import regressions, use a separate source copy without `game/.godot/`
and inspect its first import log for errors; a warmed local import cache can
hide missing imported resources. The bundled UI font is assigned to the default
theme at runtime, avoiding a project custom-font load before asset import.

`scripts/Validate.ps1` includes local leaderboard ordering, qualification/ties,
JSON round trips, replacement saves, invalid-data recovery, uppercase input,
arcade arrows, defeat transitions, confirmation, restart and fanfare volume/mute
checks. Score fixtures are written only under `artifacts/high-scores-test.json`;
the checks do not overwrite the player's real leaderboard. See [architecture](ARCHITECTURE.md)
for the state flow and [manual](MANUAL.md) for current controls and storage limits.

Verify exported notice files are present and nonempty, the GPL copy matches the
root license, and the exported metadata matches the game's captured identity.
Check the Web license link and its local file links in a browser. Verify startup
of the Windows export and inspect export logs for parser or script errors.
Store detailed results and logs under `artifacts/`.

## GitHub Actions releases

`.github/workflows/release.yml` uses GitHub-hosted **Ubuntu 24.04 x64** for both
jobs. It runs the standard precompiled Linux Godot editor headlessly and
cross-exports Web and Windows x64 using the existing presets. No Windows runner,
Wine, native compilation, signing, hosting or deployment is required.

Prepare a release commit first: choose the version under the repository release
rules, update `application/config/version` and the changelog, commit, and create
the matching stable `vMAJOR.MINOR.PATCH` tag. Pushing that tag starts the workflow.
Suffixes and leading zeros are rejected. A tag must already exist on GitHub;
neither invocation creates one or changes the version/changelog.

For manual execution, the workflow must be present on the default branch. Open
**Actions → Release → Run workflow**, keep the default workflow branch and enter
the existing tag in `tag`. The source checkout always uses that tag, rather than
the selected workflow branch. See [GitHub's manual trigger documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_dispatch).
The tagged commit must contain the CI scripts. Tag pushes created using another
workflow's default `GITHUB_TOKEN` generally do not trigger a new workflow; use
manual dispatch in that case.

The build job has read-only repository permission and:

1. Checks tag syntax, application version, exact source commit and clean Git state.
2. Downloads and verifies the pinned Linux engine and official export templates.
3. Runs `Validate.ps1`: project import plus `game/scripts/checks.gd` rules/state tests.
4. Runs the existing Web and Windows export scripts, including licensing notices.
5. Requires nonempty outputs, matching GPL text, the Web license link, and the
   expected clean version/commit in each package's metadata.
6. Uploads two ZIPs and `SHA256SUMS.txt`; logs are retained even after failure.

Only after success does the publish job receive `contents: write`, download the
verified artifact and check its SHA-256 sums. It creates a draft GitHub Release,
attaches `PocketInvasion-vMAJOR.MINOR.PATCH-web.zip`,
`PocketInvasion-vMAJOR.MINOR.PATCH-windows.zip` and `SHA256SUMS.txt`, then publishes
it. Notes contain GitHub-generated changes and instructions for corresponding
source downloads. Existing releases/assets are never overwritten. A publication
failure may leave a draft; inspect it before deciding whether to remove it and
retry. Builds for the same tag are serialized. No additional secret is needed:
the publish job uses the repository's built-in `GITHUB_TOKEN`.

Workflow artifacts/logs are kept for 14 days; published release assets remain
on the release. A manual rerun rebuilds the same tag but cannot replace a release.
This CI validates imports, game rules and packaging; it does not run the Windows
executable, inspect a browser, listen to audio or establish gameplay performance.
Keep the existing visual and platform playtesting checks for releases.

## Optional Linux development

Use Linux x64 with PowerShell 7, Git and Godot's standard Linux system libraries.
GitHub-hosted Ubuntu already supplies PowerShell and Git; these scripts do not
install runtimes or change system configuration. Use a separate checkout per OS:
the bootstrap rejects a tool directory prepared for the other platform.

From the project root:

```sh
pwsh -NoProfile -File scripts/Bootstrap.ps1 -Download
pwsh -NoProfile -File scripts/Validate.ps1
pwsh -NoProfile -File scripts/Export-Web.ps1 -Download
pwsh -NoProfile -File scripts/Export-Windows.ps1 -Download
# Requires a graphical desktop:
pwsh -NoProfile -File scripts/Run.ps1
pwsh -NoProfile -File scripts/Run.ps1 -Editor
```

`Get-GodotPath.ps1` selects the native editor for bootstrap, validation, identity,
notices, export and launch. `Bootstrap-Linux.ps1` pins the standard 4.7.2 Linux x64
ZIP and verifies SHA-256
`cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`,
obtained from the [official release asset digest](https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable)
on 2026-11-14. It also verifies the extracted binary against the authenticated
archive on every reuse, creates `_sc_` before first execution, and keeps editor
data/templates under `tools/godot/editor_data/`. Keep the ZIP in `artifacts/` for
offline verification; after preparation omit `-Download` for offline use.
Default game saves/logs continue to use Godot's platform-specific `user://` path.
`Serve-Web.ps1` retains its loopback-only test-server behavior.
