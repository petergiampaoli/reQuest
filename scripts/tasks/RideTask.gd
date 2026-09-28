extends TaskBase
## RideTask — "RIDE!"
## Two gestures at once: A/D steer the horse, F to jump.
## Rocks must be dodged; fences (full width) must be jumped. Survive to the end.

var horse_x: float = 640.0
var jump_left: float = 0.0
const JUMP_TIME: float = 0.45
var obstacle_gap: float = 0.0
var hit: bool = false

var _obstacles: Array = []
var _horse: ColorRect

func _ready() -> void:
	command_text = "RIDE!"
	super._ready()

func on_task_start() -> void:
	_horse = ColorRect.new()
	_horse.size = Vector2(26, 40)
	_horse.color = Color("#7cff7c")
	_horse.position = Vector2(horse_x - 13, 520)
	add_child(_horse)
	obstacle_gap = maxf(0.7, 1.05 / GameManager.difficulty)
	_set_hint("A/D steer   F jump")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	var dir := Input.get_axis("move_left", "move_right")
	horse_x += dir * 340.0 * delta
	horse_x = clampf(horse_x, 60.0, 1220.0)

	if Input.is_action_just_pressed("mash"):
		jump_left = JUMP_TIME
	jump_left = maxf(0.0, jump_left - delta)
	var airborne: bool = jump_left > 0.0
	_horse.position = Vector2(horse_x - 13.0, (520.0 - 46.0) if airborne else 520.0)

	obstacle_gap -= delta
	if obstacle_gap <= 0.0:
		_spawn_obstacle()
		obstacle_gap = maxf(0.7, 1.05 / GameManager.difficulty)

	var drop: Array = []
	for ob in _obstacles:
		ob["y"] = ob.get("y", 0.0) + 480.0 * delta
		var rect: ColorRect = ob["rect"]
		rect.position = Vector2(ob["x"] - ob["w"] / 2.0, ob["y"] - ob["h"] / 2.0)
		if ob["y"] > 760.0:
			drop.append(ob)
			continue
		if not (ob["y"] > 470.0 and ob["y"] < 570.0):
			continue
		if int(ob["kind"]) == 0:  # rock — dodge it
			if absf(ob["x"] - horse_x) < 34.0 and not airborne:
				hit = true
				fail()
				return
		else:  # fence — jump it
			if absf(ob["x"] - horse_x) < 46.0 and not airborne:
				hit = true
				fail()
				return
	for ob in drop:
		_obstacles.erase(ob)
		ob["rect"].queue_free()

	if _time_left < 0.05 and not hit and not _finished:
		succeed()

func _spawn_obstacle() -> void:
	var kind: int = randi_range(0, 1)
	if _obstacles.size() == 0:
		kind = 0  # start with a dodge
	if _obstacles.size() % 3 == 2:
		kind = 1  # every third is a fence
	var rect := ColorRect.new()
	var x: float
	if kind == 0:
		rect.size = Vector2(40, 36)
		rect.color = Color("#8c2f12")
		x = randf_range(140.0, 1140.0)
	else:
		rect.size = Vector2(1280, 26)  # spans the lane — must jump
		rect.color = Color("#c9b56a")
		x = 640.0
	rect.position = Vector2.ZERO
	add_child(rect)
	_obstacles.append({
		"rect": rect,
		"x": x,
		"w": rect.size.x,
		"h": rect.size.y,
		"y": -60.0,
		"kind": kind,
	})

func _set_hint(text: String) -> void:
	var hint: Label = get_node_or_null("CanvasLayer/Hint")
	if hint:
		hint.text = text