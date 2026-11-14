# Development guide

## Project intent

Build Pocket Invasion, a small, local Windows arcade game inspired by the formation-shooter gameplay shown in misleading video advertisements. Implement the advertised gameplay as a playable game. The initial goal is a satisfying, simple prototype, not a large production.

The intended gameplay is:

- A player-controlled formation of soldiers stays near the bottom of the screen and moves left and right.
- Enemies, obstacles and numbered portals/targets approach across a scrolling playfield.
- Soldiers fire forward automatically. The player aims primarily by moving the formation.
- Targets have visible hit points. Hits reduce them, and destroying a target grants its indicated reward, such as additional soldiers or score.
- Surviving threats that reach the formation remove the soldiers they actually touch. A missed target must not arbitrarily wipe out the entire formation.
- The formation expands or contracts as soldiers are gained or lost, and the run ends when no soldiers remain.
- Display the soldier count and score clearly, and provide an immediate restart.

Exact target rewards, damage values, formation layout and difficulty progression are implementation choices to tune through playtesting. Keep target health and reward visually distinguishable. Do not add multiplication gates or other mechanics merely because similar advertisements feature them.

## Scope and presentation

- Start with one short playable course or a bounded endless mode, a few target types, and clear win/lose or survival feedback.
- Keep the visual style flat and inspired by monochrome LCD / original Game Boy graphics: a limited olive-green palette, solid colors, crisp silhouettes and simple readable details. Do not use volumetric 3D styling, gradients, glossy materials, reflections, realistic lighting or complex shading, including in concept proposals.
- LCD / Game Boy inspiration does not require coarse pixel art: prefer clean contours with minimal stair-stepping and simple flat details over large visible pixel blocks.
- Score-reward enemies use the approved B-Curved design: a rounded hull and cockpit with a stylized alien pilot, dark eyes, a neutral non-smiling mouth, two antennae and a minimal torso at the controls. Make the pilot slightly larger than in the initial B-Curved concept. Across enemy size tiers, keep each pilot at the same absolute size while enlarging the spaceship and cockpit window. Larger ships may carry two or three aliens side by side within the enlarged window. Use the same flat LCD palette and clean, minimally pixelated contours.
- Fleet-reward enemies use the approved A3 captive-fighter design inside the matching curved spaceship: a large intact terrestrial fighter nearly reaches the inner circular window, held by two prominent rounded C-shaped olive clamps attached to its sides. Scale the entire Fleet design proportionally across size tiers, including hull, cockpit, captive fighter and clamps. Preserve the original egg/medallion layers in `docs/art-concepts/egg-original/` for possible reuse. Use flat solid LCD colors and clean contours.
- The existing simple 3D scene may remain as a technical implementation with a fixed elevated camera and gameplay restricted to a small number of movement axes; it must preserve the flat LCD appearance.
- Simple unshaded geometry or flat sprites and readable labels are sufficient. External models, textures and audio are optional improvements, not prerequisites.
- Enemy spaceship designs should evoke 1950s–1960s alien science fiction while keeping compact, filled silhouettes compatible with collision detection. Use the approved simple rounded B-Curved bodies for score and fleet rewards. Do not use trapezoids, perspective cues or shapes suggesting 3D volume. Keep hull and cockpit contour language consistent: an angular hull uses an angular cockpit frame; a curved hull uses a curved cockpit frame. Do not combine sharp-cornered hulls with circular or oval cockpit outlines. Keep the pilot's antennae inside the hull silhouette; avoid thin external protrusions and large empty gaps. Keep visible hulls and collision footprints closely aligned.
- Prioritize responsive controls, readable encounters and satisfying feedback over visual complexity.
- Maintain an application icon and use it for the game window and distributions;
  create one if it is missing.
- No advertising, monetization, accounts, online services, cloud features or analytics.
- Redistribution, installers, signing, stores and release export templates are outside the initial scope. Running from the local Godot editor or command line is sufficient.
- Do not begin building the game merely because this guide exists; follow the user's request in the current chat.

