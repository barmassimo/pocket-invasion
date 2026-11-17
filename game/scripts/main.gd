extends Node3D

const Rules = preload("res://scripts/invasion_rules.gd")
const Target = preload("res://scripts/target.gd")
const Sound = preload("res://scripts/sound.gd")
const Encounters = preload("res://scripts/encounters.gd")
const Motion = preload("res://scripts/target_motion.gd")
const Display = preload("res://scripts/lcd_display.gd")
const Recapture = preload("res://scripts/recapture_flash.gd")
const Pickup = preload("res://scripts/rescue_pickup.gd")
const Scores = preload("res://scripts/high_scores.gd")
const EnemyFire = preload("res://scripts/alien_fire.gd")
var alien_fire: AlienFire = EnemyFire.new()
const HIGH_SCORE_HOLD_SECONDS: float = 3.0
var high_scores: LocalHighScores = Scores.new()
var pending_high_score: bool = false
var high_score_path: String = Scores.SAVE_PATH
const PLAYER_Z: float = 5.0
const PLAYER_FIGHTER_SIZE: Vector2 = Rules.FIGHTER_SIZE * 1.10
const DEFEAT_HOLD_SECONDS: float = 10.0
const PAUSE_BLINK_INTERVAL: float = 0.5
var defeat_hold_remaining: float = 0.0
var pause_blink_time: float = 0.0
var squad: Array[Node3D] = []
var targets: Array[CourseTarget] = []
var bullets: Array[MeshInstance3D] = []
var particles: Array[MeshInstance3D] = []
var pickups: Array[RescuePickup] = []
var player_x: float = 0.0
var player_z: float = PLAYER_Z
var camera: Camera3D
var ship_previous: Dictionary[Node3D, Vector3] = {}
var elapsed: float = 0.0
var fire_clock: float = 0.0
var spawn_clock: float = 0.0
var wave: int = 0
var score: int = 0
var running: bool = false
var started: bool = false
var message: Label
var toast: Label
var toast_clock: float = 0.0
var blue: StandardMaterial3D
var yellow: StandardMaterial3D
var spark: StandardMaterial3D
var sound: ArcadeSound
var encounters: CourseEncounters = Encounters.new() as CourseEncounters
var debug_seed: int = -1
var lcd: LcdDisplay
var recapture: RecaptureFlash
var bullet_batch: MultiMeshInstance3D
var soldier_batches: Array[MultiMeshInstance3D] = []
var exhaust_batch: MultiMeshInstance3D
var bullet_mesh: BoxMesh
var toast_icon: TextureRect

func _ready() -> void:
	# Apply after asset import: project-level custom_font loads too early on a fresh checkout.
	ThemeDB.get_default_theme().default_font = preload("res://assets/fonts/share-tech-mono/ShareTechMono-Regular.ttf")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--seed=") and argument.trim_prefix("--seed=").is_valid_int():
			debug_seed = argument.trim_prefix("--seed=").to_int()
	sound = Sound.new() as ArcadeSound
	add_child(sound)
	build_world()
	high_scores.load_scores(high_score_path)
	build_ui()
	reset_run(false)
	print("USER_DATA_DIR=", OS.get_user_data_dir())

