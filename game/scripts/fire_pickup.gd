class_name FirePickup
extends Node3D

const Rules = preload("res://scripts/invasion_rules.gd")
const Art = preload("res://scripts/target_art.gd")
const CORE: Texture2D = preload("res://assets/icons/fire-core.svg")
const AURA: Texture2D = preload("res://assets/icons/alien-aura.svg")
var age: float = 0.0
var previous_position := Vector3.ZERO
var velocity := Vector2.ZERO
var visual: Node3D
var core: MeshInstance3D
var aura: MeshInstance3D
var caption: Label3D

func setup(drift: float) -> void:
	previous_position = position
	velocity = Vector2(clampf(drift * 0.2, -0.20, 0.20), Rules.PICKUP_DRIFT_SPEED)
	visual = Node3D.new()
	add_child(visual)
	# Apply projection compensation outside the rotation, preserving a screen circle.
	var aura_plane := Node3D.new()
	aura_plane.position.y = Art.PLANE_HEIGHT
	aura_plane.scale.z = 1.0 / Art.projection_scale()
	visual.add_child(aura_plane)
	aura = Art.layer(AURA, Vector2(1.12, 1.12 * Art.projection_scale()), Vector3.ZERO)
	aura_plane.add_child(aura)
	core = Art.layer(CORE, Vector2.ONE * 0.64, Vector3(0, Art.PLANE_HEIGHT + 0.01, 0))
	(core.material_override as StandardMaterial3D).render_priority = 1
	visual.add_child(core)
	caption = Label3D.new()
	caption.text = "POW"
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.no_depth_test = true
	caption.font = preload("res://assets/fonts/share-tech-mono/ShareTechMono-Regular.ttf")
	caption.font_size = 36
	caption.pixel_size = 0.009
	caption.modulate = Color("253820")
	caption.outline_modulate = Color("c4cca5")
	caption.outline_size = 5
	caption.position = Vector3(0, Art.PLANE_HEIGHT, 0.82)
	visual.add_child(caption)

func advance(delta: float) -> void:
	age += delta
	previous_position = position
	position.x += velocity.x * delta
	position.z += velocity.y * delta
	var limit: float = Rules.ROAD_HALF - Rules.PICKUP_RADIUS
	if absf(position.x) > limit:
		position.x = clampf(position.x, -limit, limit)
		velocity.x = -velocity.x
	# Translate only: rotating compensated ground planes shears their screen shape.
	visual.position.z = sin(age * 2.5) * 0.06
	# Rotate only the energy inside its compensated plane; the core stays rigid.
	aura.rotation.y = age * 0.6
	(aura.material_override as StandardMaterial3D).albedo_color.a = 0.82 + sin(age * 3.0) * 0.18
	visual.visible = age < Rules.PICKUP_BLINK_SECONDS or fmod(age - Rules.PICKUP_BLINK_SECONDS, Rules.PICKUP_BLINK_INTERVAL * 2.0) < Rules.PICKUP_BLINK_INTERVAL

func expired() -> bool:
	return age >= Rules.PICKUP_BLINK_SECONDS + Rules.BOOST_PICKUP_WARNING
