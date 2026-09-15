extends TaskBase
## TEMPLATE — copy this to create a new micro-task.
## 1. Duplicate scenes/TaskBase.tscn
## 2. Attach this script (renamed)
## 3. Add to TaskManager.task_pool

func _ready() -> void:
	command_text = "YOUR COMMAND HERE!"
	# Optional per-task time override (seconds): task_time = 7.0
	super._ready()

func on_task_start() -> void:
	# Spawn/setup here
	pass

func on_task_tick(_delta: float) -> void:
	# Per-frame checks; call succeed() / fail() when player wins/loses
	# If you do nothing, timer running out = auto-fail
	pass

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	# if event.is_action_pressed("action"): succeed()
	pass
