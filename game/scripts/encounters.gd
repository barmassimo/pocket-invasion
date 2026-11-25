class_name CourseEncounters
extends RefCounted

const Rules = preload("res://scripts/invasion_rules.gd")
var rng := RandomNumberGenerator.new()
var run_seed: int = 0
var waves_since_recovery: int = Rules.RECOVERY_MAX_SKIPPED_WAVES
var captive_ships_planned: int = 0

func reset(seed_override: int = -1) -> void:
	if seed_override < 0:
		rng.randomize()
		run_seed = rng.randi()
	else:
		run_seed = seed_override
	rng.seed = run_seed
	waves_since_recovery = Rules.RECOVERY_MAX_SKIPPED_WAVES
	captive_ships_planned = 0

func next_interval(elapsed: float = 0.0) -> float:
	return maxf(0.65, rng.randf_range(2.3, 3.3) / Rules.encounter_pressure(elapsed))

func plan(elapsed: float, wave: int, fleet_size: int = Rules.START_SOLDIERS) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var lanes: Array[float] = [-3.4, 0.0, 3.4]
	for i: int in range(lanes.size() - 1, 0, -1):
		var pick: int = rng.randi_range(0, i)
		var temporary: float = lanes[i]
		lanes[i] = lanes[pick]
		lanes[pick] = temporary
	var recovery_allowed: bool = fleet_size < Rules.RECOVERY_FLEET_THRESHOLD
	var recovery: bool = false
	if recovery_allowed:
		recovery = waves_since_recovery >= Rules.RECOVERY_MAX_SKIPPED_WAVES or rng.randf() < Rules.RECOVERY_CHANCE
		waves_since_recovery = 0 if recovery else waves_since_recovery + 1
	else:
		waves_since_recovery = Rules.RECOVERY_MAX_SKIPPED_WAVES
	var count: int = rng.randi_range(1, 2)
	if wave == 0:
		count = 2
	if elapsed > 25.0 and rng.randf() < minf(0.8, 0.3 + elapsed / 600.0):
		count = 3
	for i: int in range(count):
		var kind: int = 0 if i == 0 else rng.randi_range(1, 2)
		var size_roll: float = rng.randf()
		var tier: int = 0 if size_roll < 0.25 else (2 if size_roll > 0.75 else 1)
		if elapsed >= 180.0 and rng.randf() < minf(0.55, (elapsed - 180.0) / 600.0):
			tier = 3
		if elapsed >= 300.0 and rng.randf() < minf(0.4, (elapsed - 300.0) / 720.0):
			tier = 4
		if i == 0:
			tier = 0 if recovery else maxi(1, tier)
		var x: float = rng.randf_range(-1.2, 1.2) if wave == 0 else lanes[i] + rng.randf_range(-0.2, 0.2)
		var hp: int = Rules.target_health(kind, elapsed, rng.randf_range(0.85, 1.15), tier)
		if kind == 0 and tier == 0:
			hp = Rules.RECOVERY_HEALTH_OPTIONS[rng.randi_range(0, Rules.RECOVERY_HEALTH_OPTIONS.size() - 1)]
		if kind == 0:
			if recovery_allowed and captive_ships_planned < Rules.OPENING_CAPTIVE_SHIPS:
				hp = Rules.RECOVERY_HEALTH
			captive_ships_planned += 1
		result.append({"x": x, "z": -24.0 - float(i) * rng.randf_range(2.0, 3.5), "kind": kind, "tier": tier, "hp": hp, "reward": Rules.target_reward(kind, tier, rng.randi_range(4, 7))})
	for item: Dictionary in result:
		item["drift"] = rng.randf_range(TargetMotion.DRIFT_MIN, TargetMotion.DRIFT_MAX) * (-1.0 if rng.randf() < 0.5 else 1.0)
	ease_opening(result, elapsed)
	# A regular extra reward replaces a score slot only when the wave is full.
	# Keep the containment ship and at least one score alien.
	if wave % Rules.BOOST_WAVE_INTERVAL == Rules.BOOST_FIRST_WAVE:
		var egg: Dictionary = {"x": lanes[2], "z": -31.0, "kind": Rules.BOOST_KIND,
			"tier": 0, "hp": Rules.target_health(Rules.BOOST_KIND, elapsed, 1.0, 0),
			"reward": 1, "drift": -float(result[0].drift)}
		if result.size() == 3:
			result[2] = egg
		else:
			result.append(egg)
	return result

func ease_opening(result: Array[Dictionary], elapsed: float) -> void:
	var survival: float = elapsed - Rules.START_DIFFICULTY_SECONDS
	if survival < 0.0 or survival >= Rules.OPENING_SCORE_SECONDS:
		return
	# Post-process without drawing random numbers: supplies and future rolls stay intact.
	var has_alien: bool = false
	for item: Dictionary in result:
		if item.kind == 0:
			continue
		has_alien = true
		item["reward"] = int(item.reward) >> int(item.tier)
		item["tier"] = 0
		item["hp"] = Rules.OPENING_SCORE_HEALTH[item.kind]
	if not has_alien:
		# A supply-only wave still offers a separate, affordable score target.
		var supply: Dictionary = result[0]
		result.append({"x": -3.4 if supply.x >= 0.0 else 3.4, "z": -27.0,
			"kind": 1, "tier": 0, "hp": Rules.OPENING_SCORE_HEALTH[1],
			"reward": Rules.target_reward(1, 0), "drift": -float(supply.drift)})