## Stack and self-contained environment

- Use the standard precompiled Godot engine for Windows x64 and typed GDScript. Do not use the .NET edition or require C#.
- No Visual Studio, MSVC Build Tools, separately installed Windows SDK, global runtimes or native compilation requirements.
- Use a pinned stable Godot version selected and verified when implementation starts. Do not assume a version mentioned in an earlier discussion is current or suitable.
- Keep Godot under `tools/godot/` inside this project. Create an empty `_sc_` file alongside the editor executable before its first launch to enable self-contained mode.
- Keep editor data, settings and caches in the local `editor_data/` directory. During development, retain default project user-data behavior compatible with self-contained mode; check where saves and logs actually go.
- Do not modify the global PATH, registry associations or system installation directories. Scripts must locate tools relative to their own project root.
- Provide a PowerShell bootstrap script with fixed download URLs and versions.
- Verify downloaded files against expected SHA-256 hashes from official sources
  before extracting, executing or using them. Record the source and expected hash;
  fail clearly on mismatches.
- Bootstrap must reuse a valid existing environment and must not silently upgrade or replace it. Once prepared, normal development and play must work offline.
- Do not download export templates until exporting is requested. Do not add a package manager or a second runtime without a concrete need.
- Keep generated tools and caches out of Git; preserve the scripts and version/hash information needed to recreate them.

## Suggested layout

- `AGENTS.md`: repository-wide development instructions.
- `README.md`: brief introduction, requirements, setup and play commands.
- `game/project.godot`: Godot project entry point.
- `game/scenes/`, `game/scripts/`, `game/assets/`: game content.
- `tools/godot/`: pinned portable engine and its editor data.
- `scripts/`: PowerShell bootstrap, editor launch, game launch and focused validation.
- `artifacts/`: generated reports, captures and other verification outputs.
- `docs/`: architecture, user manual, development guide and release history.

Keep generated Godot project imports under `game/.godot/` and ignore them in Git. Do not copy the engine into the game's resource directory. Keep downloaded archives under `artifacts/` if retained.

## Implementation conventions

- Keep code, identifiers, comments, UI text and documentation in English. Use `.` for decimals.
- Prefer small reusable scenes and focused scripts. Keep gameplay state and rules separate from presentation where useful, without building a generic game framework.
- Run movement, damage and gameplay timing in `_physics_process()` or an equivalent fixed-step simulation. Use rendering callbacks for presentation as appropriate.
- Use simple controlled motion and collision queries/areas for soldiers and projectiles. Do not make every soldier an autonomous rigid-body simulation.
- Ensure fast projectiles cannot pass through targets between simulation steps; use swept tests or ray/shape queries when needed.
- Remove or recycle off-screen entities and bound active enemy/projectile counts. Introduce pooling or MultiMesh only when measurements justify the complexity.
- Keep encounter spawning and tuning values centralized and easy to adjust. Allow reproducible random seeds for debugging when randomness is introduced.
- Define keyboard left/right controls first. Mouse movement may be added if useful; document the implemented controls.
- Avoid mandatory third-party plugins and assets. If dependencies are introduced, pin them and record their source and license.

## Versioning and releases

- These rules define future versioning work. Adding them to this guide does not
  authorize implementing version/build metadata, changing application versions,
  creating tags, rebuilding distributions or publishing anything. Wait for the
  user's request to implement the versioning mechanism or create a release.
- Use `MAJOR.MINOR.PATCH` for the application version, adding a suffix only when
  explicitly requested. Never change the version automatically during development,
  commits or exports. Keep pending user-visible release notes under `Unreleased`
  in `docs/CHANGELOG.md` once release tracking is implemented.
