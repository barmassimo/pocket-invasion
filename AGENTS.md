# Development guide

## Documentation and changes

- Write for people with limited reading time. Keep only project-specific facts,
  decisions and constraints. Omit generic explanations and put each detail in
  the document where readers will look for it.
- Update affected documentation with the work. Keep setup and links in
  [README](README.md), player behavior in [MANUAL](docs/MANUAL.md), technical
  decisions in [ARCHITECTURE](docs/ARCHITECTURE.md), and commands and verification
  in [DEVELOPMENT](docs/DEVELOPMENT.md). Keep release notes under
  `Unreleased` in [CHANGELOG](docs/CHANGELOG.md), and evidence under `artifacts/`.
  For documentation-only changes, review links and commands.
- Use English for source, identifiers, comments, UI text, documentation and
  filenames. Use a decimal point.
- Flag significant expected impacts on performance, memory, disk use or
  output quality before implementing a change. Distinguish estimates from
  measurements.

## Game and art

- Pocket Invasion is a small offline formation shooter. Keep keyboard movement,
  automatic forward fire, visible target HP and separate reward labels. Contact
  removes only the fighters it actually hits. The fleet grows or shrinks with
  gains and losses. Keep the ship count, score, defeat and restart clear.
  Keep the prototype focused on one course or survival mode. Leave out
  multiplication gates, ads, purchases, accounts, online services and analytics.
  Begin implementation only when the current request calls for it.
- Use flat olive LCD colors, crisp contours and compact hulls that match collision
  footprints. The fixed elevated 3D camera is an implementation detail. Use the
  1950s–1960s sci-fi style in concepts and game art, with solid fills and no
  gradients, gloss, trapezoidal hulls, perspective cues or shading for volume.
  Match hull and cockpit contours.
- Score ships use B-Curved hulls and cockpits. Each alien has dark eyes, a neutral
  mouth, two antennae inside the hull and a minimal torso at the controls.
  Preserve the approved larger pilot size across tiers. Larger windows fit two
  or three pilots of that same size.
- Fleet ships use the matching curved A3 hull and a largely window-filling intact
  terrestrial fighter held by two rounded olive C-clamps. Scale the whole design
  proportionally across tiers.
- Keep the rare, armed egg carriers at 30 HP or more, marked `FIRE x2`. Preserve
  their source layers in `docs/art-concepts/egg-original/` and copies in runtime
  assets. Their `POW` modules have an alien-energy aura. Collection doubles firing
  frequency and shot-sound cadence for ten seconds, with normal per-shot damage,
  wider hollow projectiles and no aura on the fleet. See the manual for pickup rules.
- Maintain the original application icon for the game window and distributions.
  Bundle fonts and prefer assets that work offline without system dependencies.
  Flag any proposed exception to bundled fonts before adopting it. Pin and
  document the source and license of any new dependency.

## Environment and validation

- Use the pinned standard precompiled Godot x64 editor and typed GDScript.
  Keep the project reproducible and self-contained with the existing PowerShell
  scripts. Windows x64 is the primary host. Linux x64 uses PowerShell 7 and a
  separate checkout. Both can export Windows x64 and Web.
- Keep Godot under `tools/godot/`, create `_sc_` beside the editor before the
  first launch and keep editor data there. Leave default game user data behavior
  in place and verify where it is written. Ignore tools, imports and artifacts.
- Keep tool paths project-relative. Bootstrap must reuse a verified environment
  and reject mismatches without replacing or upgrading it. Normal play and
  development work offline after setup. Fetch export templates only for exports.
- Verify every downloaded executable, installer or archive containing either
  against a trusted published checksum before extracting, running or using it.
  For Godot, pin official download URLs and SHA-256 values in the scripts.
- Notify the user before any system-level installation or update, including a
  Visual C++ Redistributable if a future dependency requires it. The current
  project needs no such extra runtime, .NET edition, compiler or SDK. Leave global
  PATH, registry associations and system installation directories alone.
- Run gameplay on fixed steps. Keep tuning centralized and seeded encounters
  reproducible. Use swept projectile/contact tests, bound active entities and
  remove off-screen objects. Prefer focused scripts and simple controlled motion.
  Introduce pooling or additional batching only when measurements justify it.
- Verify imports and startup with the pinned editor. For gameplay changes, check
  movement, shooting, HP and rewards, local contact losses, formation updates,
  defeat and restart with a clean run state. Inspect the real window and play
  affected encounters. Listen to audio changes. Measure the busiest intended
  encounter before making performance claims. Record the checks actually run and
  any limitations.

## Releases and build identity

- The authoritative version is `application/config/version` in
  `game/project.godot`. Use `MAJOR.MINOR.PATCH` with a suffix only when requested.
  Keep Windows numeric metadata compatible. Engine and save versions are
  independent. An export alone leaves the application version,
  commits and tags unchanged.
- An unqualified release targets main. Inspect tags, the version in HEAD and the
  working tree, and all commits and the cumulative diff since the applicable
  reachable tag. For stable releases use the latest stable tag. For a requested
  suffix use the latest stable tag or tag with that exact suffix, whichever is
  later. If there is no baseline, agree on the initial version with the user.
- Use MINOR for compatible features (including releases that also fix bugs).
  Use PATCH for compatible fixes and requested docs/test/tooling-only releases.
  Small balance, layout and presentation adjustments preserve compatibility when
  core gameplay, controls and requirements stay intact. Use optional settings
  to preserve existing supported use.
- Use MAJOR for material
  player-facing incompatibility, such as loss of existing saves or supported use,
  substantial core rule/control changes or new mandatory platform dependencies.
  Explain the impact and obtain explicit approval before making such a change.
  Reset lower version components on a MAJOR or MINOR increment.
- A requested release includes version and changelog updates, relevant checks,
  a commit with the intended changes, and the exact matching tag on that commit.
  Fail on any tag/version or tag/commit mismatch. Require clean source for
  release builds. Preserve existing tags and history. Local exports, pushes,
  GitHub publication, deployment, signing and tool installation require separate
  requests. The [GitHub workflow](docs/DEVELOPMENT.md#github-actions-releases)
  builds on tag push or manual dispatch and currently accepts stable tags only.
- Windows and Web capture the version, full Git hash and dirty state before
  generating metadata. Display a short hash in the lower-left identity label,
  for example `v1.2.3-abcdef0` or `v1.2.3-test-abcdef0-modified` for a local
  build with a suffixed version. Mark staged, unstaged and non-ignored untracked
  changes as `modified`. Release builds use clean tagged commits and omit it.
- Regenerate the snapshot on each export. With no verified Git identity, show
  only the application version and replace any stale snapshot. Use the same
  identity in bundled metadata and startup logs where available. Verify exports
  keep that identity outside the checkout and run offline without Git.
- Embed or link only a verified repository root URL that the user has approved
  for distribution. A new remote requires separate approval.
