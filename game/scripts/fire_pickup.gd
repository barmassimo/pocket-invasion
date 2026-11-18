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
	aura = Art.layer(AURA, Vector2.ONE * 1.12, Vector3(0, Art.PLANE_HEIGHT, 0))
	visual.add_child(aura)
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
	# Rock and float without hiding the recognizable human module's face.
	visual.position.z = sin(age * 2.5) * 0.06
	visual.rotation.y = sin(age * 1.7) * 0.08
	visual.visible = age < Rules.PICKUP_BLINK_SECONDS or fmod(age - Rules.PICKUP_BLINK_SECONDS, Rules.PICKUP_BLINK_INTERVAL * 2.0) < Rules.PICKUP_BLINK_INTERVAL

func expired() -> bool:
	return age >= Rules.PICKUP_BLINK_SECONDS + Rules.BOOST_PICKUP_WARNING
