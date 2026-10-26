extends TaskBase
## SealTask — "SEAL IT!"
## Drag the circular stamp onto the soft red wax on the opened scroll.
## Mouse drag / touch drag / WASD + Action also work.

const SEAL_CENTER: Vector2 = Vector2(700, 514)
const SEAL_RADIUS: float = 44.0
const STAMP_START: Vector2 = Vector2(320, 400)
const STAMP_MIN: Vector2 = Vector2(70, 120)
const STAMP_MAX: Vector2 = Vector2(1210, 620)
const STAMP_SPEED: float = 420.0

var stamp_pos: Vector2 = STAMP_START

var _scroll: Node2D
var _wax: Node2D
var _stamp: Node2D

func _ready() -> void:
	command_text = "SEAL IT!"
	super._ready()

func on_task_start() -> void:
	stamp_pos = STAMP_START
	_build_scroll()
	_build_wax()
	_build_stamp()
	_update_stamp()
	_set_hint("WASD move   SPACE stamp")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()

	# WASD moves the stamp; Space stamps it when it is over the wax.
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() > 0.1:
		stamp_pos += dir * STAMP_SPEED * delta
		stamp_pos.x = clampf(stamp_pos.x, STAMP_MIN.x, STAMP_MAX.x)
		stamp_pos.y = clampf(stamp_pos.y, STAMP_MIN.y, STAMP_MAX.y)
		_update_stamp()

	var near: bool = stamp_pos.distance_to(SEAL_CENTER) < SEAL_RADIUS + 12.0
	if _wax:
		_wax.scale = Vector2(1.12, 1.12) if near else Vector2.ONE
	if Input.is_action_just_pressed("action") and near:
		gesture_performed("action")
		_do_seal()

func _do_seal() -> void:
	if _finished:
		return
	stamp_pos = SEAL_CENTER
	_update_stamp()
	if _stamp:
		var tw := create_tween()
		tw.tween_property(_stamp, "scale", Vector2(0.88, 0.88), 0.08).set_trans(Tween.TRANS_BACK)
		tw.tween_property(_stamp, "scale", Vector2.ONE, 0.12)
	if _wax:
		_wax.scale = Vector2.ONE
	succeed()

func _update_stamp() -> void:
	if _stamp:
		_stamp.position = stamp_pos

# ---------------------------------------------------------------------------
# Opened scroll with handwritten script
# ---------------------------------------------------------------------------

func _build_scroll() -> void:
	_scroll = Node2D.new()
	_scroll.name = "Scroll"
	add_child(_scroll)

	var outline := PackedVector2Array([
		Vector2(536, 240), Vector2(864, 240), Vector2(870, 250),
		Vector2(866, 562), Vector2(858, 576), Vector2(542, 576),
		Vector2(534, 562), Vector2(538, 250),
	])
	var sheet := PackedVector2Array([
		Vector2(544, 246), Vector2(856, 246), Vector2(862, 256),
		Vector2(858, 558), Vector2(850, 568), Vector2(550, 568),
		Vector2(542, 558), Vector2(544, 256),
	])

	var shadow := _poly(_scroll, outline, Color(0.0, 0.0, 0.0, 0.32))
	shadow.position = Vector2(8, 10)
	_poly(_scroll, outline, Color("#8a7350"))
	_poly(_scroll, sheet, Color("#e8d8b0"))

	# A few faint age spots.
	_ellipse(_scroll, Vector2(800, 320), Vector2(16, 8), Color(0.55, 0.45, 0.28, 0.18))
	_ellipse(_scroll, Vector2(600, 430), Vector2(24, 11), Color(0.55, 0.45, 0.28, 0.14))
	_ellipse(_scroll, Vector2(780, 250), Vector2(10, 5), Color(0.55, 0.45, 0.28, 0.2))

	_roll(232.0)
	_roll(580.0)
	_build_handwriting()

func _roll(cy: float) -> void:
	var left := 522.0
	var right := 878.0
	var h := 20.0

	# Dark capsule outline.
	_rect(_scroll, Vector2(left, cy - h), Vector2(right - left, h * 2.0), Color("#5a3f24"))
	_circle(_scroll, Vector2(left, cy), h, Color("#5a3f24"))
	_circle(_scroll, Vector2(right, cy), h, Color("#5a3f24"))

	# Parchment roll body.
	_rect(_scroll, Vector2(left + 4, cy - h + 4), Vector2(right - left - 8, h * 2.0 - 8.0), Color("#d9c49a"))
	_circle(_scroll, Vector2(left + 4, cy), h - 4.0, Color("#d9c49a"))
	_circle(_scroll, Vector2(right - 4, cy), h - 4.0, Color("#d9c49a"))

	# Hard cel-shaded bands.
	_rect(_scroll, Vector2(left + 4, cy + 6), Vector2(right - left - 8, 6), Color(0.35, 0.25, 0.14, 0.55))
	_rect(_scroll, Vector2(left + 4, cy - 14), Vector2(right - left - 8, 4), Color(1.0, 0.94, 0.8, 0.65))

	# Rolled ends.
	_circle(_scroll, Vector2(left + 4, cy), 7, Color("#8a7350"))
	_circle(_scroll, Vector2(left + 4, cy), 3, Color("#b8a27a"))
	_circle(_scroll, Vector2(right - 4, cy), 7, Color("#8a7350"))
	_circle(_scroll, Vector2(right - 4, cy), 3, Color("#b8a27a"))

