# Parked power-shot design

The power weapon was disabled at the user's request, with an explicit request to keep it available for possible restoration. This note and `archive/power-shot.gd.txt` preserve the latest accepted design. The archived code is plain text and is not loaded by Godot.

- Manual left Alt only; ignore right Alt/AltGr, key repeat and paused/game-over input.
- Start each run with 2 charges, maximum 6. Cooldown 0.75 seconds, at most 3 live power projectiles.
- Move straight forward at 22 units/second across the entire course. Remove misses beyond z=-34 without explosion, damage or refund.
- Swept first-impact collision triggers an explosion with radius 2.6 and damage equal to 120 times normal shot power, captured at launch. Do not hurt friendly ships.
- No distance/fuse detonation. No special launch sound. Play the existing break sound on explosion.
- Grant regular rewards for destroyed targets. Kind-3 lightning-bolt targets refill 1–3 charges according to tier, capped at 6, without granting ships or score.
- Seeded ammo targets appear at least every third wave, replacing a threat slot while preserving the small-ship recovery guarantee. Reset the ammo-spacing state with the run seed.
- Show current charges/readiness in the left live-state panel and the Alt instruction/bolt legend on the right.
- Reset clears charges/cooldown/pending input/projectiles. Pause clears queued input and stops both weapons.

The original bolt artwork remains at `game/assets/icons/charge.svg`. The old state names were `power_shots`, `power_ammo`, `power_clock`, `power_requested`; helper names and area-damage logic are preserved in the code snapshot, and the old integration checks are in `archive/power-shot-checks.gd.txt`. Restore fixed-step updates and the target refill branch alongside those functions. Under the new free-flight controls, launch from current `player_z` instead of the archived fixed `PLAYER_Z`; use the target's `corner_cut` in swept collisions. Reintroduce tests for correct Alt location, cooldown/repeats, charge refill/cap/exhaustion, distant impact, harmless misses, friendly immunity, pause and full restart cleanup.
