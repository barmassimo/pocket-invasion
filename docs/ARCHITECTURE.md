# Architecture

## Simulation and presentation

`game/scripts/main.gd` owns run state, fixed-step movement, spawning, swept
projectile/contact tests, pickups, defeat timing and restart. Rules and limits
live in `invasion_rules.gd`; seeded encounter planning is in `encounters.gd`.
Below 30 fighters, recovery containment ships appear in the first wave, then
with a 45.7276% per-wave chance or forcibly after two skipped waves (54.43% of
waves on average). Their +1 reward stays fixed. The first three planned
containment ships have 5 HP when the fleet is below the threshold, with their
normal tier rewards. After these three ships, small recovery HP is sampled
uniformly from 5 and 10, independent of difficulty. At 30 fighters or more, the
wave planner uses normal containment tiers and health, and primes the recovery
counter so the first wave after dropping below 30 includes a recovery ship.
Restart resets the encounter counters.
Targets, target motion and rescue pickups have focused scripts. MultiMesh batches
render fighters and bullets while simulation positions remain separate.
Normal bullets and hollow POW bullets use separate MultiMesh batches under one
shared 768-projectile simulation limit. The POW mesh is a four-rail frame,
0.14 units wide versus the normal 0.09, with the same 0.45-unit length.
Each projectile keeps its launch mesh through effect expiry; swept collision
padding, speed and one-HP damage are shared. Restart clears both render batches.
Target motion applies a capped, acceleration-limited lateral correction toward
the nearest recapturable fighter ahead within a short screen-space radius of
the hull. Containment ships, egg carriers and protected pickups are excluded.
Forward travel, wall bounds and hull separation remain active; steering eases out when no nearby
candidate remains. Tuning lives in `invasion_rules.gd`, and each target owns its
transient steering state, cleared with run entities on restart.
Recapture replaces a vulnerable rescue pickup with a small kind-0 containment
target at 5 HP, preserving its full fighter reward. The tractor beam plays first;
from 0.25 to 0.70 seconds, the hull and captive emblem grow together with smooth
easing, attached to the moving captor's inward edge. From 0.70 to 0.90 seconds,
the full-size ship opens a 0.30-unit gap and then moves independently with
an additional inward lateral drift of 0.225 units/second.
Collision separation respects this smaller gap.
This accelerates the intro's conversion/departure sequence.
HP and reward labels appear at full size. During assembly the target is excluded
from shots, contact damage, wall and hull separation; normal simulation resumes
on release. Weak references allow conversion to finish at the last anchor if the
captor is destroyed. All timing is fixed-step, freezes on pause and clears on
restart. At the target limit, recapture is deferred
and the pickup remains available. Destroying the containment target follows the
normal rescue drop and five-second protection cycle.
Player fighter and exhaust materials use linear texture filtering and alpha
blending to soften contour aliasing without changing their solid fill colors.

`alien_fire.gd` owns bounded hostile energy orbs. Alien-piloted targets and egg
carriers have individual firing clocks; fighter-containment targets never fire.
`CourseTarget.can_fire()` includes egg carriers, while `is_alien()` limits
fighter recapture and steering to the two alien-piloted score kinds.
Each orb retains its launch origin, age and nonzero constant lateral velocity,
with forward acceleration describing
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
Orbs disable depth testing and use render priority 2, above hulls and their
priority-1 cockpit layers, so overlapping enemy ships cannot hide hostile fire.
Pause freezes firing and flight; reset frees all orbs. Tuning lives in the rules.

## Rapid-fire pickups

Kind 3 targets reuse the original egg/medallion artwork through runtime copies
in `game/assets/enemies/egg-hull.svg` and `egg-core.svg`; the source layers remain
in `docs/art-concepts/egg-original/`. HP appears above the hull and `FIRE x2`
below it. `encounters.gd` inserts a small egg carrier in zero-based wave 6 and
every tenth wave thereafter. A full wave replaces its last score slot, keeping
the reinforcement target, the opening score opportunity and the three-target
wave limit. Insertion draws no extra random numbers. Carrier HP is clamped to
at least 30; the current small tier uses
`max(30, round((40 + mission_seconds * 0.08) * 0.7))`.

Destroying a carrier only drops a module; it grants no points or fighters.
`fire_pickup.gd` owns the drifting human module, its alien-energy artwork and
the `POW` label. The visual parent gently bobs without rotating or scaling;
only the energy layer rotates and pulses in opacity. Its square mesh rotates
inside a parent with camera-projection compensation, preserving its circular
screen contour through the full turn. This keeps the projected silhouettes rigid
and the collection footprint unchanged. They all blink together after
`PICKUP_BLINK_SECONDS` (five seconds), then expire three seconds later.
`fire_boost.gd` owns these modules, swept collection by surviving formation
members and the ten-second bonus timer. Modules are separate from rescue
pickups: they are immune to shots and recapture and never become steering
candidates. Off-course modules are removed; the active module cap is 16, with
the oldest removed if a new drop fills capacity.

The bonus doubles firing-clock progress instead of projectile damage. The clock
retains its partial interval and fixed-step remainder; one shot sound plays
per emitted volley, so audio and projectile cadence agree. Another collection
refreshes ten seconds without stacking. No energy aura is rendered around the
fleet. Fixed-step updates freeze timers during pause, and reset clears bonus
state and modules. The existing briefing and attract cycle remain unchanged.

## Formation and interface

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