func _build_handwriting() -> void:
	var hand := _hand_font()
	_label(_scroll, "To the Crown,\n\nWe have held the pass.\nSend ale before the thaw.\n\nYour servant,", Vector2(572, 272), Vector2(272, 158), 19, Color("#2a1a10"), hand, -0.02)
	_label(_scroll, "— Sir S.", Vector2(690, 432), Vector2(150, 30), 22, Color("#2a1a10"), hand, -0.05)

func _hand_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray([
		"Bradley Hand", "Snell Roundhand", "Noteworthy", "Marker Felt", "Comic Sans MS",
	])
	return f

# ---------------------------------------------------------------------------
# Soft red wax gob (unstamped)
# ---------------------------------------------------------------------------

func _build_wax() -> void:
	_wax = Node2D.new()
	_wax.name = "Wax"
	_wax.position = SEAL_CENTER
	add_child(_wax)

	var shadow := _poly(_wax, _blob_points(39.0), Color(0.0, 0.0, 0.0, 0.3))
	shadow.position = Vector2(4, 6)
	_poly(_wax, _blob_points(42.0), Color("#3a0f0a"))
	_poly(_wax, _blob_points(37.0), Color("#a8321a"))
	_ellipse(_wax, Vector2(-10, -12), Vector2(15, 9), Color(1.0, 0.45, 0.32, 0.55))
	_ellipse(_wax, Vector2(20, 18), Vector2(8, 5), Color("#8c2f12"))
	_ellipse(_wax, Vector2(-22, 20), Vector2(6, 4), Color("#8c2f12"))

func _blob_points(radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * float(i) / 32.0
		var r := radius * (1.0 + 0.055 * sin(a * 3.0 + 0.7) + 0.035 * cos(a * 5.0 - 0.4))
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

# ---------------------------------------------------------------------------
# Circular stamp
# ---------------------------------------------------------------------------

func _build_stamp() -> void:
	_stamp = Node2D.new()
	_stamp.name = "Stamp"
	_stamp.position = stamp_pos
	_stamp.rotation = -0.1
	add_child(_stamp)

	# Handle.
	_rect(_stamp, Vector2(-11, -60), Vector2(22, 34), Color("#1a1208"))
	_rect(_stamp, Vector2(-8, -57), Vector2(16, 30), Color("#6b4a2a"))
	_circle(_stamp, Vector2(0, -60), 11, Color("#1a1208"))
	_circle(_stamp, Vector2(0, -60), 8, Color("#8a5a32"))

	# Circular base.
	_circle(_stamp, Vector2.ZERO, 40, Color("#1a1208"))
	_circle(_stamp, Vector2.ZERO, 36, Color("#6b4a2a"))
	_circle(_stamp, Vector2.ZERO, 30, Color("#c9b56a"))
	_circle(_stamp, Vector2.ZERO, 27, Color("#6b4a2a"))

	var sigil := _label(_stamp, "⚜", Vector2(-36, -26), Vector2(72, 52), 30, Color("#ffd94c"))
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.add_theme_color_override("font_outline_color", Color("#1a1208"))
	sigil.add_theme_constant_override("outline_size", 4)

	_circle(_stamp, Vector2(-10, -12), 4, Color(1.0, 0.9, 0.7, 0.5))

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
	for i in 36:
		var a := TAU * float(i) / 36.0
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return _poly(parent, pts, color)

func _ellipse(parent: Node, center: Vector2, radius: Vector2, color: Color) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in 36:
		var a := TAU * float(i) / 36.0
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	return _poly(parent, pts, color)

func _label(parent: Node, text: String, pos: Vector2, size: Vector2, font_size: int, color: Color, font: Font = null, rotation: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if font != null:
		l.add_theme_font_override("font", font)
	l.rotation = rotation
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _set_hint(text: String) -> void:
	var hint: Label = get_node_or_null("CanvasLayer/Hint")
	if hint:
		hint.text = text
