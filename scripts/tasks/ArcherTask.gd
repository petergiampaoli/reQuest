extends TaskBase
## ArcherTask — "LOOSE!"
## WASD aims the arrow tip. Press SPACE/E to loose.
## The sharp tip must be inside the circular target for a hit. One shot.

const TARGET_RADIUS: float = 96.0
const AIM_SPEED: float = 520.0
const AIM_MIN: Vector2 = Vector2(90, 90)
const AIM_MAX: Vector2 = Vector2(1190, 640)
const TARGET_MIN: Vector2 = Vector2(150, 230)
const TARGET_MAX: Vector2 = Vector2(1130, 500)

var target_pos: Vector2 = Vector2(640, 340)
var target_vel: Vector2 = Vector2.ZERO
var aim_pos: Vector2 = Vector2(640, 500)
var has_shot: bool = false

var _target: Node2D
var _aim_arrow: Node2D

func _ready() -> void:
	command_text = "LOOSE!"
	super._ready()

func on_task_start() -> void:
	has_shot = false
	aim_pos = Vector2(640, 500)
	target_pos = Vector2(randf_range(300, 980), randf_range(260, 430))
	# Drift speed scales with difficulty.
	var s: float = 80.0 + GameManager.difficulty * 55.0
	target_vel = Vector2([-1, 1].pick_random(), randf_range(-0.4, 0.4)).normalized() * s
	_build_target()
	_build_aim_arrow()
	_update_nodes()
	_set_hint("WASD aim   SPACE shoot")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()

	# WASD-only aiming — the arrow tip is the hit point.
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() > 0.01:
		aim_pos += dir * AIM_SPEED * delta
	aim_pos.x = clampf(aim_pos.x, AIM_MIN.x, AIM_MAX.x)
	aim_pos.y = clampf(aim_pos.y, AIM_MIN.y, AIM_MAX.y)

	# Drift the target, bouncing inside the playfield.
	target_pos += target_vel * delta
	if target_pos.x < TARGET_MIN.x or target_pos.x > TARGET_MAX.x:
		target_vel.x *= -1.0
		target_pos.x = clampf(target_pos.x, TARGET_MIN.x, TARGET_MAX.x)
	if target_pos.y < TARGET_MIN.y or target_pos.y > TARGET_MAX.y:
		target_vel.y *= -1.0
		target_pos.y = clampf(target_pos.y, TARGET_MIN.y, TARGET_MAX.y)

	_update_nodes()

func _unhandled_input(event: InputEvent) -> void:
	if _finished or has_shot:
		return
	# No mouse input — only the shoot button.
	if event.is_action_pressed("action"):
		gesture_performed("action")
		_shoot()
		get_viewport().set_input_as_handled()

func _shoot() -> void:
	has_shot = true
	var hit: bool = aim_pos.distance_to(target_pos) <= TARGET_RADIUS
	if hit:
		if _target:
			_target.modulate = Color("#7cff7c")
			create_tween().tween_property(_target, "modulate", Color.WHITE, 0.25)
		succeed()
	else:
		if _aim_arrow:
			_aim_arrow.modulate = Color("#ff4a4a")
		fail()

func _update_nodes() -> void:
	if _target:
		_target.position = target_pos
	if _aim_arrow:
		_aim_arrow.position = aim_pos

# ---------------------------------------------------------------------------
# Circular target (3x the old 64px target)
# ---------------------------------------------------------------------------

func _build_target() -> void:
	_target = Node2D.new()
	_target.name = "Target"
	add_child(_target)
	_circle(_target, TARGET_RADIUS, Color("#1a1208"))
	_circle(_target, TARGET_RADIUS - 4.0, Color("#f2e8c6"))
	_circle(_target, TARGET_RADIUS * 0.72, Color("#8c2f12"))
	_circle(_target, TARGET_RADIUS * 0.46, Color("#f2e8c6"))
	_circle(_target, TARGET_RADIUS * 0.22, Color("#ffd94c"))

# ---------------------------------------------------------------------------
# Medieval arrow cursor — sharp tip at the node origin
# ---------------------------------------------------------------------------

func _build_aim_arrow() -> void:
	_aim_arrow = Node2D.new()
	_aim_arrow.name = "AimArrow"
	_aim_arrow.rotation = 0.18
	add_child(_aim_arrow)

	# Arrowhead: dark outline + steel head, tip at (0, 0).
	_poly(_aim_arrow, PackedVector2Array([
		Vector2(0, 0), Vector2(-20, 30), Vector2(0, 24), Vector2(20, 30),
	]), Color("#1a1208"))
	_poly(_aim_arrow, PackedVector2Array([
		Vector2(0, 3), Vector2(-14, 25), Vector2(0, 19), Vector2(14, 25),
	]), Color("#d8d8d8"))

	# Wooden shaft.
	_rect(_aim_arrow, Vector2(-5, 16), Vector2(10, 62), Color("#1a1208"))
	_rect(_aim_arrow, Vector2(-3, 18), Vector2(6, 58), Color("#6b4a2a"))

	# Feather fletching.
	_poly(_aim_arrow, PackedVector2Array([
		Vector2(-5, 48), Vector2(-22, 72), Vector2(-6, 78), Vector2(3, 62),
	]), Color("#1a1208"))
	_poly(_aim_arrow, PackedVector2Array([
		Vector2(5, 48), Vector2(22, 72), Vector2(6, 78), Vector2(-3, 62),
	]), Color("#1a1208"))
	_poly(_aim_arrow, PackedVector2Array([
		Vector2(-5, 52), Vector2(-17, 70), Vector2(-6, 74), Vector2(0, 62),
	]), Color("#c9b56a"))
	_poly(_aim_arrow, PackedVector2Array([
		Vector2(5, 52), Vector2(17, 70), Vector2(6, 74), Vector2(0, 62),
	]), Color("#8c2f12"))

	# Nock.
	_rect(_aim_arrow, Vector2(-4, 74), Vector2(8, 6), Color("#1a1208"))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _circle(parent: Node, radius: float, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU * float(i) / 48.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	p.polygon = pts
	p.color = color
	parent.add_child(p)
	return p

func _poly(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = color
	parent.add_child(p)
	return p

func _rect(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _set_hint(text: String) -> void:
	var hint: Label = get_node_or_null("CanvasLayer/Hint")
	if hint:
		hint.text = text
