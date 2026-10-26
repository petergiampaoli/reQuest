extends TaskBase
## ParryTask — "PARRY!"
## Two swords overlap in a random formation, held by armored gauntlets.
## A gold zone oscillates along each blade. Press SPACE when both gold zones overlap.
## Three rounds.

const ROUNDS: int = 3
const BLADE_LEN: float = 420.0
const ZONE_LEN: float = 130.0
const ZONE_THICK: float = 32.0
const CENTER: Vector2 = Vector2(640, 355)
const ZONE_MIN_SPEED: float = 300.0
const ZONE_MAX_SPEED: float = 420.0

var round_index: int = 0
var round_locked: bool = false
var round_delay: float = 0.0
var zones_overlap: bool = false
var speed_scale: float = 1.0

var _sword_a: Node2D
var _sword_b: Node2D
var _zone_a: Node2D
var _zone_b: Node2D
var _zone_a_fill: ColorRect
var _zone_b_fill: ColorRect

var _zone_a_pos: float = 0.0
var _zone_b_pos: float = 0.0
var _zone_a_dir: float = 1.0
var _zone_b_dir: float = 1.0
var _zone_a_speed: float = 360.0
var _zone_b_speed: float = 360.0

func _ready() -> void:
	command_text = "PARRY!"
	speed_scale = 0.85 + GameManager.difficulty * 0.15
	super._ready()

func on_task_start() -> void:
	round_index = 0
	round_locked = false
	round_delay = 0.0
	zones_overlap = false
	_build_swords()
	_start_round()

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	if round_locked:
		round_delay -= delta
		if round_delay <= 0.0:
			_start_round()
		return

	var zone_min := -BLADE_LEN / 2.0 + ZONE_LEN / 2.0 + 18.0
	var zone_max := BLADE_LEN / 2.0 - ZONE_LEN / 2.0 - 24.0

	_zone_a_pos += _zone_a_dir * _zone_a_speed * delta
	if _zone_a_pos > zone_max:
		_zone_a_pos = zone_max
		_zone_a_dir = -1.0
	elif _zone_a_pos < zone_min:
		_zone_a_pos = zone_min
		_zone_a_dir = 1.0

	_zone_b_pos += _zone_b_dir * _zone_b_speed * delta
	if _zone_b_pos > zone_max:
		_zone_b_pos = zone_max
		_zone_b_dir = -1.0
	elif _zone_b_pos < zone_min:
		_zone_b_pos = zone_min
		_zone_b_dir = 1.0

	_place_zone(_zone_a, _sword_a, _zone_a_pos)
	_place_zone(_zone_b, _sword_b, _zone_b_pos)

	zones_overlap = _zones_overlap()
	_set_zone_fill(Color("#fff2a0") if zones_overlap else Color("#ffd94c"))

func _unhandled_input(event: InputEvent) -> void:
	if _finished or round_locked:
		return
	if event.is_action_pressed("action"):
		gesture_performed("action")
		get_viewport().set_input_as_handled()
		if _zones_overlap():
			round_index += 1
			_set_zone_fill(Color("#7cff7c"))
			if round_index >= ROUNDS:
				succeed()
			else:
				round_locked = true
				round_delay = 0.35
		else:
			_set_zone_fill(Color("#ff4a4a"))
			fail()

# ---------------------------------------------------------------------------
# Swords + gold blade zones
# ---------------------------------------------------------------------------

func _build_swords() -> void:
	_sword_a = _make_sword()
	add_child(_sword_a)
	_sword_b = _make_sword()
	add_child(_sword_b)

	var za := _make_zone()
	_zone_a = za["node"] as Node2D
	_zone_a_fill = za["fill"] as ColorRect
	add_child(_zone_a)

	var zb := _make_zone()
	_zone_b = zb["node"] as Node2D
	_zone_b_fill = zb["fill"] as ColorRect
	add_child(_zone_b)

func _make_sword() -> Node2D:
	var s := Node2D.new()

	# Blade: dark outline, steel face, highlight, fuller.
	_poly(s, PackedVector2Array([
		Vector2(-210, -16), Vector2(158, -14), Vector2(210, 0),
		Vector2(158, 14), Vector2(-210, 16),
	]), Color("#1a1208"))
	_poly(s, PackedVector2Array([
		Vector2(-210, -11), Vector2(156, -9), Vector2(203, 0),
		Vector2(156, 9), Vector2(-210, 11),
	]), Color("#b8bcc8"))
	_poly(s, PackedVector2Array([
		Vector2(-204, -8), Vector2(150, -6), Vector2(192, 0),
		Vector2(150, -2), Vector2(-204, -3),
	]), Color("#e6e9f0"))
	_rect(s, Vector2(-196, -2), Vector2(330, 4), Color("#7a808a"))

	# Grip.
	_rect(s, Vector2(-322, -14), Vector2(114, 28), Color("#1a1208"))
	_rect(s, Vector2(-318, -10), Vector2(108, 20), Color("#3a2414"))
	for x in [-300.0, -280.0, -260.0, -240.0]:
		_rect(s, Vector2(x, -10), Vector2(4, 20), Color("#6b4a2a"))

	# Pommel.
	_circle(s, Vector2(-322, 0), 16, Color("#1a1208"))
	_circle(s, Vector2(-322, 0), 12, Color("#c9b56a"))
	_circle(s, Vector2(-324, -3), 4, Color("#e0c87a"))

	# Guard.
	_rect(s, Vector2(-226, -58), Vector2(32, 116), Color("#1a1208"))
	_rect(s, Vector2(-222, -52), Vector2(24, 104), Color("#c9b56a"))
	_rect(s, Vector2(-222, -52), Vector2(24, 6), Color("#e0c87a"))
	_circle(s, Vector2(-210, -52), 10, Color("#1a1208"))
	_circle(s, Vector2(-210, -52), 7, Color("#c9b56a"))
	_circle(s, Vector2(-210, 52), 10, Color("#1a1208"))
	_circle(s, Vector2(-210, 52), 7, Color("#c9b56a"))

	# Armored gauntlet gripping the handle.
	_poly(s, PackedVector2Array([
		Vector2(-314, -38), Vector2(-250, -42), Vector2(-238, -26),
		Vector2(-238, 26), Vector2(-250, 42), Vector2(-314, 38),
	]), Color("#1a1208"))
	_poly(s, PackedVector2Array([
		Vector2(-310, -32), Vector2(-254, -36), Vector2(-244, -22),
		Vector2(-244, 22), Vector2(-254, 36), Vector2(-310, 32),
	]), Color("#6a707a"))

	# Finger plates.
	for x in [-300.0, -286.0, -272.0, -258.0]:
		_rect(s, Vector2(x, -34), Vector2(12, 68), Color("#1a1208"))
		_rect(s, Vector2(x + 3, -30), Vector2(6, 60), Color("#8a909c"))

	# Cuff band + rivets.
	_rect(s, Vector2(-314, -34), Vector2(6, 68), Color("#1a1208"))
	_rect(s, Vector2(-312, -30), Vector2(3, 60), Color("#c9b56a"))
	_circle(s, Vector2(-306, -24), 3, Color("#c9b56a"))
	_circle(s, Vector2(-306, 24), 3, Color("#c9b56a"))
	_circle(s, Vector2(-250, -30), 3, Color("#c9b56a"))
	_circle(s, Vector2(-250, 30), 3, Color("#c9b56a"))

	return s

