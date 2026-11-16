# Pocket Invasion

A local Windows arcade prototype made with standard Godot 4.7.2 and typed GDScript, styled as an olive monochrome 1980s LCD handheld. Fly a spacecraft formation freely across the playfield, shoot automatically, break targets for score and collect freed fighters to grow the fleet.

## Screenshots

<p>
  <img src="docs/screenshots/briefing.png" alt="Mission briefing and Top 10 scores" width="360">
  <img src="docs/screenshots/gameplay.png" alt="Gameplay with a four-ship fleet, alien targets and a freed fighter" width="360">
</p>

## Prepare and play

Run PowerShell commands from this project directory:

```powershell
.\scripts\Bootstrap.ps1
.\scripts\Run.ps1
```

Open the project in the local editor:

```powershell
.\scripts\Run.ps1 -Editor
```

Godot is portable; no installation, C#, build tools, global PATH edits, or export templates are required. After setup, development and play work offline.

If rebuilding the environment, place `Godot_v4.7.2-stable_win64.exe.zip` in `artifacts/`. The bootstrap checks its SHA-256 before extracting and creates `_sc_` before first launch. To explicitly download the fixed official archive instead:

```powershell
.\scripts\Bootstrap.ps1 -Download
```

Official source: [Godot 4.7.2 release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable). Archive SHA-256, verified against the official GitHub release asset digest on 2026-11-12:

```text
731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953
```

The bootstrap also verifies both extracted executables. An existing mismatched or incomplete environment is rejected without replacement or upgrade.

## Windows portable export (x64)

```powershell
.\scripts\Export-Windows.ps1
.\artifacts\windows\PocketInvasion.exe
```

The script reuses the pinned local engine and the official export-template archive already downloaded for Web. On first Windows setup it verifies the archive SHA-256 shown below and extracts only the four Windows x64 release/debug templates into `tools/godot/editor_data/export_templates/4.7.2.stable/`. Their hashes are recorded in `windows-sha256.json` and checked on subsequent exports. Changed or unverified existing templates are rejected without replacement. If the archive is missing, explicitly allow its download with `.\scripts\Export-Windows.ps1 -Download`; otherwise export works offline.

