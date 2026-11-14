class_name RecaptureFlash
extends Control

const DURATION: float = 0.45
const MAX_FLASHES: int = 64
const INK := Color("253820")
const MID := Color("65734a")
const PAPER := Color("c4cca5")
var camera: Camera3D
var flashes: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func play(at: Vector3, target: Node3D, ship_scale: Vector2, rotation_angle: float = 0.0) -> void:
	if flashes.size() >= MAX_FLASHES:
		return
	var center: Vector3 = at + Vector3(0, 0.35, 0)
	var fighter: Vector2 = camera.unproject_position(center) - position
	var corner: Vector2 = camera.unproject_position(center + Vector3(0.22 * ship_scale.x, 0, 0.30 * ship_scale.y)) - position
	flashes.append({"fighter": fighter, "size": (corner - fighter).abs() * 2.0,
		"target": weakref(target), "source": camera.unproject_position(target.position + Vector3(0, 0.35, 0)) - position, "age": 0.0, "rotation": rotation_angle})
	queue_redraw()

func clear() -> void:
	flashes.clear()
	queue_redraw()

func advance(delta: float) -> void:
	if flashes.is_empty():
		return
	for i: int in range(flashes.size() - 1, -1, -1):
		var flash: Dictionary = flashes[i]
		flash.age += delta
		if flash.age >= DURATION:
			flashes.remove_at(i)
			continue
		var target: Node3D = flash.target.get_ref() as Node3D
		if is_instance_valid(target):
			flash.source = camera.unproject_position(target.position + Vector3(0, 0.35, 0)) - position
	queue_redraw()

func _draw() -> void:
	for flash: Dictionary in flashes:
		paint(self, flash.source, flash.fighter, flash.size, flash.age / DURATION, flash.rotation)

static func paint(canvas: CanvasItem, source: Vector2, fighter: Vector2, ship_size: Vector2, progress: float, rotation_angle: float = 0.0) -> void:
	if source.distance_to(fighter) < 8.0:
		source = fighter - Vector2(0, 12)
	var side: Vector2 = (fighter - source).normalized().orthogonal()
	var width: float = maxf(6.0, ship_size.x * 0.6)
	canvas.draw_colored_polygon(PackedVector2Array([
		source - side * 2, source + side * 2, fighter + side * width, fighter - side * width]), MID)
	for i: int in range(3):
		var scan: float = fposmod(float(i) / 3.0 - progress * 1.5, 1.0)
		var center: Vector2 = source.lerp(fighter, scan)
		var span: Vector2 = side * lerpf(2.0, width, scan)
		canvas.draw_line(center - span, center + span, PAPER, 1.5, true)
	var pull: float = smoothstep(0.0, 1.0, progress)
	var icon_size: Vector2 = ship_size * (1.0 - pull)
	if icon_size.x > 1.0:
		canvas.draw_set_transform(fighter.lerp(source, pull), rotation_angle)
		canvas.draw_texture_rect(LcdIcons.SHIP, Rect2(-icon_size * 0.5, icon_size), false, INK)
		canvas.draw_set_transform(Vector2.ZERO)
