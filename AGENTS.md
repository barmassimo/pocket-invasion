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
- Fleet-reward enemies use a matching curved spaceship with a round precious-gem emblem in a circular setting in place of the alien pilot; keep reward types visually distinct. Scale the entire Fleet design proportionally across size tiers, including hull, cockpit and emblem. Keep the inner medallion free of the three small decorative dots; retain its simple concentric rings and central disk. Do not use diamond/lozenge silhouettes, pointed sparkles or angular facets: the treasure symbol must follow the game's rounded contour language.
- The existing simple 3D scene may remain as a technical implementation with a fixed elevated camera and gameplay restricted to a small number of movement axes; it must preserve the flat LCD appearance.
- Simple unshaded geometry or flat sprites and readable labels are sufficient. External models, textures and audio are optional improvements, not prerequisites.
- Enemy spaceship designs should evoke 1950s–1960s alien science fiction while keeping compact, filled silhouettes compatible with collision detection. Use the approved simple rounded B-Curved bodies for score and fleet rewards. Do not use trapezoids, perspective cues or shapes suggesting 3D volume. Keep hull and cockpit contour language consistent: an angular hull uses an angular cockpit frame; a curved hull uses a curved cockpit frame. Do not combine sharp-cornered hulls with circular or oval cockpit outlines. Keep the pilot's antennae inside the hull silhouette; avoid thin external protrusions and large empty gaps. Keep visible hulls and collision footprints closely aligned.
- Prioritize responsive controls, readable encounters and satisfying feedback over visual complexity.
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
- Provide a PowerShell bootstrap script with fixed download URLs/version and verified SHA-256 hashes from official sources. Check downloads before extracting or executing them. Fail clearly on mismatches.
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
- `docs/`: additional documentation only when needed.

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
