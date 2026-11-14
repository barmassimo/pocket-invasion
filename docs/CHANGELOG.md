# Changelog

## Unreleased

### Fixed

- Freed fighters become recapturable as soon as the HELP! blinking starts at
  five seconds, without an additional five-second protection period.

### Added

- Windows and Web exports include the project GPL, engine license, third-party
  copyright and license texts, distribution information and build identity.
- Web exports provide a linked license page; local hosting serves text and JSON
  notices with the appropriate content types.
- GNU GPL version 3 or later license for the source code, documentation and
  original game assets, with copyright and licensing information in README.

### Changed

- Blink only the freed fighter's HELP! sign, keeping its ship and reward visible.

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
