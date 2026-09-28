extends TaskBase
## SpinTask — "SPIN THE WHEEL!"
## Two gestures at once: hold A or D to keep the pot spinning, press SPACE to mold
## a lump as it swings past the front. Stop spinning and the clay collapses.

const POT: Vector2 = Vector2(640, 360)
const RADIUS: float = 150.0
const MOLD_NEEDED: int = 6

var spin: float = 2.5
var cold_time: float = 0.0
var molded: int = 0
var lumps: Array = []  # float angles

func _ready() -> void:
	command_text = "SPIN THE WHEEL!"
	super._ready()

func on_task_start() -> void:
	lumps.clear()
	for i in MOLD_NEEDED:
		lumps.append(float(i) * (TAU / float(MOLD_NEEDED)))
	queue_redraw()
	_set_hint("Hold A/D to spin   SPACE to mold")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		spin += 3.2 * delta
		cold_time = 0.0
	else:
		spin -= 1.6 * delta
		cold_time += delta
		if cold_time > 1.6:
			fail()
			return
	spin = clampf(spin, 0.0, 6.0)

	for i in lumps.size():
		lumps[i] = fposmod(lumps[i] + spin * delta, TAU)

	if Input.is_action_just_pressed("action"):
		for i in lumps.size():
			if absf(_norm_angle(lumps[i])) < 0.30:
				lumps[i] = randf() * TAU
				molded += 1
				var label: Label = get_node_or_null("CanvasLayer/ProgressLabel")
				if not label:
					label = _add_progress_label()
				label.text = "%d/%d" % [molded, MOLD_NEEDED]
				if molded >= MOLD_NEEDED:
					succeed()
				break

	queue_redraw()

func _norm_angle(a: float) -> float:
	return fposmod(a + PI, TAU) - PI

func _draw() -> void:
	draw_circle(POT, RADIUS, Color(0.55, 0.36, 0.18))
	draw_arc(POT, RADIUS, 0, TAU, 40, Color("#1a1208"), 6.0, true)
	for a in lumps:
		var on_front: bool = absf(_norm_angle(a)) < 0.30
		var pos := POT + Vector2.from_angle(a) * RADIUS
		draw_circle(pos, 11.0, Color("#ffd94c") if on_front else Color(0.62, 0.5, 0.25))
	draw_circle(POT + Vector2.from_angle(0.0) * (RADIUS + 22.0), 6.0, Color("#7cff7c"))

func _add_progress_label() -> Label:
	var label := Label.new()
	label.name = "ProgressLabel"
	label.text = "0/%d" % MOLD_NEEDED
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