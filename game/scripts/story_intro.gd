class_name StoryIntro
extends Control

const INK := Color("253820")
const PAPER := Color("c4cca5")
const Art = preload("res://scripts/target_art.gd")
const LOOP_SECONDS: float = 13.0
const START_DELAY: float = 1.6
const MID := Color("65734a")
var font: Font = preload("res://assets/fonts/share-tech-mono/ShareTechMono-Regular.ttf")
var animation_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		animation_time = 0.0
		return
	animation_time = fmod(animation_time + delta, LOOP_SECONDS)
	queue_redraw()

func paragraph(y: float, text: String, size: int) -> void:
	# Fixed baselines keep the paragraph clear of page navigation.
	var lines: PackedStringArray = text.split("\n")
	for i: int in range(lines.size()):
		draw_string(font, Vector2(16, y + i * 21), lines[i], HORIZONTAL_ALIGNMENT_CENTER, 326, size, INK)

func _draw() -> void:
	paragraph(60, "FROM COMMAND CENTER", 20)
	paragraph(360, "Earth has fallen.\nThe aliens hold it.\n\nYou are the last fighter\nstill in flight.\n\nOur captured pilots are alive.\n\nFree them. Rebuild your formation.\nWe are holding as long as we can.\nGive Earth a fighting chance.\n\nWE ARE COUNTING ON YOU.", 17)
	draw_line(Vector2(25, 100), Vector2(333, 100), INK)
	draw_rect(Rect2(112, 79, 134, 24), INK)
	draw_string(font, Vector2(122, 96), "TOP SECRET", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, PAPER)
	# Flat orbital vignette. Only the illustration animates; the briefing stays still.
	draw_set_transform(Vector2(-25, 0))
	draw_circle(Vector2(141, 210), 72, INK, true, -1, true)
	draw_circle(Vector2(141, 210), 68, PAPER, true, -1, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(96, 163), Vector2(125, 155), Vector2(143, 173),
		Vector2(137, 193), Vector2(157, 207), Vector2(147, 224),
		Vector2(125, 218), Vector2(114, 198), Vector2(91, 191)]), INK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(156, 235), Vector2(181, 223), Vector2(197, 238),
		Vector2(181, 260), Vector2(168, 267)]), INK)
	draw_capture_sequence()
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(25, 315), Vector2(333, 315), INK)

func draw_capture_sequence() -> void:
	var t: float = animation_time - START_DELAY
	var capture: float = smoothstep(0.0, 2.4, t)
	var conversion: float = smoothstep(2.7, 4.5, t)
	var departure: float = smoothstep(6.2, 8.5, t)
	var fighter := Vector2(267, 276).lerp(Vector2(267, 239), capture)
	# A solid-color scan beam and moving rings pull the fighter into containment.
	if t >= 0.0 and t < 4.5:
		var half_width: float = lerpf(24.0, 33.0, capture)
		draw_colored_polygon(PackedVector2Array([
			Vector2(248, 209), Vector2(286, 209),
			fighter + Vector2(half_width, 23), fighter + Vector2(-half_width, 23)]), MID)
		for i: int in range(3):
			var scan: float = fmod(t * 0.6 + float(i) / 3.0, 1.0)
			var y: float = lerpf(fighter.y + 20, 213.0, scan)
			draw_line(Vector2(244, y), Vector2(290, y), PAPER, 2.0, true)
	draw_texture_rect(Art.HULL, Rect2(218, 126, 98, 98), false)
	draw_texture_rect(Art.PILOT, Rect2(248, 151, 38, 48), false)
	if conversion < 1.0:
		# The recognizable fighter contracts as the rounded shell closes around it.
		var size := Vector2(34, 46) * lerpf(1.0, 0.42, conversion)
		draw_texture_rect(LcdIcons.SHIP, Rect2(fighter - size * 0.5, size), false, INK)
	if conversion > 0.0:
		var center := fighter + Vector2(70, -40) * departure
		draw_captive_ship(center, conversion)
	var caption: String = "EARTH / OCCUPIED"
	if t >= 0.0 and t < 2.7:
		caption = "FIGHTER CAPTURED"
	elif t >= 2.7 and t < 4.5:
		caption = "ALIEN CONVERSION"
	elif t >= 4.5:
		caption = "PILOT / CAPTIVE"
	draw_string(font, Vector2(30, 309), caption, HORIZONTAL_ALIGNMENT_CENTER, 348, 12, INK)

func draw_captive_ship(center: Vector2, growth: float) -> void:
	# Reuse the exact hull and containment emblem of the rescue targets.
	var size := Vector2(60, 60) * growth
	var bounds := Rect2(center - size * 0.5, size)
	draw_texture_rect(Art.HULL, bounds, false)
	draw_texture_rect(Art.FLEET, bounds, false)
