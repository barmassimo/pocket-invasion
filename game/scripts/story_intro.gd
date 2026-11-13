class_name StoryIntro
extends Control

const INK := Color("253820")
const PAPER := Color("c4cca5")
const Art = preload("res://scripts/target_art.gd")
var font := SystemFont.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font.font_names = PackedStringArray(["Consolas", "Courier New"])
	font.font_weight = 700
	paragraph(60, "FROM COMMAND CENTER", 20)
	paragraph(347, "Command Center to last fighter.\nEarth has fallen. The aliens hold it.", 18)
	paragraph(415, "You are the last fighter in flight.", 18)
	paragraph(459, "One fighter cannot win this war,\nbut our captured pilots are alive.", 18)
	paragraph(523, "Free them. Rebuild your formation.\nWe are holding as long as we can.\nGive Earth a fighting chance.", 18)
	paragraph(666, "WE ARE COUNTING ON YOU.", 19)
	paragraph(715, "[ENTER / SPACE] START", 18)
	paragraph(746, "[D] HOW TO PLAY", 13)

func paragraph(y: float, text: String, size: int) -> void:
	var label := Label.new()
	label.position = Vector2(16, y - size)
	label.size.x = 376
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", INK)
	add_child(label)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 408, 764), PAPER)
	draw_line(Vector2(30, 100), Vector2(378, 100), INK)
	# Flat orbital vignette, using the same clean silhouettes as the course.
	draw_circle(Vector2(141, 210), 72, INK, true, -1, true)
	draw_circle(Vector2(141, 210), 68, PAPER, true, -1, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(96, 163), Vector2(125, 155), Vector2(143, 173),
		Vector2(137, 193), Vector2(157, 207), Vector2(147, 224),
		Vector2(125, 218), Vector2(114, 198), Vector2(91, 191)]), INK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(156, 235), Vector2(181, 223), Vector2(197, 238),
		Vector2(181, 260), Vector2(168, 267)]), INK)
	draw_texture_rect(Art.HULL, Rect2(218, 126, 98, 98), false)
	draw_texture_rect(Art.PILOT, Rect2(248, 151, 38, 48), false)
	draw_texture_rect(LcdIcons.SHIP, Rect2(257, 253, 34, 46), false, INK)
	draw_line(Vector2(30, 315), Vector2(378, 315), INK)
