extends SceneTree

const Main = preload("res://scripts/main.gd")
const Rules = preload("res://scripts/invasion_rules.gd")
const Encounters = preload("res://scripts/encounters.gd")
const Info = preload("res://scripts/build_info.gd")
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

func check_opening_score_targets(game: Node3D) -> void:
	var valid: bool = true
	for seed_value: int in [42, 123, 456, 789, 2026]:
		var generator := Encounters.new()
		generator.reset(seed_value)
		for wave_index: int in range(20):
			var survival: float = wave_index * 1.5
			var plan: Array[Dictionary] = generator.plan(Rules.difficulty_time(survival), wave_index)
			var aliens: int = 0
			for item: Dictionary in plan:
				if item.kind != 0:
					aliens += 1
					valid = valid and item.tier == 0 and item.hp >= 5 and item.hp <= 6 and item.reward >= 40 and item.reward <= 70
			valid = valid and aliens > 0 and plan.size() <= 3
	check(valid, "Every opening wave offers small 5-6 HP score aliens across seeds")
	var generator := Encounters.new()
	generator.reset(123)
	for survival: float in [0.0, 29.99, 30.0, 300.0]:
		var sample: Array[Dictionary] = [{"kind": 0, "tier": 0, "hp": 5, "reward": 1, "x": 0.0, "z": -24.0, "drift": 0.4}]
		var original: Array[Dictionary] = sample.duplicate(true)
		var rng_state: int = generator.rng.state
		generator.ease_opening(sample, Rules.difficulty_time(survival))
		check(sample[0] == original[0] and generator.rng.state == rng_state, "Opening adjustment preserves the entire egg and RNG state at %.2fs" % survival)
		check(sample.size() == (2 if survival < 30.0 else 1), "Guaranteed score target ends at exactly 30 seconds (%.2fs)" % survival)
		var normal: Array[Dictionary] = [{"kind": 2, "tier": 2, "hp": 150, "reward": 240}]
		generator.ease_opening(normal, Rules.difficulty_time(survival))
		check(normal[0].hp == (6 if survival < 30.0 else 150) and normal[0].reward == (60 if survival < 30.0 else 240), "Opening discount affects only early aliens (%.2fs)" % survival)
	for kind: int in [1, 2]:
		game.reset_run(true, 123)
		game.spawn_clock = 999.0
		game.elapsed = 29.0
		var target: CourseTarget = game.spawn_target(0, -24, kind, Rules.OPENING_SCORE_HEALTH[kind], 50, 0)
		for step: int in range(180):
			game._physics_process(1.0 / 60.0)
		check(not is_instance_valid(target) and game.targets.is_empty() and game.score == 50 and game.squad.size() == 1 and game.pickups.is_empty(), "Lone fighter destroys opening alien kind %d with normal fire before contact, awarding only points" % kind)

func check_health_curves() -> void:
	var supplies_unchanged: bool = true
	for survival: float in [0.0, 30.0, 60.0, 300.0, 1800.0]:
		var t: float = Rules.difficulty_time(survival)
		for tier: int in range(5):
			for variation: float in [0.85, 1.0, 1.15]:
				var expected: int = 5 if tier == 0 else maxi(1, roundi((18.0 + t * 0.30 + 12.0 * pow(t / 60.0, 2.2)) * variation * Rules.SIZE_HEALTH[tier]))
				supplies_unchanged = supplies_unchanged and Rules.target_health(0, t, variation, tier) == expected
	check(supplies_unchanged, "All egg sizes retain their previous HP curve and fixed small recovery health")
	var smooth: bool = true
	var grows: bool = true
	var gentler: bool = true
	for kind: int in [1, 2]:
		for tier: int in range(5):
			var boundary: int = Rules.target_health(kind, Rules.difficulty_time(30.0), 1.0, tier)
			smooth = smooth and boundary == Rules.target_health(kind, Rules.difficulty_time(30.01), 1.0, tier)
			if tier == 0:
				smooth = smooth and boundary == Rules.OPENING_SCORE_HEALTH[kind]
			var previous: int = boundary
			for second: int in range(31, 601):
				var hp: int = Rules.target_health(kind, Rules.difficulty_time(float(second)), 1.0, tier)
				grows = grows and hp >= previous
				previous = hp
			for survival: float in [30.0, 60.0, 180.0, 300.0, 1800.0]:
				var t: float = Rules.difficulty_time(survival)
				var old_hp: float = ([24.0, 32.0][kind - 1] + t * [0.4, 0.5][kind - 1] + [18.0, 24.0][kind - 1] * pow(t / 60.0, 2.2)) * Rules.SIZE_HEALTH[tier]
				gentler = gentler and Rules.target_health(kind, t, 1.0, tier) < roundi(old_hp)
	check(smooth, "Alien HP starts from 5-6 for small ships at 30 seconds without a health cliff")
	check(grows and gentler, "Alien HP grows monotonically for ten minutes and stays below the former curve at sampled times and every size")

