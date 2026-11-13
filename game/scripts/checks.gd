extends SceneTree

const Main = preload("res://scripts/main.gd")
const Rules = preload("res://scripts/rules.gd")
const Encounters = preload("res://scripts/encounters.gd")
var failures: int = 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func send_key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func course_plan(seed_value: int) -> Array:
	var generator := Encounters.new()
	generator.reset(seed_value)
	var result: Array = []
	for wave_index: int in range(20):
		var difficulty: float = Rules.difficulty_time(float(wave_index) * 2.8)
		result.append(generator.plan(difficulty, wave_index))
		result.append(generator.next_interval(difficulty))
	return result

func parallel_damage(game: Node3D, count: int) -> int:
	game.reset_run(true, 123)
	game.spawn_clock = 999.0
	for i: int in range(count - Rules.START_SOLDIERS):
		game.add_soldier()
	game.arrange()
	var target: CourseTarget = game.spawn_target(0, -12, 1, 1000, 50)
	target.half.x = 0.30
	send_key(KEY_CTRL, true)
	for step: int in range(120):
		game._physics_process(1.0 / 60.0)
	send_key(KEY_CTRL, false)
	return 1000 - target.hp

func run() -> void:
	var game := Main.new()
	root.add_child(game)
	# Accelerated simulation must not queue thousands of real-time audio voices.
	game.sound.muted = true
	game.set_physics_process(false)
	check(game.lcd.demo.visible, "Silent demonstration appears on the ready screen")
	game.lcd.demo.set_process(false)
	game.lcd.demo._process(28.0)
	check(is_equal_approx(game.lcd.demo.clock, 1.0) and game.squad.size() == Rules.START_SOLDIERS and game.targets.is_empty() and game.bullets.is_empty() and game.score == 0 and game.elapsed == 0.0, "Idle demonstration loops without changing gameplay state")
	game.reset_run(true, 123)
	check(not game.lcd.demo.visible and not game.lcd.demo.is_processing() and game.lcd.demo.clock == 0.0, "Starting a run hides and resets the demonstration")
	var demo_pause := InputEventKey.new()
	demo_pause.keycode = KEY_P
	demo_pause.pressed = true
	game._unhandled_key_input(demo_pause)
	check(not game.running and not game.lcd.demo.visible, "Pause never shows the demonstration")
	game._unhandled_key_input(demo_pause)
	check(game.running and not game.lcd.demo.visible, "Resuming keeps the demonstration hidden")
	game.finish()
	check(not game.lcd.demo.visible and game.message.visible and not game.running, "Defeat holds the final course with a restart prompt")
	var frozen_target: CourseTarget = game.spawn_target(2, -10, 1, 20, 50)
	var frozen_position: Vector3 = frozen_target.position
	var frozen_elapsed: float = game.elapsed
	game._physics_process(9.99)
	check(not game.lcd.demo.visible and frozen_target.position == frozen_position and game.elapsed == frozen_elapsed, "Final course stays frozen before ten seconds")
	game._physics_process(0.02)
	check(game.lcd.demo.visible and game.lcd.demo.is_processing() and not game.message.visible and game.lcd.demo.clock == 0.0, "Demo starts from the beginning after the ten-second hold")
	game.reset_run(true, 123)
	game.finish()
	game._physics_process(2.0)
	var restart := InputEventKey.new()
	restart.keycode = KEY_ENTER
	restart.pressed = true
	game._unhandled_key_input(restart)
	check(game.running and game.defeat_hold_remaining == 0.0 and game.targets.is_empty() and game.bullets.is_empty() and game.score == 0 and game.elapsed == 0.0, "Immediate restart cancels the hold and clears the previous run")
	game._unhandled_key_input(demo_pause)
	game._physics_process(11.0)
	check(not game.lcd.demo.visible and game.message.text == "PAUSED", "Cancelled defeat timeout cannot show the demo over a paused new run")
	game.reset_run(true, 123)
	check(Rules.shot_hits(Vector3(-2, 0, 0), Vector3(2, 0, -8), Vector3(0, 0, -4), Vector2(0.2, 0.2)), "Diagonal fast shots hit narrow targets without tunneling")
	check(not Rules.shot_hits(Vector3(-2, 0, 0), Vector3(2, 0, -8), Vector3(1.8, 0, -3), Vector2(0.2, 0.2)), "Diagonal near-misses do not damage targets")
	check(course_plan(123) == course_plan(123), "Same seed reproduces complete encounter sequence")
	check(course_plan(123) != course_plan(456), "Different seeds produce different encounter sequences")
	var generation_valid: bool = true
	for seed_value: int in [42, 123, 456, 789, 2026]:
		var generator := Encounters.new()
		generator.reset(seed_value)
		for wave_index: int in range(20):
			var plan: Array[Dictionary] = generator.plan(Rules.difficulty_time(float(wave_index) * 2.8), wave_index)
			var reward_count: int = 0
			for item: Dictionary in plan:
				generation_valid = generation_valid and absf(item.x) < 4.0 and item.hp > 0
				if item.kind == 0:
					reward_count += 1
			generation_valid = generation_valid and reward_count >= 1 and plan.size() <= 3
	check(generation_valid, "Random encounters stay inside road and preserve reinforcement opportunities")
	game.reset_run(true, 123)
	game.spawn_wave()
	check(game.elapsed == 0.0 and Rules.difficulty_time(game.elapsed) == 120.0 and game.targets.size() >= 2, "Run starts at two-minute difficulty with a fresh survival timer and immediate threats")
	var recoveries_present: bool = true
	for seed_value: int in [42, 123, 456, 789, 2026]:
		for survival: float in [0.0, 300.0, 1800.0]:
			var generator := Encounters.new()
			generator.reset(seed_value)
			var missed: int = 0
			for wave_index: int in range(30):
				var found: bool = false
				for item: Dictionary in generator.plan(Rules.difficulty_time(survival + wave_index * 2.0), wave_index):
					if item.kind == 0 and item.tier == 0:
						found = item.hp == 5 and item.reward == 1
				missed = 0 if found else missed + 1
				recoveries_present = recoveries_present and missed <= 1
	check(recoveries_present, "Easy +1 crates appear at least every two waves, including at high difficulty")
	var recovered_alone: bool = true
	for survival: float in [0.0, 300.0, 1800.0]:
		game.reset_run(true, 123)
		game.elapsed = survival
		game.spawn_clock = 999.0
		while game.squad.size() > 1:
			var removed: Node3D = game.squad.pop_back()
			removed.free()
		game.arrange()
		game.spawn_target(0, -24, 0, Rules.target_health(0, Rules.difficulty_time(survival), 1.0, 0), 1, 0)
		send_key(KEY_CTRL, true)
		for step: int in range(180):
			game._physics_process(1.0 / 60.0)
		send_key(KEY_CTRL, false)
		recovered_alone = recovered_alone and game.squad.size() == 2 and game.targets.is_empty() and game.running
	check(recovered_alone, "One soldier can earn a recovery reinforcement at start, five and thirty minutes")
	var rewards_grow: bool = true
	for kind: int in range(3):
		for tier: int in range(4):
			rewards_grow = rewards_grow and Rules.target_reward(kind, tier, 7) < Rules.target_reward(kind, tier + 1, 4)
	check(rewards_grow, "Larger size always grants a larger reward, even across random score rolls")
	var elite_seen: bool = false
	var command_seen: bool = false
	var elite_generator := Encounters.new()
	elite_generator.reset(123)
	for wave_index: int in range(100):
		for item: Dictionary in elite_generator.plan(420.0 + wave_index * 4.0, wave_index):
			elite_seen = elite_seen or item.tier == 3
			command_seen = command_seen or item.tier == 4
	check(elite_seen and command_seen and Rules.target_reward(0, 3) == 8 and Rules.target_reward(0, 4) == 16, "Late waves include heavy and command objects with +8/+16 supply rewards")
	check(Rules.course_speed(480) - Rules.course_speed(420) > Rules.course_speed(360) - Rules.course_speed(300) and Rules.target_health(2, 600, 1.0, 4) > Rules.target_health(2, 360, 1.0, 4) * 2, "Late scrolling accelerates and command-target health outgrows the old plateau")
	game.reset_run(true, 123)
	var limits_valid: bool = true
	for time: float in [0.0, 89.99, 90.0, 180.0, 270.0, 1800.0]:
		game.elapsed = time
		for i: int in range(120):
			game.add_soldier()
		limits_valid = limits_valid and game.squad.size() == 48
	check(limits_valid, "Fleet capacity stays at 48 at start, former unlock times and thirty minutes")
	game.reset_run(true, 123)
	check(Rules.MAX_SOLDIERS == 48 and game.squad.size() == Rules.START_SOLDIERS, "Restart clears the full fleet and restores four ships with fixed capacity")
	game.reset_run(true, 123)
	var small: CourseTarget = game.spawn_target(-3, -4, 0, Rules.target_health(0, 20, 1.0, 0), Rules.target_reward(0, 0), 0)
	var large: CourseTarget = game.spawn_target(3, -4, 0, Rules.target_health(0, 20, 1.0, 2), Rules.target_reward(0, 2), 2)
	check(large.half.x > small.half.x and large.hp > small.hp, "Target size changes both visible mesh/collision footprint and HP")
	var pilot_dimensions: Vector2 = Vector2.ZERO
	var crew_valid: bool = true
	var fleet_proportions_valid: bool = true
	for tier: int in range(5):
		var alien: CourseTarget = game.spawn_target(0, -16, 1, 100, 50, tier)
		var cache: CourseTarget = game.spawn_target(3, -16, 0, 100, 2, tier)
		crew_valid = crew_valid and alien.pilots.size() == [1, 1, 2, 2, 3][tier] and alien.emblem == null
		for pilot: MeshInstance3D in alien.pilots:
			var dimensions: Vector2 = (pilot.mesh as PlaneMesh).size
			if pilot_dimensions == Vector2.ZERO:
				pilot_dimensions = dimensions
			crew_valid = crew_valid and dimensions.is_equal_approx(pilot_dimensions)
		fleet_proportions_valid = fleet_proportions_valid and cache.pilots.is_empty() and (cache.emblem.mesh as PlaneMesh).size.is_equal_approx((cache.body.mesh as PlaneMesh).size)
	check(crew_valid, "Score size tiers add up to three pilots while preserving every pilot's absolute dimensions")
	check(fleet_proportions_valid, "Fleet hull and treasure emblem scale in the same proportions at every size tier")
	game.destroy_target(large)
	check(game.squad.size() == Rules.START_SOLDIERS + 4, "Destroying large reinforcement target grants its four-soldier reward")
	game.reset_run(true, 123)
	game.elapsed = 270.0
	for i: int in range(28):
		game.add_soldier()
	game.arrange()
	var command: CourseTarget = game.spawn_target(0, -15, 0, 1, Rules.target_reward(0, 4), 4)
	game.destroy_target(command)
	check(game.squad.size() == 48 and Rules.shot_damage(game.squad.size()) == 1, "Command supply grants sixteen soldiers while shot damage stays at one")
	var damage4: int = parallel_damage(game, 4)
	var damage12: int = parallel_damage(game, 12)
	var damage24: int = parallel_damage(game, 24)
	print("PARALLEL_DAMAGE_2S: squad4=", damage4, " squad12=", damage12, " squad24=", damage24)
	check(damage4 > 0 and damage12 >= damage4 * 2.5 and damage24 >= damage4 * 5.0, "Extra soldiers and faster volleys increase damage with parallel shots")
	game.reset_run(true, 123)
	game.spawn_clock = 999.0
	game.spawn_target(0.6, -12, 1, 1000, 50)
	send_key(KEY_CTRL, true)
	game._physics_process(0.016)
	send_key(KEY_CTRL, false)
	var origins: Array[float] = []
	for bullet: MeshInstance3D in game.bullets:
		origins.append(bullet.position.x)
	game.advance_bullets(0.2)
	var parallel: bool = game.bullets.size() == origins.size()
	for i: int in range(game.bullets.size()):
		parallel = parallel and is_equal_approx(game.bullets[i].position.x, origins[i]) and is_zero_approx(game.bullets[i].rotation.y)
	check(parallel, "Projectiles stay parallel even when a target is offset from the formation")
	game.reset_run(true, 123)
	game.spawn_clock = 999.0
	for i: int in range(20):
		game.add_soldier()
	game.arrange()
	game.spawn_target(0, -24, 2, Rules.target_health(2, Rules.difficulty_time(0), 1.15, 2), 160, 2)
	send_key(KEY_CTRL, true)
	for step: int in range(360):
		game._physics_process(1.0 / 60.0)
	send_key(KEY_CTRL, false)
	check(game.targets.is_empty() and game.score == 160 and game.squad.size() == 24, "Full squad can destroy a large starting-difficulty obstacle with parallel fire")
	game.reset_run()
	game._physics_process(0.1)
	check(game.bullets.size() == Rules.START_SOLDIERS, "Normal fire starts automatically without keyboard input")
	game.spawn_clock = 999.0
	for step: int in range(60):
		game._physics_process(1.0 / 60.0)
	check(game.bullets.size() > Rules.START_SOLDIERS, "Automatic fire continues without holding Ctrl")
	game.reset_run(true, 123)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	game._physics_process(0.1)
	check(game.player_x > 0, "D key moves formation right")
	key = key.duplicate() as InputEventKey
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	key = InputEventKey.new()
	key.physical_keycode = KEY_LEFT
	key.keycode = KEY_LEFT
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	game._physics_process(0.2)
	check(game.player_x < 0, "Left arrow moves formation left")
	key = key.duplicate() as InputEventKey
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	game.reset_run(true, 123)
	game.spawn_clock = 999.0
	var initial_z: float = game.player_z
	send_key(KEY_W, true)
	game._physics_process(0.1)
	send_key(KEY_W, false)
	check(game.player_z < initial_z, "W moves the fleet toward the top")
	var forward_z: float = game.player_z
	send_key(KEY_UP, true)
	game._physics_process(0.1)
	send_key(KEY_UP, false)
	check(game.player_z < forward_z, "Up arrow also moves the fleet forward")
	forward_z = game.player_z
	send_key(KEY_S, true)
	game._physics_process(0.1)
	send_key(KEY_S, false)
	send_key(KEY_DOWN, true)
	game._physics_process(0.1)
	send_key(KEY_DOWN, false)
	check(game.player_z > forward_z, "S and down arrow move the fleet toward the bottom")
	var edges_valid: bool = true
	for count: int in [Rules.START_SOLDIERS, Rules.MAX_SOLDIERS]:
		game.reset_run(true, 123)
		game.elapsed = 270.0
		for i: int in range(count - Rules.START_SOLDIERS):
			game.add_soldier()
		game.player_z = -10000.0
		game.arrange()
		var top_y: float = 10000.0
		for ship: Node3D in game.squad:
			top_y = minf(top_y, game.camera.unproject_position(ship.position + Vector3(0, 0.35, 0)).y)
		game.player_z = 10000.0
		game.arrange()
		var bottom_y: float = 0.0
		for ship: Node3D in game.squad:
			bottom_y = maxf(bottom_y, game.camera.unproject_position(ship.position + Vector3(0, 0.35, 0)).y)
		edges_valid = edges_valid and top_y >= 24 and top_y <= 40 and bottom_y >= 760 and bottom_y <= 776
	check(edges_valid, "Small and full fleets can reach both screen edges without leaving the frame")
	game.reset_run(true, 123)
	game.spawn_clock = 999.0
	var moving_threat: CourseTarget = game.spawn_target(game.squad[0].position.x, game.player_z - 1.0, 1, 999, 50)
	moving_threat.half = Vector2(0.05, 0.05)
	send_key(KEY_W, true)
	game._physics_process(0.2)
	send_key(KEY_W, false)
	check(game.squad.size() == 3, "Moving forward through a threat removes the crossed ship, without a safe player line")
	check(Rules.shot_fraction(Vector3(0.45, 0, 0.45), Vector3(0.45, 0, 0.45), Vector3.ZERO, Vector2(0.5, 0.5)) == INF, "Empty corners of rounded hulls do not register a false hit")
	check(is_equal_approx(Rules.shot_fraction(Vector3(0, 0, 2), Vector3(0, 0, -2), Vector3.ZERO, Vector2(1, 0.5), 0.0), 0.375), "Fast shots enter an ellipse at its visible boundary")
	check(Rules.shot_fraction(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector2.ONE) == 0.0, "Stationary contact inside a rounded hull is detected")
	check(Rules.shot_fraction(Vector3(1.2, 0, 2), Vector3(1.2, 0, -2), Vector3.ZERO, Vector2.ONE) == INF, "A fast near-miss beside the round hull stays a miss")
	game.reset_run()
	game.player_x = 100.0
	game.arrange()
	check(game.squad[-1].position.x < Rules.ROAD_HALF, "Formation stays inside road")
	game.player_x = 0.0
	game.arrange()
	var reward: CourseTarget = game.spawn_target(0, -4, 0, 1, 4)
	game.bullets.append(game.box(Vector3.ONE * 0.1, Vector3(0, 0.5, 0), game.yellow))
	game.advance_bullets(0.3)
	check(game.targets.is_empty() and game.squad.size() == Rules.START_SOLDIERS + 4 and game.score == 25, "Swept shot destroys target and grants reward exactly once")
	check(not is_instance_valid(reward), "Destroyed target removed")
	game.reset_run()
	var tough: CourseTarget = game.spawn_target(0, -4, 1, 2, 50)
	game.bullets.append(game.box(Vector3.ONE * 0.1, Vector3(0, 0.5, 0), game.yellow))
	game.advance_bullets(0.3)
	check(tough.hp == 1 and game.score == 0, "Hits reduce HP without granting an early reward")
	game.reset_run()
	var distant: CourseTarget = game.spawn_target(0, -20, 0, 10, 2)
	game.bullets.append(game.box(Vector3.ONE * 0.1, Vector3(0, 0.5, 0), game.yellow))
	game.advance_bullets(1.0)
	check(distant.hp == 9 and game.bullets.is_empty(), "Shots reach distant targets beyond the removed range limit")
	game.reset_run()
	var threat: CourseTarget = game.spawn_target(4.7, 5, 1, 100, 20)
	game.resolve_contacts()
	check(game.squad.size() == Rules.START_SOLDIERS, "Missed target outside formation causes no losses")
	threat.position.x = game.squad[0].position.x
	threat.previous_x = threat.position.x
	threat.half = Vector2(0.05, 0.05)
	game.resolve_contacts()
	check(game.squad.size() == Rules.START_SOLDIERS - 1, "Contact removes only touched soldier")
	check(game.squad[0].position.x > -1.45, "Formation compacts after casualty")
	game.reset_run(true, 123)
	var fast: CourseTarget = game.spawn_target(game.squad[0].position.x, 10, 1, 100, 20)
	fast.previous_z = 0.0
	fast.half = Vector2(0.05, 0.05)
	game.resolve_contacts()
	check(game.squad.size() == 3, "Fast threats sweep only the soldiers they actually cross")
	game.reset_run()
	game.spawn_target(0, 5, 1, 100, 20).half.x = 6
	game._physics_process(0.016)
	check(game.squad.is_empty() and not game.running and game.message.text.begins_with("FLEET LOST"), "Zero ships ends run")
	game.reset_run()
	check(game.squad.size() == Rules.START_SOLDIERS and game.targets.is_empty() and game.bullets.is_empty() and game.particles.is_empty() and game.score == 0 and game.elapsed == 0 and game.wave == 0 and game.running and game.player_z == Main.PLAYER_Z and game.ship_previous.is_empty() and game.bullet_batch.multimesh.visible_instance_count == 0 and game.soldier_batches[0].multimesh.visible_instance_count == 4, "Restart clears run state, flight position, movement history and rendered instances")
	game.elapsed = 59.99
	game._physics_process(0.016)
	check(game.running and game.elapsed > 60.0 and game.message.text.is_empty(), "Passing one minute never ends the run")
	var endless_spawning: bool = true
	for seconds: float in [61.0, 300.0, 1800.0]:
		game.reset_run(true, 123)
		game.elapsed = seconds
		game.spawn_clock = 0.0
		game._physics_process(0.016)
		endless_spawning = endless_spawning and game.running and game.wave == 1 and not game.targets.is_empty()
	check(endless_spawning, "Encounters keep spawning after one, five and thirty minutes")
	check(Rules.course_speed(0) > 3.1 and Rules.course_speed(300) > Rules.course_speed(60) and Rules.target_health(1, 1800, 1.0) > Rules.target_health(1, 300, 1.0) and Rules.encounter_pressure(300) > Rules.encounter_pressure(60), "Scrolling starts faster and speed, HP and encounter pressure keep growing")
	var pause := InputEventKey.new()
	pause.keycode = KEY_P
	pause.pressed = true
	game._unhandled_key_input(pause)
	check(not game.running and game.message.text.begins_with("PAUSED"), "Pause works beyond the former time limit")
	game.reset_run()
	game.elapsed = 270.0
	for i: int in range(120):
		game.add_soldier()
	game.arrange()
	check(game.squad.size() == Rules.MAX_SOLDIERS, "Squad capacity bounded")
	await process_frame
	var camera: Camera3D = game.get_viewport().get_camera_3d()
	var viewport_size: Vector2 = game.get_viewport().get_visible_rect().size
	var formation_visible: bool = true
	for soldier: Node3D in game.squad:
		var screen: Vector2 = camera.unproject_position(soldier.position)
		formation_visible = formation_visible and screen.y > viewport_size.y * 0.8 and screen.y < viewport_size.y - 20.0
	check(formation_visible, "Full formation stays visible in the bottom fifth of the screen")
	game.reset_run(true, 123)
	var constant_damage: bool = true
	for fleet_size: int in range(1, Rules.MAX_SOLDIERS + 1):
		constant_damage = constant_damage and Rules.shot_damage(fleet_size) == 1
	check(constant_damage, "Every fleet size from 1 to 48 deals exactly one HP per projectile")
	game.reset_run(true, 123)
	var rear: CourseTarget = game.spawn_target(0, -8, 1, 100, 50)
	var front: CourseTarget = game.spawn_target(0, -10, 1, 100, 50)
	Main.Motion.advance(game.targets, 0.0, 1.0 / 60.0)
	var rear_top: float = game.camera.unproject_position(rear.position + Vector3(0, rear.body.position.y, -rear.half.y)).y
	var front_bottom: float = game.camera.unproject_position(front.position + Vector3(0, front.body.position.y, front.half.y)).y
	check(rear_top >= front_bottom - 0.01, "Round hulls separate in camera view with caption clearance")
	game.reset_run(true, 123)
	rear = game.spawn_target(0, -8, 1, 5, 50, 0)
	front = game.spawn_target(0, -10.5, 1, 1000, 50, 4)
	var front_start: float = front.position.z
	var rear_start: float = rear.position.z
	Main.Motion.advance(game.targets, 0.0, 1.0 / 60.0)
	rear_top = game.camera.unproject_position(rear.position + Vector3(0, rear.body.position.y, -rear.half.y)).y
	front_bottom = game.camera.unproject_position(front.position + Vector3(0, front.body.position.y, front.half.y)).y
	check(rear_top >= front_bottom - 0.01 and absf(rear.position.z - rear_start) > absf(front.position.z - front_start) * 100, "Mixed-size round hulls separate visibly and the low-HP hull yields more")
	game.reset_run(true, 123)
	var light: CourseTarget = game.spawn_target(-0.85, -8, 1, 10, 50)
	var heavy: CourseTarget = game.spawn_target(0.85, -8, 1, 100, 50)
	light.velocity.x = 0.5
	heavy.velocity.x = -0.5
	Main.Motion.resolve_pair(light, heavy, 6.0)
	check(absf(light.velocity.x - 0.5) > absf(heavy.velocity.x + 0.5) * 9.9 and is_equal_approx(10 * light.velocity.x + 100 * heavy.velocity.x, -45.0), "HP-weighted impacts conserve lateral momentum and deflect lighter hulls more")
	check(light.hp == 10 and heavy.hp == 100 and game.score == 0, "Object collisions preserve HP and grant no rewards")
	light.position = Vector3(-0.85, 0, -8)
	heavy.position = Vector3(0.85, 0, -8)
	heavy.hit(90)
	light.velocity.x = 0.5
	heavy.velocity.x = -0.5
	Main.Motion.resolve_pair(light, heavy, 6.0)
	check(is_equal_approx(light.velocity.x, -heavy.velocity.x), "Damaged hulls use remaining HP as mass")
	game.reset_run(true, 123)
	var edge: CourseTarget = game.spawn_target(5.49, -8, 1, 100, 50)
	edge.velocity.x = 0.5
	Main.Motion.advance(game.targets, 6.0, 0.1)
	check(edge.position.x + edge.half.x <= Rules.ROAD_HALF and edge.velocity.x < 0, "Right border contains the complete hull and reflects outward velocity")
	edge.position.x = -5.49
	edge.velocity.x = -0.5
	Main.Motion.advance(game.targets, 6.0, 0.1)
	check(edge.position.x - edge.half.x >= -Rules.ROAD_HALF and edge.velocity.x > 0, "Left border contains the complete hull and reflects outward velocity")
	game.reset_run(true, 123)
	var crossing: CourseTarget = game.spawn_target(1, -8, 1, 100, 50)
	crossing.velocity.x = -20.0
	Main.Motion.advance(game.targets, 0.0, 0.1)
	game.bullets.append(game.box(Vector3.ONE * 0.1, Vector3(0, 0.5, -6.6), game.yellow))
	game.advance_bullets(0.1)
	check(crossing.hp == 99, "Shots sweep relative lateral motion instead of missing crossing hulls")
	game.reset_run(true, 123)
	crossing = game.spawn_target(-3, game.player_z, 1, 100, 50)
	crossing.previous_x = 3
	game.resolve_contacts()
	check(game.squad.is_empty(), "Sideways threats sweep the ships actually crossed")
	game.reset_run(true, 123)
	light = game.spawn_target(-2, -8, 1, 10, 50)
	heavy = game.spawn_target(2, -8, 1, 100, 50)
	light.velocity.x = 15.0
	heavy.velocity.x = -15.0
	Main.Motion.advance(game.targets, 6.0, 0.1)
	check(light.position.x < heavy.position.x and light.velocity.x < 0 and Main.Motion.penetration(light, heavy).length() < 0.001, "Fast approaching objects collide without crossing or remaining overlapped")
	game.reset_run(true, 123)
	light = game.spawn_target(4.7, -8, 1, 5, 50)
	heavy = game.spawn_target(3.2, -8, 1, 100, 50)
	heavy.velocity.x = 1.0
	Main.Motion.advance(game.targets, 6.0, 0.5)
	check(light.position.x + light.half.x <= Rules.ROAD_HALF and heavy.position.x + heavy.half.x <= Rules.ROAD_HALF and Main.Motion.penetration(light, heavy).length() < 0.005, "Mass-weighted collision beside a wall keeps both hulls inside and separated")
	game.reset_run(true, 123)
	game.spawn_wave()
	var drift_valid: bool = true
	for item: CourseTarget in game.targets:
		drift_valid = drift_valid and absf(item.velocity.x) >= Main.Motion.DRIFT_MIN and absf(item.velocity.x) <= Main.Motion.DRIFT_MAX
	check(drift_valid, "Spawned objects receive gentle seeded lateral drift")
	# Reproducible course with a simple steering pattern checks entity lifetime.
	var max_bullets: int = 0
	var max_targets: int = 0
	send_key(KEY_CTRL, true)
	for step: int in range(3600):
		if not game.running:
			break
		game.player_x = sin(float(step) / 130.0) * 3.0
		game._physics_process(1.0 / 60.0)
		max_bullets = maxi(max_bullets, game.bullets.size())
		max_targets = maxi(max_targets, game.targets.size())
	send_key(KEY_CTRL, false)
	check(max_bullets <= Rules.MAX_BULLETS and max_targets <= 30, "Scripted course keeps entity counts bounded")
	print("SIMULATION: elapsed=", game.elapsed, " soldiers=", game.squad.size(), " score=", game.score, " peak_bullets=", max_bullets, " peak_targets=", max_targets)
	print("CHECK_FAILURES=", failures)
	game.free()
	quit(0 if failures == 0 else 1)
