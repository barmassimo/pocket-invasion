class_name LcdDisplay
extends Control

signal volume_changed(percent: float)
signal mute_requested

const Rules = preload("res://scripts/invasion_rules.gd")
const Demo = preload("res://scripts/attract_demo.gd")
const Intro = preload("res://scripts/story_intro.gd")
const WINDOW_WIDTH: int = 775
const PLAYFIELD_CENTER_X: float = 550.0
const PAGE_COUNT: int = 3
const INK := Color("253820")
const GHOST := Color(0.16, 0.22, 0.12, 0.09)
const DIGITS: Array[int] = [63, 6, 91, 79, 102, 109, 125, 7, 127, 111]
var demo: AttractDemo
var intro: StoryIntro
var attract_clock: float = 0.0
var attract_active: bool = false
var soldiers: int = 4
var score: int = 0
var seconds: int = 0
var muted: bool = false
var volume_slider: HSlider
var page_navigation: Control
var lcd_font := SystemFont.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lcd_font.font_names = PackedStringArray(["Consolas", "Courier New"])
	lcd_font.font_weight = 700
	demo = Demo.new() as AttractDemo
	demo.position = Vector2(379, 65)
	add_child(demo)
	intro = Intro.new() as StoryIntro
	intro.position = Vector2(349, 18)
	intro.visible = false
	add_child(intro)
	page_navigation = Control.new()
	page_navigation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_navigation)
	page_navigation.draw.connect(draw_page_navigation)
	add_page_button(Vector2(459, 651), Vector2(32, 32), "<", "Previous page (Left arrow)", func() -> void: step_page(-1))
	for page: int in range(PAGE_COUNT):
		add_page_button(Vector2(498 + page * 18, 651), Vector2(18, 32), "", "Page %d" % (page + 1), select_page.bind(page))
	add_page_button(Vector2(559, 651), Vector2(32, 32), ">", "Next page (Right arrow)", func() -> void: step_page(1))
	volume_slider = HSlider.new()
	volume_slider.position = Vector2(87, 742)
	volume_slider.size = Vector2(190, 28)
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 1
	volume_slider.value = 50
	volume_slider.focus_mode = Control.FOCUS_NONE
	volume_slider.mouse_filter = Control.MOUSE_FILTER_STOP
	volume_slider.tooltip_text = "Volume"
	for style_name: String in ["slider", "grabber_area", "grabber_area_highlight"]:
		var track := StyleBoxFlat.new()
		track.bg_color = Color("98a580") if style_name == "slider" else INK
		track.content_margin_top = 1.5
		track.content_margin_bottom = 1.5
		track.corner_radius_top_left = 2
		track.corner_radius_top_right = 2
		track.corner_radius_bottom_left = 2
		track.corner_radius_bottom_right = 2
		volume_slider.add_theme_stylebox_override(style_name, track)
	for icon_name: String in ["grabber", "grabber_highlight", "grabber_disabled"]:
		volume_slider.add_theme_icon_override(icon_name, preload("res://assets/icons/volume_knob.svg"))
	volume_slider.value_changed.connect(func(value: float) -> void: volume_changed.emit(value))
	add_child(volume_slider)
	var speaker_button := Button.new()
	speaker_button.position = Vector2(40, 740)
	speaker_button.size = Vector2(40, 30)
	speaker_button.flat = true
	speaker_button.focus_mode = Control.FOCUS_NONE
	speaker_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_name: String in ["normal", "hover", "pressed", "focus"]:
		speaker_button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	speaker_button.pressed.connect(func() -> void: mute_requested.emit())
	add_child(speaker_button)

func set_playing(playing: bool) -> void:
	attract_active = not playing
	page_navigation.visible = not playing
	attract_clock = 0.0
	demo.set_playing(true)
	intro.animation_time = 0.0
	intro.visible = not playing
	page_navigation.queue_redraw()
	set_process(not playing)
	queue_redraw()