func check_pickup_recapture(game: Node3D) -> void:
	game.reset_run(true, 123)
	game.spawn_pickup(Vector3(3, 0, -20), 4)
	var pickup: RescuePickup = game.pickups[0]
	pickup.advance(4.99)
	check(pickup.spin.visible and pickup.caption.visible and not pickup.help_sign.visible and not pickup.can_be_recaptured(), "Freed fighters remain steady and protected before five seconds without a HELP sign")
	pickup.advance(0.20)
	check(pickup.spin.visible and pickup.caption.visible and not pickup.help_sign.visible and pickup.can_be_recaptured(), "Only HELP blinks off while the fighter and reward stay visible and recapturable")
	pickup.advance(0.18)
	check(pickup.spin.visible and pickup.caption.visible and pickup.help_sign.visible, "HELP blinks on while the fighter and reward remain visible")
	var alien: CourseTarget = game.spawn_target(pickup.position.x, pickup.position.z, 1, 100, 50)
	pickup.age = 4.99
	game.recapture_pickups()
	check(game.pickups.size() == 1 and game.recapture.flashes.is_empty(), "Alien contact cannot recapture before blinking starts")
	pickup.advance(0.01)
	game.recapture_pickups()
	check(game.pickups.is_empty() and game.recapture.flashes.size() == 1 and game.squad.size() == 1 and game.score == 0 and alien.hp == 100, "At exactly five seconds alien contact removes only the freed fighter without granting rewards or damaging the alien")
	game.recapture_pickups()
	check(game.recapture.flashes.size() == 1, "A captured fighter cannot be captured twice")
	game.recapture.advance(0.3)
	check(not game.recapture.flashes.is_empty(), "Pickup capture uses the slower beam")
	game.recapture.advance(0.16)
	check(game.recapture.flashes.is_empty(), "Slower capture beam expires cleanly")
	for kind: int in [0, 1, 2]:
		game.reset_run(true, 123)
		game.spawn_pickup(Vector3(3, 0, -8), 1)
		game.pickups[0].age = 30.0
		game.spawn_target(3, -8, kind, 100, 50)
		game.recapture_pickups()
		check((game.pickups.size() == 1 and game.recapture.flashes.is_empty()) if kind == 0 else (game.pickups.is_empty() and game.recapture.flashes.size() == 1), "Only alien-piloted ships recapture eligible fighters (kind %d)" % kind)
	game.reset_run(true, 123)
	game.spawn_pickup(Vector3(3, 0, -8), 1)
	game.pickups[0].age = 30.0
	game.recapture_pickups()
	check(game.pickups.size() == 1, "Eligible fighters stay available until an alien actually touches them")
	var fast: CourseTarget = game.spawn_target(3, -3, 1, 100, 50)
	fast.previous_z = -13.0
	fast.half = Vector2(0.05, 0.05)
	game.recapture_pickups()
	check(game.pickups.is_empty(), "Fast alien crossings use swept pickup recapture")
	game.reset_run(true, 123)
	game.spawn_pickup(game.squad[0].position, 2)
	game.pickups[0].age = 5.19
	game.pickups[0].advance(0.0)
	game.collect_pickups()
	check(game.pickups.is_empty() and game.squad.size() == 3, "Freed fighters remain collectible while HELP is hidden")

