# Pocket Invasion

A local Windows arcade prototype made with standard Godot 4.7.2 and typed GDScript, styled as an olive monochrome 1980s LCD handheld. Fly a spacecraft formation freely across the playfield, shoot automatically and break targets for more ships or score.

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

The preset uses Compatibility/WebGL 2.0, single-threaded execution, an adaptive canvas and no PWA/service worker. No special COOP/COEP headers are needed. Keyboard controls are shared with Windows; click the canvas if it lacks focus. Browser-reserved keys may behave differently (especially F11/Esc); F is the game's alternative fullscreen key. Audio requires initial user interaction. Mobile/touch controls are not implemented. System fonts fall back to Godot's default font on Web, so text appearance can differ from Windows. Browser performance, audio and cross-browser behavior require testing; native validation does not establish Web compatibility.

The first Web build was verified on 2026-11-13 in the in-app Chromium browser: introduction, Enter to start, automatic shooting, targets/rewards and P to pause were observed, with no console warnings/errors. Audio, fullscreen, movement limits, performance and other browsers remain unverified. Details are in `artifacts/web-verification.md`.

Volume changes only update the music pause state when it actually changes, avoiding redundant unpause calls that can restart Web Sample playback in Godot 4.7.2. The Web build was regenerated after this correction; native checks passed and changing the slider in the browser produced no console warnings/errors. The user confirmed that deployment on IIS works with the included MIME mappings and reported that the audio glitch appears resolved. This is user listening feedback, not an exhaustive load test; Web loop resume after an actual pause/mute remains unverified.

## Controls and rules

- Enter / Space: start from the introduction, demo or defeat screen. These keys do nothing during play or pause.
- W / A / S / D or all four arrow keys: move up, left, down and right.
- Normal fire is automatic while the run is active; no Ctrl input is needed.
- P: pause or resume.
- F11 or F: toggle fullscreen, preserving the game's aspect ratio.
- Esc: leave fullscreen without changing the current run or pause state. There is no command to abandon a run.
- M: mute or unmute music and sound effects (M=MUTE). The speaker icon shows a cross when muted. Mute is kept when restarting the run.
- Drag the horizontal slider beside the speaker to adjust master audio volume (0–100%, initially 50%). Raising it unmutes audio; volume and mute survive a run restart. The default effects level is about 3.5 dB louder than the original mix.

On launch, a message headed FROM COMMAND CENTER addresses the last fighter directly: Earth has fallen, captured pilots are still alive, and the fleet must be rebuilt to fight back. The command holds its position and calls for action in an urgent, professional tone. The TOP SECRET orbital illustration reuses the existing alien and fighter artwork with clean olive contours. After 1.6 seconds, an alien beam captures the fighter and converts it into the same round containment spacecraft seen on reinforcement targets, using the exact gameplay hull and Fleet emblem; the silent sequence repeats every 11 seconds while the briefing text stays still. The How to Play prompt uses the same readable size as Start. The briefing stays visible until Enter / Space starts the game, or D shows the controls demo. The introduction only appears on launch, so defeat never interrupts the demo with the story. Each run begins with the lone fighter from the story; reinforcements rebuild the fleet during play.

Start with one ship and no hard fleet-size cap. Reinforcement rewards grant their full ship count. Above 32 ships, the formation widens by one column for each additional group of eight ships (33–40: nine columns, 41–48: ten, and so on), up to 20 columns to keep all ships inside the playfield. A wider fleet has less lateral escape room and is harder to keep intact, providing a natural constraint through contact losses. Losses reduce its width again. The LCD displays the current ship count. Restarting restores one ship.

Enemies now use the approved flat, rounded 1950s–1960s alien-spacecraft design, with original SVG layers under `game/assets/enemies/`. Score enemies show a neutral-faced alien with two antennae: small/regular ships carry one pilot, medium/heavy ships two, and command ships three. Every pilot stays the same absolute size across tiers; only the hull and cockpit grow. Fleet supplies show the clean circular treasure emblem instead, without the three small inner dots, and scale the entire hull/cockpit/emblem proportionally. Both score-awarding encounter kinds use alien ships; their existing HP and reward tuning remain distinct. There are no glossy materials, perspective-drawn hulls, reflections or shaded volume. The fixed camera's foreshortening is compensated so the flat hulls appear round.

