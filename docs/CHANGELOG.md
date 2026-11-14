# Changelog

## Unreleased

### Fixed

- Freed fighters become recapturable as soon as the HELP! blinking starts at
  five seconds, without an additional five-second protection period.

### Added

- GitHub Actions release workflow on Linux, triggered by stable version tags or
  manually for an existing tag, with automated checks, Web/Windows ZIPs and hashes.
- Optional Linux support for the shared bootstrap, validation, export and launch
  scripts using the pinned standard engine and existing export presets.
- Local Top 10 with fictional starting pilots, uppercase keyboard/arcade name
  entry and a triumphant chiptune loop for qualifying scores.
- Windows and Web exports include the project GPL, engine license, third-party
  copyright and license texts, distribution information and build identity.
- Web exports provide a linked license page; local hosting serves text and JSON
  notices with the appropriate content types.
- GNU GPL version 3 or later license for the source code, documentation and
  original game assets, with copyright and licensing information in README.

### Changed

- Blink only the freed fighter's HELP! sign, keeping its ship and reward visible.

- Show the Top 10 and How to Play keys in the left column during the demo,
  keeping the version visible and hiding the silent demo's volume controls.
- Keep the Enter/Space start prompt in the left column only, removing its
  duplicate from the three briefing/demo pages.
- Give the command-center message a uniform font size and line spacing, with
  one blank line between paragraphs and a compact gap below the illustration.
- Qualifying defeats open name entry after three seconds or Enter/Space;
  confirming returns to the demo with the updated leaderboard.
- Enclose `[ARROWS]` in square brackets in the briefing and demonstration controls.
- Show only the application version when Git identity or a valid exported build
  snapshot is unavailable, without an extra suffix.

## 1.0.0 - 2026-11-14

### Added

- Initial versioned release of the existing Pocket Invasion prototype, with
  Windows and Web export scripts, endless formation combat, collectible fighters,
  LCD artwork, briefing, animated instructions and synthesized audio.
- Application version and short source commit in the lower-left HUD, with the
  full hash available in a tooltip. Development builds identify local changes
  with `modified`; exports bundle their build identity and run without Git.
- Release rules based on cumulative changes since the applicable version tag.

### Changed

- Raised the volume slider and mute button to make room for the version display.