func mat(color: Color, glow: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func box(size: Vector3, at: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	add_child(node)
	return node

func build_world() -> void:
	blue = mat(Color("253820"))
	yellow = mat(Color("20341c"), true)
	spark = mat(Color("435b31"), true)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("bdc79f")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b9d5f7")
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.2
	add_child(sun)
	camera = Camera3D.new()
	camera.position = Rules.CAMERA_POSITION
	add_child(camera)
	camera.look_at(Rules.CAMERA_FOCUS)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 26.0
	# Preserve the course's pixel scale and center in the screen beside the HUD.
	camera.h_offset = -(Display.PLAYFIELD_CENTER_X - Display.WINDOW_WIDTH * 0.5) * camera.size / 800.0
	camera.current = true
	box(Vector3(11, 0.3, 40), Vector3(0, -0.3, -8), mat(Color("c4cca5")))
	bullet_batch = create_batch(Vector3(0.09, 0.09, 0.45), yellow, Rules.MAX_BULLETS)
	bullet_mesh = bullet_batch.multimesh.mesh as BoxMesh
	var ships: MultiMeshInstance3D = create_batch(Vector3.ONE, blue, Rules.START_SOLDIERS)
	var hull := PlaneMesh.new()
	hull.size = PLAYER_FIGHTER_SIZE
	ships.multimesh.mesh = hull
	var hull_material: StandardMaterial3D = blue.duplicate() as StandardMaterial3D
	hull_material.albedo_texture = LcdIcons.SHIP
	hull_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hull_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	ships.material_override = hull_material
	soldier_batches.append(ships)
	exhaust_batch = create_batch(Vector3.ONE, blue, Rules.MAX_FORMATION_COLUMNS)
	var exhaust := PlaneMesh.new()
	exhaust.size = Vector2(0.15, 0.24)
	exhaust_batch.multimesh.mesh = exhaust
	var exhaust_material: StandardMaterial3D = hull_material.duplicate() as StandardMaterial3D
	exhaust_material.albedo_texture = preload("res://assets/icons/exhaust.svg")
	exhaust_batch.material_override = exhaust_material

func create_batch(size: Vector3, material: StandardMaterial3D, capacity: int) -> MultiMeshInstance3D:
	var batch := MultiMeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = capacity
	instances.visible_instance_count = 0
	batch.multimesh = instances
	batch.material_override = material
	batch.custom_aabb = AABB(Vector3(-8, -1, -36), Vector3(16, 5, 50))
	add_child(batch)
	return batch

func sync_bullets() -> void:
	bullet_batch.multimesh.visible_instance_count = bullets.size()
	for i: int in range(bullets.size()):
		bullets[i].visible = false
		bullet_batch.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, bullets[i].position))

func label_at(at: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = at
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("253820"))
	var lcd_font: Font = preload("res://assets/fonts/share-tech-mono/ShareTechMono-Regular.ttf")
	l.add_theme_font_override("font", lcd_font)
	return l

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	lcd = Display.new() as LcdDisplay
	layer.add_child(lcd)
	lcd.volume_changed.connect(set_sound_volume)
	lcd.mute_requested.connect(toggle_sound_mute)
	lcd.name_confirmed.connect(save_high_score)
	lcd.high_scores = high_scores
	recapture = Recapture.new() as RecaptureFlash
	recapture.camera = camera
	layer.add_child(recapture)
	recapture.position = Display.PLAYFIELD_RECT.position
	recapture.size = Display.PLAYFIELD_RECT.size
	message = label_at(Vector2(Display.PLAYFIELD_CENTER_X - 160, 310), 22, Color.WHITE)
	message.size = Vector2(320, 220)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(message)
	toast = label_at(Vector2(80, 510), 18, Color("90ffe0"))
	toast.size.x = 245
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(toast)
	toast_icon = TextureRect.new()
	toast_icon.position = Vector2(46, 510)
	toast_icon.size = Vector2(28, 28)
	toast_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	toast_icon.modulate = Color("253820")
	toast_icon.visible = false
	layer.add_child(toast_icon)

func notice(text: String, duration: float, kind: int = -1) -> void:
	toast.text = text
	toast_clock = duration
	toast_icon.visible = kind >= 0
	if kind >= 0:
		toast_icon.texture = LcdIcons.reward(kind)

