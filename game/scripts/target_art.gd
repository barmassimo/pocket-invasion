class_name TargetArt
extends RefCounted

# Original flat vector layers. Pilot dimensions are independent of hull scale.
const HULL: Texture2D = preload("res://assets/enemies/hull.svg")
const PILOT: Texture2D = preload("res://assets/enemies/pilot.svg")
const FLEET: Texture2D = preload("res://assets/enemies/fleet.svg")
const EGG_HULL: Texture2D = preload("res://assets/enemies/egg-hull.svg")
const EGG_CORE: Texture2D = preload("res://assets/enemies/egg-core.svg")
const PLANE_HEIGHT: float = 0.35
const PILOT_SIZE := Vector2(0.76, 0.95)
const PILOT_SPACING: float = 0.70

static func projection_scale() -> float:
	var direction: Vector3 = InvasionRules.CAMERA_POSITION - InvasionRules.CAMERA_FOCUS
	return absf(direction.y) / direction.length()

static func crew_count(tier: int) -> int:
	return 3 if tier == 4 else (2 if tier >= 2 else 1)

static func layer(texture: Texture2D, size: Vector2, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(size.x, size.y / projection_scale())
	node.mesh = plane
	node.position = at
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = material
	return node