func check_high_scores(game: Node3D) -> void:
	var original_table: LocalHighScores = game.high_scores
	game.high_scores = Main.Scores.new()
	game.lcd.high_scores = game.high_scores
	game.high_score_path = ProjectSettings.globalize_path("res://../artifacts/high-scores-test.json")
	var table: LocalHighScores = game.high_scores
	check(table.entries.size() == 10 and table.rank_for(1042) == -1 and table.rank_for(1043) == 9 and table.rank_for(4880) == 0, "Ten seeded scores use strict qualification and stable ties")
	check(Main.Scores.clean_name("aB!c") == "ABC", "Names accept only uppercase arcade characters")
	check(table.record(4880, "test pilot") == 0 and table.entries[0].name == "TEST PILOT" and table.entries.size() == 10, "New score displaces exactly the last row and uppercases the name")
	check(table.save_scores(game.high_score_path) == OK, "Local score table writes successfully")
	var loaded := Main.Scores.new()
	loaded.load_scores(game.high_score_path)
	check(loaded.entries == table.entries, "Scores survive loading a new table")
	loaded.record(4881, "")
	check(loaded.entries[0].name == "PILOT" and loaded.save_scores(game.high_score_path) == OK, "Empty names get a fallback and saving replaces the previous file")
	var broken := FileAccess.open(game.high_score_path, FileAccess.WRITE)
	broken.store_string('{"format":1,"entries":[null]}')
	broken.close()
	loaded.load_scores(game.high_score_path)
	check(loaded.entries.size() == 10 and loaded.entries[0].name == "AKIRA", "Malformed local data restores the complete seeded table")
	table.reset_defaults()
	game.reset_run(true, 123)
	game.set_physics_process(false)
	game.score = 2310
	game.finish()
	game._physics_process(2.99)
	check(not game.lcd.entering_name and game.pending_high_score, "Qualifying defeat waits three seconds before name entry")
	game._physics_process(0.02)
	check(game.lcd.entering_name and not game.lcd.attract_active and not game.running and game.sound.fanfare_active and not game.sound.music_active, "Qualifying defeat opens name entry with the exclusive victory loop")
	check(game.lcd.volume_slider.visible and game.lcd.speaker_button.visible and game.lcd.version_label.visible, "Musical name entry retains sound controls and version")
	var key := InputEventKey.new()
	key.pressed = true
	var entries_before: Array = table.entries.duplicate(true)
	for empty_name: String in ["", " ".repeat(Main.Scores.NAME_LENGTH)]:
		game.lcd.name_buffer = empty_name
		key.keycode = KEY_ENTER
		game._unhandled_key_input(key)
		check(game.lcd.entering_name and game.pending_high_score and table.entries == entries_before and game.sound.fanfare_active, "Empty name confirmation keeps the score pending and the entry screen active")
		check(game.lcd.name_error_flash_remaining > 0.0, "Empty name flashes the input field")
		game.lcd._process(0.1)
		var remaining: float = game.lcd.name_error_flash_remaining
		key.echo = true
		game._unhandled_key_input(key)
		check(game.lcd.name_error_flash_remaining == remaining, "Held Enter does not restart the error flash")
		key.echo = false
		game.lcd._process(1.0)
		check(game.lcd.name_error_flash_remaining == 0.0 and game.lcd.entering_name, "Error flash ends once and keeps name editing available")
	game.lcd.name_buffer = " ".repeat(Main.Scores.NAME_LENGTH)
	key.keycode = KEY_M
	key.unicode = 109
	game._unhandled_key_input(key)
	check(game.lcd.name_buffer.begins_with("M") and not game.sound.muted, "Typed lowercase M becomes an uppercase name letter without muting")
	key.unicode = 0
	key.keycode = KEY_UP
	game._unhandled_key_input(key)
	key.keycode = KEY_RIGHT
	game._unhandled_key_input(key)
	key.keycode = KEY_DOWN
	game._unhandled_key_input(key)
	check(game.lcd.name_buffer.begins_with("MA-"), "Arcade arrows choose letters and wrap through the character set")
	game.sound.toggle_mute()
	check(game.sound.fanfare.stream_paused, "Mute silences the victory loop")
	game.sound.toggle_mute()
	game.set_sound_volume(0)
	check(game.sound.fanfare.stream_paused, "Zero volume silences the victory loop")
	game.set_sound_volume(50)
	check(not game.sound.fanfare.stream_paused, "Volume restores the victory loop")
	key.keycode = KEY_ENTER
	game._unhandled_key_input(key)
	check(not game.lcd.entering_name and game.lcd.attract_active and not game.sound.fanfare.playing and not game.pending_high_score and table.entries[5].name == "MA-", "Enter saves once, stops the fanfare and returns to the leaderboard demo")
	check(not game.lcd.volume_slider.visible and not game.lcd.speaker_button.visible and game.lcd.version_label.visible, "Silent Top 10 hides audio controls but keeps the version")
	loaded.load_scores(game.high_score_path)
	check(loaded.entries == table.entries, "Confirmed score and name persist together")
	game.reset_run(true, 123)
	game.score = 6000
	game.finish()
	key.keycode = KEY_SPACE
	game._unhandled_key_input(key)
	check(game.lcd.entering_name and game.defeat_hold_remaining == 0 and not game.running, "Space skips a qualifying defeat hold into name entry without restarting")
	key.keycode = KEY_ENTER
	key.echo = true
	game._unhandled_key_input(key)
	check(game.lcd.entering_name, "Held Enter cannot accidentally confirm a name")
	key.echo = false
	key.keycode = KEY_UP
	game._unhandled_key_input(key)
	key.keycode = KEY_KP_ENTER
	game._unhandled_key_input(key)
	key.keycode = KEY_ENTER
	game._unhandled_key_input(key)
	check(game.running and not game.lcd.entering_name and not game.lcd.attract_active and not game.sound.fanfare.playing, "Next Enter starts a clean run and hides the leaderboard")
	game.high_scores = original_table
	game.lcd.high_scores = original_table
	game.high_score_path = Main.Scores.SAVE_PATH
	game.reset_run(false)

