extends TaskBase
## StirTask — "STIR THE STEW!"
## Circle with WASD to move the large ladle around the isometric cauldron.
## Detects angular progress around the pot.

const POT_CENTER: Vector2 = Vector2(640, 320)
const RIM_RX: float = 262.0
const RIM_RY: float = 102.0
const SOUP_RX: float = 226.0
const SOUP_RY: float = 80.0
const STIR_RX: float = 175.0
const STIR_RY: float = 48.0

var angle: float = 0.0
var last_angle: float = 0.0
var total_spin: float = 0.0
var needed_spins: float = 2.6
var pos: Vector2 = Vector2.ZERO
var bubble_timer: float = 0.0
var fire_time: float = 0.0

var _pot: Node2D
var _fire: Node2D
var _ladle: Node2D
var _bubble_layer: Node2D

@onready var progress: ProgressBar = $CanvasLayer/StirBar

func _ready() -> void:
	command_text = "STIR THE STEW!"
	needed_spins = 2.2 + GameManager.difficulty * 0.5
	if progress:
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.08, 0.06, 0.04, 0.9)
		bg.border_color = Color(0.55, 0.45, 0.28, 1.0)
		bg.set_border_width_all(2)
		bg.set_corner_radius_all(3)
		progress.add_theme_stylebox_override("background", bg)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color.WHITE
		fill.set_corner_radius_all(2)
		progress.add_theme_stylebox_override("fill", fill)
	super._ready()

func on_task_start() -> void:
	total_spin = 0.0
	angle = 0.0
	last_angle = 0.0
	bubble_timer = 0.0
	fire_time = 0.0
	pos = POT_CENTER + Vector2(STIR_RX, 0)
	_build_scene()
	_update_ladle()
	if progress:
		progress.max_value = needed_spins * TAU
		progress.value = 0.0
		progress.modulate = Color("#ffd94c")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()

	fire_time += delta
	if _fire:
		_fire.scale = Vector2(1.0, 1.0 + sin(fire_time * 8.0) * 0.04)

	# WASD moves the ladle bowl around the soup.
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() > 0.15:
		pos += dir * 380.0 * delta
		pos = _clamp_to_stir(pos - POT_CENTER)

	var vec := pos - POT_CENTER
	var n := Vector2(vec.x / STIR_RX, vec.y / STIR_RY)
	angle = atan2(n.y, n.x)
	var delta_angle := angle - last_angle
	if delta_angle > PI:
		delta_angle -= TAU
	elif delta_angle < -PI:
		delta_angle += TAU

	if vec.length() > 20.0 and absf(delta_angle) < 0.5 and absf(delta_angle) > 0.01:
		total_spin += absf(delta_angle)
		_update_ladle()
		bubble_timer -= delta
		if bubble_timer <= 0.0:
			_pop_bubble()
			bubble_timer = 0.14
	last_angle = angle

	if progress:
		progress.value = total_spin
		progress.modulate = Color("#7cff7c") if total_spin > needed_spins * TAU * 0.7 else Color("#ffd94c")
	if total_spin >= needed_spins * TAU:
		succeed()

# ---------------------------------------------------------------------------
# Scene construction — isometric cauldron, fire, large ladle
# ---------------------------------------------------------------------------

func _build_scene() -> void:
	_ellipse(self, Vector2(640, 610), Vector2(300, 32), Color(0.0, 0.0, 0.0, 0.35))
	_build_fire()
	_build_pot()
	_bubble_layer = Node2D.new()
	_bubble_layer.name = "Bubbles"
	add_child(_bubble_layer)
	_build_ladle()

