extends TaskBase
## CrankTask — "CRANK IT!"
## Two gestures at once: hold A/D to spin the pointer, mash F on the gold zone.
## If you stop spinning, the winch seizes and you fail.

const CENTER: Vector2 = Vector2(640, 300)
const RADIUS: float = 210.0
const SPIN_SPEED: float = 3.0

var needles: float = 0.0          # pointer speed
var needle_angle: float = 0.0
var target_angle: float = 0.0
var catches: int = 0
const NEED_REPEAT_CATCHES: int = 6
var stopped_time: float = 0.0

func _ready() -> void:
	command_text = "CRANK IT!"
	super._ready()

func on_task_start() -> void:
	target_angle = randf() * TAU
	_queue_redraw()
	_set_hint("Hold A/D to spin   F on gold")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		needles = dir * SPIN_SPEED
		needle_angle += needles * delta
		stopped_time = 0.0
	else:
		needles = 0.0
		stopped_time += delta
		if stopped_time > 1.1:
			fail()
			return

	var diff := _norm_angle(needle_angle - target_angle)
	var hot: bool = absf(diff) < 0.45
	# Make the zone glow while the needle is inside it
	queue_redraw()

	var label: Label = get_node_or_null("CanvasLayer/ProgressLabel")
	if not label:
		label = _add_progress_label()

	if Input.is_action_just_pressed("mash") and hot:
		gesture_performed("mash")
		catches += 1
		target_angle = randf() * TAU
		label.text = "%d/%d" % [catches, NEED_REPEAT_CATCHES]
		if catches >= NEED_REPEAT_CATCHES:
			succeed()

func _norm_angle(a: float) -> float:
	return fposmod(a + PI, TAU) - PI

func _draw() -> void:
	var c := CENTER
	# Wheel body
	draw_circle(c, RADIUS * 0.42, Color(0.16, 0.10, 0.05))
	draw_arc(c, RADIUS * 0.42, 0, TAU, 48, Color("#6b5a3e"), 6.0, true)
	# Target zone
	var hot: bool = absf(_norm_angle(needle_angle - target_angle)) < 0.45
	draw_sector(c, target_angle - 0.45, target_angle + 0.45, RADIUS, Color("#ffd94c") if hot else Color(0.55, 0.45, 0.22))
	# Pointer
	var tip := Vector2.from_angle(needle_angle)
	var p_from := c + tip * 30.0
	var p_to := c + tip * RADIUS
	draw_line(p_from, p_to, Color("#7cff7c"), 4.0)
	draw_circle(p_to, 8.0, Color("#c9b56a"))

func draw_sector(center: Vector2, from: float, to: float, radius: float, color: Color) -> void:
	var pts: PackedVector2Array = [center]
	var steps: int = 20
	for i in steps + 1:
		var a: float = lerpf(from, to, float(i) / float(steps))
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(pts, color)

func _queue_redraw() -> void:
	queue_redraw()

func _add_progress_label() -> Label:
	var label := Label.new()
	label.name = "ProgressLabel"
	label.text = "0/%d" % NEED_REPEAT_CATCHES
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1, 0.851, 0.298))
	label.add_theme_color_override("font_outline_color", Color(0.09, 0.07, 0.03))
	label.add_theme_constant_override("outline_size", 6)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -100.0
	label.offset_top = 540.0
	label.offset_right = 100.0
	label.offset_bottom = 576.0
	get_node("CanvasLayer").add_child(label)
	return label

func _set_hint(text: String) -> void:
	var hint: Label = get_node_or_null("CanvasLayer/Hint")
	if hint:
		hint.text = text