extends TaskBase
## SmithTask — "FUEL THE FIRE!"
## Two gestures at once: F to pump the bellows (keep the heat up) while A/D moves the
## blade onto the glowing mark. Settle 5 marks. Let the fire die and you fail.

const SETTLES_NEEDED: int = 5
var heat: float = 70.0
var sword_x: float = 640.0
var rune_x: float = 640.0
var settle_t: float = 0.0
var settles: int = 0

var _sword_rect: ColorRect
var _rune_rect: ColorRect
var _heat_bar: ProgressBar

func _ready() -> void:
	command_text = "FUEL THE FIRE!"
	super._ready()

func on_task_start() -> void:
	rune_x = randf_range(220.0, 1060.0)
	_sword_rect = ColorRect.new()
	_sword_rect.size = Vector2(18, 60)
	_sword_rect.color = Color("#9ad4ff")
	_sword_rect.position = Vector2(sword_x - 9, 396)
	add_child(_sword_rect)

	_rune_rect = ColorRect.new()
	_rune_rect.size = Vector2(40, 14)
	_rune_rect.color = Color("#ffd94c")
	_rune_rect.position = Vector2(rune_x - 20, 470)
	add_child(_rune_rect)

	_heat_bar = ProgressBar.new()
	_heat_bar.name = "HeatBar"
	_heat_bar.max_value = 100.0
	_heat_bar.value = heat
	_heat_bar.show_percentage = false
	_heat_bar.anchor_left = 0.5
	_heat_bar.anchor_right = 0.5
	_heat_bar.offset_left = -250.0
	_heat_bar.offset_right = 250.0
	_heat_bar.offset_top = 90.0
	_heat_bar.offset_bottom = 112.0
	get_node("CanvasLayer").add_child(_heat_bar)

	_set_hint("F pump the bellows   A/D forge on the glow")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()
	heat -= 26.0 * delta
	if Input.is_action_just_pressed("mash"):
		heat += 9.0
		gesture_performed("mash")
	heat = clampf(heat, 0.0, 100.0)

	var dir := Input.get_axis("move_left", "move_right")
	sword_x += dir * 360.0 * delta
	sword_x = clampf(sword_x, 200.0, 1080.0)

	if _sword_rect:
		_sword_rect.position.x = sword_x - 9.0
	if _heat_bar:
		_heat_bar.value = heat
		var hot: bool = heat >= 55.0
		_heat_bar.modulate = Color("#7cff7c") if hot else Color("#ff4a4a")

	# Settle if aligned AND hot at the same time — both gestures must be live
	var aligned: bool = absf(sword_x - rune_x) < 30.0
	if aligned and heat >= 55.0:
		settle_t += delta
		if _rune_rect:
			_rune_rect.modulate = Color(1.0, 1.0, 1.0) if int(settle_t * 10.0) % 2 == 0 else Color("#ffd94c")
	else:
		settle_t = 0.0
		if _rune_rect:
			_rune_rect.modulate = Color("#ffd94c")

	if settle_t >= 0.45:
		settle_t = 0.0
		settles += 1
		var label: Label = get_node_or_null("CanvasLayer/ProgressLabel")
		if not label:
			label = _add_progress_label()
		label.text = "%d/%d" % [settles, SETTLES_NEEDED]
		rune_x = randf_range(220.0, 1060.0)
		if _rune_rect:
			_rune_rect.position.x = rune_x - 20.0
		if settles >= SETTLES_NEEDED:
			succeed()

	if heat <= 0.0:
		fail()

func _add_progress_label() -> Label:
	var label := Label.new()
	label.name = "ProgressLabel"
	label.text = "0/%d" % SETTLES_NEEDED
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