func add_page_button(at: Vector2, bounds: Vector2, text: String, hint: String, action: Callable) -> void:
	var button := Button.new()
	button.position = at
	button.size = bounds
	button.text = text
	button.tooltip_text = hint
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", lcd_font)
	button.add_theme_font_size_override("font_size", 24)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color_name, INK)
	for style_name: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	button.pressed.connect(action)
	page_navigation.add_child(button)

func current_page() -> int:
	return 0 if attract_clock < Intro.LOOP_SECONDS else 1 + floori((attract_clock - Intro.LOOP_SECONDS) / Demo.LESSON_SECONDS)

func step_page(direction: int) -> void:
	select_page(posmod(current_page() + direction, PAGE_COUNT))

func select_page(page: int) -> void:
	if not attract_active:
		return
	var selected: int = posmod(page, PAGE_COUNT)
	attract_clock = 0.0 if selected == 0 else Intro.LOOP_SECONDS + (selected - 1) * Demo.LESSON_SECONDS
	intro.animation_time = 0.0
	_process(0.0)

func page_remaining_fraction() -> float:
	if current_page() == 0:
		return 1.0 - attract_clock / Intro.LOOP_SECONDS
	return 1.0 - fposmod(attract_clock - Intro.LOOP_SECONDS, Demo.LESSON_SECONDS) / Demo.LESSON_SECONDS

func draw_page_navigation() -> void:
	for page: int in range(PAGE_COUNT):
		page_navigation.draw_circle(Vector2(507 + page * 18, 667), 4, INK if page == current_page() else Color("98a580"))
	# A quiet, unlabelled countdown drains toward the fixed left edge.
	page_navigation.draw_rect(Rect2(607, 666, 48, 2), Color("b0bb94"))
	page_navigation.draw_rect(Rect2(607, 666, 48 * page_remaining_fraction(), 2), Color("65734a"))

func _process(delta: float) -> void:
	if not attract_active:
		return
	attract_clock = fposmod(attract_clock + delta, Intro.LOOP_SECONDS + Demo.LOOP_SECONDS)
	intro.visible = attract_clock < Intro.LOOP_SECONDS
	demo.visible = not intro.visible
	if demo.visible:
		demo.clock = attract_clock - Intro.LOOP_SECONDS
		demo.queue_redraw()
	page_navigation.queue_redraw()
	queue_redraw()

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
	caption(Vector2(46, 47), "POCKET INVASION", 19)
	caption(Vector2(46, 70), "HANDHELD COMBAT SYSTEM", 12)
	caption(Vector2(46, 98), "SHIPS")
	segment_text("%02d" % soldiers, Vector2(47, 109), 34)
	caption(Vector2(46, 171), "SCORE")
	segment_text("%07d" % score, Vector2(47, 181), 34)
	caption(Vector2(46, 244), "MISSION TIME")
	segment_text("%02d:%02d" % [seconds / 60, seconds % 60], Vector2(47, 254), 34)
	draw_line(Vector2(46, 403), Vector2(329, 403), INK)
	caption(Vector2(46, 427), "THREAT LEVEL")
	segment_text("%02d" % Rules.threat_level(float(seconds)), Vector2(47, 443), 34)
	draw_line(Vector2(46, 626), Vector2(329, 626), INK)
	draw_set_transform(Vector2(46, 745.5), 0.0, Vector2(0.75, 0.75))
	draw_speaker(Vector2.ZERO)
	draw_set_transform(Vector2.ZERO)

func draw_speaker(at: Vector2) -> void:
	# A compact filled speaker with sound waves or a mute cross.
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, 8), at + Vector2(7, 8), at + Vector2(17, 0),
		at + Vector2(17, 28), at + Vector2(7, 20), at + Vector2(0, 20)
	]), INK)
	if muted:
		draw_line(at + Vector2(23, 8), at + Vector2(35, 20), INK, 3, true)
		draw_line(at + Vector2(23, 20), at + Vector2(35, 8), INK, 3, true)
	else:
		draw_arc(at + Vector2(15, 14), 11, -PI / 3, PI / 3, 16, INK, 2, true)
		draw_arc(at + Vector2(15, 14), 19, -PI / 3, PI / 3, 24, INK, 2, true)

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