Health stays labeled `HP` above each ship. The reward amount appears separately below the hull so it never covers the crew or treasure. The left HUD still uses the spacecraft icon for fleet gains and the medal icon for score gains. Small through command fleet supplies award +1/+2/+4/+8/+16 ships. Score rewards by size remain 40–70 / 80–140 / 160–280 / 320–560 / 640–1120. Small recovery supplies remain present.

All live game information is in the left column: ship count, score, mission time, threat level, mode, audio state and reward/loss notifications. The window has exactly two areas: the statistics column on the left and the main screen on the right. The former third column is removed, narrowing the window to 775 x 800 while preserving the course scale and framing. The main screen alternates between the game and a silent 27-second arcade demonstration that is available with D from the introduction and begins ten seconds after defeat: shoot a 5-HP ship cache to grow from one ship to two, destroy an alien ship for points, and avoid contact that removes only the ship touched. In the contact lesson, both ships move together at fixed spacing; the obstacle clips the left ship while the right ship survives. Each nine-second lesson ends with a three-second freeze and a short English caption. The demonstration is hidden during play and pause, resets when a run starts, and never creates gameplay entities or audio. After defeat, the final course and a restart prompt stay frozen for ten seconds. Pressing Enter or Space from defeat starts a new run immediately and cancels the pending demo. If no new run starts, the demo begins automatically. The main screen shows the introduction on launch, the demo after this hold, and the live course during play or pause. Pausing freezes the course with a PAUSED message; it never switches to the demo. Defeat is identified by the FLEET LOST heading above the demo.

Vertical movement spans the entire visible playfield, from the bottom to the top, retaining only a small border margin and enough room to keep the whole formation visible. Diagonal input is normalized, and vertical world movement compensates for camera foreshortening so screen movement feels comparable in both axes. There is no safe player line: moving into an approaching target can destroy the ships actually crossed. Shots always travel forward; flying above an object does not make ships fire backwards. New reinforcements, casualties and restart update the bounds and reset movement history appropriately.

Normal shots travel straight forward in parallel, without convergence, auto-aim or homing, and are recycled after passing the far end of the visible course. Move the formation to put its firing columns over a target. Each ship fires one projectile per volley automatically. Volley intervals improve from 0.45 seconds with one to four ships to a 0.20-second floor. Each projectile always deals exactly 1 HP of damage, regardless of fleet size. Larger fleets still fire more projectiles, with the existing faster volley intervals. Normal projectiles remain bounded to 768.

The bomb, Alt action, ammunition targets, charge counter and associated live state have been removed from active gameplay. At the user's request, the accepted bomb design, original functions, regression checks and bolt artwork are preserved for possible restoration; see [parked power-shot design](docs/power-shot.md). The archive is plain text and does not run. Normal automatic fire and the existing impact/destruction sounds remain.

Targets drift gently sideways while descending and rebound from invisible course borders. Swept projectile and ship-contact tests follow the visible elliptical hull rather than its bounding rectangle, so shots through the empty corners miss. All hulls use a common ellipse aspect ratio compensated for the fixed camera; object separation is calculated in the corresponding circular metric, with a small presentation gap for HP/reward labels. Remaining HP still acts as mass: heavy targets deflect less, and damaged targets become easier to push. Impacts do not consume HP or grant rewards. Drift and collision tuning live in `game/scripts/target_motion.gd`.

Each restart randomizes lanes, offsets, one to three targets per wave, enemy/obstacle mix, target sizes, HP variation, score rewards and wave intervals. Every wave offers a reinforcement target. The opening wave includes a small reinforcement ship near the center and at least one threat.

Small Fleet supply ships always have 5 HP and grant +1 ship, independently of difficulty. They appear at least every two waves, with extra random appearances, so losing most of the fleet does not make every reinforcement target unaffordable. Their travel speed is capped at 6.4 units/second, preserving a shooting opportunity as the rest of the course accelerates. Other targets retain increasing health and larger rewards. All targets, including Fleet supplies, are contact threats if left intact.