Output is `artifacts/windows/PocketInvasion.exe` and `PocketInvasion.pck`. Copy both files together to run on a compatible Windows x64 PC without installing Godot. The preset uses Compatibility rendering, with no installer, code signing, console wrapper or external Windows build tools. Export errors are recorded in `artifacts/windows-export.log`. This is portable in the sense of requiring no installation; default runtime caches and logs can still be written under `%APPDATA%\Godot\app_userdata\Pocket Invasion\`.

The project and Windows executable share the original flat LCD fighter icon in `game/assets/icons/app-icon.svg`. Windows export embeds the icon and application name using Godot's built-in resource editing, with no additional tool download.

Verified on 2026-11-14: local export with archive verification, subsequent reuse of installed template hashes, and visual inspection of the exported executable's briefing, start, automatic fire, targets, defeat, restart and pause. Export completed without reported errors. This was a startup smoke check, not a full gameplay, audio, performance or other-PC compatibility test. Details are in `artifacts/windows-verification.md`.

## Web export (desktop browsers)

The Web build uses this same Godot project and GDScript code. Export using the pinned local engine:

```powershell
.\scripts\Export-Web.ps1 -Download
```

The first setup downloads the official standard 4.7.2 export-template archive (about 1.19 GiB), verifies SHA-256 `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`, and extracts only `web_nothreads_release.zip` and `web_nothreads_debug.zip` into `tools/godot/editor_data/export_templates/4.7.2.stable/`. It records and checks their hashes on reuse, rejecting changed files. The archive stays in `artifacts/`. Source: [official release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable). Subsequent exports work offline with `.\scripts\Export-Web.ps1`.

Output is `artifacts/web/index.html` and its companion files. Serve the entire directory, keeping filenames together. For local testing:

```powershell
.\scripts\Serve-Web.ps1
```

Open [the local game](http://127.0.0.1:8060/) in a desktop browser. Stop the server with Ctrl+C. This loopback-only server is for local testing, not production hosting. Opening the HTML directly as a file does not work. Deployment requires static web hosting, preferably HTTPS, with `.wasm` served as `application/wasm`.

Exports include `web.config` for IIS hosting: it maps `.wasm` to `application/wasm` and `.pck` to `application/octet-stream` within the game directory, removing inherited entries for these extensions before adding them to avoid duplicates. Upload it alongside `index.html`; merge the `staticContent` entries if that directory already has its own `web.config`. The host must allow configuration of this section. Other static hosts do not need this file.

The preset uses Compatibility/WebGL 2.0, single-threaded execution, an adaptive canvas and no PWA/service worker. No special COOP/COEP headers are needed. Keyboard controls are shared with Windows; click the canvas if it lacks focus. Browser-reserved keys may behave differently (especially F11/Esc); F is the game's alternative fullscreen key. Audio requires initial user interaction. Mobile/touch controls are not implemented. Share Tech Mono is bundled for interface text on Windows and Web; numeric readouts retain their existing rendering, with no installed font requirement. Browser performance, audio and cross-browser behavior require testing; native validation does not establish Web compatibility.

The first Web build was verified on 2026-11-13 in the in-app Chromium browser: introduction, Enter to start, automatic shooting, targets/rewards and P to pause were observed, with no console warnings/errors. Audio, fullscreen, movement limits, performance and other browsers remain unverified. Details are in `artifacts/web-verification.md`.

Volume changes only update the music pause state when it actually changes, avoiding redundant unpause calls that can restart Web Sample playback in Godot 4.7.2. The Web build was regenerated after this correction; native checks passed and changing the slider in the browser produced no console warnings/errors. The user confirmed that deployment on IIS works with the included MIME mappings and reported that the audio glitch appears resolved. This is user listening feedback, not an exhaustive load test; Web loop resume after an actual pause/mute remains unverified.

## Distribution licenses

Both export scripts add `LICENSE.txt` (GNU GPLv3), `GODOT_LICENSE.txt`,
`THIRD_PARTY_NOTICES.txt`, `DISTRIBUTION.txt` and `build-info.json` alongside the
game files. Keep these files in Windows packages and Web uploads. Third-party
copyrights and full license texts are generated offline from the pinned engine's
built-in license tables, which can include components unused by a particular export.

Web exports also include `licenses.html`, accessible from the small **Licenses**
link at the bottom right of the game page. No repository URL is embedded.

Source archives are not generated or included in these output directories.
When publishing on GitHub, provide the corresponding source through the release's
automatic source downloads. See [distribution details](docs/DEVELOPMENT.md).

## Versions and build identity

GitHub Actions runs tests and exports on **Linux (`ubuntu-24.04`)**, then publishes
Web and Windows x64 ZIPs in a GitHub Release. Push an existing prepared stable tag
`vMAJOR.MINOR.PATCH`, or select **Actions → Release → Run workflow** and enter that
tag. It must match the application version; the workflow does not choose a version
or create a tag. See [CI release instructions](docs/DEVELOPMENT.md#github-actions-releases).

The same bootstrap, validation, export and launch scripts also support Linux x64
with PowerShell 7 (`pwsh`), using a separate checkout from Windows. This is optional;
Windows development retains its existing requirements and commands.

The lower-left HUD shows the application version and seven-character source commit
as `vMAJOR.MINOR.PATCH-hash`, without spaces or parentheses, with `-modified` appended
when local changes are present.
Hover over it to read the full hash. The volume slider and mute button sit above it.
`modified` indicates tracked or non-ignored untracked changes beyond that commit;
release builds are exported from the clean, tagged release commit and omit this marker.
The hash is a local source reference; no GitHub link or network access is used.

`game/project.godot` (`application/config/version`) is the single version source.
Development launches, including runs from the Godot editor, detect the current
checkout identity when Git is available. Without Git/repository metadata the game
still runs, showing only `vMAJOR.MINOR.PATCH`, without a hash or extra suffix.
Both export scripts regenerate the ignored `game/build_info.json` snapshot before
exporting and bundle it in the game package. If Git or the repository is unavailable
at export time, this replaces any previous snapshot with unavailable identity;
the exported game shows only the application version, never a previously saved hash.
Exports only read that snapshot, so
they retain their identity outside the checkout and require no Git at runtime.
Missing or invalid snapshots also show only `vMAJOR.MINOR.PATCH`.

Exporting alone does not increment the version or create a release. A requested
release updates the version and [changelog](docs/CHANGELOG.md), commits its changes
and creates the matching version tag. Publication and deployment are separate actions.

## Controls and rules

- Enter / Space: start from the introduction/demo or a defeat outside the Top 10. A qualifying defeat opens name entry instead. These keys do nothing during play or pause.
- Left / Right on the introduction/manual: previous / next page. Click the < / > arrows beside the page dots, or click a dot to choose a page. Navigation wraps around and restarts the selected page's timer; automatic cycling continues. A subtle 48-by-2-pixel bar beside the navigator starts full and shrinks toward its left edge until the next page.
- W / A / S / D or all four arrow keys: move up, left, down and right.
- Normal fire is automatic while the run is active; no Ctrl input is needed.
- P: pause or resume.
- F11 or F: toggle fullscreen, preserving the game's aspect ratio.
- Esc: leave fullscreen without changing the current run or pause state. There is no command to abandon a run.
- M: mute or unmute music and sound effects (M=MUTE). The speaker icon shows a cross when muted. Mute is kept when restarting the run.
- Drag the horizontal slider beside the speaker to adjust master audio volume (0–100%, initially 50%). Raising it unmutes audio; volume and mute survive a run restart. The default effects level is about 3.5 dB louder than the original mix.

On launch, a message headed FROM COMMAND CENTER addresses the last fighter directly: Earth has fallen, captured pilots are still alive, and the fleet must be rebuilt to fight back. The command holds its position and calls for action in an urgent, professional tone. The TOP SECRET orbital illustration reuses the existing alien and fighter artwork with clean olive contours. After 1.6 seconds, an alien beam captures the fighter and converts it into the same round containment spacecraft seen on reinforcement targets, using the exact gameplay hull and Fleet emblem; the silent briefing animation lasts 13 seconds while its text stays still. The briefing is page one of a continuous three-page cycle, followed by the two nine-second How to Play animations, then back to the briefing (31 seconds total). All pages use the full right panel width and three page dots; the Start prompt appears only in the left column. Enter / Space starts immediately from any page. There is no D shortcut for the manual; D remains a movement key during play. Each run begins with the lone fighter from the story; reinforcements rebuild the fleet during play.

Start with one ship and no hard fleet-size cap. Breaking a captured-fighter/Fleet ship releases a drifting fighter marked +N instead of adding ships immediately. Fly any formation member into it to collect the full indicated ship count. It rotates slowly, matches the initial small fleet ships in size, is immune to fire, and lets shots pass through to targets behind it. The freed craft drifts slowly toward the bottom, independently of course acceleration, and disappears after leaving the playfield. After 5 seconds a small arched 1960s-style HELP! sign starts blinking; the fighter and its reward label remain visible. From that moment, contact with an alien-piloted ship can recapture it, including while the HELP! sign is hidden. Captured-fighter/Fleet ships cannot recapture fighters. The warning does not prevent player collection or change shot immunity, and the timer alone does not remove a fighter. Pause freezes it; restart clears every uncollected fighter. At most 64 pickups remain active; if that bound is reached, a new release adds its full reward to the nearest existing pickup. The existing 25 points are awarded when the containment ship is broken; the reinforcement sound and +N fleet notice occur on collection. Above 32 ships, the formation widens by one column for each additional group of eight ships (33–40: nine columns, 41–48: ten, and so on), up to 20 columns to keep all ships inside the playfield. A wider fleet has less lateral escape room and is harder to keep intact, providing a natural constraint through contact losses. Losses reduce its width again. The LCD displays the current ship count. Restarting restores one ship.

Enemies now use the approved flat, rounded 1950s–1960s alien-spacecraft design, with original SVG layers under `game/assets/enemies/`. Score enemies show a neutral-faced alien with two antennae: small/regular ships carry one pilot, medium/heavy ships two, and command ships three. Every pilot stays the same absolute size across tiers; only the hull and cockpit grow. Fleet targets use the approved A3 captive-fighter design: a large intact terrestrial fighter nearly fills the circular window, held by two prominent rounded C-shaped olive clamps attached to its sides. Hull, window, fighter and clamps scale proportionally across all five sizes. The original egg/medallion layers remain available in `docs/art-concepts/egg-original/`; concept previews are under `artifacts/captured-fighter-concepts/`. Gameplay uses a clean three-color SVG, with no generated-image texture. Both score-awarding encounter kinds use alien ships; their existing HP and reward tuning remain distinct. There are no glossy materials, perspective-drawn hulls, reflections or shaded volume. The fixed camera's foreshortening is compensated so the flat hulls appear round.

Health stays labeled `HP` above each intact target ship. The reward amount appears separately below the hull so it never covers the crew or captive fighter. The left HUD still uses the spacecraft icon for fleet gains and the medal icon for score gains. Small through command fleet supplies award +1/+2/+4/+8/+16 ships. Score rewards by size remain 40–70 / 80–140 / 160–280 / 320–560 / 640–1120. Small recovery supplies remain present.

During play, all live game information is in the left column: ship count, score, mission time, level, mode, audio state and reward/loss notifications. The window has exactly two areas: the statistics column on the left and the main screen on the right. The former third column is removed, narrowing the window to 725 x 800 while preserving the course scale and framing. The main screen alternates between the game and the silent three-page briefing/manual cycle, which also begins ten seconds after a non-qualifying defeat. Its two manual pages demonstrate how to shoot a 5-HP containment ship, move to collect the rotating freed fighter and grow from one ship to two, and destroy an alien ship for points. The left column shows the Top 10 and How to Play controls throughout the three-page cycle; the right pages leave more space around the content without repeating the start prompt. Each lesson ends with a three-second hold and short English captions. The demonstration is hidden during play and pause, resets when a run starts, and never creates gameplay entities or audio. After a defeat outside the Top 10, the final course and a restart prompt stay frozen for ten seconds. Enter or Space starts a new run immediately; otherwise the cycle begins automatically from the briefing. A qualifying score waits three seconds, then opens uppercase name entry with a triumphant chiptune loop. Enter or Space skips that wait into name entry. Confirming the name returns to the demo and updated Top 10. See [the manual](docs/MANUAL.md) for name controls and local storage. The main screen shows the three-page cycle on launch and after this hold, and the live course during play or pause. Pausing freezes the course with a PAUSED message; it never switches to the demo. Defeat is identified by the FLEET LOST heading during the ten-second hold.

Vertical movement spans the entire visible playfield, from the bottom to the top, retaining only a small border margin and enough room to keep the whole formation visible. Diagonal input is normalized, and vertical world movement compensates for camera foreshortening so screen movement feels comparable in both axes. There is no safe player line: moving into an approaching target can destroy the ships actually crossed. Shots always travel forward; flying above an object does not make ships fire backwards. New reinforcements, casualties and restart update the bounds and reset movement history appropriately.

Normal shots travel straight forward in parallel, without convergence, auto-aim or homing, and are recycled after passing the far end of the visible course. Move the formation to put its firing columns over a target. Each ship fires one projectile per volley automatically. Volley intervals improve from 0.45 seconds with one to four ships to a 0.20-second floor. Each projectile always deals exactly 1 HP of damage, regardless of fleet size. Larger fleets still fire more projectiles, with the existing faster volley intervals. Normal projectiles remain bounded to 768.

The bomb, Alt action, ammunition targets, charge counter and associated live state have been removed from active gameplay. At the user's request, the accepted bomb design, original functions, regression checks and bolt artwork are preserved for possible restoration; see [parked power-shot design](docs/power-shot.md). The archive is plain text and does not run. Normal automatic fire and the existing impact/destruction sounds remain.

Targets drift gently sideways while descending and rebound from invisible course borders. Swept projectile and ship-contact tests follow the visible elliptical hull rather than its bounding rectangle, so shots through the empty corners miss. All hulls use a common ellipse aspect ratio compensated for the fixed camera; object separation is calculated in the corresponding circular metric, with a small presentation gap for HP/reward labels. Remaining HP still acts as mass: heavy targets deflect less, and damaged targets become easier to push. Impacts do not consume HP or grant rewards. Drift and collision tuning live in `game/scripts/target_motion.gd`.

Each restart randomizes lanes, offsets, one to three targets per wave, enemy/obstacle mix, target sizes, HP variation, score rewards and wave intervals. Every wave offers a reinforcement target. The opening wave includes a small reinforcement ship near the center and at least one threat.

For the first 30 seconds of mission time, every wave also offers an alien-piloted score ship. Opening aliens use the small hull, 5 or 6 HP and the normal small score reward (40–70 points), so a lone fighter can destroy them. From 30 seconds onward, new aliens resume the existing size mix with a gentler HP curve; already spawned ships keep their HP. With `m = max(0, mission_seconds - 30) / 60`, the two alien variants have base HP `5 / 0.7 + 18*m + 8*m^1.6` and `6 / 0.7 + 24*m + 10*m^1.6`. Existing size factors (0.7/1/1.5/4/7), random variation (+/-15%) and rounding apply. Small aliens therefore continue from roughly 5-6 HP at 30 seconds rather than jumping to the old 73-95 HP; larger hulls still carry more HP. Alien health does not depend on fleet size. Captured-fighter/Fleet frequency, health, rewards and random rolls are unchanged, as are scrolling speed and wave intervals.

Small Fleet supply ships always have 5 HP and grant +1 ship, independently of difficulty. They appear at least every two waves, with extra random appearances, so losing most of the fleet does not make every reinforcement target unaffordable. Their travel speed is capped at 6.4 units/second, preserving a shooting opportunity as the rest of the course accelerates. Other targets retain increasing health and larger rewards. All targets, including Fleet supplies, are contact threats if left intact.

There is no finish line or time limit. The LCD shows elapsed mission time; the run ends only when no soldiers remain. Internal difficulty starts at level 2 with a 60-second offset applied to Captured-fighter/Fleet health, wave pressure, target tiers and speed. Alien health uses the separate mission-time curve described above. The LCD starts at LEVEL 01 and mission time 00:00; displayed level increases by one each full survival minute and resets on restart. Scrolling follows `1.3 * (3.8 + 0.014*t + 0.000012*t*t)`, where `t` is mission time plus 60 seconds. Speed starts at 6.09 units/second (previously 3.8) and accelerates continuously: about 7.34 at one minute, 8.72 at two, 11.80 at four and 15.34 at six. Captured-fighter/Fleet HP retains its existing power curve; alien HP uses the gentler exponent of 1.6. Wave pressure grows and heavy objects become more likely. Easy small supplies are exempt from health growth. Wave intervals have a 0.65-second safety floor and active targets remain bounded to 30, but speed and normal HP keep increasing without a fleet-size cap. Fast targets use swept contact checks, removing only soldiers actually crossed.

For reproducible debugging, the engine log prints `RUN_SEED`. Replay a seed with:

```powershell
.\scripts\Run.ps1 -Seed 123
```

When an explicit seed is supplied, restarting repeats that course. Without it, each restart generates a fresh seed.

The fixed 3D camera keeps the spacecraft formation near the lower edge. Fighters retain their original visible size at every fleet count. Larger formations use compact ranks, widening above 32 ships while additional ranks are compressed into the existing formation depth as the fleet grows. Fighter silhouettes have swept wings and a cockpit cutout, replacing humanoid meshes. Unshaded olive materials, a passive-matrix grid, ghost segments, seven-segment counters and a handheld-style bezel create the LCD presentation. Original SVG icons are stored in `game/assets/icons/` and enemy artwork in `game/assets/enemies/`; the bundled Share Tech Mono font uses SIL OFL 1.1 (source and license in `game/assets/fonts/share-tech-mono/`). Interface typography uses this font with system fallback disabled; seven-segment counters and existing numeric reward/HP readouts are preserved. Ships and normal projectiles use MultiMesh rendering; ship rendering capacity grows with the fleet; individual gameplay positions and collisions remain separate.

Original synthesized arcade sounds provide feedback for shots, hits, destroyed targets, reinforcements, casualties and defeat. They are generated locally in `game/scripts/sound.gd`; no downloaded audio or additional runtime is needed. Shot audio plays once per volley and hit sounds are throttled to avoid crowding the mix. An original 24-bar, 132 BPM chiptune loop (about 44 seconds) adds a pulse melody with three developing phrases, an alternating octave triangle bass, and light chip kick/snare/hat percussion during play. It is synthesized locally in `game/scripts/music.gd`, with no downloaded assets. The melody is reduced by about 1 dB and the bass raised by about 0.9 dB relative to the initial arrangement; percussion and master settings are unchanged. Music stays below effects, pauses with P, resumes at the same position, stops on defeat and restarts from the beginning on a new run. M and the volume slider control both music and effects; the ready screen and demonstration remain silent and hide the volume controls. The version remains visible. Name entry plays a separate original victory loop, controlled by the same volume and mute settings.

Every surviving target is a contact threat, including missed supplies. Only ships intersecting it are removed; targets passing beside the fleet cause no damage. Every intact target uses the same micro-explosion when it hits a formation ship, including alien-piloted and captured-fighter/Fleet ships. The controls demo uses this same contact feedback. The 0.45-second capture beam is reserved for eligible freed fighters being recaptured by alien-piloted ships; it removes the pickup without adding targets, changing alien HP or granting rewards. The intro keeps its original capture sequence. Pickup warning timers and capture effects freeze on pause; pending capture effects finish during the defeat hold and clear on restart. The formation compacts after losses, so steer away from ongoing contacts. There are no multiplication gates.

The logical window is 725 × 800. The right panel fits around the original 11-unit-wide course with about 10 pixels of margin on each side. The camera preserves the original pixel scale. Matching olive margins surround the right panel in play, briefing and demo, aligned with the HUD top and bottom. Only the left HUD panel has a thin black inner outline. The course, enemy labels, projectiles and effects are visually clipped to the light rectangle, so nothing appears over its surrounding margins or the HUD. Vertical movement stops 10 pixels earlier at both ends to keep fighters inside the inset area; horizontal limits, collisions and encounter tuning are unchanged. Intro text and demo animations use the compact panel width.

## Validation and local data

```powershell
.\scripts\Validate.ps1
```

Validation imports the project and checks automatic fire, four-direction input, small/full-fleet top and bottom bounds, moving-ship contacts, curved-edge misses, seeded generation, recovery, elite tiers, fixed capacity, growing difficulty, parallel trajectories, contact losses, flight reset and full-fleet framing. It also checks fixed pilot dimensions and proportional Fleet artwork across all five sizes. Sound is muted during accelerated checks. Logs and the current enemy-size capture are under `artifacts/`. The curved-enemy change has no new frame-rate claim.

To inspect all five enemy sizes side by side at the actual gameplay pixel scale:

```powershell
.\tools\godot\Godot_v4.7.2-stable_win64_console.exe --path .\game --script res://scripts/preview_targets.gd
```

This focused visual preview saves `artifacts/enemy-tiers.png`. Add `-- --capture` to close it after saving. It does not change course tuning or add a gameplay mode.

`tools/godot/editor_data/` contains the editor settings and cache, verified after launch. The actual default project data path reported by this Windows build is `%APPDATA%\Godot\app_userdata\Pocket Invasion\`, even with the editor in self-contained mode. It contains shader caches and, without an explicit log override, game logs under `logs/`. No custom user-data setting is enabled. The game saves its Top 10 in `high_scores.json` in this directory. Web builds use browser-local storage through Godot's `user://` filesystem; see [local score storage](docs/MANUAL.md#local-score-storage). Project imports stay in `game/.godot/`.

The first sandboxed verification could not create the default user-data directory; running with normal desktop access resolved this. Detailed verification notes are in `artifacts/verification.md`.

## Prototype limits

One randomized endless mode, flat SVG enemy artwork in a simple 3D scene, fixed elevated camera, keyboard controls and synthesized effects and an original minimal chiptune loop. Difficulty, visuals and sound mix are initial tuning; long-term difficulty is not exhaustively playtested. There are no frame-rate claims, installers, third-party assets, network features, or services. Web export is available as described above. Rules and tuning are in `game/scripts/invasion_rules.gd`; seeded encounter generation is in `game/scripts/encounters.gd`.

## License

Copyright (C) 2026 Massimo Barbieri.

Pocket Invasion's source code, documentation and original game assets are licensed
under the GNU General Public License, version 3 or (at your option) any later
version (`GPL-3.0-or-later`). See [LICENSE](LICENSE) for the full terms. The project
is provided without warranty.

Godot Engine and third-party components retain their respective licenses.
Distributed Windows and Web builds must include the applicable copyright and
license notices and provide access to their corresponding source under the GPL.
See [Godot's license guidance](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html).




