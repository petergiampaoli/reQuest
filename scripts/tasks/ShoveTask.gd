extends TaskBase
## ShoveTask — "SHOVE!"
## Two gestures at once: hold W to push the boulder (releases let it roll back),
## SPACE to kick the debris chasing you. Three hits from debris and you're done.

const START_X: float = 140.0
const GOAL_X: float = 1140.0
var boulder_x: float = START_X
var hp: int = 3
var spawn_t: float = 0.0
var kick_cd: float = 0.0
var _debris: Array = []  # {rect, x}

var _boulder: ColorRect

func _ready() -> void:
	command_text = "SHOVE!"
	super._ready()

func on_task_start() -> void:
	_boulder = ColorRect.new()
	_boulder.size = Vector2(84, 84)
	_boulder.color = Color("#8c8a80")
	_boulder.position = Vector2(boulder_x - 42, 258)
	add_child(_boulder)
	kick_cd = 0.0
	spawn_t = 0.5
	_set_hint("Hold W to push   SPACE kick debris")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()
	# Push / rollback
	if Input.is_action_pressed("move_up"):
		boulder_x += 150.0 * delta
	else:
		boulder_x -= 26.0 * delta
	boulder_x = clampf(boulder_x, START_X, GOAL_X)
	if _boulder:
		_boulder.position.x = boulder_x - 42.0

	# Debris spawn + travel
	spawn_t -= delta
	if spawn_t <= 0.0:
		_spawn_debris()
		spawn_t = maxf(0.6, 0.8 / GameManager.difficulty)

	kick_cd = maxf(0.0, kick_cd - delta)
	if Input.is_action_just_pressed("action") and kick_cd <= 0.0:
		kick_cd = 0.16
		gesture_performed("action")
		_kick_nearest()

	var drop: Array = []
	for d in _debris:
		d["x"] -= 320.0 * delta
		d["rect"].position.x = d["x"] - 14.0
		if d["x"] < boulder_x + 100.0:
			# Debris reached the boulder — big setback
			hp -= 1
			boulder_x = clampf(boulder_x - 240.0, START_X, GOAL_X)
			d["rect"].queue_free()
			drop.append(d)
			var label: Label = get_node_or_null("CanvasLayer/ProgressLabel")
			if not label:
				label = _add_progress_label()
			label.text = "%d/%d   ♥%d" % [int((boulder_x - START_X) / (GOAL_X - START_X) * 100.0), 100, hp]
			if hp <= 0:
				fail()
				return
	# clean removed
	for d in drop:
		_debris.erase(d)

	var label: Label = get_node_or_null("CanvasLayer/ProgressLabel")
	if not label:
		label = _add_progress_label()
	label.text = "%d%%   ♥%d" % [int((boulder_x - START_X) / (GOAL_X - START_X) * 100.0), hp]

	if boulder_x >= GOAL_X:
		succeed()

func _spawn_debris() -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(28, 28)
	rect.color = Color("#8c2f12")
	rect.position = Vector2(1260, 286)
	add_child(rect)
	_debris.append({"rect": rect, "x": 1260.0})

func _kick_nearest() -> void:
	var nearest: Dictionary = {}
	var best_x: float = 1e9
	for d in _debris:
		if d["x"] > boulder_x and d["x"] < best_x:
			nearest = d
			best_x = d["x"]
	if best_x > 1e8 or best_x - boulder_x > 320.0:
		return
	nearest["rect"].queue_free()
	_debris.erase(nearest)

func _add_progress_label() -> Label:
	var label := Label.new()
	label.name = "ProgressLabel"
	label.text = "0%   ♥3"
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