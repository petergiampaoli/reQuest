extends Node
## DemoRunner — runs a single micro-task outside the normal quest flow.
## Launched by ./play <task> (see the repo-root `play` script).
##
## The task scene is instantiated directly and its result signals are detached
## from TaskManager, so a win/loss never advances to the next task or boss.
## R retries the same task; Esc quits.

const DEMO_COLOR := Color("#ffd94c")
const SUCCESS_COLOR := Color("#7cff7c")
const FAIL_COLOR := Color("#ff4a4a")

var _task: Node = null
var _task_info: Dictionary = {}
var _finished: bool = false
var _restarting: bool = false

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var query: String = String(args[0]).strip_edges() if not args.is_empty() else ""
	_task_info = _find_task(query)
	if _task_info.is_empty():
		_print_usage()
		get_tree().quit(1)
		return
	_spawn_task()

## Match by catalog id ("archer") or display name ("ARCHER", "TIGHT-WIRE").
func _find_task(query: String) -> Dictionary:
	if query.is_empty():
		return {}
	var wanted := _normalize(query)
	for entry in TaskManager.TASKS:
		if _normalize(String(entry["id"])) == wanted:
			return entry
		if _normalize(String(entry["name"])) == wanted:
			return entry
	return {}

func _normalize(value: String) -> String:
	return value.to_lower().strip_edges().replace(" ", "-").replace("_", "-")

func _print_usage() -> void:
	print("Usage: ./play <task>")
	print("Available tasks:")
	for entry in TaskManager.TASKS:
		print("  %-10s %s" % [entry["id"], entry["name"]])

func _spawn_task() -> void:
	_reset_game_state()
	_finished = false
	var path := String(_task_info["scene"])
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("[DemoRunner] Could not load task scene: %s" % path)
		get_tree().quit(1)
		return

	_task = packed.instantiate()
	add_child(_task)
	# TaskBase registers itself with TaskManager in _ready(). Detach those
	# connections so the demo owns the result instead of the quest router.
	_detach_task_manager(_task)
	_task.task_succeeded.connect(_on_task_succeeded)
	_task.task_failed.connect(_on_task_failed)
	_set_labels("R retry • Esc quit", DEMO_COLOR)
	print("[DemoRunner] Playing '%s' (%s)" % [_task_info["name"], path])

func _detach_task_manager(task: Node) -> void:
	for signal_name in ["task_succeeded", "task_failed"]:
		if not task.has_signal(signal_name):
			continue
		for connection in task.get_signal_connection_list(signal_name):
			var callback: Callable = connection["callable"]
			# Only detach TaskManager's router; keep the task's own listeners
			# (e.g. TaskBase's heart-punch animation on task_failed).
			if callback.get_object() == TaskManager and task.is_connected(signal_name, callback):
				task.disconnect(signal_name, callback)

## In-memory only — the demo must never write test results to the save file.
func _reset_game_state() -> void:
	GameManager.quest_number = 1
	GameManager.difficulty = 1.0
	GameManager.current_task_index = 0
	GameManager.boss_phase = false
	GameManager.lives = 3
	GameManager.gold = 0
	GameManager.successes_this_quest = 0
	GameManager.trinket_auto_used = false
	GameManager.upgrades = {"extra_time": 0, "extra_life": 0, "gold_bonus": 0, "quick_hands": 0}
	GameManager.gesture_augments = {}
	GameManager.owned_trinkets = {}
	GameManager.equipped_trinkets = []

## Reuse the task's HUD labels so the demo HUD matches the game.
func _set_labels(hint: String, color: Color) -> void:
	var progress := _task.get_node_or_null("CanvasLayer/QuestProgress") as Label
	var hint_label := _task.get_node_or_null("CanvasLayer/GoldLabel") as Label
	if progress:
		progress.text = "DEMO — %s" % _task_info["name"]
		progress.add_theme_color_override("font_color", DEMO_COLOR)
	if hint_label:
		hint_label.text = hint
		hint_label.add_theme_color_override("font_color", color)

func _on_task_succeeded(time_left: float) -> void:
	_finished = true
	_set_labels("SUCCESS — R retry • Esc quit", SUCCESS_COLOR)
	print("[DemoRunner] SUCCESS '%s' (%.2fs left)" % [_task_info["id"], time_left])

func _on_task_failed() -> void:
	_finished = true
	_set_labels("FAILED — R retry • Esc quit", FAIL_COLOR)
	print("[DemoRunner] FAILED '%s'" % [_task_info["id"]])

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		get_tree().quit()
	elif event.keycode == KEY_R:
		get_viewport().set_input_as_handled()
		_restart()

func _restart() -> void:
	if _restarting:
		return
	_restarting = true
	# TaskBase waits 0.65s after a result to show its banner; let that finish
	# before freeing the node so its coroutine doesn't resume on a dead object.
	if _finished:
		await get_tree().create_timer(0.7).timeout
	if is_instance_valid(_task):
		remove_child(_task)
		_task.queue_free()
	_task = null
	_restarting = false
	_spawn_task()
