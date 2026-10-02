extends TaskBase
## TightWireTask — "TIGHT-WIRE!"
## Two gestures at once: A/D to balance the pole (keep the marker inside the gold),
## SPACE to step forward. 8 steps. Fall if you over-balance.

const STEPS_NEEDED: int = 8
var step: int = 0
var tilt: float = 0.0
var player_x: float = 180.0
var falling: bool = false

func _ready() -> void:
	command_text = "TIGHT-WIRE!"
	super._ready()

func on_task_start() -> void:
	tilt = 0.0
	step = 0
	queue_redraw()
	_set_hint("A/D balance   SPACE to step")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()
	# Wobble + drift to the edges — keep fighting it
	tilt += (randf() - 0.5) * 3.4 * delta + tilt * 0.18 * delta
	if Input.is_action_pressed("move_left"):
		tilt -= 1.15 * delta
	if Input.is_action_pressed("move_right"):
		tilt += 1.15 * delta
	tilt = clampf(tilt, -1.2, 1.2)

	if absf(tilt) > 1.0:
		falling = true
		fail()
		return

	if Input.is_action_just_pressed("action"):
		gesture_performed("action")
		step += 1
		tilt *= 0.35
		player_x = lerpf(180.0, 1100.0, float(step) / float(STEPS_NEEDED))

	var label: Label = get_node_or_null("CanvasLayer/ProgressLabel")
	if not label:
		label = _add_progress_label()
	label.text = "%d/%d" % [step, STEPS_NEEDED]

	if step >= STEPS_NEEDED:
		succeed()
		return

	queue_redraw()

func _draw() -> void:
	var rope_y: float = 400.0
	draw_rect(Rect2(180, rope_y - 1.5, 920, 3), Color("#c9b56a"))
	# player along the rope
	var bob := sin(Time.get_ticks_msec() * 0.02) * (3.0 + absf(tilt) * 14.0)
	draw_circle(Vector2(player_x, rope_y - 12.0 + bob), 12.0, Color("#7cff7c"))
	# balance bar
	var bar_y: float = 550.0
	draw_rect(Rect2(540, bar_y - 6, 200, 12), Color(0.1, 0.08, 0.04))
	draw_rect(Rect2(590, bar_y - 6, 100, 12), Color("#ffd94c"))
	var marker_x: float = 640.0 + tilt * 100.0
	draw_rect(Rect2(marker_x - 4, bar_y - 10, 8, 20), Color("#ff4a4a"))

func _add_progress_label() -> Label:
	var label := Label.new()
	label.name = "ProgressLabel"
	label.text = "0/%d" % STEPS_NEEDED
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1, 0.851, 0.298))
	label.add_theme_color_override("font_outline_color", Color(0.09, 0.07, 0.03))
	label.add_theme_constant_override("outline_size", 6)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -100.0
	label.offset_top = 580.0
	label.offset_right = 100.0
	label.offset_bottom = 616.0
	get_node("CanvasLayer").add_child(label)
	return label

func _set_hint(text: String) -> void:
	var hint: Label = get_node_or_null("CanvasLayer/Hint")
	if hint:
		hint.text = text