func reset_run(play: bool = true, seed_override: int = -1) -> void:
	encounters.reset(seed_override if seed_override >= 0 else debug_seed)
	if play:
		print("RUN_SEED=", encounters.run_seed)
	sound.stop_all()
	recapture.clear()
	alien_fire.clear()
	for collection: Array in [squad, targets, bullets, particles, pickups]:
		for item: Node in collection:
			item.free()
		collection.clear()
	sync_bullets()
	player_x = 0.0
	player_z = PLAYER_Z
	ship_previous.clear()
	elapsed = 0.0
	fire_clock = 0.0
	spawn_clock = 1.0
	wave = 0
	score = 0
	toast_clock = 0.0
	toast.text = ""
	toast_icon.visible = false
	for i: int in range(Rules.START_SOLDIERS):
		add_soldier()
	arrange()
	running = play
	sound.set_music_playing(play)
	started = play
	pending_high_score = false
	defeat_hold_remaining = 0.0
	pause_blink_time = 0.0
	message.modulate.a = 1.0
	lcd.set_playing(play)
	message.visible = play
	message.text = "" if play else "POCKET INVASION\n\nREADY"
	update_hud()

func add_soldier() -> void:
	var soldier := Node3D.new()
	add_child(soldier)
	squad.append(soldier)

func arrange() -> void:
	player_x = clampf(player_x, -Rules.movement_limit(squad.size()), Rules.movement_limit(squad.size()))
	var positions: Array[Vector3] = Rules.offsets(squad.size())
	var limits: Vector2 = vertical_limits()
	player_z = clampf(player_z, limits.x, limits.y)
	for i: int in range(squad.size()):
		squad[i].position = positions[i] + Vector3(player_x, 0, player_z)
	var offsets: Array[Vector3] = [Vector3(0, 0.35, 0)]
	for part: int in range(soldier_batches.size()):
		var instances: MultiMesh = soldier_batches[part].multimesh
		if instances.instance_count < squad.size():
			instances.instance_count = maxi(squad.size(), instances.instance_count * 2)
		instances.visible_instance_count = squad.size()
		for i: int in range(squad.size()):
			soldier_batches[part].multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, squad[i].position + offsets[part]))
	sync_exhaust()

func sync_exhaust() -> void:
	var instances: MultiMesh = exhaust_batch.multimesh
	instances.visible_instance_count = 0
	if squad.is_empty():
		return
	# Full rows cover those ahead; only the final two rows can have exposed engines.
	var columns: int = Rules.formation_columns(squad.size())
	var last_row: int = ((squad.size() - 1) / columns) * columns
	var emitted: int = 0
	for i: int in range(maxi(0, last_row - columns), squad.size()):
		var covered: bool = false
		var next_row: int = (i / columns + 1) * columns
		for j: int in range(next_row, mini(next_row + columns, squad.size())):
			if absf(squad[i].position.x - squad[j].position.x) < Rules.FIGHTER_SIZE.x:
				covered = true
				break
		if covered:
			continue
		var frame: int = (floori(elapsed / 0.10) + i) % 3
		var length_scale: float = [0.70, 1.0, 0.82][frame]
		var tail: float = PLAYER_FIGHTER_SIZE.y * (57.0 / 64.0 - 0.5)
		var at: Vector3 = squad[i].position + Vector3(0, 0.35, tail + 0.12 * length_scale)
		instances.set_instance_transform(emitted, Transform3D(Basis.from_scale(Vector3(1, 1, length_scale)), at))
		emitted += 1
	instances.visible_instance_count = emitted

func screen_z(y: float) -> float:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var point := Vector2(viewport_size.x / 2.0, y * viewport_size.y / 800.0)
	var origin: Vector3 = camera.project_ray_origin(point)
	var direction: Vector3 = camera.project_ray_normal(point)
	return (origin + direction * ((0.35 - origin.y) / direction.y)).z

func vertical_limits() -> Vector2:
	var count: int = squad.size()
	var rows: int = maxi(0, (count - 1) / Rules.formation_columns(count))
	var depth: float = rows * Rules.formation_spacing(count).y
	return Vector2(screen_z(Display.PLAYFIELD_RECT.position.y + 8.0) + 0.32, screen_z(Display.PLAYFIELD_RECT.end.y - 8.0) - depth - 0.32)

