extends TaskBase
## ArcherTask — "LOOSE!"
## Aim crosshair (mouse or WASD) at the drifting target, press [SPACE]/E to shoot.
## Medieval archery + modern crosshair. One shot.

var target_pos: Vector2 = Vector2(640, 340)
var target_vel: Vector2 = Vector2.ZERO
var crosshair_pos: Vector2 = Vector2(640, 340)
var has_shot: bool = false
var aim_speed: float = 520.0

@onready var target: ColorRect = $Target
@onready var crosshair: ColorRect = $Crosshair
@onready var arrow: ColorRect = $Arrow
@onready var hint: Label = $CanvasLayer/Hint

func _ready() -> void:
	command_text = "LOOSE!"
	super._ready()

func on_task_start() -> void:
	has_shot = false
	crosshair_pos = Vector2(640, 500)
	target_pos = Vector2(randf_range(300, 980), randf_range(200, 420))
	# Drift speed scales with difficulty
	var s: float = 80.0 + GameManager.difficulty * 55.0
	target_vel = Vector2([-1, 1].pick_random(), randf_range(-0.4, 0.4)).normalized() * s
	if arrow:
		arrow.visible = false
	if hint:
		hint.text = "Aim with MOUSE / WASD  •  [SPACE] to shoot"
	_update_nodes()

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	# Move target, bounce
	target_pos += target_vel * delta
	if target_pos.x < 180 or target_pos.x > 1100:
		target_vel.x *= -1
		target_pos.x = clampf(target_pos.x, 180, 1100)
	if target_pos.y < 180 or target_pos.y > 520:
		target_vel.y *= -1
		target_pos.y = clampf(target_pos.y, 180, 520)

	# Crosshair: mouse takes priority if moved recently, else WASD
	var mouse_pos := get_viewport().get_mouse_position()
	# If mouse near center or moved, use it (simple heuristic: if mouse != (0,0))
	if mouse_pos.length() > 10 and (mouse_pos - crosshair_pos).length() < 600:
		crosshair_pos = mouse_pos
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() > 0.1:
		crosshair_pos += dir * aim_speed * delta
	crosshair_pos.x = clampf(crosshair_pos.x, 40, 1240)
	crosshair_pos.y = clampf(crosshair_pos.y, 40, 680)

	_update_nodes()
	# Reticle pulse when close
	if crosshair and target:
		var d := crosshair_pos.distance_to(target_pos)
		var close: bool = d < 48
		crosshair.modulate = Color("#7cff7c") if close else Color.WHITE
		crosshair.scale = Vector2(1.15, 1.15) if close else Vector2.ONE

func _update_nodes() -> void:
	if target:
		target.position = target_pos - target.size / 2
	if crosshair:
		crosshair.position = crosshair_pos - crosshair.size / 2

func _unhandled_input(event: InputEvent) -> void:
	if _finished or has_shot:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_shoot()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("action"):
		_shoot()
		get_viewport().set_input_as_handled()

func _shoot() -> void:
	has_shot = true
	var d := crosshair_pos.distance_to(target_pos)
	# Hit radius 44 (tightens with difficulty)
	var radius: float = maxf(28.0, 46.0 - GameManager.difficulty * 4.0)
	# Arrow flight
	if arrow:
		arrow.visible = true
		arrow.position = crosshair_pos - arrow.size / 2
		arrow.modulate = Color("#ffd94c")
	var hit: bool = d <= radius
	if hit:
		if target:
			target.color = Color("#7cff7c")
			create_tween().tween_property(target, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_BACK)
		succeed()
	else:
		if crosshair:
			crosshair.modulate = Color("#ff4a4a")
		# brief window to try again if time left >1.2s and not too close to end? But spec says one shot — fail immediately
		fail()
