extends TaskBase
## RideTask — "RIDE!"
## Third-person chase view: A/D steer the horse, SPACE jumps barrels and fences.
## Barrels sit in a lane and must be dodged; fences span the road and must be jumped.
## Survive until the timer runs out.

# --- Perspective / world constants ---
const VIEW_W: float = 1280.0
const VIEW_H: float = 720.0
const VX: float = 640.0
const HORIZON_Y: float = 236.0
const ROAD_FAR_HALF: float = 30.0
const ROAD_NEAR_HALF: float = 520.0
const ROAD_BOTTOM_HALF: float = 780.0
const PLAYER_LINE_Y: float = 556.0
const HORSE_FEET_Y: float = 594.0
const HORSE_MIN_X: float = 190.0
const HORSE_MAX_X: float = 1090.0
const HORSE_SPEED: float = 460.0
const JUMP_TIME: float = 0.52
const JUMP_HEIGHT: float = 132.0
const COLLISION_Z_MIN: float = 0.86
const COLLISION_Z_MAX: float = 1.04
const REMOVE_Z: float = 1.10
const BARREL_HIT_RADIUS: float = 92.0

var _horse_x: float = VX
var _steer: float = 0.0
var _jump_t: float = 0.0
var _is_jumping: bool = false
var _run_time: float = 0.0
var _obstacle_gap: float = 0.0
var _spawn_count: int = 0

var _world: Node2D
var _obstacle_layer: Node2D
var _horse: Node2D
var _shadow: Polygon2D
var _obstacles: Array = []

func _ready() -> void:
	command_text = "RIDE!"
	super._ready()

func on_task_start() -> void:
	_horse_x = VX
	_steer = 0.0
	_jump_t = 0.0
	_is_jumping = false
	_run_time = 0.0
	_obstacle_gap = 0.75
	_spawn_count = 0
	_obstacles.clear()
	_build_world()
	_build_horse()
	_update_horse(0.0)
	_set_hint("A / D steer   SPACE jump")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	_run_time += delta
	track_movement()

	_steer = Input.get_axis("move_left", "move_right")
	_horse_x = clampf(_horse_x + _steer * HORSE_SPEED * delta, HORSE_MIN_X, HORSE_MAX_X)

	if Input.is_action_just_pressed("action") and not _is_jumping:
		_is_jumping = true
		_jump_t = 0.0
		gesture_performed("action")

	if _is_jumping:
		_jump_t += delta
		if _jump_t >= JUMP_TIME:
			_is_jumping = false
			_jump_t = 0.0

	_update_horse(delta)

	_obstacle_gap -= delta
	if _obstacle_gap <= 0.0:
		_spawn_obstacle()
		_obstacle_gap = maxf(0.62, 1.0 / GameManager.difficulty)

	_update_obstacles(delta)
	if _finished:
		return

	if _time_left < 0.05:
		succeed()

# ---------------------------------------------------------------------------
# World / perspective
# ---------------------------------------------------------------------------

func _build_world() -> void:
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)

	# Dusk sky and ground behind the road.
	_rect(_world, Vector2.ZERO, Vector2(VIEW_W, HORIZON_Y), Color("#241f33"))
	_rect(_world, Vector2(0.0, HORIZON_Y), Vector2(VIEW_W, VIEW_H - HORIZON_Y), Color("#1a1d14"))

	# A low, ragged horizon so the road has something to vanish into.
	var hills := Polygon2D.new()
	hills.polygon = PackedVector2Array([
		Vector2(0.0, HORIZON_Y),
		Vector2(0.0, HORIZON_Y - 42.0),
		Vector2(120.0, HORIZON_Y - 72.0),
		Vector2(270.0, HORIZON_Y - 34.0),
		Vector2(430.0, HORIZON_Y - 88.0),
		Vector2(610.0, HORIZON_Y - 40.0),
		Vector2(780.0, HORIZON_Y - 96.0),
		Vector2(980.0, HORIZON_Y - 46.0),
		Vector2(1140.0, HORIZON_Y - 68.0),
		Vector2(VIEW_W, HORIZON_Y - 24.0),
		Vector2(VIEW_W, HORIZON_Y),
	])
	hills.color = Color("#17141f")
	_world.add_child(hills)

	# Road: narrow at the horizon, wide at the camera.
	var road := Polygon2D.new()
	road.polygon = PackedVector2Array([
		Vector2(VX - ROAD_FAR_HALF, HORIZON_Y),
		Vector2(VX + ROAD_FAR_HALF, HORIZON_Y),
		Vector2(VX + ROAD_BOTTOM_HALF, VIEW_H),
		Vector2(VX - ROAD_BOTTOM_HALF, VIEW_H),
	])
	road.color = Color("#3a2e24")
	_world.add_child(road)

	_road_edge(-1.0)
	_road_edge(1.0)
	for band in [[0.06, 0.16], [0.23, 0.33], [0.40, 0.50], [0.57, 0.67], [0.74, 0.84], [0.91, 1.0]]:
		_center_dash(band[0], band[1])

	_obstacle_layer = Node2D.new()
	_obstacle_layer.name = "Obstacles"
	add_child(_obstacle_layer)

