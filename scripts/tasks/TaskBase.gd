extends Node2D
class_name TaskBase
## TaskBase — all micro-tasks extend this.
## Provides: command label, 10s timer (variable), success/fail signals, bomb/fuse UI.

signal task_succeeded(time_left: float)
signal task_failed

@export var command_text: String = "DO IT!"
@export var task_time: float = -1.0  # -1 = use GameManager.get_task_time()
@export var show_timer: bool = true

var _time_left: float
var _finished: bool = false
var _timer: Timer

# Nodes expected in scene (TaskBase.tscn provides them) — optional if task builds its own
@onready var _command_label: Label = get_node_or_null("CanvasLayer/CommandLabel")
@onready var _timer_bar: ProgressBar = get_node_or_null("CanvasLayer/TimerBar")
@onready var _result_label: Label = get_node_or_null("CanvasLayer/ResultLabel")
@onready var _progress_label: Label = get_node_or_null("CanvasLayer/QuestProgress")
@onready var _gold_label: Label = get_node_or_null("CanvasLayer/GoldLabel")
@onready var _hearts_container: Control = get_node_or_null("CanvasLayer/Hearts")
var _hearts_labels: Array[Label] = []

func _ready() -> void:
	# Register with TaskManager so it can forward results
	TaskManager.register_task(self)

	if task_time < 0:
		task_time = GameManager.get_task_time()
	_time_left = task_time

	if _command_label:
		_command_label.text = command_text
		# Punch animation
		_command_label.scale = Vector2(1.4, 1.4)
		create_tween().tween_property(_command_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if _timer_bar:
		_timer_bar.max_value = task_time
		_timer_bar.value = _time_left
		_timer_bar.visible = show_timer

	if _result_label:
		_result_label.visible = false

	if _progress_label:
		_progress_label.text = "Quest %d — %d/%d" % [GameManager.quest_number, GameManager.current_task_index + 1, GameManager.TASKS_PER_QUEST]
	if _gold_label:
		_gold_label.text = "Gold %d" % GameManager.gold
		GameManager.gold_changed.connect(func(v): if _gold_label: _gold_label.text = "Gold %d" % v)

	_ensure_hearts_hud()
	_update_hearts_display(GameManager.lives)
	GameManager.lives_changed.connect(_update_hearts_display)
	# Also animate on fail immediately before GameManager decrements (visual punch on FAILED)
	task_failed.connect(func(): _pulse_hearts_on_fail())

	_timer = Timer.new()
	_timer.wait_time = 1.0 / 60.0
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_on_tick)

	# Hook for child tasks
	on_task_start()

## Override in child task
func on_task_start() -> void:
	pass

## Override — called every frame via _on_tick
func on_task_tick(_delta: float) -> void:
	pass

## Child calls this when player wins
func succeed() -> void:
	if _finished:
		return
	_finished = true
	_timer.stop()
	task_succeeded.emit(_time_left)
	_show_result(true)
	await get_tree().create_timer(0.65).timeout
	# TaskManager handles routing; fallback if not wired
	if not task_succeeded.get_connections().is_empty():
		pass
	else:
		TaskManager.report_result(true, _time_left)

## Child calls this when player fails explicitly
func fail() -> void:
	if _finished:
		return
	_finished = true
	_timer.stop()
	task_failed.emit()
	_show_result(false)
	await get_tree().create_timer(0.65).timeout
	if task_failed.get_connections().is_empty():
		TaskManager.report_result(false, 0.0)

func _on_tick() -> void:
	if _finished:
		return
	var dt: float = _timer.wait_time
	_time_left -= dt
	_time_left = maxf(_time_left, 0.0)

	if _timer_bar:
		_timer_bar.value = _time_left
		# Color ramp: gold -> red
		var t: float = _time_left / task_time
		if t < 0.3:
			_timer_bar.modulate = Color("#ff4a4a")
		elif t < 0.6:
			_timer_bar.modulate = Color("#ffd24a")
		else:
			_timer_bar.modulate = Color("#7cff7c")

	on_task_tick(dt)

	if _time_left <= 0.0 and not _finished:
		# Time's up — auto-fail unless child already succeeded
		fail()

func _show_result(success: bool) -> void:
	if _result_label == null:
		return
	_result_label.visible = true
	_result_label.text = "SUCCESS!" if success else "FAILED!"
	_result_label.modulate = Color("#7cff7c") if success else Color("#ff4a4a")
	_result_label.scale = Vector2(0.5, 0.5)
	create_tween().tween_property(_result_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)

func _ensure_hearts_hud() -> void:
	var canvas: CanvasLayer = get_node_or_null("CanvasLayer")
	if canvas == null:
		return
	# If scene already has Hearts container (new tscns), just collect labels
	_hearts_container = canvas.get_node_or_null("Hearts")
	if _hearts_container != null:
		_hearts_labels.clear()
		for c in _hearts_container.get_children():
			if c is Label:
				_hearts_labels.append(c)
		return
	# Otherwise create it dynamically for legacy task scenes
	var box := HBoxContainer.new()
	box.name = "Hearts"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	# Center-top: anchor 0.5,0 + offset
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.0
	box.anchor_bottom = 0.0
	box.offset_left = -72.0
	box.offset_top = 10.0
	box.offset_right = 72.0
	box.offset_bottom = 48.0
	canvas.add_child(box)
	_hearts_container = box
	for i in 3:
		var l := Label.new()
		l.name = "Heart%d" % i
		l.text = "♥"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 34)
		l.add_theme_color_override("font_color", Color("#ff4a4a"))
		l.add_theme_color_override("font_outline_color", Color("#1a1208"))
		l.add_theme_constant_override("outline_size", 6)
		box.add_child(l)
		_hearts_labels.append(l)

func _update_hearts_display(new_lives: int) -> void:
	if _hearts_labels.is_empty():
		return
	# Ensure enough labels for extra lives (upgrade)
	while _hearts_labels.size() < new_lives:
		var l := Label.new()
		l.text = "♥"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 34)
		l.add_theme_color_override("font_color", Color("#ff4a4a"))
		l.add_theme_color_override("font_outline_color", Color("#1a1208"))
		l.add_theme_constant_override("outline_size", 6)
		_hearts_container.add_child(l)
		_hearts_labels.append(l)
	for i in _hearts_labels.size():
		var lbl: Label = _hearts_labels[i]
		var filled: bool = i < new_lives
		if filled:
			lbl.text = "♥"
			lbl.modulate = Color("#ff4a4a")
			lbl.visible = true
		else:
			# Animate loss if it was previously filled
			if lbl.text == "♥" and lbl.modulate == Color("#ff4a4a"):
				var tw := create_tween()
				tw.tween_property(lbl, "scale", Vector2(1.45, 1.45), 0.11).set_trans(Tween.TRANS_BACK)
				tw.tween_property(lbl, "scale", Vector2(0.55, 0.55), 0.13)
				tw.tween_callback(func():
					lbl.text = "♡"
					lbl.modulate = Color("#5a3a3a")
					lbl.scale = Vector2.ONE
				)
			else:
				lbl.text = "♡"
				lbl.modulate = Color("#5a3a3a")
				lbl.visible = true

func _pulse_hearts_on_fail() -> void:
	# Quick punch on remaining hearts to sell the hit
	for lbl in _hearts_labels:
		if lbl.text == "♥":
			var tw := create_tween()
			tw.tween_property(lbl, "scale", Vector2(1.18, 1.18), 0.08)
			tw.tween_property(lbl, "scale", Vector2.ONE, 0.10)

func _unhandled_input(event: InputEvent) -> void:
	# Allow child to also handle via _unhandled_input
	pass
