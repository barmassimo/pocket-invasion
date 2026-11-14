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
and build scripts. Do not embed a repository URL in the application or notices
without the user's approval.

License files do not replace the obligation to provide corresponding source.
Exporting does not publish or create a release, commit, tag or application version.

## Verification

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
