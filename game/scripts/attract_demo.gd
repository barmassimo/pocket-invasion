class_name AttractDemo
extends Control

# Presentation only: no gameplay entities, rewards, input or audio are created.
const INK := Color("253820")
const PAPER := Color("c4cca5")
const Art = preload("res://scripts/target_art.gd")
const LESSON_SECONDS: float = 9.0
const LOOP_SECONDS: float = LESSON_SECONDS * 2.0
const CONTENT_WIDTH: float = 308.0
const ACTION_OFFSET := Vector2(14, 0)
var clock: float = 0.0
var font: Font = ThemeDB.fallback_font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_playing(playing: bool) -> void:
	if playing:
		clock = 0.0
	visible = not playing
	set_process(not playing)
	queue_redraw()

func _process(delta: float) -> void:
	clock = fposmod(clock + delta, LOOP_SECONDS)
	queue_redraw()

func text_at(y: float, text: String, size: int = 16) -> void:
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, CONTENT_WIDTH, size, INK)

func ship(at: Vector2) -> void:
	draw_texture_rect(LcdIcons.SHIP, Rect2(at - Vector2(17, 23), Vector2(34, 46)), false, INK)

func target(at: Vector2, hp: int, kind: int) -> void:
	var rect := Rect2(at - Vector2(46, 46), Vector2(92, 92))
	draw_texture_rect(Art.HULL, rect, false)
	if kind == 0:
		draw_texture_rect(Art.FLEET, rect, false)
	else:
		draw_texture_rect(Art.PILOT, Rect2(at - Vector2(19, 24), Vector2(38, 48)), false)
	draw_string(font, at + Vector2(-30, 62), "+1" if kind == 0 else "+50", HORIZONTAL_ALIGNMENT_CENTER, 60, 18, INK)
	draw_string(font, at + Vector2(-50, -57), "HP %d" % hp, HORIZONTAL_ALIGNMENT_CENTER, 100, 18, INK)

func explosion(at: Vector2, progress: float) -> void:
	for i: int in range(8):
		var direction := Vector2.from_angle(i * TAU / 8.0)
		draw_line(at + direction * (15 + progress * 15), at + direction * (24 + progress * 20), INK, 3)

func _draw() -> void:
	var lesson: int = floori(clock / LESSON_SECONDS)
	var time: float = fposmod(clock, LESSON_SECONDS)
	# Hold each result completely still for the last three seconds.
	var action: float = minf(time, 6.0)
	text_at(0, "HOW TO PLAY", 20)
	draw_line(Vector2(0, 48), Vector2(CONTENT_WIDTH, 48), INK)
	text_at(80, ["BUILD YOUR FLEET", "EARN POINTS"][lesson], 16)
	draw_rect(Rect2(10, 104, CONTENT_WIDTH - 20, 350), INK, false)
	draw_set_transform(ACTION_OFFSET)
	draw_shooting(action, lesson)
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(0, 480), Vector2(CONTENT_WIDTH, 480), INK)
	if time >= (4.25 if lesson == 0 else 5.5):
		var lines: Array = [
			["BREAK THE CAPTURE SHIP.", "TOUCH THE FREE FIGHTER", "TO REBUILD YOUR FLEET."],
			["DESTROY ALIENS FOR POINTS."]][lesson]
		for i: int in range(lines.size()):
			text_at(512 + i * 25, lines[i], 16)
	else:
		text_at(546, "FIRE IS AUTOMATIC", 14)

func action_text(y: float, text: String, size: int = 16) -> void:
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, 280, size, INK)

func draw_shooting(time: float, kind: int) -> void:
	var impact: Vector2 = Vector2(140, 213)
	var hits: int = clampi(floori((time - 1.25) / 0.75) + 1, 0, 5)
	if hits < 5:
		target(impact, 5 - hits, kind)
		for i: int in range(5):
			var shot_time: float = time - (0.65 + i * 0.75)
			if shot_time >= 0 and shot_time < 0.6:
				var y: float = lerpf(377, 258, shot_time / 0.6)
				draw_line(Vector2(140, y), Vector2(140, y - 10), INK, 3)
		if hits > 0 and fposmod(time - 1.25, 0.75) < 0.12:
			explosion(impact, 0.4)
	elif time < 4.9:
		explosion(impact, clampf((time - 4.25) / 0.65, 0, 1))
	if kind == 0:
		var approach: float = smoothstep(4.6, 5.5, time)
		var y: float = lerpf(407, 233, approach)
		if time >= 4.25 and time < 5.5:
			var angle: float = (time - 4.25) * InvasionRules.PICKUP_SPIN_SPEED
			draw_set_transform(ACTION_OFFSET + impact, angle)
			ship(Vector2.ZERO)
			# Restore the panel offset after drawing the rotating pickup.
			draw_set_transform(ACTION_OFFSET)
			action_text(285, "MOVE TO COLLECT", 16)
		var spread: float = smoothstep(5.5, 6.0, time)
		ship(Vector2(140 - spread * 18, y))
		if time >= 5.5:
			ship(Vector2(140 + 18, y))
			action_text(312, "+1 SHIP", 21)
	else:
		ship(Vector2(140, 407))
		if time >= 4.9:
			action_text(312, "+50 POINTS", 21)
	action_text(125, "SHIPS  %d" % (2 if kind == 0 and time >= 5.5 else 1), 14)
