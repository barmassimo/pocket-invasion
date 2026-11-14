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

Freed fighters are protected from recapture for five seconds. As soon as they
show the blinking HELP! sign, alien-piloted ships can recapture them on
contact, including while the sign is hidden. Only HELP! blinks; the fighter and
reward stay visible. You can still collect them.

P pauses/resumes, M mutes/unmutes, F or F11 toggles fullscreen, and Esc leaves
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
- Enter: save and return to the demo with the updated Top 10. An empty name
  becomes PILOT. Held Enter does not accidentally confirm a name.

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
