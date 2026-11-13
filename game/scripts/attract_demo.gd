class_name AttractDemo
extends Control

# Presentation only: no gameplay entities, rewards, input or audio are created.
const INK := Color("253820")
const PAPER := Color("c4cca5")
const Art = preload("res://scripts/target_art.gd")
const LESSON_SECONDS: float = 9.0
const LOOP_SECONDS: float = LESSON_SECONDS * 3.0
var clock: float = 0.0
var font := SystemFont.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font.font_names = PackedStringArray(["Consolas", "Courier New"])
	font.font_weight = 700

func set_playing(playing: bool) -> void:
	if visible and playing:
		clock = 0.0
	visible = not playing
	set_process(not playing)
	queue_redraw()

func _process(delta: float) -> void:
	clock = fposmod(clock + delta, LOOP_SECONDS)
	queue_redraw()

func text_at(y: float, text: String, size: int = 16) -> void:
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, 280, size, INK)

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
	# Hold the result completely still for the last three seconds of each lesson.
	var action: float = minf(time, 6.0)
	text_at(0, "HOW TO PLAY", 20)
	draw_line(Vector2(0, 48), Vector2(280, 48), INK)
	text_at(80, ["01 / BUILD YOUR FLEET", "02 / EARN POINTS", "03 / WATCH YOUR HULL"][lesson], 16)
	draw_rect(Rect2(10, 104, 260, 350), INK, false)
	if lesson < 2:
		draw_shooting(action, lesson)
	else:
		draw_contact(action)
	draw_line(Vector2(0, 480), Vector2(280, 480), INK)
	if time >= 5.5:
		var lines: Array = [
			["SHOOT THESE TARGETS", "TO GET MORE SHIPS.", "1 SHIP + 1 = 2 SHIPS"],
			["BREAK ALIEN SHIPS", "TO EARN POINTS.", "HP = HITS REMAINING"],
			["AVOID INTACT TARGETS.", "ONLY SHIPS THEY TOUCH", "ARE LOST. KEEP MOVING!"]][lesson]
		for i: int in range(lines.size()):
			text_at(512 + i * 25, lines[i], 16)
	else:
		text_at(519, "WATCH AND LEARN", 16)
		text_at(546, "FIRE IS AUTOMATIC" if lesson < 2 else "MOVE [W][A][S][D] / [ARROWS]", 14)
	for i: int in range(3):
		draw_circle(Vector2(122 + i * 18, 602), 4, INK if i == lesson else Color("98a580"))
	text_at(648, "PRESS [ENTER] TO PLAY", 18)
	text_at(677, "[P] PAUSE    [M] MUTE", 12)
	text_at(699, "[ENTER] RESTART", 12)

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
	var spread: float = smoothstep(4.5, 5.5, time) if kind == 0 else 0.0
	ship(Vector2(140 - spread * 18, 407))
	if spread > 0:
		ship(Vector2(140 + 18, lerpf(310, 407, spread)))
	if time >= 4.9:
		text_at(312, "+1 SHIP" if kind == 0 else "+50 POINTS", 21)
	text_at(125, "SHIPS  %d" % (2 if kind == 0 and time >= 5.5 else 1), 14)

func draw_contact(time: float) -> void:
	var y: float = lerpf(210, 395, smoothstep(0.7, 4.2, time))
	# Both ships share the player's formation movement; only the left hull is hit.
	var dodge: float = smoothstep(0.7, 2.8, time) * 45
	if time < 5.3:
		target(Vector2(104, y), 5, 1)
	if time < 3.0:
		ship(Vector2(104 + dodge, 407))
	elif time < 3.8:
		explosion(Vector2(104 + dodge, 407), (time - 3.0) / 0.8)
	ship(Vector2(140 + dodge, 407))
	if time >= 4.4:
		text_at(265, "1 SHIP LOST", 20)
		text_at(296, "1 SHIP SURVIVES", 16)

