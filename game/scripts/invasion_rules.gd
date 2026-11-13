class_name InvasionRules
extends RefCounted

const START_SOLDIERS: int = 1
const SHOT_RATE_REFERENCE_COUNT: int = 4
const ROAD_HALF: float = 5.5
const CAMERA_POSITION := Vector3(0, 21, 11.8)
const CAMERA_FOCUS := Vector3(0, 0, -8.2)
const SPACING: float = 0.58
const WIDE_FORMATION_THRESHOLD: int = 32
const SHIPS_PER_EXTRA_COLUMN: int = 8
const MAX_FORMATION_COLUMNS: int = 20
const SHOT_INTERVAL: float = 0.45
const MAX_BULLETS: int = 768
const START_DIFFICULTY_SECONDS: float = 60.0
const DISPLAY_START_THREAT: int = 1
const COURSE_SPEED_MULTIPLIER: float = 1.3
const RECOVERY_HEALTH: int = 5
const BULLET_SPEED: float = 28.0
const SIZE_SCALES: Array[float] = [0.8, 1.0, 1.25, 1.5, 1.8]
const SIZE_HEALTH: Array[float] = [0.7, 1.0, 1.5, 4.0, 7.0]
const SQUAD_REWARDS: Array[int] = [1, 2, 4, 8, 16]

static func target_health(kind: int, elapsed: float, variation: float, tier: int = 1) -> int:
	# Small reinforcement crates remain recoverable with a single soldier.
	if kind == 0 and tier == 0:
		return RECOVERY_HEALTH
	# Modest time-based growth, independent of squad size: gaining soldiers pays off.
	var base: float = [18.0, 24.0, 32.0][kind]
	var growth: float = [0.30, 0.40, 0.50][kind]
	var minutes: float = maxf(0.0, elapsed) / 60.0
	var escalation: float = [12.0, 18.0, 24.0][kind] * pow(minutes, 2.2)
	return maxi(1, roundi((base + elapsed * growth + escalation) * variation * SIZE_HEALTH[tier]))

static func difficulty_time(survival_time: float) -> float:
	return START_DIFFICULTY_SECONDS + survival_time

static func course_speed(elapsed: float) -> float:
	var active: float = maxf(0.0, elapsed)
	# Apply the opening offset to speed too, then shorten the firing opportunity.
	return COURSE_SPEED_MULTIPLIER * (3.8 + active * 0.014 + active * active * 0.000012)

static func threat_level(survival_time: float) -> int:
	return DISPLAY_START_THREAT + floori(survival_time / 60.0)

static func shot_damage(_count: int) -> int:
	return 1

static func shot_interval(count: int) -> float:
	return maxf(0.20, SHOT_INTERVAL / sqrt(maxf(1.0, float(count) / SHOT_RATE_REFERENCE_COUNT)))

static func encounter_pressure(elapsed: float) -> float:
	var minutes: float = maxf(0.0, elapsed) / 60.0
	return 1.0 + 0.22 * log(1.0 + maxf(0.0, elapsed) / 45.0) + 0.1 * pow(minutes, 1.3)

static func target_reward(kind: int, tier: int, score_roll: int = 5) -> int:
	if kind == 0:
		return SQUAD_REWARDS[tier]
	return clampi(score_roll, 4, 7) * 10 * (1 << tier)

static func offsets(count: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var width: int = formation_columns(count)
	var columns: int = mini(count, width)
	var spacing: Vector2 = formation_spacing(count)
	for i: int in range(count):
		var row: int = i / width
		var row_count: int = mini(columns, count - row * width)
		result.append(Vector3((float(i % width) - float(row_count - 1) / 2.0) * spacing.x, 0.0, float(row) * spacing.y))
	return result

static func formation_columns(count: int) -> int:
	if count <= 24:
		return 6
	# Large fleets trade lateral escape room for more firing columns.
	var extra: int = ceili(float(maxi(0, count - WIDE_FORMATION_THRESHOLD)) / SHIPS_PER_EXTRA_COLUMN)
	return mini(8 + extra, MAX_FORMATION_COLUMNS)

static func formation_spacing(count: int) -> Vector2:
	if count <= 24:
		return Vector2(SPACING, SPACING)
	# Keep additional ranks inside the existing formation depth.
	var rear_row: int = maxi(1, (count - 1) / formation_columns(count))
	return Vector2(0.46, minf(0.30, 1.5 / rear_row))

static func movement_limit(count: int) -> float:
	return ROAD_HALF - float(mini(count, formation_columns(count)) - 1) * formation_spacing(count).x / 2.0 - 0.3

# Sweep a relative segment against the visible elliptical hull. Expanded radii
# include the projectile or ship contact margin; empty bounding-box corners miss.
static func shot_hits(from: Vector3, to: Vector3, center: Vector3, half: Vector2) -> bool:
	return shot_fraction(from, to, center, half) != INF

static func shot_fraction(from: Vector3, to: Vector3, center: Vector3, half: Vector2, padding: float = 0.07) -> float:
	var radii: Vector2 = half + Vector2.ONE * padding
	var origin := Vector2(from.x - center.x, from.z - center.z) / radii
	var motion := Vector2(to.x - from.x, to.z - from.z) / radii
	var c: float = origin.length_squared() - 1.0
	if c <= 0.0:
		return 0.0
	var a: float = motion.length_squared()
	if a < 0.00000001:
		return INF
	var b: float = origin.dot(motion)
	var discriminant: float = b * b - a * c
	if discriminant < 0.0:
		return INF
	var entry: float = (-b - sqrt(discriminant)) / a
	return clampf(entry, 0.0, 1.0) if entry >= -0.000001 and entry <= 1.000001 else INF
