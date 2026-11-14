# Architecture

## Simulation and presentation

`game/scripts/main.gd` owns run state, fixed-step movement, spawning, swept
projectile/contact tests, pickups, defeat timing and restart. Rules and limits
live in `invasion_rules.gd`; seeded encounter planning is in `encounters.gd`.
Targets, target motion and rescue pickups have focused scripts. MultiMesh batches
render fighters and bullets while simulation positions remain separate.

`lcd_display.gd` draws the olive LCD panels, game statistics and Top 10. It owns
the three-page cycle (`story_intro.gd` plus `attract_demo.gd`), page navigation,
volume widgets and the uppercase arcade name editor. Demo animations create no
gameplay entities or audio. A fixed camera renders the flat course in the inset
right panel; HUD masking keeps the course out of the bezel and left column.
All text labels use `ThemeDB.fallback_font`: Open Sans SemiBold embedded in the
pinned Godot engine, shared by Windows and Web without system font lookup or
additional font downloads. Briefing text uses fixed 21-unit line baselines,
including blank lines, to keep the paragraph clear of the page navigation.

## Defeat and high scores

The main script loads `LocalHighScores` at startup. A qualifying defeat freezes
the course for three physics-timed seconds; Enter/Space can advance immediately
to name entry. Other defeats retain the ten-second hold and immediate restart.
Name entry consumes keyboard input before normal shortcuts. Confirm emits the
name to main, which records and saves exactly once, stops audio and returns to
the briefing cycle. Starting a run clears pending entry and all previous run
entities. Pause cannot activate the demo or the leaderboard.

`high_scores.gd` stores ten descending score/name dictionaries, seeded with
fictional names. Strict comparison puts existing scores first on ties. Names
are bounded to twelve uppercase arcade characters. A versioned JSON envelope
is validated in full before replacing defaults. Saving flushes and closes a
temporary file before renaming it over the previous file. Failure preserves the
in-memory table and is surfaced to the player. `user://` supplies native local
application data or browser IndexedDB without another runtime or service.

## Audio

`sound.gd` manages synthesized effects and two exclusive music players.
`music.gd` generates the gameplay loop and an original eight-bar major-key
victory march. The victory loop runs only during name entry. Both music players
respect volume/mute and avoid redundant Web unpause operations. Confirmation
and restart stop the victory loop. The attract cycle stays silent.

## Environment and identity

The portable pinned engine and its self-contained editor data live under
`tools/godot/`; imports stay under `game/.godot/`. Scripts resolve paths relative
to the project. Build identity and export snapshots are separate from the
application version and player data. See [development](DEVELOPMENT.md) and
[README](../README.md) for setup, exports and verification.

Identity capture reads `origin` and includes the approved project root URL when
it matches Pocket Invasion's repository. The HUD version opens that captured URL.
Exports read only their bundled snapshot; absent or unapproved remotes leave the
version unlinked, and future remotes require separate approval.

The command scripts select a native Windows or Linux editor through
`Get-GodotPath.ps1`; export targets remain Web and Windows x64 on either host.
GitHub Actions builds a clean tagged snapshot on Linux with read-only repository
access. A separate publishing job receives write access only after validation and
packaging succeed, then attaches both ZIPs and checksums to the tag's release.
