extends TaskBase
## CannonTask — "MAN THE CANNON!"
## Two gestures at once: A/D keeps the barrel on the moving target while holding SPACE
## to charge. Fire with F once charged — 4 clean hits to win.

const BASE: Vector2 = Vector2(640, 470)
const HITS_NEEDED: int = 4

var barrel_angle: float = 0.0
var charge: float = 0.0
var hits: int = 0
var t: float = 0.0
var target_x: float = 640.0
var target_y: float = 260.0

var _barrel: ColorRect
var _target_rect: ColorRect
var _charge_bar: ProgressBar

func _ready() -> void:
	command_text = "MAN THE CANNON!"
	super._ready()

func on_task_start() -> void:
	_barrel = ColorRect.new()
	_barrel.size = Vector2(120, 22)
	_barrel.color = Color("#8c2f12")
	_barrel.pivot_offset = Vector2(14, 11)
	add_child(_barrel)
	_target_rect = ColorRect.new()
	_target_rect.size = Vector2(46, 30)
	_target_rect.color = Color("#b06ad4")
	add_child(_target_rect)
	_charge_bar = ProgressBar.new()
	_charge_bar.name = "ChargeBar"
	_charge_bar.max_value = 100.0
	_charge_bar.value = 0.0
	_charge_bar.show_percentage = false
	_charge_bar.anchor_left = 0.5
	_charge_bar.anchor_right = 0.5
	_charge_bar.offset_left = -150.0
	_charge_bar.offset_right = 150.0
	_charge_bar.offset_top = 560.0
	_charge_bar.offset_bottom = 580.0
	get_node("CanvasLayer").add_child(_charge_bar)
	_set_hint("A/D aim   hold SPACE charge   F fire")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	track_movement()
	t += delta
	var dir := Input.get_axis("move_left", "move_right")
	barrel_angle += dir * 1.15 * delta
	barrel_angle = clampf(barrel_angle, -0.9, 0.9)

	# Target moves
	target_x = 640.0 + 340.0 * sin(t * 0.8)
	target_y = 260.0 + 60.0 * sin(t * 1.7)

	# Aim math — barrel points up from BASE by barrel_angle
	var aim_dir := Vector2(sin(barrel_angle), -cos(barrel_angle))
	var to_target := (Vector2(target_x, target_y) - BASE).normalized()
	var aligned: bool = absf(aim_dir.angle_to(to_target)) < 0.09

	if Input.is_action_pressed("action"):
		charge += 34.0 * delta
		if Input.is_action_just_pressed("action"):
			gesture_performed("action")
		if not aligned:
			charge -= 26.0 * delta  # leaks while off-target
	else:
		charge -= 8.0 * delta
	charge = clampf(charge, 0.0, 100.0)

	if Input.is_action_just_pressed("mash"):
		gesture_performed("mash")
		if aligned and charge >= 75.0:
			hits += 1
			charge = 0.0
			var label: Label = get_node_or_null("CanvasLayer/ProgressLabel")
			if not label:
				label = _add_progress_label()
			label.text = "%d/%d" % [hits, HITS_NEEDED]
			if hits >= HITS_NEEDED:
				succeed()
		elif aligned:
			charge = 0.0

	# Visuals
	if _barrel:
		_barrel.position = BASE + Vector2(-60.0, -11.0)
		_barrel.rotation = barrel_angle
		_barrel.modulate = Color("#7cff7c") if aligned else Color.WHITE
	if _target_rect:
		_target_rect.position = Vector2(target_x - 23, target_y - 15)
	if _charge_bar:
		_charge_bar.value = charge
		_charge_bar.modulate = Color("#ffd94c") if charge >= 75.0 else Color(0.62, 0.5, 0.25)

func _add_progress_label() -> Label:
	var label := Label.new()
	label.name = "ProgressLabel"
	label.text = "0/%d" % HITS_NEEDED
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