func _unhandled_key_input(event: InputEvent) -> void:
	if lcd.entering_name and event is InputEventKey and event.pressed and event.keycode not in [KEY_ESCAPE, KEY_F11]:
		lcd.handle_name_key(event)
		get_viewport().set_input_as_handled()
		return
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if pending_high_score:
			begin_high_score()
		elif not started or squad.is_empty():
			reset_run()
	elif event.keycode in [KEY_LEFT, KEY_RIGHT] and lcd.attract_active:
		lcd.step_page(-1 if event.keycode == KEY_LEFT else 1)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE:
		var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif event.keycode == KEY_M:
		toggle_sound_mute()
	elif event.keycode == KEY_F11 or event.keycode == KEY_F:
		var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		var fullscreen: bool = mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif event.keycode == KEY_P and started and not squad.is_empty():
		running = not running
		lcd.set_playing(true)
		sound.stop_effects()
		sound.set_music_playing(running)
		message.text = "PAUSED" if not running else ""
		pause_blink_time = 0.0
		message.modulate.a = 1.0

func _process(delta: float) -> void:
	if started and not running and not squad.is_empty():
		pause_blink_time = fmod(pause_blink_time + delta, PAUSE_BLINK_INTERVAL * 2.0)
		message.modulate.a = 1.0 if pause_blink_time < PAUSE_BLINK_INTERVAL else 0.0
	else:
		pause_blink_time = 0.0
		message.modulate.a = 1.0

func _physics_process(delta: float) -> void:
	# Finish any pending cosmetic beam even when the last ship was just lost.
	# Pause still freezes it; restart clears it with the rest of the presentation.
	if running or defeat_hold_remaining > 0.0:
		recapture.advance(delta)
	if not running:
		if defeat_hold_remaining > 0.0:
			defeat_hold_remaining = maxf(0.0, defeat_hold_remaining - delta)
			if defeat_hold_remaining == 0.0:
				if pending_high_score:
					begin_high_score()
				else:
					return_to_demo()
		return
	elapsed += delta
	sound.tick(delta)
	ship_previous.clear()
	for ship: Node3D in squad:
		ship_previous[ship] = ship.position
	var movement := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	movement = movement.limit_length()
	player_x += movement.x * 7.0 * delta
	# Compensate the camera foreshortening so vertical and horizontal screen speeds agree.
	player_z += movement.y * 9.7 * delta
	arrange()
	var difficulty: float = Rules.difficulty_time(elapsed)
	var speed: float = Rules.course_speed(difficulty)
	spawn_clock -= delta
	if spawn_clock <= 0.0:
		spawn_wave()
		spawn_clock += encounters.next_interval(difficulty)
	fire_clock = maxf(0.0, fire_clock - delta)
	if fire_clock <= 0.0:
		fire_clock = Rules.shot_interval(squad.size())
		sound.play_effect("shot")
		for soldier: Node3D in squad:
			if bullets.size() < Rules.MAX_BULLETS:
				var bullet := MeshInstance3D.new()
				bullet.mesh = bullet_mesh
				bullet.visible = false
				bullet.position = soldier.position + Vector3(0.05, Target.Art.PLANE_HEIGHT, -0.4)
				add_child(bullet)
				bullet.set_meta("damage", Rules.shot_damage(squad.size()))
				bullets.append(bullet)
	Motion.advance(targets, speed, delta, pickups)
	for pickup: RescuePickup in pickups:
		pickup.advance(delta)
	for target: CourseTarget in targets:
		target.animate(delta)
	advance_bullets(delta)
	sync_bullets()
	resolve_contacts(alien_fire.advance(delta, squad, ship_previous))
	alien_fire.fire(self, targets, Vector3(player_x, 0, player_z), delta, elapsed)
	collect_pickups()
	recapture_pickups()
	for i: int in range(pickups.size() - 1, -1, -1):
		if pickups[i].position.z > 11.0:
			pickups[i].free()
			pickups.remove_at(i)
	for i: int in range(targets.size() - 1, -1, -1):
		if targets[i].position.z > 11:
			targets[i].free()
			targets.remove_at(i)
	for i: int in range(particles.size() - 1, -1, -1):
		var p: MeshInstance3D = particles[i]
		p.scale *= 0.87
		p.position.y += delta * 2.0
		if p.scale.x < 0.03:
			p.free()
			particles.remove_at(i)
	toast_clock = maxf(0, toast_clock - delta)
	if toast_clock == 0:
		toast.text = ""
		toast_icon.visible = false
	if squad.is_empty():
		finish()
	update_hud()

