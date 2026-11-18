class_name FireBoost
extends RefCounted

const Rules = preload("res://scripts/invasion_rules.gd")
const Pickup = preload("res://scripts/fire_pickup.gd")
const Art = preload("res://scripts/target_art.gd")
var pickups: Array[FirePickup] = []
var remaining: float = 0.0

func clear() -> void:
	for pickup: FirePickup in pickups:
		pickup.free()
	pickups.clear()
	remaining = 0.0

func spawn(parent: Node3D, at: Vector3, drift: float) -> void:
	# Keep the newest earned module if an artificial stress case fills capacity.
	if pickups.size() >= Rules.MAX_BOOST_PICKUPS:
		pickups.pop_front().free()
	var pickup := Pickup.new() as FirePickup
	parent.add_child(pickup)
	pickup.position = at
	pickup.setup(drift)
	pickups.append(pickup)

func advance(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	for i: int in range(pickups.size() - 1, -1, -1):
		pickups[i].advance(delta)
		if pickups[i].expired() or pickups[i].position.z > 11.0:
			pickups[i].free()
			pickups.remove_at(i)

func collect(squad: Array[Node3D], previous: Dictionary[Node3D, Vector3]) -> bool:
	var collected: bool = false
	var half := Vector2(Rules.PICKUP_RADIUS, Rules.PICKUP_RADIUS / Art.projection_scale())
	for i: int in range(pickups.size() - 1, -1, -1):
		var pickup: FirePickup = pickups[i]
		for soldier: Node3D in squad:
			var before: Vector3 = previous.get(soldier, soldier.position)
			if Rules.shot_fraction(before - pickup.previous_position, soldier.position - pickup.position, Vector3.ZERO, half, 0.20) != INF:
				remaining = Rules.BOOST_DURATION
				collected = true
				pickup.free()
				pickups.remove_at(i)
				break
	return collected

func rate_multiplier() -> float:
	return Rules.BOOST_FIRE_RATE if remaining > 0.0 else 1.0
