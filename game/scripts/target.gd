class_name CourseTarget
extends Node3D

const Art = preload("res://scripts/target_art.gd")
var hp: int
var reward: int
var kind: int
var size_tier: int
var half: Vector2
var caption: Label3D
var reward_caption: Label3D
var body: MeshInstance3D
var emblem: MeshInstance3D
var pilots: Array[MeshInstance3D] = []
var flash: float = 0.0
var material: StandardMaterial3D
var velocity := Vector2.ZERO
var recapture_steering: float = 0.0
var previous_x: float
var previous_z: float
var fire_clock: float = InvasionRules.ALIEN_FIRE_DELAY
var shots_fired: int = 0
var assembly_age: float = -1.0
var assembly_captor: WeakRef
var assembly_anchor := Vector3.ZERO
var assembly_radius: float = 0.0
var assembly_side: float = 1.0
var hull_clearance: float = 0.35

func is_assembling() -> bool:
	return assembly_age >= 0.0

func begin_assembly(captor: CourseTarget) -> void:
	assembly_age = 0.0
	assembly_captor = weakref(captor)
	assembly_anchor = captor.position
	assembly_radius = captor.half.x
	assembly_side = -1.0 if captor.position.x > 0.0 else 1.0
	hull_clearance = InvasionRules.RECAPTURE_RELEASE_GAP * 0.5
	velocity.x = captor.velocity.x + assembly_side * InvasionRules.RECAPTURE_RELEASE_DRIFT
	advance_assembly(0.0)
	previous_x = position.x
	previous_z = position.z

func advance_assembly(delta: float) -> void:
	assembly_age += delta
	var captor: CourseTarget = assembly_captor.get_ref() as CourseTarget
	if is_instance_valid(captor):
		assembly_anchor = captor.position
	var growth: float = smoothstep(InvasionRules.RECAPTURE_GROW_START, InvasionRules.RECAPTURE_GROW_END, assembly_age)
	var departure: float = smoothstep(InvasionRules.RECAPTURE_GROW_END, InvasionRules.RECAPTURE_RELEASE_END, assembly_age)
	# Like the intro, the shell closes around the fighter before departure.
	# Keep its growing edge attached to the captor, then open label clearance.
	position = assembly_anchor + Vector3(assembly_side * (assembly_radius + half.x * growth + InvasionRules.RECAPTURE_RELEASE_GAP * departure), 0, 0)
	body.visible = growth > 0.0
	emblem.visible = growth > 0.0
	body.scale = Vector3.ONE * maxf(0.001, growth)
	emblem.scale = body.scale
	caption.visible = growth >= 1.0
	reward_caption.visible = caption.visible
	if assembly_age >= InvasionRules.RECAPTURE_RELEASE_END:
		assembly_age = -1.0
		assembly_captor = null

func setup(type: int, health: int, gain: int, tier: int = 1) -> void:
	kind = type
	size_tier = tier
	previous_x = position.x
	previous_z = position.z
	hp = maxi(InvasionRules.BOOST_MIN_HEALTH, health) if kind == InvasionRules.BOOST_KIND else health
	reward = gain
	var radius: float = 0.90 * InvasionRules.SIZE_SCALES[tier]
	# Compensate the elevated camera so the flat hull reads as a circle on screen.
	half = Vector2(radius, radius / Art.projection_scale())
	body = Art.layer(Art.EGG_HULL if kind == InvasionRules.BOOST_KIND else Art.HULL, Vector2.ONE * radius * 2.0, Vector3(0, Art.PLANE_HEIGHT, 0))
	add_child(body)
	material = body.material_override as StandardMaterial3D
	if kind == 0 or kind == InvasionRules.BOOST_KIND:
		# Hull, captive fighter and clamps scale together, unlike the score pilots.
		emblem = Art.layer(Art.EGG_CORE if kind == InvasionRules.BOOST_KIND else Art.FLEET, Vector2.ONE * radius * 2.0, Vector3(0, Art.PLANE_HEIGHT + 0.002, 0))
		(emblem.material_override as StandardMaterial3D).render_priority = 1
		add_child(emblem)
	else:
		var count: int = Art.crew_count(tier)
		for i: int in range(count):
			var x: float = (i - (count - 1) * 0.5) * Art.PILOT_SPACING
			var pilot := Art.layer(Art.PILOT, Art.PILOT_SIZE, Vector3(x, Art.PLANE_HEIGHT + 0.002, 0))
			(pilot.material_override as StandardMaterial3D).render_priority = 1
			add_child(pilot)
			pilots.append(pilot)
	caption = make_caption(40)
	caption.position = Vector3(0, Art.PLANE_HEIGHT, -half.y - 0.27)
	add_child(caption)
	reward_caption = make_caption(36)
	reward_caption.position = Vector3(0, Art.PLANE_HEIGHT, half.y + 0.23)
	add_child(reward_caption)
	refresh()

func make_caption(font_size: int) -> Label3D:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = font_size
	label.pixel_size = 0.009
	label.modulate = Color("20341f")
	label.outline_modulate = Color("c4cca5")
	label.outline_size = 5
	var lcd_font: Font = preload("res://assets/fonts/share-tech-mono/ShareTechMono-Regular.ttf")
	label.font = lcd_font
	return label

func refresh() -> void:
	caption.text = "HP %d" % hp
	reward_caption.text = "FIRE x2" if kind == InvasionRules.BOOST_KIND else "+%d" % reward

func is_alien() -> bool:
	return kind == 1 or kind == 2

func can_fire() -> bool:
	return is_alien() or kind == InvasionRules.BOOST_KIND

func travel_speed(course_speed: float) -> float:
	return minf(6.4, course_speed) if kind == 0 and size_tier == 0 else course_speed

func hit(damage: int = 1) -> bool:
	hp = maxi(0, hp - damage)
	flash = 0.09
	refresh()
	return hp <= 0

func animate(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	material.albedo_color = Color("92a274") if flash > 0.0 else Color.WHITE
