class_name RescuePickup
extends Node3D

const Art = preload("res://scripts/target_art.gd")
const Rules = preload("res://scripts/invasion_rules.gd")
const HELP: Texture2D = preload("res://assets/icons/rescue_help.svg")
var reward: int = 1
var previous_position := Vector3.ZERO
var velocity := Vector2.ZERO
var spin: Node3D
var caption: Label3D
var age: float = 0.0
var help_sign: MeshInstance3D

func setup(amount: int, drift: float) -> void:
	reward = amount
	previous_position = position
	velocity = Vector2(clampf(drift * 0.2, -0.20, 0.20), Rules.PICKUP_DRIFT_SPEED)
	# Rotate inside a camera-compensated plane so the fighter keeps its shape.
	var screen_plane := Node3D.new()
	screen_plane.position.y = Art.PLANE_HEIGHT
	screen_plane.scale.z = 1.0 / Art.projection_scale()
	add_child(screen_plane)
	# Keep compensation on the parent: screen_scale * rotation, never the reverse.
	spin = Node3D.new()
	screen_plane.add_child(spin)
	# Match the small formation's projected dimensions before rotating in screen space.
	var projection: float = Art.projection_scale()
	var hull := Art.layer(LcdIcons.SHIP, Vector2(Rules.FIGHTER_SIZE.x, Rules.FIGHTER_SIZE.y * projection * projection), Vector3.ZERO)
	(hull.material_override as StandardMaterial3D).albedo_color = Color("253820")
	spin.add_child(hull)
	caption = Label3D.new()
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.no_depth_test = true
	caption.font_size = 32
	caption.pixel_size = 0.009
	caption.modulate = Color("253820")
	caption.outline_modulate = Color("c4cca5")
	caption.outline_size = 5
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New"])
	font.font_weight = 700
	caption.font = font
	caption.position = Vector3(0, Art.PLANE_HEIGHT, 0.65)
	add_child(caption)
	help_sign = Art.layer(HELP, Vector2(1.05, 0.525), Vector3(0, Art.PLANE_HEIGHT, -0.85))
	help_sign.visible = false
	add_child(help_sign)
	refresh()

func refresh() -> void:
	caption.text = "+%d" % reward

func advance(delta: float) -> void:
	age += delta
	var shown: bool = age < Rules.PICKUP_BLINK_SECONDS or fmod(age - Rules.PICKUP_BLINK_SECONDS, Rules.PICKUP_BLINK_INTERVAL * 2.0) < Rules.PICKUP_BLINK_INTERVAL
	spin.visible = shown
	caption.visible = shown
	help_sign.visible = shown and age >= Rules.PICKUP_BLINK_SECONDS
	previous_position = position
	position.x += velocity.x * delta
	position.z += velocity.y * delta
	var limit: float = Rules.ROAD_HALF - Rules.PICKUP_RADIUS
	if absf(position.x) > limit:
		position.x = clampf(position.x, -limit, limit)
		velocity.x = -velocity.x
	spin.rotation.y += Rules.PICKUP_SPIN_SPEED * delta

func can_be_recaptured() -> bool:
	return age >= Rules.PICKUP_RECAPTURE_SECONDS
