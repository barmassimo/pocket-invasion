class_name LcdDisplay
extends Control

signal volume_changed(percent: float)
signal mute_requested
signal name_confirmed(player_name: String)

const Rules = preload("res://scripts/invasion_rules.gd")
const Demo = preload("res://scripts/attract_demo.gd")
const Intro = preload("res://scripts/story_intro.gd")
const Info = preload("res://scripts/build_info.gd")
const WINDOW_WIDTH: int = 725
const PLAYFIELD_CENTER_X: float = 528.0
const PLAYFIELD_RECT := Rect2(359, 27, 338, 746)
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
var speaker_button: Button
var page_navigation: Control
var version_label: LinkButton
var lcd_font: Font = ThemeDB.fallback_font
var high_scores: LocalHighScores
var entering_name: bool = false
var name_buffer: String = ""
var name_cursor: int = 0
var entry_score: int = 0
var entry_rank: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	demo = Demo.new() as AttractDemo
	demo.position = Vector2(374, 65)
	add_child(demo)
	intro = Intro.new() as StoryIntro
	intro.position = Vector2(349, 18)
	intro.visible = false
	add_child(intro)
	page_navigation = Control.new()
	page_navigation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_navigation)
	page_navigation.draw.connect(draw_page_navigation)
	add_page_button(Vector2(434, 651), Vector2(32, 32), "<", "Previous page (Left arrow)", func() -> void: step_page(-1))
	for page: int in range(PAGE_COUNT):
		add_page_button(Vector2(473 + page * 18, 651), Vector2(18, 32), "", "Page %d" % (page + 1), select_page.bind(page))
	add_page_button(Vector2(534, 651), Vector2(32, 32), ">", "Next page (Right arrow)", func() -> void: step_page(1))
	volume_slider = HSlider.new()
	volume_slider.position = Vector2(87, 709)
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
	speaker_button = Button.new()
	speaker_button.position = Vector2(29, 707)
	speaker_button.size = Vector2(40, 30)
	speaker_button.flat = true
	speaker_button.focus_mode = Control.FOCUS_NONE
	speaker_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style_name: String in ["normal", "hover", "pressed", "focus"]:
		speaker_button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	speaker_button.pressed.connect(func() -> void: mute_requested.emit())
	add_child(speaker_button)
	var identity: Dictionary = Info.current()
	version_label = LinkButton.new()
	version_label.focus_mode = Control.FOCUS_NONE
	version_label.underline = LinkButton.UNDERLINE_MODE_ON_HOVER
	version_label.position = Vector2(46, 747)
	version_label.size = Vector2(283, 22)
	version_label.text = Info.label(identity)
	version_label.add_theme_font_override("font", lcd_font)
	version_label.add_theme_font_size_override("font_size", 12)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		version_label.add_theme_color_override(color_name, INK)
	version_label.mouse_filter = Control.MOUSE_FILTER_PASS
	version_label.tooltip_text = "Source commit: %s" % identity.get("commit", "unavailable")
	if identity.get("modified", false):
		version_label.tooltip_text += "\nLocal changes beyond this commit are included."
	var project_url: String = identity.get("repository_url", "")
	version_label.disabled = project_url.is_empty()
	if not project_url.is_empty():
		version_label.tooltip_text += "\nOpen project: %s" % project_url
		version_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		version_label.pressed.connect(func() -> void: OS.shell_open(project_url))
	add_child(version_label)
	print("BUILD_IDENTITY=", version_label.text)

func set_playing(playing: bool) -> void:
	entering_name = false
	volume_slider.visible = playing
	speaker_button.visible = playing
	attract_active = not playing
	page_navigation.visible = not playing
	attract_clock = 0.0
	demo.set_playing(true)
	intro.animation_time = 0.0
	intro.visible = not playing
	page_navigation.queue_redraw()
	set_process(not playing)
	queue_redraw()

func begin_name_entry(points: int, rank: int) -> void:
	set_playing(true)
	entering_name = true
	entry_score = points
	entry_rank = rank
	name_buffer = " ".repeat(LocalHighScores.NAME_LENGTH)
	name_cursor = 0
	queue_redraw()

func handle_name_key(event: InputEventKey) -> void:
	if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		if not event.echo:
			name_confirmed.emit(name_buffer)
		return
	match event.keycode:
		KEY_LEFT:
			name_cursor = posmod(name_cursor - 1, LocalHighScores.NAME_LENGTH)
		KEY_RIGHT:
			name_cursor = posmod(name_cursor + 1, LocalHighScores.NAME_LENGTH)
		KEY_UP, KEY_DOWN:
			var index: int = LocalHighScores.ALPHABET.find(name_buffer[name_cursor])
			index = posmod(index + (1 if event.keycode == KEY_UP else -1), LocalHighScores.ALPHABET.length())
			replace_name_character(LocalHighScores.ALPHABET[index])
		KEY_BACKSPACE:
			name_cursor = maxi(0, name_cursor - 1)
			replace_name_character(" ")
		KEY_DELETE:
			replace_name_character(" ")
		KEY_HOME:
			name_cursor = 0
		KEY_END:
			name_cursor = mini(name_buffer.strip_edges().length(), LocalHighScores.NAME_LENGTH - 1)
		_:
			if event.unicode >= 32 and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed:
				var character: String = String.chr(event.unicode).to_upper()
				if character.length() == 1 and character in LocalHighScores.ALPHABET:
					replace_name_character(character)
					name_cursor = mini(name_cursor + 1, LocalHighScores.NAME_LENGTH - 1)
	queue_redraw()