func run() -> void:
	var clean_identity: Dictionary = {"version": Info.version(), "commit": "a".repeat(40), "modified": false}
	check(Info.label(clean_identity) == "v%s-aaaaaaa" % Info.version(), "Clean build identity uses compact version-hash format")
	var dirty_identity: Dictionary = clean_identity.duplicate()
	dirty_identity["modified"] = true
	check(Info.label(dirty_identity) == "v%s-aaaaaaa-modified" % Info.version(), "Development identity marks local modifications")
	check(Info.label({}) == "v%s" % Info.version(), "Missing provenance shows the application version alone")
	check(Info.repository_url("https://github.com/barmassimo/pocket-invasion.git") == Info.PROJECT_URL, "Approved HTTPS remote links to the project root")
	check(Info.repository_url("git@github.com:barmassimo/pocket-invasion.git") == Info.PROJECT_URL, "Approved SSH remote links to the HTTPS project root")
	check(Info.repository_url("https://github.com/other/private.git").is_empty(), "Unapproved remotes are not exposed")
	var linked_identity: Dictionary = clean_identity.duplicate()
	linked_identity["repository_url"] = Info.PROJECT_URL
	check(Info.validated(JSON.parse_string(JSON.stringify(linked_identity))).get("repository_url") == Info.PROJECT_URL, "Bundled identity preserves the approved project URL without Git")
	check(Info.source_identity(ProjectSettings.globalize_path("res://assets")).is_empty(), "A source directory without its own repository cannot inherit an enclosing Git identity")
	var invalid_identity: Dictionary = clean_identity.duplicate()
	invalid_identity["version"] = "stale-version"
	check(Info.validated(invalid_identity).is_empty(), "Snapshots from another application version are rejected")
	invalid_identity = clean_identity.duplicate()
	invalid_identity["modified"] = "false"
	check(Info.validated(invalid_identity).is_empty(), "Malformed modification state cannot masquerade as a clean build")
	invalid_identity = clean_identity.duplicate()
	invalid_identity["commit"] = "not-a-hash"
	check(Info.validated(invalid_identity).is_empty(), "Invalid commit identity is rejected")
	var game := Main.new()
	root.add_child(game)
	check_high_scores(game)
	check(game.lcd.volume_slider.get_rect().end.y < 773, "Volume control stays inside the bottom of the LCD panel")
	check(game.lcd.version_label.position.x == 46 and game.lcd.version_label.get_rect().end.y < 773, "Version label stays inside the lower-left LCD panel")
	check(game.lcd.intro.visible and not game.lcd.demo.visible and not game.running, "Startup shows the story without running the course or demo")
	var control_key := InputEventKey.new()
	control_key.pressed = true
	control_key.keycode = KEY_SPACE
	game._unhandled_key_input(control_key)
	check(game.running and not game.lcd.intro.visible, "Space starts from the story")
	check(not game.lcd.version_label.visible and not game.lcd.copyright_label.visible and game.lcd.volume_slider.visible and game.lcd.speaker_button.visible, "Gameplay footer shows only audio controls")
	game.score = 123
	for code: Key in [KEY_ENTER, KEY_SPACE]:
		control_key.keycode = code
		game._unhandled_key_input(control_key)
		check(game.score == 123 and game.running, "Start keys never restart an active run")
	control_key.keycode = KEY_P
	game._unhandled_key_input(control_key)
	control_key.keycode = KEY_ENTER
	game._unhandled_key_input(control_key)
	check(not game.running and game.score == 123 and game.message.text == "PAUSED", "Enter never restarts a paused run")
	control_key.keycode = KEY_ESCAPE
	game._unhandled_key_input(control_key)
	check(game.started and not game.running and game.score == 123 and game.squad.size() == Rules.START_SOLDIERS and game.message.text == "PAUSED" and not game.lcd.demo.visible, "Escape preserves a paused run")
	control_key.keycode = KEY_P
	game._unhandled_key_input(control_key)
	control_key.keycode = KEY_ESCAPE
	game._unhandled_key_input(control_key)
	check(game.running and game.started and game.score == 123 and not game.lcd.demo.visible, "Escape preserves an active run")
	game.reset_run(false)
	check(not game.sound.music.playing, "Ready demonstration stays silent")
	game.set_physics_process(false)
	game.reset_run(true, 123)
	check(game.sound.music.playing and not game.sound.music.stream_paused, "Starting a run starts the soundtrack")
	game.sound.toggle_mute()
	check(game.sound.music.stream_paused, "Mute silences the soundtrack")
	game.sound.toggle_mute()
	check(not game.sound.music.stream_paused, "Unmute restores the soundtrack")
	game.set_sound_volume(0.0)
	check(game.sound.music.stream_paused, "Zero volume silences the soundtrack")
	game.set_sound_volume(50.0)
	check(not game.sound.music.stream_paused, "Raising volume restores the soundtrack")
	game.reset_run(false)
	# Accelerated simulation must not queue thousands of real-time audio voices.
	game.sound.muted = true
	game.set_physics_process(false)
	check(game.lcd.intro.visible and not game.lcd.demo.visible, "Ready cycle starts with the briefing")
	control_key.keycode = KEY_D
	game._unhandled_key_input(control_key)
	check(game.lcd.intro.visible and game.lcd.attract_clock == 0.0, "D no longer skips the briefing")
	game.lcd.set_process(false)
	check(is_equal_approx(game.lcd.page_remaining_fraction(), 1.0), "Briefing countdown starts full")
	game.lcd._process(6.5)
	check(game.lcd.current_page() == 0 and is_equal_approx(game.lcd.page_remaining_fraction(), 0.5), "Briefing countdown drains over thirteen seconds")
	control_key.keycode = KEY_RIGHT
	game._unhandled_key_input(control_key)
	check(game.lcd.current_page() == 1 and is_equal_approx(game.lcd.page_remaining_fraction(), 1.0), "Right arrow selects the next page with a fresh countdown")
	game.lcd._process(4.5)
	check(is_equal_approx(game.lcd.page_remaining_fraction(), 0.5), "Manual countdown drains over nine seconds")
	game.lcd._process(4.5)
	check(game.lcd.current_page() == 2 and is_equal_approx(game.lcd.page_remaining_fraction(), 1.0), "Empty countdown advances to the points lesson and refills")
	game.lcd.step_page(1)
	check(game.lcd.current_page() == 0, "Next after the third page wraps to the briefing")
	control_key.keycode = KEY_LEFT
	game._unhandled_key_input(control_key)
	check(game.lcd.current_page() == 2, "Left from the briefing wraps to the points lesson")
	game.lcd.select_page(0)
	for page: int in range(2):
		game.lcd._process(13.0 if page == 0 else 9.0)
		check(game.lcd.demo.visible and not game.lcd.intro.visible and is_equal_approx(game.lcd.demo.clock, page * 9.0), "Cycle advances to manual page %d" % (page + 2))
		control_key.keycode = KEY_ENTER
		game._unhandled_key_input(control_key)
		check(game.running and not game.lcd.demo.visible and not game.lcd.intro.visible, "Enter starts from manual page %d" % (page + 2))
		game.reset_run(false)
		game.lcd._process(13.0 + page * 9.0)
	game.lcd._process(9.0)
	check(game.lcd.intro.visible and not game.lcd.demo.visible and game.lcd.attract_clock == 0.0, "Three-page cycle returns to the briefing")
	game.lcd._process(32.0)
	check(is_equal_approx(game.lcd.attract_clock, 1.0) and game.squad.size() == Rules.START_SOLDIERS and game.targets.is_empty() and game.bullets.is_empty() and game.score == 0 and game.elapsed == 0.0, "Idle cycle loops without changing gameplay state")
	game.reset_run(true, 123)
	check(not game.lcd.demo.visible and not game.lcd.demo.is_processing() and game.lcd.demo.clock == 0.0, "Starting a run hides and resets the demonstration")
	var demo_pause := InputEventKey.new()
	demo_pause.keycode = KEY_P
	demo_pause.pressed = true
	game._unhandled_key_input(demo_pause)
	check(not game.running and not game.lcd.demo.visible, "Pause never shows the demonstration")
	check(not game.sound.music_active and game.sound.music.stream_paused, "Pause suspends the soundtrack")
	game._unhandled_key_input(demo_pause)
	check(game.running and not game.lcd.demo.visible, "Resuming keeps the demonstration hidden")
	game.finish()
	check(not game.sound.music_active and game.sound.music.stream_paused, "Defeat suspends music before the defeat effect and silent demo")
	check(not game.lcd.demo.visible and game.message.visible and not game.running, "Defeat holds the final course with a restart prompt")
	var frozen_target: CourseTarget = game.spawn_target(2, -10, 1, 20, 50)
	var frozen_position: Vector3 = frozen_target.position
	var frozen_elapsed: float = game.elapsed
	game._physics_process(9.99)
	check(not game.lcd.demo.visible and frozen_target.position == frozen_position and game.elapsed == frozen_elapsed, "Final course stays frozen before ten seconds")
	game._physics_process(0.02)
	check(game.lcd.intro.visible and not game.lcd.demo.visible and game.lcd.is_processing() and not game.message.visible and game.lcd.attract_clock == 0.0, "Three-page cycle starts with the briefing after the ten-second hold")
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
	check_opening_score_targets(game)
	check_health_curves()
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
	check(game.elapsed == 0.0 and Rules.difficulty_time(game.elapsed) == 60.0 and game.targets.size() >= 2, "Run starts at internal level two with a fresh survival timer and immediate threats")
	check(Rules.threat_level(0.0) == 1 and Rules.threat_level(59.99) == 1 and Rules.threat_level(60.0) == 2 and Rules.threat_level(120.0) == 3, "Displayed threat starts at one and advances at survival-minute boundaries")
	check(Rules.target_health(1, Rules.difficulty_time(30.0), 1.0, 0) == 5 and Rules.encounter_pressure(Rules.difficulty_time(0.0)) > 1.28, "Alien HP starts gently while opening wave pressure keeps the existing difficulty offset")
	var previous_speed: float = Rules.course_speed(Rules.difficulty_time(0.0))
	var previous_gain: float = 0.0
	var speed_accelerates: bool = is_equal_approx(previous_speed, 6.08816)
	for step: int in range(1, 36001):
		var speed: float = Rules.course_speed(Rules.difficulty_time(float(step) / 60.0))
		var gain: float = speed - previous_speed
		speed_accelerates = speed_accelerates and gain > previous_gain
		previous_speed = speed
		previous_gain = gain
	check(speed_accelerates, "Faster opening speed grows every physics tick with increasing gains for ten minutes")
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
		recovered_alone = recovered_alone and game.squad.size() == 1 and game.targets.is_empty() and game.pickups.size() == 1 and game.running
		if not game.pickups.is_empty():
			game.player_x = game.pickups[0].position.x
			game.player_z = game.pickups[0].position.z
			game.arrange()
			game.ship_previous.clear()
			game.collect_pickups()
		recovered_alone = recovered_alone and game.squad.size() == 2 and game.pickups.is_empty()
	check(recovered_alone, "One fighter can free then collect a recovery reinforcement at start, five and thirty minutes")
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
		game.reset_run(true, 123)
		game.elapsed = time
		for i: int in range(124 - Rules.START_SOLDIERS):
			game.add_soldier()
		game.arrange()
		limits_valid = limits_valid and game.squad.size() == 124 and game.soldier_batches[0].multimesh.visible_instance_count == 124
	check(limits_valid, "Fleet grows beyond 48 with every ship rendered at all survival times")
	check(Rules.formation_columns(32) == 8 and Rules.formation_columns(33) == 9 and Rules.formation_columns(40) == 9 and Rules.formation_columns(41) == 10, "Formation starts widening above 32 ships, adding a column per eight reinforcements")
	var spacing_valid: bool = true
	for count: int in range(1, 257):
		var positions: Array[Vector3] = Rules.offsets(count)
		var columns: int = Rules.formation_columns(count)
		for i: int in range(1, count):
			if i % columns != 0:
				spacing_valid = spacing_valid and is_equal_approx(positions[i].x - positions[i - 1].x, Rules.SPACING)
			if i >= columns:
				spacing_valid = spacing_valid and is_equal_approx(positions[i].z - positions[i - columns].z, Rules.SPACING)
	check(spacing_valid, "Fleets from 1 to 256 retain their original horizontal and vertical spacing")
	var widening_valid: bool = true
	var previous_limit: float = Rules.movement_limit(32)
	for count: int in range(33, 257):
		var limit: float = Rules.movement_limit(count)
		widening_valid = widening_valid and limit > 0.0 and limit <= previous_limit
		for offset: Vector3 in Rules.offsets(count):
			widening_valid = widening_valid and absf(offset.x) + limit + 0.3 <= Rules.ROAD_HALF + 0.00001
		previous_limit = limit
	check(widening_valid and Rules.movement_limit(64) < Rules.movement_limit(32), "Growing fleets lose lateral escape room while every ship stays inside the course")
	game.reset_run(true, 123)
	for i: int in range(41 - Rules.START_SOLDIERS):
		game.add_soldier()
	game.player_x = Rules.movement_limit(32)
	game.arrange()
	check(is_equal_approx(game.player_x, Rules.movement_limit(41)), "Widening after reinforcements clamps the fleet back inside the border")
	while game.squad.size() > 32:
		game.squad.pop_back().free()
	game.arrange()
	check(Rules.formation_columns(game.squad.size()) == 8 and Rules.movement_limit(32) > Rules.movement_limit(41), "Losses below the threshold restore compact width and lateral escape room")
	game.reset_run(true, 123)
	check(game.squad.size() == 1 and game.elapsed == 0.0 and Rules.difficulty_time(game.elapsed) == 60.0 and Rules.threat_level(game.elapsed) == 1, "Restart restores one lone ship, internal level two and displayed level one")
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
	check(game.pickups.size() == 1 and game.pickups[0].reward == 4 and game.squad.size() == Rules.START_SOLDIERS, "Large egg releases a four-ship pickup")
	game.pickups[0].position = game.squad[0].position
	game.pickups[0].previous_position = game.pickups[0].position
	game.collect_pickups()
	check(game.squad.size() == Rules.START_SOLDIERS + 4, "Collecting a large reinforcement grants all four ships")
	game.reset_run(true, 123)
	game.elapsed = 270.0
	for i: int in range(48 - Rules.START_SOLDIERS):
		game.add_soldier()
	game.arrange()
	var command: CourseTarget = game.spawn_target(0, -15, 0, 1, Rules.target_reward(0, 4), 4)
	game.destroy_target(command)
	game.pickups[0].position = game.squad[0].position
	game.pickups[0].previous_position = game.pickups[0].position
	game.collect_pickups()
	check(game.squad.size() == 64 and Rules.shot_damage(game.squad.size()) == 1, "Collecting a command supply grants sixteen ships while shot damage stays at one")
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
	for i: int in range(24 - Rules.START_SOLDIERS):
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
	for count: int in [Rules.START_SOLDIERS, 124]:
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
		edges_valid = edges_valid and top_y >= 34 and top_y <= 50 and bottom_y >= 750 and bottom_y <= 766
	check(edges_valid, "Small and expanded fleets reach the inset top and bottom limits without entering the frame margin")
	game.reset_run(true, 123)
	game.spawn_clock = 999.0
	var moving_threat: CourseTarget = game.spawn_target(game.squad[0].position.x, game.player_z - 1.0, 1, 999, 50)
	moving_threat.half = Vector2(0.05, 0.05)
	send_key(KEY_W, true)
	game._physics_process(0.2)
	send_key(KEY_W, false)
	check(game.squad.is_empty() and not game.running, "Flying the lone starting ship through a threat ends the run")
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
	check(game.targets.is_empty() and game.squad.size() == Rules.START_SOLDIERS and game.pickups.size() == 1 and game.pickups[0].reward == 4 and game.score == 25, "Egg destruction releases its full reward without adding ships before contact")
	check(not is_instance_valid(reward), "Destroyed target removed")
	game.collect_pickups()
	check(game.squad.size() == Rules.START_SOLDIERS and game.pickups.size() == 1, "Distant freed fighters do not join automatically")
	var freed: RescuePickup = game.pickups[0]
	var pickup_hull: MeshInstance3D = freed.spin.get_child(0) as MeshInstance3D
	var pickup_mesh := pickup_hull.mesh as PlaneMesh
	var pickup_corner: Vector2 = game.camera.unproject_position(pickup_hull.to_global(Vector3(pickup_mesh.size.x * 0.5, 0, pickup_mesh.size.y * 0.5)))
	var fleet_corner: Vector2 = game.camera.unproject_position(freed.position + Vector3(Rules.FIGHTER_SIZE.x * 0.5, 0.35, Rules.FIGHTER_SIZE.y * 0.5))
	check(pickup_corner.distance_to(fleet_corner) < 0.001, "Freed fighters match the initial fleet's exact projected size")
	var rigid_rotation: bool = true
	var mesh_half: Vector2 = pickup_mesh.size * 0.5
	var expected_size: Vector2 = Rules.FIGHTER_SIZE * Vector2(1.0, Main.Target.Art.projection_scale()) * (800.0 / game.camera.size)
	for angle_step: int in range(25):
		freed.spin.rotation.y = TAU * float(angle_step) / 24.0
		var a: Vector2 = game.camera.unproject_position(pickup_hull.to_global(Vector3(-mesh_half.x, 0, -mesh_half.y)))
		var b: Vector2 = game.camera.unproject_position(pickup_hull.to_global(Vector3(mesh_half.x, 0, -mesh_half.y)))
		var c: Vector2 = game.camera.unproject_position(pickup_hull.to_global(Vector3(-mesh_half.x, 0, mesh_half.y)))
		var edge_x: Vector2 = b - a
		var edge_y: Vector2 = c - a
		rigid_rotation = rigid_rotation and absf(edge_x.length() - expected_size.x) < 0.001 and absf(edge_y.length() - expected_size.y) < 0.001 and absf(edge_x.normalized().dot(edge_y.normalized())) < 0.001
	check(rigid_rotation, "A full pickup rotation preserves projected edge lengths and right angles without stretching or shear")
	freed.spin.rotation.y = 0.0
	var old_angle: float = freed.spin.rotation.y
	freed.advance(0.1)
	check(freed.spin.rotation.y > old_angle and freed.position.z > freed.previous_position.z, "Freed fighters drift and rotate slowly")
	var parked_position: Vector3 = freed.position
	var parked_angle: float = freed.spin.rotation.y
	control_key.keycode = KEY_P
	game._unhandled_key_input(control_key)
	game._physics_process(0.25)
	check(freed.position == parked_position and freed.spin.rotation.y == parked_angle, "Pause freezes freed-fighter drift and rotation")
	game._unhandled_key_input(control_key)
	var behind: CourseTarget = game.spawn_target(freed.position.x, freed.position.z - 3.0, 1, 2, 50)
	game.bullets.append(game.box(Vector3.ONE * 0.1, freed.position + Vector3(0, 0.5, 1), game.yellow))
	game.advance_bullets(0.3)
	check(game.pickups.size() == 1 and freed.reward == 4 and behind.hp == 1, "Bullets pass through invulnerable freed fighters and still hit enemies behind them")
	game.ship_previous[game.squad[0]] = freed.position + Vector3(0, 0, 2)
	game.squad[0].position = freed.position - Vector3(0, 0, 2)
	game.collect_pickups()
	check(game.pickups.is_empty() and game.squad.size() == Rules.START_SOLDIERS + 4 and game.score == 25, "Swept pickup contact grants the entire reinforcement reward once without losses")
	game.collect_pickups()
	check(game.squad.size() == Rules.START_SOLDIERS + 4, "Collected fighters cannot grant duplicate rewards")
	game.reset_run(true, 123)
	for i: int in range(Rules.MAX_PICKUPS + 1):
		game.spawn_pickup(Vector3(0, 0, -5), 1)
	var pending_reward: int = 0
	for pickup: RescuePickup in game.pickups:
		pending_reward += pickup.reward
	check(game.pickups.size() == Rules.MAX_PICKUPS and pending_reward == Rules.MAX_PICKUPS + 1, "Pickup capacity stays bounded while retaining all released rewards")
	game.pickups[0].position.z = 12.0
	game.spawn_clock = 999.0
	game._physics_process(1.0 / 60.0)
	check(game.pickups.size() == Rules.MAX_PICKUPS - 1, "Missed pickups are removed after leaving the course")
	game.reset_run()
	check(game.pickups.is_empty(), "Restart clears all uncollected fighters")
	check_pickup_recapture(game)
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
	for i: int in range(4 - Rules.START_SOLDIERS):
		game.add_soldier()
	game.arrange()
	var threat: CourseTarget = game.spawn_target(4.7, 5, 1, 100, 20)
	game.resolve_contacts()
	check(game.squad.size() == 4, "Missed target outside formation causes no losses")
	threat.position.x = game.squad[0].position.x
	threat.previous_x = threat.position.x
	threat.half = Vector2(0.05, 0.05)
	game.resolve_contacts()
	check(game.squad.size() == 3, "Contact removes only touched soldier")
	check(game.recapture.flashes.is_empty() and game.particles.size() == 8 and threat.hp == 100 and game.score == 0, "Alien contact uses the same micro-explosion as egg contact, without recapture")
	check(game.squad[0].position.x > -1.45, "Formation compacts after casualty")
	game.reset_run(true, 123)
	for i: int in range(4 - Rules.START_SOLDIERS):
		game.add_soldier()
	game.arrange()
	var egg: CourseTarget = game.spawn_target(game.squad[0].position.x, game.squad[0].position.z, 0, 100, 1)
	egg.half = Vector2(0.05, 0.05)
	game.resolve_contacts()
	check(game.squad.size() == 3 and game.recapture.flashes.is_empty() and game.particles.size() == 8 and egg.hp == 100 and game.score == 0, "Egg contact keeps the micro-explosion and identical contact losses without rewards")
	game.reset_run(true, 123)
	for i: int in range(4 - Rules.START_SOLDIERS):
		game.add_soldier()
	game.arrange()
	var fast: CourseTarget = game.spawn_target(game.squad[0].position.x, 10, 1, 100, 20)
	fast.previous_z = 0.0
	fast.half = Vector2(0.05, 0.05)
	game.resolve_contacts()
	check(game.squad.size() == 3, "Fast threats sweep only the soldiers they actually cross")
	game.reset_run()
	game.spawn_target(0, 5, 1, 100, 20).half.x = 6
	game._physics_process(0.016)
	check(game.squad.is_empty() and not game.running and game.message.text.begins_with("FLEET LOST"), "Zero ships ends run")
	game.spawn_pickup(Vector3(0, 0, 5), 1)
	game.collect_pickups()
	check(game.squad.is_empty() and game.pickups.size() == 1 and not game.running, "Uncollected fighters cannot revive a defeated fleet")
	check(game.recapture.flashes.is_empty(), "Last ship collision never starts a recapture beam")
	game.recapture.play(Vector3.ZERO, game.targets[0], Vector2.ONE)
	game._physics_process(0.3)
	check(not game.recapture.flashes.is_empty(), "Slower pickup recapture remains visible beyond 0.3 seconds")
	game._physics_process(0.2)
	check(game.recapture.flashes.is_empty(), "Pending pickup recapture finishes during the defeat hold")
	game.recapture.play(Vector3.ZERO, game.targets[0], Vector2.ONE)
	game.reset_run()
	check(game.recapture.flashes.is_empty(), "Restart clears pending recapture visuals")
	check(game.squad.size() == Rules.START_SOLDIERS and game.targets.is_empty() and game.bullets.is_empty() and game.particles.is_empty() and game.score == 0 and game.elapsed == 0 and game.wave == 0 and game.running and game.player_z == Main.PLAYER_Z and game.ship_previous.is_empty() and game.bullet_batch.multimesh.visible_instance_count == 0 and game.soldier_batches[0].multimesh.visible_instance_count == 1, "Restart clears run state, flight position, movement history and rendered instances")
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
	for i: int in range(124 - Rules.START_SOLDIERS):
		game.add_soldier()
	game.arrange()
	check(game.squad.size() == 124, "All reinforcements are retained beyond the former capacity")
	await process_frame
	var camera: Camera3D = game.get_viewport().get_camera_3d()
	var viewport_size: Vector2 = game.get_viewport().get_visible_rect().size
	var road_left: Vector2 = camera.unproject_position(Vector3(-Rules.ROAD_HALF, 0, 0))
	var road_right: Vector2 = camera.unproject_position(Vector3(Rules.ROAD_HALF, 0, 0))
	var pixel_scale: float = viewport_size.y / 800.0
	check(absf((road_right.x - road_left.x) / pixel_scale - 338.46154) < 0.01, "Narrower window preserves the original projected course width and object scale")
	check(absf((road_left.x + road_right.x) * 0.5 / pixel_scale - Main.Display.PLAYFIELD_CENTER_X) < 0.01 and road_left.x / pixel_scale > 348 and road_right.x / pixel_scale < Main.Display.WINDOW_WIDTH - 18, "Course is centered within the compact right panel with clear bezel margins")
	var formation_visible: bool = true
	for soldier: Node3D in game.squad:
		var screen: Vector2 = camera.unproject_position(soldier.position)
		formation_visible = formation_visible and screen.y > Main.Display.PLAYFIELD_RECT.position.y * pixel_scale and screen.y < Main.Display.PLAYFIELD_RECT.end.y * pixel_scale
	check(formation_visible, "Expanded formation stays visible inside the playfield without compressing ranks")
	game.reset_run(true, 123)
	var constant_damage: bool = true
	for fleet_size: int in range(1, 125):
		constant_damage = constant_damage and Rules.shot_damage(fleet_size) == 1
	check(constant_damage, "Every tested fleet size from 1 to 124 deals exactly one HP per projectile")
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
