# Changelog

## Unreleased

### Changed

- Make recovery containment ships appear in about 54.4% of waves, guaranteeing
  one within three waves and keeping the +1 fighter reward. The first wave's
  recovery ship always has 5 HP; later ships have equally likely 5 or 10 HP.
- Lower the pitch of alien spaceship explosions.
- Lower captive-pilot spaceship explosion pitch by 20%.
- Smooth player fighter and exhaust contours with linear texture filtering and
  alpha blending, leaving other artwork unchanged.
- Enlarge player formation fighters visually by 10%, keeping formation spacing,
  collision sizes and freed fighters unchanged.

### Added

- Alien-piloted ships gently deviate toward nearby vulnerable freed fighters
  to recapture them while passing.
- Add pulsing LCD rocket exhaust to fighters with no other fighter directly
  behind them. Pause freezes the animation and restart resets it.

## 1.3.0 - 2026-11-17

### Added

- Alien ships fire small energy globes with animated electric discharges and
  oblique parabolic trajectories. Local impact discharges destroy more nearby
  fighters on centered hits and fewer on grazing hits.
- Enemy firing is active from the start, with repeat-fire frequency gradually
  reaching its full cadence over the first minute.
- Ships with two alien pilots launch two globes simultaneously.

## 1.2.5 - 2026-11-16

### Fixed

- Apply the default UI font at runtime so fresh-checkout imports do not fail
  GitHub build validation before the bundled font has been imported.

## 1.2.4 - 2026-11-16

### Changed

- Use bundled Share Tech Mono for all text, including HP, rewards, Help readouts,
  leaderboard scores, pause and defeat; preserve the seven-segment counters.
- Add a small gap after the automatic-fire instruction beneath the leaderboard.
- Keep formation spacing constant at every fleet size; cap rows at 18 columns
  to fit the course without compressing fighters.
- Blink the PAUSED message every half second while gameplay stays frozen.

### Fixed

- Keep fighters at their original visible size above 24 ships.
- Reject empty or spaces-only names in Top 10 entry, flashing the name field
  once without saving or leaving the screen.

## 1.2.3 - 2026-11-14

### Fixed

- Complete the menu footer with an aligned, clickable copyright linking to
  massimobarbieri.it. Keep only audio controls at the bottom during gameplay
  and pause.

## 1.2.2 - 2026-11-14

### Fixed

- Use Godot's embedded Open Sans SemiBold for HUD, briefing, demo and target
  labels on both Windows and Web, removing dependence on installed system fonts.

## 1.2.1 - 2026-11-14

### Fixed

- Keep briefing text clear of page navigation when Web fallback fonts have
  taller line metrics than the Windows fonts.

## 1.2.0 - 2026-11-14

### Added

- Clickable HUD version linking to the approved project repository, captured
  with build identity for future Windows and Web exports.

## 1.1.0 - 2026-11-14

### Added

- GitHub Actions releases on Linux, triggered by stable version tags or manually
  for an existing tag, with automated checks, Web/Windows ZIPs and checksums.
- Optional Linux support for the shared bootstrap, validation, export and launch
  scripts using the pinned standard engine and existing export presets.
- Local Top 10 with fictional starting pilots, uppercase keyboard/arcade name
  entry and a triumphant chiptune loop for qualifying scores.
- GNU GPL version 3 or later licensing for source, documentation and original
  assets; Windows and Web packages include project, engine and third-party
  notices, source-access information and build identity.
- Linked Web license page and appropriate text/JSON MIME types in local hosting.
- Briefing and gameplay screenshots in README.

### Changed

- Blink only the freed fighter's HELP! sign, keeping its ship and reward visible.
- Show the Top 10 and How to Play keys in the left column during the demo,
  keeping the version visible and hiding the silent demo's volume controls.
- Refine briefing spacing and typography, keep the start prompt in the left
  column only, and bracket `[ARROWS]` in briefing/demo hints.
- Qualifying defeats open name entry after three seconds or Enter/Space;
  confirming returns to the demo with the updated leaderboard.
- Show only the application version when Git identity or a valid exported build
  snapshot is unavailable, without an extra suffix.

### Fixed

- Freed fighters become recapturable as soon as the HELP! blinking starts at
  five seconds, without an additional five-second protection period.

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