func _road_edge(side: float) -> void:
	var top_inner := VX + side * ROAD_FAR_HALF
	var top_outer := VX + side * (ROAD_FAR_HALF + 4.0)
	var bottom_inner := VX + side * ROAD_BOTTOM_HALF
	var bottom_outer := VX + side * (ROAD_BOTTOM_HALF + 18.0)
	var strip := Polygon2D.new()
	strip.polygon = PackedVector2Array([
		Vector2(top_inner, HORIZON_Y),
		Vector2(top_outer, HORIZON_Y),
		Vector2(bottom_outer, VIEW_H),
		Vector2(bottom_inner, VIEW_H),
	])
	strip.color = Color("#8d7a4e")
	_world.add_child(strip)

func _center_dash(z0: float, z1: float) -> void:
	var y0 := _depth_y(z0)
	var y1 := _depth_y(z1)
	var w0 := lerpf(1.5, 7.0, z0)
	var w1 := lerpf(1.5, 7.0, z1)
	var dash := Polygon2D.new()
	dash.polygon = PackedVector2Array([
		Vector2(VX - w0, y0),
		Vector2(VX + w0, y0),
		Vector2(VX + w1, y1),
		Vector2(VX - w1, y1),
	])
	dash.color = Color(0.79, 0.71, 0.41, 0.55)
	_world.add_child(dash)

func _depth_y(z: float) -> float:
	return lerpf(HORIZON_Y, PLAYER_LINE_Y, pow(clampf(z, 0.0, 1.08), 1.4))

func _scale_at(z: float) -> float:
	return lerpf(0.08, 1.0, pow(clampf(z, 0.0, 1.0), 1.55))

func _road_half_at(z: float) -> float:
	return lerpf(ROAD_FAR_HALF, ROAD_NEAR_HALF, pow(clampf(z, 0.0, 1.0), 1.25))

# ---------------------------------------------------------------------------
# Horse + rider (seen from behind)
# ---------------------------------------------------------------------------