- An unqualified request such as "make a release" targets the main branch and
  uses the latest reachable stable `vMAJOR.MINOR.PATCH` tag as the comparison
  baseline, ignoring suffixed tags. If the user requests a suffix such as `-rc`,
  use the latest reachable tag that is either stable or has that exact suffix;
  ignore other suffixes. Do not invent suffixes or suffix counters.
- Before choosing the release version, inspect existing tags, the version in HEAD
  and the working tree, and all commits and the cumulative diff since the applicable
  baseline. Choose the increment from those combined changes, not from the current
  version string or the latest commit alone. If no applicable baseline exists,
  agree on the initial version with the user; do not invent release history.
- Apply the compatibility criteria below before choosing MINOR or PATCH. Increment
  MINOR for compatible new functionality and reset PATCH to 0. Increment PATCH for
  compatible fixes without new functionality. Features together with fixes require
  MINOR. An explicitly requested release containing only documentation, tests or
  development tooling changes uses PATCH.
- For this standalone game, assess MAJOR compatibility from the player's
  perspective, rather than only from a programming API. Incompatible changes to
  existing default behavior, controls or gameplay rules, loss of compatibility
  with existing saved data/settings if introduced, removal of supported use, or
  new mandatory platform, hardware, browser or external-tool requirements warrant
  a MAJOR proposal. Requiring network access to install a new mandatory tool is
  itself a new requirement, even if installation is automatic.
- Before implementing a change that meets those MAJOR criteria, explain the
  specific incompatibility and its effect on existing players, propose MAJOR,
  and obtain the user's explicit agreement. Approval of a general feature or an
  unqualified release request does not by itself approve an unexplained
  incompatibility. When approved for release, reset MINOR and PATCH to 0.
- Optional capabilities remain compatible only when existing use retains the same
  defaults and requirements. A new setting preserves compatibility only if it is
  optional and leaving it unset preserves existing default behavior. Internal
  refactoring alone does not warrant MAJOR when player behavior and requirements
  remain compatible. Correcting a defect to restore documented/intended behavior
  can be PATCH; do not disguise deliberate changes to defaults as fixes.
- A requested release includes updating the application version and CHANGELOG,
  running appropriate checks, committing the intended release changes and metadata,
  and creating the matching `vMAJOR.MINOR.PATCH` tag, with exactly the requested
  suffix, on that release commit. Resolve which working-tree changes belong to
  the release before committing; do not include unrelated work. Never overwrite
  existing tags or rewrite existing commits to create a release.
- A release request alone does not authorize pushing, creating a GitHub Release,
  uploading binaries, deploying Web content, installing tools or signing packages.
  Exporting a local build alone does not create a release or increment the version.
- Use one authoritative application version, from which Godot's application
  version, visible version labels and export metadata derive. Keep Windows numeric
  metadata compatible with its required format. Godot engine and any future save
  format versions are independent of the application version. Avoid duplicating
  the current version in introductory/design documentation; preserve clearly
  identified historical records.

## Build identity in Web and Windows distributions

- When this mechanism is requested, both Web and Windows builds must include the
  application version, source Git commit and local modification state captured
  at build time. Show the identity at the bottom left of the HUD.
  Use the same identity in bundled build metadata and startup logs where available.
- When a repository remote is available, ask the user before making the displayed
  version clickable or including the repository URL in distributions, because the
  repository may be private. The presence of a remote alone is not authorization.
  If approved, link to the repository root, not a specific commit, tag or release.
  Capture the verified repository URL at build time; do not invent a URL when no
  remote is available. This rule does not itself authorize implementing the link.
- Display a compact identity such as `v1.2.3-abcdef0` or
  `v1.2.3-abcdef0-modified`, without spaces or parentheses, and retain the full
  commit hash in build metadata.
  Mark `modified` when tracked files differ from HEAD, including staged changes,
  or non-ignored untracked files exist. Ignored tools, caches and generated exports
  must not make a build appear modified. Capture identity before generating build
  metadata so the generated metadata does not itself cause a dirty state.