There is no finish line or time limit. The LCD shows elapsed mission time; the run ends only when no soldiers remain. Internal difficulty starts at level 2 with a 60-second offset applied to health, wave pressure, target tiers and speed. The LCD starts at threat level 01 and mission time 00:00; displayed threat increases by one each full survival minute and resets on restart. Scrolling follows `1.3 * (3.8 + 0.014*t + 0.000012*t*t)`, where `t` is mission time plus 60 seconds. Speed starts at 6.09 units/second (previously 3.8) and accelerates continuously: about 7.34 at one minute, 8.72 at two, 11.80 at four and 15.34 at six. Normal HP adds a survival-time power curve, while wave pressure grows and heavy objects become more likely. Easy small supplies are exempt from health growth. Wave intervals have a 0.65-second safety floor and active targets remain bounded to 30, but speed and normal HP keep increasing without a fleet-size cap. Fast targets use swept contact checks, removing only soldiers actually crossed.

For reproducible debugging, the engine log prints `RUN_SEED`. Replay a seed with:

```powershell
.\scripts\Run.ps1 -Seed 123
```

When an explicit seed is supplied, restarting repeats that course. Without it, each restart generates a fresh seed.

The fixed 3D camera keeps the spacecraft formation near the lower edge. Larger formations use compact ranks, widening above 32 ships while additional ranks are compressed into the existing formation depth as the fleet grows. Fighter silhouettes have swept wings and a cockpit cutout, replacing humanoid meshes. Unshaded olive materials, a passive-matrix grid, ghost segments, seven-segment counters and a handheld-style bezel create the LCD presentation. Original SVG icons are stored in `game/assets/icons/` and enemy artwork in `game/assets/enemies/`; no third-party assets or new dependencies were added. Typography uses Windows system monospace fonts with Godot fallback. Ships and normal projectiles use MultiMesh rendering; ship rendering capacity grows with the fleet; individual gameplay positions and collisions remain separate.

Original synthesized arcade sounds provide feedback for shots, hits, destroyed targets, reinforcements, casualties and defeat. They are generated locally in `game/scripts/sound.gd`; no downloaded audio or additional runtime is needed. Shot audio plays once per volley and hit sounds are throttled to avoid crowding the mix. An original 24-bar, 132 BPM chiptune loop (about 44 seconds) adds a pulse melody with three developing phrases, an alternating octave triangle bass, and light chip kick/snare/hat percussion during play. It is synthesized locally in `game/scripts/music.gd`, with no downloaded assets. Music stays below effects, pauses with P, resumes at the same position, stops on defeat and restarts from the beginning on a new run. M and the volume slider control both music and effects; the ready screen and demonstration remain silent.

Every surviving target is a contact threat, including missed supplies. Only ships intersecting it are removed; targets passing beside the fleet cause no damage. The formation compacts after losses, so steer away from ongoing contacts. There are no multiplication gates.

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

`tools/godot/editor_data/` contains the editor settings and cache, verified after launch. The actual default project data path reported by this Windows build is `%APPDATA%\Godot\app_userdata\Pocket Invasion\`, even with the editor in self-contained mode. It contains shader caches and, without an explicit log override, game logs under `logs/`. No custom user-data setting is enabled. The game does not write saves. Project imports stay in `game/.godot/`.

The first sandboxed verification could not create the default user-data directory; running with normal desktop access resolved this. Detailed verification notes are in `artifacts/verification.md`.

## Prototype limits

One randomized endless mode, flat SVG enemy artwork in a simple 3D scene, fixed elevated camera, keyboard controls and synthesized effects and an original minimal chiptune loop. Difficulty, visuals and sound mix are initial tuning; long-term difficulty is not exhaustively playtested. There are no frame-rate claims, installers, third-party assets, network features, or services. Web export is available as described above. Rules and tuning are in `game/scripts/invasion_rules.gd`; seeded encounter generation is in `game/scripts/encounters.gd`.




