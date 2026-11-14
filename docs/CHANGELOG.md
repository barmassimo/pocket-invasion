# Changelog

## Unreleased

### Changed

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
