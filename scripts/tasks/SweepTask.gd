extends TaskBase
## SweepTask — "SWEEP!"
## Two gestures at once: hold SPACE to sweep while A/D moves the broom along the floor.
## Clear 12 spots of grime. Sweeping only works while the broom is over them.

const CLEAN_NEEDED: int = 12
var broom_x: float = 640.0
var cleaned: int = 0
var spawn_t: float = 0.0
var sweep_on: bool = false
var _spots: Array = []  # {rect, x, y}

var _broom: ColorRect
var _glow: ColorRect

func _ready() -> void:
	command_text = "SWEEP!"
	super._ready()

func on_task_start() -> void:
	_broom = ColorRect.new()
	_broom.size = Vector2(10, 90)
	_broom.color = Color("#c9b56a")
	add_child(_broom)
	_glow = ColorRect.new()
	_glow.size = Vector2(96, 6)
	_glow.color = Color("#ffd94c")
	_glow.visible = false
	add_child(_glow)
	for i in CLEAN_NEEDED:
		_add_spot()
	spawn_t = 0.6
	_set_hint("Hold SPACE to sweep   A/D move")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()
	var dir := Input.get_axis("move_left", "move_right")
	broom_x += dir * 430.0 * delta
	broom_x = clampf(broom_x, 120.0, 1160.0)

	if Input.is_action_just_pressed("action"):
		gesture_performed("action")
	sweep_on = Input.is_action_pressed("action")

	if _broom:
		_broom.position = Vector2(broom_x - 5, 430)
	if _glow:
		_glow.position = Vector2(broom_x - 48, 520)
		_glow.visible = sweep_on

	if sweep_on:
		for spot in _spots.duplicate():
			var sx: float = spot["x"]
			if absf(sx - broom_x) < 48.0:
				spot["rect"].queue_free()
				_spots.erase(spot)
				cleaned += 1
				var label: Label = get_node_or_null("CanvasLayer/ProgressLabel")
				if not label:
					label = _add_progress_label()
				label.text = "%d/%d" % [cleaned, CLEAN_NEEDED]
				if cleaned >= CLEAN_NEEDED:
					succeed()

	# Keep a plateau of grime to sweep
	spawn_t -= delta
	if spawn_t <= 0.0 and _spots.size() < 8:
		_add_spot()
		spawn_t = 0.45

func _add_spot() -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(20, 14)
	rect.color = Color("#6a5a3e")
	var x: float = randf_range(160.0, 1120.0)
	var y: float = randf_range(520.0, 534.0)
	rect.position = Vector2(x, y)
	add_child(rect)
	_spots.append({"rect": rect, "x": x, "y": y})

func _add_progress_label() -> Label:
	var label := Label.new()
	label.name = "ProgressLabel"
	label.text = "0/%d" % CLEAN_NEEDED
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