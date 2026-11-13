class_name CourseTarget
extends Node3D

var hp: int
var reward: int
var kind: int
var size_tier: int
var half: Vector2
var caption: Label3D
var body: MeshInstance3D
var flash: float = 0.0
var material: StandardMaterial3D
var base_color: Color
var velocity := Vector2.ZERO
var previous_x: float
var previous_z: float
var reward_caption: Label3D
var corner_cut: float

func setup(type: int, health: int, gain: int, tier: int = 1) -> void:
	kind = type
	size_tier = tier
	previous_x = position.x
	previous_z = position.z
	var size_scale: float = SquadRules.SIZE_SCALES[tier]
	hp = health
	reward = gain
	half = Vector2(0.90, 0.45) if kind != 2 else Vector2(0.65, 0.5)
	half *= size_scale
	corner_cut = minf(half.x, half.y) * (0.42 if kind == 2 else 0.28)
	base_color = [Color("4a5e37"), Color("2d4027"), Color("65734a")][kind]
	material = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	body = MeshInstance3D.new()
	body.mesh = hull_mesh(1.2 * size_scale)
	body.material_override = material
	body.position.y = 0.6 * size_scale
	add_child(body)
	caption = Label3D.new()
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.no_depth_test = true
	caption.font_size = 48
	caption.pixel_size = 0.009
	caption.modulate = Color("20341f")
	caption.outline_modulate = Color("c4cca5")
	caption.outline_size = 8
	var lcd_font := SystemFont.new()
	lcd_font.font_names = PackedStringArray(["Consolas", "Courier New"])
	lcd_font.font_weight = 700
	caption.font = lcd_font
	caption.position.y = 1.2 * size_scale + 1.15
	add_child(caption)
	var symbol := Sprite3D.new()
	symbol.texture = LcdIcons.target(kind)
	symbol.pixel_size = 0.0085 * size_scale
	symbol.modulate = Color("c4cca5")
	symbol.no_depth_test = true
	symbol.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	symbol.position.y = 0.90 * size_scale
	add_child(symbol)
	reward_caption = Label3D.new()
	reward_caption.font = lcd_font
	reward_caption.font_size = 40
	reward_caption.pixel_size = 0.009
	reward_caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	reward_caption.no_depth_test = true
	reward_caption.modulate = Color("c4cca5")
	reward_caption.outline_modulate = base_color
	reward_caption.outline_size = 3
	reward_caption.position = Vector3(0, 0.24 * size_scale, 0)
	add_child(reward_caption)
	if tier >= 3:
		for stripe: int in range(tier - 1):
			var bar := MeshInstance3D.new()
			var bar_mesh := BoxMesh.new()
			bar_mesh.size = Vector3(0.08, 0.14, half.y * 2.05)
			bar.mesh = bar_mesh
			var stripe_mat := StandardMaterial3D.new()
			stripe_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			stripe_mat.albedo_color = Color("b7c096")
			bar.material_override = stripe_mat
			bar.position = Vector3(half.x * 0.84, 0.25 + stripe * 0.22, 0)
			add_child(bar)
	refresh()

func hull_mesh(height: float) -> ArrayMesh:
	# An extruded eight-sided hull gives every crate clipped, readable corners.
	var x: float = half.x
	var z: float = half.y
	var c: float = corner_cut
	var points: Array[Vector2] = [Vector2(-x + c, -z), Vector2(x - c, -z), Vector2(x, -z + c), Vector2(x, z - c), Vector2(x - c, z), Vector2(-x + c, z), Vector2(-x, z - c), Vector2(-x, -z + c)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.UP)
	for i: int in range(points.size()):
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		var at := Vector3(a.x, height / 2.0, a.y)
		var bt := Vector3(b.x, height / 2.0, b.y)
		var ab := Vector3(a.x, -height / 2.0, a.y)
		var bb := Vector3(b.x, -height / 2.0, b.y)
		for vertex: Vector3 in [Vector3(0, height / 2.0, 0), at, bt, Vector3(0, -height / 2.0, 0), bb, ab, at, ab, bb, at, bb, bt]:
			surface.add_vertex(vertex)
	return surface.commit()

func refresh() -> void:
	caption.text = "HP %d" % hp
	reward_caption.text = "+%d" % reward

func travel_speed(course_speed: float) -> float:
	return minf(6.4, course_speed) if kind == 0 and size_tier == 0 else course_speed

func hit(damage: int = 1) -> bool:
	hp = maxi(0, hp - damage)
	flash = 0.09
	refresh()
	return hp <= 0

func animate(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	material.albedo_color = Color("92a274") if flash > 0.0 else base_color
