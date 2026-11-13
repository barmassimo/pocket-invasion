class_name LcdDisplay
extends Control

const Rules = preload("res://scripts/rules.gd")
const Demo = preload("res://scripts/attract_demo.gd")
const WINDOW_WIDTH: int = 775
const PLAYFIELD_CENTER_X: float = 550.0
const INK := Color("253820")
const GHOST := Color(0.16, 0.22, 0.12, 0.09)
const DIGITS: Array[int] = [63, 6, 91, 79, 102, 109, 125, 7, 127, 111]
var demo: AttractDemo
var soldiers: int = 4
var score: int = 0
var seconds: int = 0
var lcd_font := SystemFont.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lcd_font.font_names = PackedStringArray(["Consolas", "Courier New"])
	lcd_font.font_weight = 700
	demo = Demo.new() as AttractDemo
	demo.position = Vector2(PLAYFIELD_CENTER_X - 140, 65)
	add_child(demo)

func set_playing(playing: bool) -> void:
	demo.set_playing(playing)

func update_status(count: int, points: int, time: float) -> void:
	soldiers = count
	score = points
	seconds = floori(time)
	queue_redraw()

func caption(at: Vector2, text: String, size: int = 15) -> void:
	draw_string(lcd_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)

func _draw() -> void:
	# The same screen shows either the live course or the attract sequence.
	if demo.visible:
		draw_rect(Rect2(349, 18, 408, 764), Color("c4cca5"))
	# Passive-matrix texture, not CRT scanlines. Drawn once per HUD update.
	for x: int in range(18, WINDOW_WIDTH - 17, 5):
		draw_line(Vector2(x, 18), Vector2(x, 782), Color(0.15, 0.22, 0.1, 0.025))
	for y: int in range(18, 783, 5):
		draw_line(Vector2(18, y), Vector2(WINDOW_WIDTH - 18, y), Color(0.15, 0.22, 0.1, 0.025))
	draw_rect(Rect2(0, 0, WINDOW_WIDTH, 800), Color("394135"), false, 22.0)
	draw_rect(Rect2(17, 17, WINDOW_WIDTH - 34, 766), Color("6b7556"), false, 3.0)
	draw_rect(Rect2(27, 27, 321, 746), INK, false, 1.0)
	for at: Vector2 in [Vector2(9, 9), Vector2(WINDOW_WIDTH - 9, 9), Vector2(9, 791), Vector2(WINDOW_WIDTH - 9, 791)]:
		draw_circle(at, 3, Color("161d13"))
	caption(Vector2(46, 47), "STAR FLEET / LCD", 19)
	caption(Vector2(46, 70), "HANDHELD COMBAT SYSTEM", 12)
	caption(Vector2(46, 98), "SHIPS / CAPACITY")
	segment_text("%02d/%02d" % [soldiers, Rules.MAX_SOLDIERS], Vector2(47, 109), 34)
	caption(Vector2(46, 171), "SCORE")
	segment_text("%07d" % score, Vector2(47, 181), 34)
	caption(Vector2(46, 244), "SURVIVAL TIME")
	segment_text("%02d:%02d" % [seconds / 60, seconds % 60], Vector2(47, 254), 34)
	draw_line(Vector2(46, 403), Vector2(329, 403), INK)
	caption(Vector2(46, 427), "THREAT LEVEL")
	segment_text("%02d" % Rules.threat_level(float(seconds)), Vector2(47, 443), 34)
	draw_line(Vector2(46, 626), Vector2(329, 626), INK)

func segment_text(text: String, at: Vector2, height: float) -> void:
	var cursor: Vector2 = at
	for character: String in text:
		if character == ":":
			draw_circle(cursor + Vector2(height * 0.12, height * 0.32), height * 0.045, INK)
			draw_circle(cursor + Vector2(height * 0.12, height * 0.72), height * 0.045, INK)
			cursor.x += height * 0.28
		elif character == "/":
			draw_line(cursor + Vector2(height * 0.25, 0), cursor + Vector2(0, height), INK, 2.0)
			cursor.x += height * 0.38
		else:
			var mask: int = DIGITS[character.to_int()]
			var width: float = height * 0.49
			var thickness: float = height * 0.095
			var edges: Array[Vector4] = [Vector4(0, 0, width, 0), Vector4(width, 0, width, height / 2), Vector4(width, height / 2, width, height), Vector4(0, height, width, height), Vector4(0, height / 2, 0, height), Vector4(0, 0, 0, height / 2), Vector4(0, height / 2, width, height / 2)]
			for i: int in range(7):
				var edge: Vector4 = edges[i]
				var a: Vector2 = cursor + Vector2(edge.x, edge.y)
				var b: Vector2 = cursor + Vector2(edge.z, edge.w)
				var inset: Vector2 = (b - a).normalized() * thickness * 0.65
				draw_line(a + inset, b - inset, INK if mask & (1 << i) else GHOST, thickness)
			cursor.x += height * 0.66