func spawn_target(x: float, z: float, kind: int, hp: int, reward: int, tier: int = 1) -> CourseTarget:
	if targets.size() >= 30:
		return null
	var target := Target.new() as CourseTarget
	add_child(target)
	target.position = Vector3(x, 0, z)
	target.setup(kind, hp, reward, tier)
	targets.append(target)
	return target

func spawn_wave() -> void:
	for encounter: Dictionary in encounters.plan(Rules.difficulty_time(elapsed), wave):
		var target: CourseTarget = spawn_target(encounter.x, encounter.z, encounter.kind, encounter.hp, encounter.reward, encounter.tier)
		if target != null:
			target.velocity.x = encounter.drift
	wave += 1

func advance_bullets(delta: float) -> void:
	for i: int in range(bullets.size() - 1, -1, -1):
		var bullet: MeshInstance3D = bullets[i]
		var before: Vector3 = bullet.position
		bullet.position.z -= Rules.BULLET_SPEED * delta
		var nearest: CourseTarget = null
		var first_fraction: float = INF
		for target: CourseTarget in targets:
			var relative_from := before - Vector3(target.previous_x, 0, target.previous_z)
			var relative_to := bullet.position - target.position
			var fraction: float = Rules.shot_fraction(relative_from, relative_to, Vector3.ZERO, target.half)
			if fraction < first_fraction:
				first_fraction = fraction
				nearest = target
		if nearest != null:
			sound.play_effect("hit")
			if nearest.hit(int(bullet.get_meta("damage", 1))):
				destroy_target(nearest)
		# Recycle only after leaving the whole course, never at an in-course range limit.
		if nearest != null or bullet.position.z < -34.0:
			bullet.free()
			bullets.remove_at(i)

func burst(at: Vector3) -> void:
	for i: int in range(8):
		if particles.size() >= 160:
			break
		var angle: float = float(i) * TAU / 8.0
		particles.append(box(Vector3.ONE * 0.22, at + Vector3(cos(angle) * 0.65, 0.6, sin(angle) * 0.65), spark))

func destroy_target(target: CourseTarget) -> void:
	burst(target.position)
	if target.kind == 0:
		sound.play_effect("break")
		spawn_pickup(target.position, target.reward, target.velocity.x)
		notice("PILOT FREE / COLLECT", 1.2)
		score += 25
	else:
		sound.play_effect("alien_break")
		score += target.reward
		notice("+%d" % target.reward, 1.2, 1)
	targets.erase(target)
	target.free()

func spawn_pickup(at: Vector3, reward: int, drift: float = 0.0) -> void:
	# Preserve every earned ship even if the active pickup count reaches its bound.
	if pickups.size() >= Rules.MAX_PICKUPS:
		var nearest: RescuePickup = pickups[0]
		for candidate: RescuePickup in pickups:
			if candidate.position.distance_squared_to(at) < nearest.position.distance_squared_to(at):
				nearest = candidate
		nearest.reward += reward
		nearest.refresh()
		return
	var pickup := Pickup.new() as RescuePickup
	add_child(pickup)
	pickup.position = at
	pickup.setup(reward, drift)
	pickups.append(pickup)

