# Architecture

## Simulation and presentation

`game/scripts/main.gd` owns run state, fixed-step movement, spawning, swept
projectile/contact tests, pickups, defeat timing and restart. Rules and limits
live in `invasion_rules.gd`; seeded encounter planning is in `encounters.gd`.
Targets, target motion and rescue pickups have focused scripts. MultiMesh batches
render fighters and bullets while simulation positions remain separate.

`alien_fire.gd` owns bounded hostile energy orbs. Alien targets have individual
firing clocks; containment targets never fire. Each orb retains its launch origin,
age and nonzero constant lateral velocity, with forward acceleration describing
an exact parabola in the course plane. Fixed-step updates sweep short curve
segments against moving fighters and consume each orb at its first impact.
That impact discharges over a local 0.80-unit screen-circular radius, testing
fighter footprints interpolated at the impact time. Central hits overlap more
fighters than edge hits; remote fighters are never selected by a damage count.
Survival time scales repeat-shot clock progress from 20% at the start to 100%
at 60 seconds, with no opening protection. Each ship's first attack uses the
unscaled 1.15-second wind-up. Cadence stays capped thereafter;
enemy count supplies further growth in total fire. Two-pilot ships emit a pair
from the two pilot positions in one tick with a shared cooldown. Capacity is
reserved for the complete pair, so the global limit never splits a volley.
Orb and hull casualties are collected before a single formation compaction.
Two flat SVG frames alternate electric discharges outside the collidable core.
Pause freezes firing and flight; reset frees all orbs. Tuning lives in the rules.

Formation spacing stays at 0.58 world units on both axes for all fleet sizes.
Column capacity rises from six to eight above 24 ships, then gains one per eight
reinforcements above 32, capped at 18 so full-width rows fit the course without
compression. Movement limits use the current formation width and depth.
A separate MultiMesh draws cosmetic rocket exhaust on fighters without a
horizontally overlapping fighter in the row behind. Only the final two rows
need checking, since earlier rows have complete rows behind them. Three flame
lengths follow the run clock, freezing during pause and resetting on restart.

`lcd_display.gd` draws the olive LCD panels, game statistics and Top 10. It owns
the three-page cycle (`story_intro.gd` plus `attract_demo.gd`), page navigation,
volume widgets and the uppercase arcade name editor. Demo animations create no
gameplay entities or audio. A fixed camera renders the flat course in the inset
right panel; HUD masking keeps the course out of the bezel and left column.
Interface text uses bundled Share Tech Mono (SIL OFL 1.1), with system fallback
disabled. All text shares this font, including target/pickup HP and rewards,
numeric reward/loss notices, Help readouts and leaderboard scores. The project
default theme receives it at runtime for inherited UI text such as tooltips,
after assets have been imported. No project-level custom font is configured,
because Godot loads that setting before the first import on a fresh checkout.
Seven-segment HUD counters remain drawn geometry. The HELP! sign is outlined SVG artwork.
Font provenance
and license live in `game/assets/fonts/share-tech-mono/`; no font installation or
runtime download is needed on Windows or Web. Briefing text uses fixed 21-unit line baselines,
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
