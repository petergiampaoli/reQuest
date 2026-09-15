extends TaskBase
## DodgeTask — "DODGE!"
## Move with WASD/arrows to avoid falling barrels/rocks. Survive until timer ends (par survive = win).

var player_pos: Vector2 = Vector2(640, 500)
var speed: float = 420.0
var spawn_timer: float = 0.0
var hit: bool = false

@onready var player: ColorRect = $Player
@onready var hint: Label = $CanvasLayer/Hint

func _ready() -> void:
	command_text = "DODGE!"
	super._ready()

func on_task_start() -> void:
	player_pos = Vector2(640, 500)
	if player:
		player.position = player_pos - player.size / 2
	if hint:
		hint.text = "WASD / Arrows to move"
	# If we survive the timer, we win — so don't auto-fail; override fail logic by succeeding at timeout
	# We achieve this by NOT calling fail on timeout; instead succeed if not hit.
	# Monkey-patch: we will intercept _on_tick timeout via custom logic in on_task_tick

func on_task_tick(delta: float) -> void:
	if _finished:
		return

	# Movement
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_pos += dir * speed * delta
	player_pos.x = clampf(player_pos.x, 60, 1220)
	player_pos.y = clampf(player_pos.y, 140, 600)
	if player:
		player.position = player_pos - player.size / 2
		player.modulate = Color("#ff4a4a") if hit else Color("#7cff7c")

	# Spawning
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_barrel()
		spawn_timer = maxf(0.18, 0.45 / GameManager.difficulty)

	# Collision check
	for b in get_tree().get_nodes_in_group("dodge_barrel"):
		if b is Node2D or b is ColorRect:
			var rect: Rect2
			if b is ColorRect:
				rect = Rect2(b.position, b.size)
			else:
				rect = Rect2(b.position - Vector2(16, 16), Vector2(32, 32))
			var p_rect := Rect2(player_pos - Vector2(18, 18), Vector2(36, 36))
			if p_rect.intersects(rect):
				hit = true
				fail()
				return

	# Survive check — if timer almost done and not hit, succeed
	# TaskBase will call fail() at 0; intercept by succeeding 0.05s before
	if _time_left < 0.05 and not hit and not _finished:
		succeed()

func _spawn_barrel() -> void:
	var barrel := ColorRect.new()
	barrel.size = Vector2(32, 32)
	barrel.color = Color(0.45, 0.28, 0.12)
	barrel.position = Vector2(randf_range(80, 1200), -40)
	barrel.add_to_group("dodge_barrel")
	add_child(barrel)
	# Add border for woodcut look
	var tween := create_tween()
	tween.tween_property(barrel, "position:y", 720, randf_range(0.7, 1.1) / GameManager.difficulty)
	tween.finished.connect(func(): 
		if is_instance_valid(barrel):
			barrel.queue_free()
	)
