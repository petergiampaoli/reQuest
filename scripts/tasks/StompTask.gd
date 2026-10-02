extends TaskBase
## StompTask — "STOMP!"
## Two gestures at once: A/D slide the stomper onto the vine telegraph, then F when it
## bursts. Let any vine finish bursting and you fail.

const SLOTS: Array = [280, 393, 506, 619, 732, 845, 958]
const NEED_KILLS: int = 8

var player_x: float = 640.0
var kills: int = 0
var vine_timer: float = 0.0
var _vines: Array = []  # {slot, stage, t, rect, burst_t}

var _stomp_rect: ColorRect

func _ready() -> void:
	command_text = "STOMP!"
	super._ready()

func on_task_start() -> void:
	_stomp_rect = ColorRect.new()
	_stomp_rect.size = Vector2(64, 56)
	_stomp_rect.color = Color("#9ad4ff")
	_stomp_rect.position = Vector2(player_x - 32, 396)
	add_child(_stomp_rect)
	vine_timer = 0.4
	_set_hint("A/D position   F stomp the burst!")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()
	var dir := Input.get_axis("move_left", "move_right")
	player_x += dir * 400.0 * delta
	player_x = clampf(player_x, 200.0, 1040.0)
	if _stomp_rect:
		_stomp_rect.position.x = player_x - 32.0

	# Spawn cadence
	vine_timer -= delta
	if vine_timer <= 0.0 and _vines.size() < 2:
		_spawn_vine()
		vine_timer = maxf(0.5, 0.72 / GameManager.difficulty)

	# Advance stages
	for v in _vines:
		v["t"] += delta
		if v["stage"] == 0 and v["t"] >= 0.55:
			v["stage"] = 1
			v["t"] = 0.0
			var r: ColorRect = v["rect"]
			r.color = Color("#7cff7c")
		elif v["stage"] == 1 and v["t"] >= 0.4:
			# Burst resolved without stomping — you're done for
			fail()
			return

	# Stomp check
	if Input.is_action_just_pressed("mash"):
		gesture_performed("mash")
		for v in _vines:
			if v["stage"] == 1 and absf(SLOTS[v["slot"]] - player_x) < 60.0:
				kills += 1
				var label: Label = get_node_or_null("CanvasLayer/ProgressLabel")
				if not label:
					label = _add_progress_label()
				label.text = "%d/%d" % [kills, NEED_KILLS]
				v["rect"].queue_free()
				_vines.erase(v)
				if kills >= NEED_KILLS:
					succeed()
				break

	# Update visuals
	for v in _vines:
		var r: ColorRect = v["rect"]
		var slot_x: float = SLOTS[v["slot"]]
		if v["stage"] == 0:
			r.position = Vector2(slot_x - 6.0, 430.0 + (0.55 - v["t"]) * 90.0)
		else:
			r.position = Vector2(slot_x - 24.0, 430.0 + (0.4 - v["t"]) * 60.0)

func _spawn_vine() -> void:
	var slot: int = randi_range(0, SLOTS.size() - 1)
	var rect := ColorRect.new()
	rect.size = Vector2(12, 60)
	rect.color = Color("#b06ad4")
	rect.position = Vector2(SLOTS[slot] - 6.0, 540.0)
	add_child(rect)
	_vines.append({"slot": slot, "stage": 0, "t": 0.0, "rect": rect})

func _add_progress_label() -> Label:
	var label := Label.new()
	label.name = "ProgressLabel"
	label.text = "0/%d" % NEED_KILLS
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