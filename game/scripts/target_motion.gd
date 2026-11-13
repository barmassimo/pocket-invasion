class_name TargetMotion
extends RefCounted

const Rules = preload("res://scripts/rules.gd")
const RESTITUTION: float = 0.65
const DRIFT_MIN: float = 0.25
const DRIFT_MAX: float = 0.55
const SOLVER_PASSES: int = 16
const CAPTION_CLEARANCE: float = 1.35
const AXES: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2(0.70710678, 0.70710678), Vector2(0.70710678, -0.70710678)]

static func advance(targets: Array[CourseTarget], course_speed: float, delta: float) -> void:
	var fastest: float = 0.0
	for target: CourseTarget in targets:
		target.previous_x = target.position.x
		target.previous_z = target.position.z
		fastest = maxf(fastest, target.velocity.length() + target.travel_speed(course_speed))
	# Small spatial steps keep moving hulls from crossing between collision tests.
	var steps: int = maxi(1, ceili(maxf(delta * 120.0, fastest * delta / 0.15)))
	var dt: float = delta / steps
	for step: int in range(steps):
		for target: CourseTarget in targets:
			target.velocity.y *= exp(-2.5 * dt)
			target.position.x += target.velocity.x * dt
			target.position.z += (target.travel_speed(course_speed) + target.velocity.y) * dt
		for iteration: int in range(SOLVER_PASSES):
			for target: CourseTarget in targets:
				resolve_wall(target)
			for i: int in range(targets.size()):
				for j: int in range(i + 1, targets.size()):
					resolve_pair(targets[i], targets[j], course_speed)
		for target: CourseTarget in targets:
			resolve_wall(target)

static func resolve_wall(target: CourseTarget) -> void:
	var limit: float = maxf(0.0, Rules.ROAD_HALF - target.half.x)
	if absf(target.position.x) >= limit:
		var side: float = 1.0 if target.position.x >= 0 else -1.0
		target.position.x = side * limit
		if target.velocity.x * side > 0.0:
			# The border is immovable (infinite mass); every object bounces inward.
			target.velocity.x *= -RESTITUTION

# The elevated camera projects hull height along the course. Base-only collision
# allowed tall meshes to overlap visibly even when their floor footprints separated.
# Reserve a small gap for the HP caption above each hull as well.
static func projected_height(target: CourseTarget) -> float:
	var camera_offset: Vector3 = Rules.CAMERA_POSITION - Rules.CAMERA_FOCUS
	return target.body.position.y * absf(camera_offset.z / camera_offset.y) + CAPTION_CLEARANCE * 0.5

static func collision_center(target: CourseTarget) -> Vector2:
	return Vector2(target.position.x, target.position.z - projected_height(target))

static func projection_radius(target: CourseTarget, axis: Vector2) -> float:
	return absf(axis.x) * target.half.x + absf(axis.y) * (target.half.y + projected_height(target)) - target.corner_cut * minf(absf(axis.x), absf(axis.y))

static func penetration(a: CourseTarget, b: CourseTarget) -> Vector2:
	var distance: Vector2 = collision_center(b) - collision_center(a)
	if absf(distance.x) >= a.half.x + b.half.x or absf(distance.y) >= a.half.y + b.half.y + projected_height(a) + projected_height(b):
		return Vector2.ZERO
	var depth: float = INF
	var normal := Vector2.ZERO
	# Separating-axis test of the complete projected hull, retaining clipped corners.
	for axis: Vector2 in AXES:
		var overlap: float = projection_radius(a, axis) + projection_radius(b, axis) - absf(distance.dot(axis))
		if overlap <= 0.0:
			return Vector2.ZERO
		if overlap < depth:
			depth = overlap
			normal = axis if distance.dot(axis) >= 0.0 else -axis
	return normal * depth

static func resolve_pair(a: CourseTarget, b: CourseTarget, course_speed: float) -> void:
	var separation: Vector2 = penetration(a, b)
	if separation == Vector2.ZERO:
		return
	var normal: Vector2 = separation.normalized()
	var inverse_a: float = 1.0 / maxi(1, a.hp)
	var inverse_b: float = 1.0 / maxi(1, b.hp)
	var inverse_sum: float = inverse_a + inverse_b
	var correction: Vector2 = separation + normal * 0.00001
	var move_a: Vector2 = -correction * inverse_a / inverse_sum
	var move_b: Vector2 = correction * inverse_b / inverse_sum
	# Transfer blocked correction to the other body rather than clamping it away.
	var clamped_a: float = clampf(a.position.x + move_a.x, -Rules.ROAD_HALF + a.half.x, Rules.ROAD_HALF - a.half.x)
	move_b.x -= move_a.x - (clamped_a - a.position.x)
	move_a.x = clamped_a - a.position.x
	var clamped_b: float = clampf(b.position.x + move_b.x, -Rules.ROAD_HALF + b.half.x, Rules.ROAD_HALF - b.half.x)
	move_a.x -= move_b.x - (clamped_b - b.position.x)
	move_b.x = clamped_b - b.position.x
	a.position += Vector3(move_a.x, 0, move_a.y)
	b.position += Vector3(move_b.x, 0, move_b.y)
	var relative_velocity: Vector2 = b.velocity - a.velocity + Vector2(0, b.travel_speed(course_speed) - a.travel_speed(course_speed))
	var approach: float = relative_velocity.dot(normal)
	if approach < 0.0:
		var impulse: Vector2 = -(1.0 + RESTITUTION) * approach / inverse_sum * normal
		a.velocity -= impulse * inverse_a
		b.velocity += impulse * inverse_b
