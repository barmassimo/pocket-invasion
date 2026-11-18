class_name AlienFire
extends RefCounted

const Rules = preload("res://scripts/invasion_rules.gd")
const Art = preload("res://scripts/target_art.gd")
const TEXTURE: Texture2D = preload("res://assets/enemies/energy-orb.svg")
const TEXTURE_ALT: Texture2D = preload("res://assets/enemies/energy-orb-alt.svg")
var orbs: Array[MeshInstance3D] = []

func clear() -> void:
	for orb: MeshInstance3D in orbs:
		orb.free()
	orbs.clear()

func emit_from(parent: Node3D, target: CourseTarget, aim_x: float) -> void:
	var count: int = 2 if Art.crew_count(target.size_tier) == 2 else 1
	# Reserve a complete volley so a double ship never fires a partial pair.
	if not target.can_fire() or orbs.size() + count > Rules.MAX_ENERGY_ORBS:
		return
	for index: int in range(count):
		var offset: float = (index - (count - 1) * 0.5) * Art.PILOT_SPACING
		emit_orb(parent, target, aim_x, offset)
	target.shots_fired += 1

func emit_orb(parent: Node3D, target: CourseTarget, aim_x: float, offset: float) -> void:
	# A fixed nonzero lateral velocity and forward acceleration trace a parabola
	# in the playfield, never a vertical shot, even when the fleet is aligned.
	var launch_x: float = target.position.x + offset
	var direction: float = signf(aim_x - launch_x)
	if absf(aim_x - launch_x) < 0.5:
		direction = signf(offset) if offset != 0.0 else (-1.0 if target.shots_fired % 2 == 0 else 1.0)
	# The central disc matches the collision radius; the outer sparks are cosmetic.
	var orb: MeshInstance3D = Art.layer(TEXTURE, Vector2.ONE * Rules.ORB_RADIUS * 3.2, Vector3.ZERO)
	parent.add_child(orb)
	orb.position = target.position + Vector3(offset, Art.PLANE_HEIGHT + 0.01, target.half.y * 0.65)
	orb.set_meta("origin", orb.position)
	orb.set_meta("lateral", direction * Rules.ORB_LATERAL_SPEED)
	orb.set_meta("age", 0.0)
	orbs.append(orb)

func point_at(orb: MeshInstance3D, age: float) -> Vector3:
	var origin: Vector3 = orb.get_meta("origin")
	return origin + Vector3(float(orb.get_meta("lateral")) * age, 0,
		Rules.ORB_FORWARD_SPEED * age + 0.5 * Rules.ORB_ACCELERATION * age * age)

func discharge(at: Vector3, squad: Array[Node3D], previous: Dictionary[Node3D, Vector3], fraction: float) -> Array[Node3D]:
	var touched: Array[Node3D] = []
	# A local circular screen-space pulse overlaps more fighters in the middle
	# of a formation, and fewer when it only clips an edge. No global damage roll.
	var half := Rules.FIGHTER_SIZE * 0.5 + Vector2(Rules.ORB_DISCHARGE_RADIUS,
		Rules.ORB_DISCHARGE_RADIUS / Art.projection_scale())
	for ship: Node3D in squad:
		var old: Vector3 = previous.get(ship, ship.position)
		var offset: Vector3 = old.lerp(ship.position, fraction) - at
		if Rules.shot_fraction(offset, offset, Vector3.ZERO, half, 0.0) != INF:
			touched.append(ship)
	return touched

func advance(delta: float, squad: Array[Node3D], previous: Dictionary[Node3D, Vector3]) -> Array[Node3D]:
	var casualties: Array[Node3D] = []
	var half := Vector2(Rules.FIGHTER_SIZE.x * 0.5 + Rules.ORB_RADIUS,
		Rules.FIGHTER_SIZE.y * 0.5 + Rules.ORB_RADIUS / Art.projection_scale())
	for i: int in range(orbs.size() - 1, -1, -1):
		var orb: MeshInstance3D = orbs[i]
		var age: float = orb.get_meta("age")
		var hit: Node3D = null
		var impact := Vector3.ZERO
		var impact_fraction: float = 0.0
		# Small swept segments follow the curve and moving fighters without tunneling.
		var steps: int = maxi(1, ceili(delta * 120.0))
		for step: int in range(steps):
			var start: float = float(step) / steps
			var end: float = float(step + 1) / steps
			var before: Vector3 = point_at(orb, age + delta * start)
			var after: Vector3 = point_at(orb, age + delta * end)
			var nearest: float = INF
			for ship: Node3D in squad:
				if ship in casualties:
					continue
				var old: Vector3 = previous.get(ship, ship.position)
				var fraction: float = Rules.shot_fraction(before - old.lerp(ship.position, start),
					after - old.lerp(ship.position, end), Vector3.ZERO, half, 0.0)
				if fraction < nearest:
					nearest = fraction
					hit = ship
			if hit != null:
				impact = before.lerp(after, nearest)
				impact_fraction = lerpf(start, end, nearest)
				break
		orb.set_meta("age", age + delta)
		orb.position = point_at(orb, age + delta)
		(orb.material_override as StandardMaterial3D).albedo_texture = TEXTURE if int((age + delta) / 0.09) % 2 == 0 else TEXTURE_ALT
		if hit != null:
			for ship: Node3D in discharge(impact, squad, previous, impact_fraction):
				if ship not in casualties:
					casualties.append(ship)
		if hit != null or age + delta >= Rules.ORB_LIFETIME or absf(orb.position.x) > Rules.ROAD_HALF + 0.5 or orb.position.z > 11.0:
			orb.free()
			orbs.remove_at(i)
	return casualties

func fire(parent: Node3D, targets: Array[CourseTarget], aim: Vector3, delta: float, survival_time: float) -> void:
	if delta <= 0.0:
		return
	var rate: float = Rules.alien_fire_rate(maxf(0.0, survival_time - delta * 0.5))
	for target: CourseTarget in targets:
		if not target.can_fire() or target.position.z < -22.0 or target.position.z + target.half.y >= aim.z - 2.0:
			continue
		# New arrivals keep a short wind-up even at the initial low cadence.
		# The ramp scales repeat shots without delaying the first attack.
		target.fire_clock -= delta * (1.0 if target.shots_fired == 0 else rate)
		if target.fire_clock <= 0.0:
			emit_from(parent, target, aim.x)
			target.fire_clock = Rules.ALIEN_FIRE_INTERVAL
