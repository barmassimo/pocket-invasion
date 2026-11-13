class_name LcdIcons
extends RefCounted

const SHIP: Texture2D = preload("res://assets/icons/ship.svg")
const SCORE: Texture2D = preload("res://assets/icons/score.svg")
const ENEMY: Texture2D = preload("res://assets/icons/enemy.svg")
const BLOCK: Texture2D = preload("res://assets/icons/block.svg")

static func reward(kind: int) -> Texture2D:
	return SHIP if kind == 0 else SCORE

static func target(kind: int) -> Texture2D:
	# The target's single emblem and HUD legend share one meaning.
	return reward(kind)
