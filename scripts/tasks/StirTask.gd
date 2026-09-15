extends TaskBase
## StirTask — "STIR THE STEW!"
## Move in circles (WASD / stick / mouse drag) to stir the cauldron.
## Detects angular progress around center.

var angle: float = 0.0
var last_angle: float = 0.0
var total_spin: float = 0.0
var needed_spins: float = 2.6 # full 360s required
var pos: Vector2 = Vector2.ZERO
var center: Vector2 = Vector2(640, 360)

@onready var spoon: ColorRect = $Spoon
@onready var cauldron: ColorRect = $Cauldron
@onready var progress: ProgressBar = $CanvasLayer/StirBar
@onready var bubble_timer: float = 0.0

func _ready() -> void:
	command_text = "STIR THE STEW!"
	needed_spins = 2.2 + GameManager.difficulty * 0.5
	super._ready()

func on_task_start() -> void:
	total_spin = 0.0
	angle = 0.0
	last_angle = 0.0
	# Start spoon at east
	pos = center + Vector2(90, 0)
	if spoon:
		spoon.position = pos - spoon.size / 2
	if progress:
		progress.max_value = needed_spins * TAU
		progress.value = 0
		progress.modulate = Color("#ffd94c")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	# Input: vector from center, OR mouse position
	var input_vec: Vector2 = Vector2.ZERO
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() > 0.15:
		# Treat dir as velocity around cauldron
		pos += dir * 380.0 * delta
		pos = center + (pos - center).normalized() * 90.0
	else:
		var mp := get_viewport().get_mouse_position()
		if mp.distance_to(center) < 220 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			pos = center + (mp - center).normalized() * 90.0

	var vec := pos - center
	angle = atan2(vec.y, vec.x)
	var delta_angle := angle - last_angle
	# Wrap
	if delta_angle > PI:
		delta_angle -= TAU
	elif delta_angle < -PI:
		delta_angle += TAU
	# Only count if actually moving (ignore jitter)
	if vec.length() > 20 and absf(delta_angle) < 0.5 and absf(delta_angle) > 0.01:
		# Only count consistent direction? Allow either but prefer one way — count absolute
		total_spin += absf(delta_angle)
		if spoon:
			spoon.position = pos - spoon.size / 2
			spoon.rotation = angle + PI/2
		# Bubble pop
		bubble_timer -= delta
		if bubble_timer <= 0:
			_pop_bubble()
			bubble_timer = 0.14
	last_angle = angle
	if progress:
		progress.value = total_spin
		progress.modulate = Color("#7cff7c") if total_spin > needed_spins * TAU * 0.7 else Color("#ffd94c")
	if total_spin >= needed_spins * TAU:
		succeed()

func _pop_bubble() -> void:
	var b := ColorRect.new()
	b.size = Vector2(10, 10)
	b.color = Color(0.6, 0.85, 0.55, 0.7)
	b.position = center + Vector2(randf_range(-55, 55), randf_range(-30, 30))
	add_child(b)
	var t := create_tween()
	t.tween_property(b, "position:y", b.position.y - 24, 0.45)
	t.parallel().tween_property(b, "modulate:a", 0.0, 0.45)
	t.finished.connect(func(): if is_instance_valid(b): b.queue_free())
	if cauldron:
		cauldron.modulate = Color(1.08, 1.04, 0.95)
		create_tween().tween_property(cauldron, "modulate", Color.WHITE, 0.12)
