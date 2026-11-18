# Player manual

## Playing

Run `scripts/Run.ps1` from PowerShell in the project root after preparing the
environment as described in [README](../README.md#prepare-and-play).
Optional Linux x64 use requires PowerShell 7 and a graphical desktop; see
[Linux setup](DEVELOPMENT.md#optional-linux-development). Downloadable release
packages target Windows x64 and Web; a native Linux game package is not produced.
Enter or Space starts from any briefing/demo page. Arrows or WASD move the fleet
in four directions; firing is automatic. Destroy aliens for points and break
containment ships, then touch the freed fighters to grow the fleet. Contact with
an intact enemy removes only fighters actually touched. The run ends at zero ships.

Small containment ships grant +1 fighter. The first wave always includes one
with 5 HP. Later ships have 5 or 10 HP, each equally likely regardless of
difficulty or fleet size. After the first wave, each wave has about a 45.7%
chance of including one, with a guaranteed appearance after
two consecutive waves without one. This gives about 54.4% of waves a small
containment ship on average. You must still free and collect the fighter.

Rare egg/medallion ships show HP above the hull and `FIRE x2` below it. They
appear first in the seventh wave, then once every ten waves, without replacing
the guaranteed reinforcement opportunity. They have at least 30 HP, increasing
with mission time, and fire hostile energy globes. Contact with their hulls
removes touched fighters just like other intact targets. They do not recapture
freed fighters.

Destroying an egg ship releases a floating human weapon module surrounded by
alien energy and labeled `POW`. Destroying the carrier grants neither points
nor fighters and does not activate the bonus: touch the module with a surviving
formation member to collect it. Shots pass through modules, and enemies cannot
recapture them. An uncollected module drifts down the course; after five seconds
the whole object and `POW` label blink together, remaining collectible even
while hidden. After three more seconds it disappears, or sooner if it leaves
the course.

Collecting `POW` doubles the entire fleet's automatic firing frequency for ten
seconds. Shot sounds play at the same faster cadence. Each projectile still
deals 1 HP and travels at normal speed; boosted shots are slightly wider and
hollow in the center. The fleet has no surrounding energy aura. Another module
refreshes the bonus to ten seconds without stacking speed or duration. When the
bonus expires, new shots return to the normal solid shape and cadence; shots
already in flight keep their launch appearance. Pause freezes both module
expiry and bonus duration. Restart clears modules, the bonus and all shots.

Alien-piloted ships also fire small energy globes surrounded by flickering electric
discharges. Their paths curve diagonally down the course, always with sideways
motion, distinct from the fleet's straight shots. On impact a globe discharges
locally and disappears: a centered hit can destroy several nearby fighters,
while grazing the fleet removes fewer. Distant fighters are unaffected and
dodged globes cause no losses. Alien firing is active from the start, with frequency
ramping from 20% to full over the first 60 seconds. Each ship's first attack has
only a short wind-up; the ramp controls repeat shots. Ships with two alien pilots
fire two globes simultaneously from separate positions, sharing one firing clock.
After that each ship keeps the same cadence; more aliens mean more total fire.
Containment ships do not shoot. Pause freezes globes and firing clocks, and
restart clears them and resets the frequency ramp.

Fighters keep the same visible size and horizontal/vertical spacing at every
fleet count. Rows hold up to six fighters through 24 ships, eight through 32,
then gain one column per eight reinforcements up to 18 columns. Additional
fighters add rows behind the front row; incomplete rows stay centered.
Rocket exhaust animates on fighters with no fighter directly behind them,
including exposed fighters ahead of a shorter last row. Pause freezes the flame.
Larger formations occupy more space and leave less room to move.
There is no fixed fighter-count cap: the growing footprint and exposure to
enemy contact are the intended natural constraint on fleet size.

Freed fighters are protected from recapture for five seconds. As soon as they
show the blinking HELP! sign, alien-piloted ships can recapture them on
contact, including while the sign is hidden. Only HELP! blinks; the fighter and
reward stay visible. You can still collect them.
Nearby alien-piloted ships gently steer sideways toward these vulnerable fighters
as they pass, while continuing down the course. They do not turn back to pursue them.

P pauses/resumes; PAUSED blinks every half second while the course is frozen.
M mutes/unmutes, F or F11 toggles fullscreen, and Esc leaves
fullscreen. The volume slider controls music and effects. Start keys do nothing
during a run or pause. Restart clears all previous run entities and counters.
During gameplay and pause, the footer shows only volume and mute controls;
the copyright and version are hidden.

## Demo and Top 10

The left column displays the Top 10, followed by How to Play and the keys.
The Enter/Space start prompt appears only in this column, not on the three right pages.
The version stays at the bottom. Click it to open the project repository in your
browser when its URL was captured from the approved remote. The game remains
usable offline; opening the link is optional. The silent demo hides the volume controls.
The copyright above the version opens https://massimobarbieri.it in your browser.
Left/Right changes briefing/demo pages; the dots and arrows are also clickable.
The three pages continue cycling automatically. During play and pause the left
column displays the existing game statistics instead of the leaderboard.

The initial table contains ten fictional pilots with international names and
irregular scores from 1042 to 4879. A new score must beat the tenth score to qualify;
existing entries take precedence on ties. Only the ten highest scores remain.

A qualifying defeat holds the course for three seconds, then opens name entry.
Enter or Space opens it immediately during that hold. A triumphant chiptune
loops during name entry, with the existing volume and mute settings; the volume
and speaker controls are visible here. There is no automatic name-entry timeout.

- Type directly: letters become uppercase. Names have up to 12 characters,
  using A–Z, digits, spaces and hyphens.
- Up/Down: cycle the current character; Left/Right: move the cursor, wrapping
  at the ends. The highlighted slot shows which character will change.
- Backspace: erase the previous slot; Delete: clear the current slot.
- Home/End: jump to the beginning or first unused slot.
- Enter: save and return to the demo with the updated Top 10. Empty names,
  including spaces only, are rejected: the name field flashes once and stays
  editable. Held Enter does not accidentally confirm a name or repeat the flash.

Typing M, P or F during name entry writes a letter; the clickable speaker and
volume slider still control sound. Outside the Top 10, defeat retains the
ten-second hold and immediate Enter/Space restart.

F11 and Esc remain available during name entry for fullscreen control.

## Local score storage

The only saved game data is `user://high_scores.json`. On Windows this is
`%APPDATA%\Godot\app_userdata\Pocket Invasion\high_scores.json` by default.
On the Web it is in the browser's local IndexedDB storage, through Godot's
[user data filesystem](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html).
There is no server, account, network synchronization or shared leaderboard.
Different browsers, browser profiles and site addresses keep separate tables.
Clearing site data removes the Web scores; private browsing or blocked browser
storage may prevent persistence. Keep the same hosting address to retain scores.

Missing or invalid data restores the initial fictional table. A write failure
keeps the updated table for the current session and shows a save-failure notice.
Audio settings survive restarting a run but are not saved between launches.