func _make_zone() -> Dictionary:
	var node := Node2D.new()

	var outline := ColorRect.new()
	outline.position = Vector2(-ZONE_LEN / 2.0 - 3.0, -ZONE_THICK / 2.0 - 3.0)
	outline.size = Vector2(ZONE_LEN + 6.0, ZONE_THICK + 6.0)
	outline.color = Color("#8c6a1a")
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(outline)

	var fill := ColorRect.new()
	fill.position = Vector2(-ZONE_LEN / 2.0, -ZONE_THICK / 2.0)
	fill.size = Vector2(ZONE_LEN, ZONE_THICK)
	fill.color = Color("#ffd94c")
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(fill)

	return {"node": node, "fill": fill}

func _start_round() -> void:
	round_locked = false
	round_delay = 0.0

	_sword_a.position = CENTER + Vector2(randf_range(-55.0, 55.0), randf_range(-35.0, 35.0))
	_sword_a.rotation = deg_to_rad(randf_range(-28.0, 28.0))
	_sword_b.position = CENTER + Vector2(randf_range(-55.0, 55.0), randf_range(-35.0, 35.0))
	_sword_b.rotation = deg_to_rad(randf_range(58.0, 122.0))

	var zone_min := -BLADE_LEN / 2.0 + ZONE_LEN / 2.0 + 18.0
	var zone_max := BLADE_LEN / 2.0 - ZONE_LEN / 2.0 - 24.0
	_zone_a_pos = randf_range(zone_min, zone_max)
	_zone_b_pos = randf_range(zone_min, zone_max)
	_zone_a_dir = [-1.0, 1.0].pick_random()
	_zone_b_dir = [-1.0, 1.0].pick_random()
	_zone_a_speed = randf_range(ZONE_MIN_SPEED, ZONE_MAX_SPEED) * speed_scale
	_zone_b_speed = randf_range(ZONE_MIN_SPEED, ZONE_MAX_SPEED) * speed_scale

	_place_zone(_zone_a, _sword_a, _zone_a_pos)
	_place_zone(_zone_b, _sword_b, _zone_b_pos)

	# Start clean: reroll the zone positions if they already overlap.
	for i in 20:
		if not _zones_overlap():
			break
		_zone_a_pos = randf_range(zone_min, zone_max)
		_zone_b_pos = randf_range(zone_min, zone_max)
		_place_zone(_zone_a, _sword_a, _zone_a_pos)
		_place_zone(_zone_b, _sword_b, _zone_b_pos)

	zones_overlap = _zones_overlap()
	_set_zone_fill(Color("#fff2a0") if zones_overlap else Color("#ffd94c"))

func _place_zone(zone: Node2D, sword: Node2D, local_x: float) -> void:
	if zone == null or sword == null:
		return
	var dir := Vector2(cos(sword.rotation), sin(sword.rotation))
	zone.position = sword.position + dir * local_x
	zone.rotation = sword.rotation

func _zones_overlap() -> bool:
	if _zone_a == null or _zone_b == null:
		return false
	var pa := _zone_polygon(_zone_a)
	var pb := _zone_polygon(_zone_b)
	return not Geometry2D.intersect_polygons(pa, pb).is_empty()

func _zone_polygon(zone: Node2D) -> PackedVector2Array:
	var t := zone.global_transform
	return PackedVector2Array([
		t * Vector2(-ZONE_LEN / 2.0, -ZONE_THICK / 2.0),
		t * Vector2(ZONE_LEN / 2.0, -ZONE_THICK / 2.0),
		t * Vector2(ZONE_LEN / 2.0, ZONE_THICK / 2.0),
		t * Vector2(-ZONE_LEN / 2.0, ZONE_THICK / 2.0),
	])

func _set_zone_fill(color: Color) -> void:
	if _zone_a_fill:
		_zone_a_fill.color = color
	if _zone_b_fill:
		_zone_b_fill.color = color

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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

func _circle(parent: Node, center: Vector2, radius: float, color: Color) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in 26:
		var a := TAU * float(i) / 26.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return _poly(parent, pts, color)