func _build_horse() -> void:
	_shadow = _ellipse(null, Vector2.ZERO, Vector2(78, 14), Color(0.0, 0.0, 0.0, 0.35))
	_shadow.name = "Shadow"
	_shadow.z_index = 1
	_shadow.position = Vector2(_horse_x, HORSE_FEET_Y + 7.0)
	add_child(_shadow)

	_horse = Node2D.new()
	_horse.name = "Horse"
	_horse.z_index = 2
	_horse.position = Vector2(_horse_x, HORSE_FEET_Y)
	add_child(_horse)

	# Hind legs + hooves.
	_rect(_horse, Vector2(-42, -80), Vector2(18, 80), Color("#3f2616"))
	_rect(_horse, Vector2(24, -80), Vector2(18, 80), Color("#3f2616"))
	_rect(_horse, Vector2(-44, -12), Vector2(22, 14), Color("#1d120a"))
	_rect(_horse, Vector2(22, -12), Vector2(22, 14), Color("#1d120a"))

	# Rump / body.
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-60, -160), Vector2(-48, -176), Vector2(-20, -184),
		Vector2(20, -184), Vector2(48, -176), Vector2(60, -160),
		Vector2(70, -120), Vector2(62, -82), Vector2(40, -70),
		Vector2(-40, -70), Vector2(-62, -82), Vector2(-70, -120),
	])
	body.color = Color("#6b3f24")
	_horse.add_child(body)
	_ellipse(_horse, Vector2(0, -112), Vector2(52, 34), Color(0.25, 0.14, 0.08, 0.45))

	# Tail, drawn on top of the rump so it reads from the chase camera.
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([
		Vector2(-10, -150), Vector2(10, -150), Vector2(16, -66),
		Vector2(7, -30), Vector2(-2, -44), Vector2(-15, -78),
	])
	tail.color = Color("#24160d")
	_horse.add_child(tail)

	# Saddle.
	_rect(_horse, Vector2(-38, -178), Vector2(76, 22), Color("#2a1a10"))
	_rect(_horse, Vector2(-38, -178), Vector2(76, 4), Color("#c9b56a"))
	_rect(_horse, Vector2(-6, -196), Vector2(12, 20), Color("#2a1a10"))

	# Rider legs + boots.
	_rect(_horse, Vector2(-46, -174), Vector2(18, 60), Color("#3a2a20"))
	_rect(_horse, Vector2(28, -174), Vector2(18, 60), Color("#3a2a20"))
	_rect(_horse, Vector2(-48, -122), Vector2(22, 14), Color("#1d120a"))
	_rect(_horse, Vector2(26, -122), Vector2(22, 14), Color("#1d120a"))

	# Neck + rider cloak / torso.
	_rect(_horse, Vector2(-6, -270), Vector2(12, 14), Color("#d9a06b"))
	var cloak := Polygon2D.new()
	cloak.polygon = PackedVector2Array([
		Vector2(-30, -262), Vector2(30, -262), Vector2(38, -214),
		Vector2(30, -176), Vector2(-30, -176), Vector2(-38, -214),
	])
	cloak.color = Color("#8c2f12")
	_horse.add_child(cloak)
	_rect(_horse, Vector2(-3, -254), Vector2(6, 70), Color(0.25, 0.08, 0.04, 0.55))

	# Arms + hands.
	_rect(_horse, Vector2(-42, -250), Vector2(12, 46), Color("#6d2310"))
	_rect(_horse, Vector2(30, -250), Vector2(12, 46), Color("#6d2310"))
	_rect(_horse, Vector2(-42, -210), Vector2(12, 12), Color("#d9a06b"))
	_rect(_horse, Vector2(30, -210), Vector2(12, 12), Color("#d9a06b"))

	# Hood + iron helmet (back of the rider's head, not a face).
	_ellipse(_horse, Vector2(0, -284), Vector2(23, 25), Color("#3a1a0e"))
	_ellipse(_horse, Vector2(0, -284), Vector2(17, 19), Color("#4a4a52"))
	_rect(_horse, Vector2(-15, -292), Vector2(30, 4), Color("#c9b56a"))
	_rect(_horse, Vector2(-16, -301), Vector2(32, 9), Color("#2a1a10"))

func _update_horse(delta: float) -> void:
	var jump_height := 0.0
	if _is_jumping:
		var t := clampf(_jump_t / JUMP_TIME, 0.0, 1.0)
		jump_height = sin(t * PI) * JUMP_HEIGHT
	var bob := 0.0
	if not _is_jumping:
		bob = sin(_run_time * 17.0) * 2.0
	_horse.position = Vector2(_horse_x, HORSE_FEET_Y - jump_height + bob)
	_horse.rotation = lerpf(_horse.rotation, _steer * 0.07, minf(1.0, delta * 12.0))
	if _shadow:
		var shrink := 1.0 - (jump_height / JUMP_HEIGHT) * 0.45
		_shadow.position = Vector2(_horse_x, HORSE_FEET_Y + 7.0)
		_shadow.scale = Vector2(shrink, shrink)
		_shadow.color = Color(0.0, 0.0, 0.0, 0.35 * shrink)

# ---------------------------------------------------------------------------
# Obstacles — barrels (dodge) and fences (jump)
# ---------------------------------------------------------------------------