- `modified` means local changes exist beyond the linked commit; the link does
  not identify their exact contents. It is build provenance, not a version suffix,
  and must not change the application version or numeric Windows version fields.
  Build a release only after committing and tagging, with a clean working tree,
  so the release distribution does not display `modified`.
- Bundle the captured identity with each distribution. Running an exported build
  must not require Git, a checkout, network access or a GitHub API request, and must
  not inspect an unrelated repository on the player's machine. The GitHub link is
  optional to open; the game remains local and works offline.
- If Git or repository metadata is unavailable, keep the application usable and
  show only the application version (for example, `v1.0.0`), without a hash or
  extra suffix; do not
  invent a commit, repository URL or clean state. Verify both exports retain their
  captured identity when run outside the checkout before claiming this is supported.
  Always regenerate the snapshot at export time. If no repository identity can be
  verified then, replace any previous snapshot with unavailable identity; never
  reuse a stale hash. A build made with verified identity retains its hash when
  subsequently run outside the repository.

## Documentation maintenance

- Keep `README.md` and repository-wide `AGENTS.md` at the root, and project
  documentation under `docs/`.
- Maintain `docs/ARCHITECTURE.md` for components, data flow, timing, design decisions
  and material technical constraints. Read it when understanding architecture,
  resuming work or planning changes across components; reading it is not required
  for every small, self-contained edit.
- Maintain `docs/MANUAL.md` for interactions, controls, shortcuts, defaults, setup
  and user-visible limitations. Describe current behavior, not its history.
- Maintain `docs/DEVELOPMENT.md` for environment, build and verification commands,
  fixture requirements, report locations and known validation limitations.
- Keep README concise: introduction, requirements, setup/play commands and links
  to detailed documentation. Update it when presentation, scope, requirements or
  initial setup changes.
- Update affected documentation as part of the same task without waiting for a
  separate request. This is an agent responsibility, not a background synchronizer.
  Update only documents whose content actually changes.
- Organize architecture documentation by topic and replace outdated descriptions
  rather than appending dated implementation reports or routine fix narratives.
- Keep pending release notes under `Unreleased` in `docs/CHANGELOG.md` without
  changing the application version. On a requested release, consolidate relevant
  notes into a concise version entry, grouped by Added/Changed/Fixed as applicable.
  Record only verifiable history; do not infer missing versions or label untagged
  work as a published release.
- Keep detailed verification evidence in `artifacts/`; do not transcribe every
  pass count, capture or intermediate attempt into permanent documentation.
  Preserve material limitations that affect interpreting results.
- Review relative links when moving or renaming documents. Keep commands portable
  across repository locations and do not publish personal absolute paths or present
  ignored local fixtures as bundled prerequisites.
- Documentation-only changes need link and command review, not game reruns.

## Launch and validation

- Provide project-relative PowerShell commands to prepare the environment, open the editor and run the game without global configuration.
- Verify that the project imports and starts with the pinned local engine and produces no script/parser errors.
- Headless checks are useful for startup and isolated rules, but do not replace visual inspection and actual playtesting.
- For gameplay changes, check movement limits, shooting, target health/rewards, contact losses, formation updates, game over and restart. Verify that restarting clears all previous run state.
- Inspect the real window for readable labels, correct camera framing and usable controls. Listen when introducing or changing audio.
- Measure performance in the intended busiest encounter before making frame-rate or capacity claims. Record the conditions and limitations of any measurement.
- Warn the user before implementing requested changes that are expected to substantially affect performance. Distinguish estimates from measured results.
- Add focused automated checks for meaningful rules when warranted; avoid tests that only mirror implementation details.
- Store detailed logs and captures under `artifacts/`. Report only checks actually performed and clearly identify checks that could not be performed.
- Update setup instructions, controls and documented limitations as part of the same change that affects them. Do not change an application version or create a release unless requested.