func _build_fire() -> void:
	_fire = Node2D.new()
	_fire.name = "Fire"
	_fire.position = Vector2(640, 600)
	add_child(_fire)

	_ellipse(_fire, Vector2(0, 8), Vector2(155, 34), Color(1.0, 0.45, 0.12, 0.16))

	# Logs.
	_poly(_fire, PackedVector2Array([
		Vector2(-110, 10), Vector2(-20, 28), Vector2(100, 4),
		Vector2(96, 20), Vector2(-24, 44), Vector2(-112, 26),
	]), Color("#2a1a10"))
	_poly(_fire, PackedVector2Array([
		Vector2(-110, 14), Vector2(-20, 30), Vector2(100, 8),
		Vector2(96, 16), Vector2(-22, 36), Vector2(-108, 22),
	]), Color("#6b4a2a"))
	_poly(_fire, PackedVector2Array([
		Vector2(-90, 24), Vector2(10, 8), Vector2(110, 28),
		Vector2(108, 38), Vector2(8, 20), Vector2(-88, 34),
	]), Color("#2a1a10"))
	_poly(_fire, PackedVector2Array([
		Vector2(-90, 27), Vector2(10, 12), Vector2(110, 31),
		Vector2(108, 35), Vector2(8, 18), Vector2(-88, 30),
	]), Color("#8a5a32"))

	# Layered flames.
	_poly(_fire, PackedVector2Array([
		Vector2(-90, 10), Vector2(-62, -60), Vector2(-38, -30),
		Vector2(-12, -100), Vector2(12, -45), Vector2(36, -85),
		Vector2(62, -30), Vector2(88, 10),
	]), Color("#8c2f12"))
	_poly(_fire, PackedVector2Array([
		Vector2(-70, 10), Vector2(-46, -45), Vector2(-24, -20),
		Vector2(-2, -80), Vector2(18, -30), Vector2(42, -60),
		Vector2(66, 10),
	]), Color("#d4551f"))
	_poly(_fire, PackedVector2Array([
		Vector2(-42, 8), Vector2(-26, -30), Vector2(-8, -12),
		Vector2(8, -52), Vector2(26, -22), Vector2(42, 8),
	]), Color("#ffb52e"))
	_poly(_fire, PackedVector2Array([
		Vector2(-20, 6), Vector2(-10, -20), Vector2(2, -34),
		Vector2(16, -14), Vector2(24, 6),
	]), Color("#ffe066"))

	_circle(_fire, Vector2(-58, 16), 4, Color("#ffb52e"))
	_circle(_fire, Vector2(54, 20), 3, Color("#ffd94c"))
	_circle(_fire, Vector2(8, 24), 3, Color("#ff7a2e"))

func _build_pot() -> void:
	_pot = Node2D.new()
	_pot.name = "Pot"
	add_child(_pot)

	# Legs (behind the body).
	_leg(Vector2(500, 530), Vector2(520, 590), Vector2(548, 590), Vector2(536, 530))
	_leg(Vector2(744, 530), Vector2(762, 590), Vector2(790, 590), Vector2(778, 530))
	_leg(Vector2(628, 535), Vector2(638, 580), Vector2(658, 580), Vector2(650, 535))

	# Cauldron body.
	var body_outline := PackedVector2Array([
		Vector2(374, 320), Vector2(382, 432), Vector2(440, 520),
		Vector2(530, 562), Vector2(750, 562), Vector2(840, 520),
		Vector2(898, 432), Vector2(906, 320), Vector2(640, 286),
	])
	var body_fill := PackedVector2Array([
		Vector2(384, 326), Vector2(392, 428), Vector2(448, 512),
		Vector2(534, 552), Vector2(746, 552), Vector2(832, 512),
		Vector2(888, 428), Vector2(896, 326), Vector2(640, 300),
	])
	_poly(_pot, body_outline, Color("#141418"))
	_poly(_pot, body_fill, Color("#2b2b33"))

	# Cel-shaded facets.
	_poly(_pot, PackedVector2Array([
		Vector2(392, 340), Vector2(400, 428), Vector2(452, 508),
		Vector2(534, 548), Vector2(600, 548), Vector2(560, 500),
		Vector2(510, 430), Vector2(480, 350),
	]), Color("#41414b"))
	_poly(_pot, PackedVector2Array([
		Vector2(888, 340), Vector2(880, 428), Vector2(828, 508),
		Vector2(746, 548), Vector2(680, 548), Vector2(720, 500),
		Vector2(770, 430), Vector2(800, 350),
	]), Color("#1c1c22"))

	# Rim + soup surface.
	_ellipse(_pot, POT_CENTER, Vector2(RIM_RX, RIM_RY), Color("#141418"))
	_ellipse(_pot, POT_CENTER, Vector2(RIM_RX - 10, RIM_RY - 8), Color("#3a3a44"))
	_ellipse(_pot, POT_CENTER, Vector2(RIM_RX - 22, RIM_RY - 16), Color("#4a4a55"))
	_ellipse(_pot, POT_CENTER, Vector2(SOUP_RX, SOUP_RY), Color("#2f4a22"))
	_ellipse(_pot, POT_CENTER + Vector2(-24, -12), Vector2(170, 46), Color("#3a5a2a"))
	_ellipse(_pot, POT_CENTER + Vector2(-58, -22), Vector2(90, 24), Color("#4a6a34"))
	_circle(_pot, POT_CENTER + Vector2(120, 18), 6, Color("#6b8a3a"))
	_circle(_pot, POT_CENTER + Vector2(-130, 26), 5, Color("#5a7a2e"))
	_circle(_pot, POT_CENTER + Vector2(60, -40), 4, Color("#6b8a3a"))

	# Side handles.
	_arc_line(_pot, Vector2(386, 360), 44, -PI / 2.0, -3.0 * PI / 2.0, Color("#141418"), 18)
	_arc_line(_pot, Vector2(386, 360), 44, -PI / 2.0, -3.0 * PI / 2.0, Color("#4a4a55"), 11)
	_arc_line(_pot, Vector2(894, 360), 44, -PI / 2.0, PI / 2.0, Color("#141418"), 18)
	_arc_line(_pot, Vector2(894, 360), 44, -PI / 2.0, PI / 2.0, Color("#4a4a55"), 11)