func collect_pickups() -> void:
	# Only living formation members can collect; new recruits cannot chain pickups.
	var gained: int = 0
	var half := Vector2(Rules.PICKUP_RADIUS, Rules.PICKUP_RADIUS / Target.Art.projection_scale())
	for i: int in range(pickups.size() - 1, -1, -1):
		var pickup: RescuePickup = pickups[i]
		for soldier: Node3D in squad:
			var before: Vector3 = ship_previous.get(soldier, soldier.position)
			if Rules.shot_fraction(before - pickup.previous_position, soldier.position - pickup.position, Vector3.ZERO, half, 0.20) != INF:
				gained += pickup.reward
				pickup.free()
				pickups.remove_at(i)
				break
	if gained > 0:
		for i: int in range(gained):
			add_soldier()
		sound.play_effect("reinforce")
		notice("+%d" % gained, 1.2, 0)
		arrange()

func resolve_contacts(casualties: Array[Node3D] = []) -> void:
	# Collect all touched soldiers before compacting the formation.
	for soldier: Node3D in squad:
		if soldier in casualties:
			continue
		for target: CourseTarget in targets:
			var before: Vector3 = ship_previous.get(soldier, soldier.position)
			var relative_from := Vector3(before.x - target.previous_x, 0, before.z - target.previous_z)
			var relative_to := Vector3(soldier.position.x - target.position.x, 0, soldier.position.z - target.position.z)
			if Rules.shot_fraction(relative_from, relative_to, Vector3.ZERO, target.half, 0.20) != INF:
				casualties.append(soldier)
				break
	for soldier: Node3D in casualties:
		burst(soldier.position)
		squad.erase(soldier)
		ship_previous.erase(soldier)
		soldier.free()
	if not casualties.is_empty():
		sound.play_effect("loss")
		notice("-%d" % casualties.size(), 0.8, 0)
		arrange()

func recapture_pickups() -> void:
	for i: int in range(pickups.size() - 1, -1, -1):
		var pickup: RescuePickup = pickups[i]
		if not pickup.can_be_recaptured():
			continue
		for target: CourseTarget in targets:
			if target.kind == 0:
				continue
			var before := pickup.previous_position - Vector3(target.previous_x, 0, target.previous_z)
			var after := pickup.position - target.position
			if Rules.shot_fraction(before, after, Vector3.ZERO, target.half, Rules.PICKUP_RADIUS) != INF:
				recapture.play(pickup.position, target, Vector2.ONE, -pickup.spin.rotation.y)
				pickup.free()
				pickups.remove_at(i)
				break

func finish() -> void:
	running = false
	started = false
	sound.set_music_playing(false)
	pending_high_score = high_scores.rank_for(score) >= 0
	defeat_hold_remaining = HIGH_SCORE_HOLD_SECONDS if pending_high_score else DEFEAT_HOLD_SECONDS
	lcd.set_playing(true)
	message.visible = true
	sound.play_effect("defeat")
	message.text = "FLEET LOST\n\nTOP 10 SCORE!\n\n[ENTER / SPACE]\nENTER YOUR NAME" if pending_high_score else "FLEET LOST\n\n[ENTER / SPACE] START"

func begin_high_score() -> void:
	defeat_hold_remaining = 0.0
	toast.text = ""
	toast_icon.visible = false
	message.visible = false
	lcd.begin_name_entry(score, high_scores.rank_for(score))
	sound.set_fanfare_playing(true)

func save_high_score(player_name: String) -> void:
	if not pending_high_score:
		return
	high_scores.record(score, player_name)
	var error: Error = high_scores.save_scores(high_score_path)
	pending_high_score = false
	sound.stop_all()
	return_to_demo()
	if error != OK:
		notice("SAVE FAILED / SESSION ONLY", 0.0)
		push_warning("Local high scores could not be saved: %s" % error_string(error))

func return_to_demo() -> void:
	toast.text = ""
	toast_icon.visible = false
	message.visible = false
	lcd.set_playing(false)
	update_hud()

func update_hud() -> void:
	lcd.update_status(squad.size(), score, elapsed)
	lcd.muted = sound.muted or sound.volume_percent <= 0.0

func set_sound_volume(percent: float) -> void:
	if percent > 0.0:
		sound.muted = false
	sound.set_volume(percent)
	update_hud()

func toggle_sound_mute() -> void:
	sound.toggle_mute()
	update_hud()


