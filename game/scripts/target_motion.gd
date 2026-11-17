class_name TargetMotion
extends RefCounted

const Rules = preload("res://scripts/invasion_rules.gd")
const RESTITUTION: float = 0.65
const DRIFT_MIN: float = 0.25
const DRIFT_MAX: float = 0.55
const SOLVER_PASSES: int = 16
const CAPTION_CLEARANCE: float = 0.35

static func advance(targets: Array[CourseTarget], course_speed: float, delta: float, pickups: Array[RescuePickup] = []) -> void:
	var fastest: float = 0.0
	for target: CourseTarget in targets:
		target.previous_x = target.position.x
		target.previous_z = target.position.z
		fastest = maxf(fastest, target.velocity.length() + target.travel_speed(course_speed) + Rules.RECAPTURE_SEEK_SPEED)
	# Small spatial steps keep moving hulls from crossing between collision tests.
	var steps: int = maxi(1, ceili(maxf(delta * 120.0, fastest * delta / 0.15)))
	var dt: float = delta / steps
	for step: int in range(steps):
		for target: CourseTarget in targets:
			var steering: float = seek_pickup(target, pickups, course_speed)
			target.recapture_steering = move_toward(target.recapture_steering, steering, Rules.RECAPTURE_SEEK_ACCELERATION * dt)
			target.velocity.y *= exp(-2.5 * dt)
			target.position.x += (target.velocity.x + target.recapture_steering) * dt
			target.position.z += (target.travel_speed(course_speed) + target.velocity.y) * dt
		for iteration: int in range(SOLVER_PASSES):
			for target: CourseTarget in targets:
				resolve_wall(target)
			for i: int in range(targets.size()):
				for j: int in range(i + 1, targets.size()):
					resolve_pair(targets[i], targets[j], course_speed)
		for target: CourseTarget in targets:
			resolve_wall(target)

static func seek_pickup(target: CourseTarget, pickups: Array[RescuePickup], course_speed: float) -> float:
	if target.kind == 0:
		return 0.0
	var nearest: RescuePickup = null
	var nearest_distance: float = INF
	for pickup: RescuePickup in pickups:
		if not pickup.can_be_recaptured() or pickup.position.z < target.position.z:
			continue
		var offset := Vector2(pickup.position.x - target.position.x, (pickup.position.z - target.position.z) * TargetArt.projection_scale())
		var distance: float = offset.length()
		if distance <= target.half.x + Rules.PICKUP_RADIUS + Rules.RECAPTURE_SEEK_RANGE and distance < nearest_distance:
			nearest = pickup
			nearest_distance = distance
	if nearest == null:
		return 0.0
	# Only a shallow lateral correction; forward travel and collision drift remain.
	var limit: float = minf(Rules.RECAPTURE_SEEK_SPEED, course_speed * 0.18)
	return clampf((nearest.position.x - target.position.x) * 2.0, -limit, limit)

static func resolve_wall(target: CourseTarget) -> void:
	var limit: float = maxf(0.0, Rules.ROAD_HALF - target.half.x)
	if absf(target.position.x) >= limit:
		var side: float = 1.0 if target.position.x >= 0 else -1.0
		target.position.x = side * limit
		if target.recapture_steering * side > 0.0:
			target.recapture_steering = 0.0
		if target.velocity.x * side > 0.0:
			# The border is immovable (infinite mass); every object bounces inward.
			target.velocity.x *= -RESTITUTION

static func penetration(a: CourseTarget, b: CourseTarget) -> Vector2:
	# All hulls have the same camera-compensated ellipse aspect ratio. In this
	# metric they are circles, so pair separation is exact even on curved edges.
	# A small presentation gap reserves space for HP and reward labels.
	var projection: float = TargetArt.projection_scale()
	var distance := Vector2(b.position.x - a.position.x, (b.position.z - a.position.z) * projection)
	var depth: float = a.half.x + b.half.x + CAPTION_CLEARANCE * 2.0 - distance.length()
	if depth <= 0.0:
		return Vector2.ZERO
	var normal: Vector2 = distance.normalized() if distance.length_squared() > 0.000001 else Vector2.RIGHT
	return Vector2(normal.x, normal.y / projection) * depth

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
	var relative_velocity: Vector2 = b.velocity - a.velocity + Vector2(b.recapture_steering - a.recapture_steering, b.travel_speed(course_speed) - a.travel_speed(course_speed))
	var approach: float = relative_velocity.dot(normal)
	if approach < 0.0:
		var impulse: Vector2 = -(1.0 + RESTITUTION) * approach / inverse_sum * normal
		a.velocity -= impulse * inverse_a
		b.velocity += impulse * inverse_b