func _build_ladle() -> void:
	_ladle = Node2D.new()
	_ladle.name = "Ladle"
	_ladle.position = pos
	add_child(_ladle)

	# Long wooden handle with a dark outline.
	_poly(_ladle, PackedVector2Array([
		Vector2(20, -14), Vector2(210, -66), Vector2(218, -52), Vector2(28, 2),
	]), Color("#1a1208"))
	_poly(_ladle, PackedVector2Array([
		Vector2(22, -10), Vector2(206, -60), Vector2(210, -54), Vector2(28, -2),
	]), Color("#6b4a2a"))
	_poly(_ladle, PackedVector2Array([
		Vector2(44, -24), Vector2(64, -29), Vector2(68, -16), Vector2(48, -11),
	]), Color("#c9b56a"))
	_circle(_ladle, Vector2(214, -58), 10, Color("#1a1208"))
	_circle(_ladle, Vector2(214, -58), 7, Color("#8a5a32"))

	# Bowl.
	_ellipse(_ladle, Vector2.ZERO, Vector2(38, 28), Color("#1a1208"))
	_ellipse(_ladle, Vector2.ZERO, Vector2(32, 22), Color("#8a5a32"))
	_ellipse(_ladle, Vector2.ZERO, Vector2(24, 15), Color("#3a2414"))
	_ellipse(_ladle, Vector2(-8, -7), Vector2(10, 5), Color(1.0, 0.9, 0.7, 0.35))

func _leg(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> void:
	_poly(_pot, PackedVector2Array([a, b, c, d]), Color("#141418"))
	var mid := (a + b + c + d) / 4.0
	_poly(_pot, PackedVector2Array([
		a.lerp(mid, 0.18), b.lerp(mid, 0.18), c.lerp(mid, 0.18), d.lerp(mid, 0.18),
	]), Color("#2b2b33"))

# ---------------------------------------------------------------------------
# Stir math
# ---------------------------------------------------------------------------

func _update_ladle() -> void:
	if _ladle:
		_ladle.position = pos

func _clamp_to_stir(v: Vector2) -> Vector2:
	var n := Vector2(v.x / STIR_RX, v.y / STIR_RY)
	if n.length() < 0.0001:
		n = Vector2.RIGHT
	n = n.normalized()
	return POT_CENTER + Vector2(n.x * STIR_RX, n.y * STIR_RY)

func _pop_bubble() -> void:
	var a := randf() * TAU
	var r := sqrt(randf()) * 0.72
	var p := POT_CENTER + Vector2(cos(a) * SOUP_RX * r, sin(a) * SOUP_RY * r)
	var b := _circle_poly(randf_range(4.0, 8.0), Color(0.6, 0.85, 0.55, 0.7))
	b.position = p
	_bubble_layer.add_child(b)
	var t := create_tween()
	t.tween_property(b, "position:y", b.position.y - 34.0, 0.5)
	t.parallel().tween_property(b, "modulate:a", 0.0, 0.5)
	t.finished.connect(func(): if is_instance_valid(b): b.queue_free())

# ---------------------------------------------------------------------------
# Drawing helpers
# ---------------------------------------------------------------------------

func _poly(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = color
	parent.add_child(p)
	return p

func _circle(parent: Node, center: Vector2, radius: float, color: Color) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * float(i) / 28.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return _poly(parent, pts, color)

func _ellipse(parent: Node, center: Vector2, radius: Vector2, color: Color) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * float(i) / 40.0
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	return _poly(parent, pts, color)

func _arc_line(parent: Node, center: Vector2, radius: float, from: float, to: float, color: Color, width: float) -> Line2D:
	var l := Line2D.new()
	var pts := PackedVector2Array()
	for i in 25:
		var a := lerpf(from, to, float(i) / 24.0)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	l.points = pts
	l.width = width
	l.default_color = color
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	parent.add_child(l)
	return l

func _circle_poly(radius: float, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	p.polygon = pts
	p.color = color
	return p