func _spawn_obstacle() -> void:
	var index := _spawn_count
	var kind := 0 if index % 3 != 2 else 1
	_spawn_count += 1
	var node := Node2D.new()
	if kind == 0:
		_build_barrel(node)
		# Draw barrels in front of the horse so the one you are about to hit is readable.
		node.z_index = 3
		# The first barrel is dead-center so the player has to steer.
		var lane := 0.0 if index == 0 else randf_range(-0.82, 0.82)
		node.position = Vector2(VX + lane * ROAD_FAR_HALF, HORIZON_Y)
		node.scale = Vector2(0.08, 0.08)
		_obstacle_layer.add_child(node)
		_obstacles.append({"node": node, "kind": 0, "lane": lane, "z": 0.0})
	else:
		_build_fence(node)
		node.z_index = 1
		node.position = Vector2(VX, HORIZON_Y)
		node.scale = Vector2(ROAD_FAR_HALF / ROAD_NEAR_HALF, 0.08)
		_obstacle_layer.add_child(node)
		_obstacles.append({"node": node, "kind": 1, "lane": 0.0, "z": 0.0})

func _build_barrel(root: Node2D) -> void:
	# Big foreground barrel — roughly horse-height so it reads at a glance.
	_rect(root, Vector2(-44, -120), Vector2(88, 120), Color("#8c5a2b"))
	_rect(root, Vector2(-48, -128), Vector2(96, 14), Color("#b07a3f"))
	_rect(root, Vector2(-44, -98), Vector2(88, 10), Color("#3a2414"))
	_rect(root, Vector2(-44, -46), Vector2(88, 10), Color("#3a2414"))
	_rect(root, Vector2(-28, -108), Vector2(12, 96), Color("#a86a32"))
	_rect(root, Vector2(18, -108), Vector2(8, 96), Color("#7a4a24"))
	_ellipse(root, Vector2(0, -128), Vector2(48, 10), Color("#c08a4a"))

func _build_fence(root: Node2D) -> void:
	var w := ROAD_NEAR_HALF * 2.0
	var post_w := 20.0
	_rect(root, Vector2(-ROAD_NEAR_HALF, -96), Vector2(post_w, 96), Color("#5a3a22"))
	_rect(root, Vector2(ROAD_NEAR_HALF - post_w, -96), Vector2(post_w, 96), Color("#5a3a22"))
	_rect(root, Vector2(-ROAD_NEAR_HALF, -78), Vector2(w, 16), Color("#8c5a2b"))
	_rect(root, Vector2(-ROAD_NEAR_HALF, -44), Vector2(w, 14), Color("#7a4a24"))
	_rect(root, Vector2(-ROAD_NEAR_HALF, -82), Vector2(w, 3), Color("#c9b56a"))
	_rect(root, Vector2(-ROAD_NEAR_HALF, -48), Vector2(w, 3), Color("#c9b56a"))

func _update_obstacles(delta: float) -> void:
	var speed := 0.70 + 0.10 * (GameManager.difficulty - 1.0)
	var drop: Array = []
	for ob in _obstacles:
		var z: float = float(ob["z"]) + speed * delta
		ob["z"] = z
		if z > REMOVE_Z:
			drop.append(ob)
			continue

		var scale := _scale_at(z)
		var y := _depth_y(z)
		var half := _road_half_at(z)
		var node: Node2D = ob["node"]
		var lane: float = ob["lane"]
		if int(ob["kind"]) == 0:
			node.position = Vector2(VX + lane * half, y)
			node.scale = Vector2(scale, scale)
		else:
			node.position = Vector2(VX, y)
			node.scale = Vector2(half / ROAD_NEAR_HALF, scale)

		if z < COLLISION_Z_MIN or z > COLLISION_Z_MAX:
			continue
		if int(ob["kind"]) == 0:
			if not _is_jumping and absf(VX + lane * half - _horse_x) < BARREL_HIT_RADIUS:
				fail()
				return
		elif not _is_jumping:
			fail()
			return

	for ob in drop:
		_obstacles.erase(ob)
		ob["node"].queue_free()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _rect(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func _ellipse(parent: Node, center: Vector2, radius: Vector2, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	p.polygon = pts
	p.color = color
	if parent != null:
		parent.add_child(p)
	return p

func _set_hint(text: String) -> void:
	var hint: Label = get_node_or_null("CanvasLayer/Hint")
	if hint:
		hint.text = text
