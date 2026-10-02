extends TaskBase
## RowTask — "ROW!"
## Two gestures at once: A/D steer the boat, F to row. Slip through 6 river gates.
## Stroke to advance; you only pass a gate if you're aligned with its opening.

var boat_x: float = 640.0
var strokes: int = 0
var gates_done: int = 0
var strokes_per_gate: int = 5
var _gates: Array = []  # {x, y}

var _boat_rect: ColorRect

func _ready() -> void:
	command_text = "ROW!"
	super._ready()

func on_task_start() -> void:
	strokes_per_gate = 5 if GameManager.difficulty < 1.6 else 6
	_gates.clear()
	for i in 6:
		_gates.append({
			"x": randf_range(220.0, 1060.0),
			"y": 500.0 - float(i) * 84.0,
			"done": false,
		})
	_boat_rect = ColorRect.new()
	_boat_rect.size = Vector2(60, 26)
	_boat_rect.color = Color("#7cff7c")
	add_child(_boat_rect)
	_build_gate_visuals()
	_set_hint("A/D steer   F to row")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()
	var dir := Input.get_axis("move_left", "move_right")
	boat_x += dir * 380.0 * delta
	boat_x = clampf(boat_x, 140.0, 1140.0)

	var boat_y: float = 500.0 - float(strokes) * 12.0
	if _boat_rect:
		_boat_rect.position = Vector2(boat_x - 30.0, boat_y - 13.0)

	if Input.is_action_just_pressed("mash"):
		gesture_performed("mash")
		strokes = gesture_count("mash")
		var label: Label = get_node_or_null("CanvasLayer/ProgressLabel")
		if not label:
			label = _add_progress_label()
		label.text = "%d/%d" % [gates_done, 6]
		if gates_done < 6:
			var gate: Dictionary = _gates[gates_done]
			if strokes >= strokes_per_gate * (gates_done + 1) and absf(boat_x - gate["x"]) < 62.0:
				gate["done"] = true
				gates_done += 1
				label.text = "%d/%d" % [gates_done, 6]
				if gates_done >= 6:
					succeed()

func _build_gate_visuals() -> void:
	# line of the river
	var river := ColorRect.new()
	river.size = Vector2(1280, 2)
	river.position = Vector2(0, 560)
	river.color = Color(0.16, 0.22, 0.3)
	add_child(river)
	for gate in _gates:
		var x: float = gate["x"]
		var y: float = gate["y"]
		var p1 := ColorRect.new()
		p1.size = Vector2(34, 16)
		p1.color = Color("#8c2f12")
		p1.position = Vector2(x - 220.0, y - 8.0)
		add_child(p1)
		var p2 := ColorRect.new()
		p2.size = Vector2(34, 16)
		p2.color = Color("#8c2f12")
		p2.position = Vector2(x + 186.0, y - 8.0)
		add_child(p2)

func _add_progress_label() -> Label:
	var label := Label.new()
	label.name = "ProgressLabel"
	label.text = "0/6"
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