func replace_name_character(character: String) -> void:
	name_buffer = name_buffer.substr(0, name_cursor) + character + name_buffer.substr(name_cursor + 1)

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
		page_navigation.draw_circle(Vector2(482 + page * 18, 667), 4, INK if page == current_page() else Color("98a580"))
	# A quiet, unlabelled countdown drains toward the fixed left edge.
	page_navigation.draw_rect(Rect2(582, 666, 48, 2), Color("b0bb94"))
	page_navigation.draw_rect(Rect2(582, 666, 48 * page_remaining_fraction(), 2), Color("65734a"))

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
	# Hide the 3D course everywhere outside the light panel, including beneath
	# the HUD and the gaps between the bezel strokes.
	var margin_color := Color("bdc79f")
	draw_rect(Rect2(0, 0, PLAYFIELD_RECT.position.x, 800), margin_color)
	draw_rect(Rect2(PLAYFIELD_RECT.end.x, 0, WINDOW_WIDTH - PLAYFIELD_RECT.end.x, 800), margin_color)
	draw_rect(Rect2(PLAYFIELD_RECT.position.x, 0, PLAYFIELD_RECT.size.x, PLAYFIELD_RECT.position.y), margin_color)
	draw_rect(Rect2(PLAYFIELD_RECT.position.x, PLAYFIELD_RECT.end.y, PLAYFIELD_RECT.size.x, 800 - PLAYFIELD_RECT.end.y), margin_color)
	# The course and attract pages share the same surrounding margin.
	if intro.visible or demo.visible or entering_name:
		draw_rect(PLAYFIELD_RECT, Color("c4cca5"))
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
	if attract_active or entering_name:
		draw_high_scores()
	else:
		draw_game_status()
	if entering_name:
		draw_name_entry()
	if not attract_active:
		draw_set_transform(Vector2(46, 714.6), 0.0, Vector2(0.60, 0.60))
		draw_speaker(Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)

func draw_game_status() -> void:
	caption(Vector2(46, 98), "SHIPS")
	segment_text("%02d" % soldiers, Vector2(47, 109), 34)
	caption(Vector2(46, 171), "SCORE")
	segment_text("%07d" % score, Vector2(47, 181), 34)
	caption(Vector2(46, 244), "MISSION TIME")
	segment_text("%02d:%02d" % [seconds / 60, seconds % 60], Vector2(47, 254), 34)
	draw_line(Vector2(46, 403), Vector2(329, 403), INK)
	caption(Vector2(46, 427), "LEVEL")
	segment_text("%02d" % Rules.threat_level(float(seconds)), Vector2(47, 443), 34)
	draw_line(Vector2(46, 626), Vector2(329, 626), INK)

func draw_high_scores() -> void:
	caption(Vector2(46, 108), "TOP 10", 20)
	caption(Vector2(46, 132), "PILOT", 12)
	caption(Vector2(276, 132), "SCORE", 12)
	draw_line(Vector2(46, 143), Vector2(329, 143), INK)
	if high_scores != null:
		for i: int in range(high_scores.entries.size()):
			var row: Dictionary = high_scores.entries[i]
			var y: float = 169 + i * 28
			caption(Vector2(46, y), "%02d" % (i + 1), 14)
			caption(Vector2(78, y), row.name, 16)
			draw_string(lcd_font, Vector2(216, y), str(row.score), HORIZONTAL_ALIGNMENT_RIGHT, 112, 16, INK)
	draw_line(Vector2(46, 440), Vector2(329, 440), INK)
	caption(Vector2(46, 471), "HOW TO PLAY", 20)
	var lines: Array[String] = ["[ENTER / SPACE] START", "[WASD / ARROWS] MOVE", "FIRE IS AUTOMATIC", "[P] PAUSE   [M] MUTE", "[F / F11] FULLSCREEN", "[ESC] EXIT FULLSCREEN"]
	for i: int in range(lines.size()):
		caption(Vector2(46, 505 + i * 27), lines[i], 15)

func draw_name_entry() -> void:
	draw_string(lcd_font, Vector2(374, 186), "TOP 10 / WELL DONE!", HORIZONTAL_ALIGNMENT_CENTER, 308, 22, INK)
	draw_string(lcd_font, Vector2(374, 230), "RANK %02d   SCORE %d" % [entry_rank + 1, entry_score], HORIZONTAL_ALIGNMENT_CENTER, 308, 17, INK)
	draw_line(Vector2(384, 261), Vector2(672, 261), INK)
	draw_string(lcd_font, Vector2(374, 309), "ENTER YOUR NAME", HORIZONTAL_ALIGNMENT_CENTER, 308, 20, INK)
	for i: int in range(LocalHighScores.NAME_LENGTH):
		var x: float = 385 + i * 24
		if i == name_cursor:
			draw_rect(Rect2(x - 2, 338, 22, 37), INK)
		draw_string(lcd_font, Vector2(x, 365), name_buffer[i] if name_buffer[i] != " " else "_", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("c4cca5") if i == name_cursor else INK)
	var lines: Array[String] = ["TYPE OR USE THE ARROWS", "[UP / DOWN] CHANGE LETTER", "[LEFT / RIGHT] MOVE CURSOR", "[BACKSPACE] ERASE", "[ENTER] SAVE & RETURN"]
	for i: int in range(lines.size()):
		draw_string(lcd_font, Vector2(374, 437 + i * 34), lines[i], HORIZONTAL_ALIGNMENT_CENTER, 308, 16, INK)

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


