extends Node
## TaskManager — owns the quest sequence and instantiates task scenes.
## Each task is its own scene that extends TaskBase (scripts/tasks/TaskBase.gd).

signal task_will_start(task_name: String, index: int, total: int)

# Task catalog — single source of truth.
# Each entry: id, name, scene, rank. Ranks gate availability:
# rank 1 is always unlocked; each completed quest (10 tasks) unlocks the next rank.
# Add new tasks here so they can be picked by the quest randomizer.
const TASKS: Array = [
	{"id": "mash",     "name": "MASH",     "scene": "res://scenes/tasks/MashTask.tscn",     "rank": 1},
	{"id": "dodge",    "name": "DODGE",    "scene": "res://scenes/tasks/DodgeTask.tscn",    "rank": 1},
	{"id": "parry",    "name": "PARRY",    "scene": "res://scenes/tasks/ParryTask.tscn",    "rank": 1},
	{"id": "sort",     "name": "SORT",     "scene": "res://scenes/tasks/SortTask.tscn",     "rank": 1},
	{"id": "lockpick", "name": "LOCKPICK", "scene": "res://scenes/tasks/LockpickTask.tscn", "rank": 1},
	{"id": "archer",   "name": "ARCHER",   "scene": "res://scenes/tasks/ArcherTask.tscn",   "rank": 1},
	{"id": "stir",     "name": "STIR",     "scene": "res://scenes/tasks/StirTask.tscn",     "rank": 1},
	{"id": "seal",     "name": "SEAL",     "scene": "res://scenes/tasks/SealTask.tscn",     "rank": 1},
	{"id": "chant",    "name": "CHANT",    "scene": "res://scenes/tasks/ChantTask.tscn",    "rank": 1},
	{"id": "balance",  "name": "BALANCE",  "scene": "res://scenes/tasks/BalanceTask.tscn",  "rank": 1},
]

var _quest_queue: Array[String] = []
var _current_task: Node = null

## Called at quest start — randomly assigns TASKS_PER_QUEST tasks from unlocked ranks.
func begin_quest() -> void:
	_quest_queue.clear()
	_build_queue()

func start_next_task() -> void:
	# Build queue lazily as a fallback if begin_quest() wasn't called
	if _quest_queue.is_empty():
		_build_queue()

	if _quest_queue.is_empty():
		push_error("[TaskManager] No tasks unlocked!")
		return

	var path: String = _quest_queue.pop_front()
	task_will_start.emit(path.get_file().get_basename(), GameManager.current_task_index + 1, GameManager.TASKS_PER_QUEST)
	# Small inter-task beat — could add a "NEXT: ..." interstitial here
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file(path)

func _build_queue() -> void:
	var pool := unlocked_tasks()
	if pool.is_empty():
		push_error("[TaskManager] No unlocked tasks!")
		return
	var scenes: Array[String] = []
	for task in pool:
		scenes.append(String(task["scene"]))
	_quest_queue.clear()
	while _quest_queue.size() < GameManager.TASKS_PER_QUEST:
		var chunk := scenes.duplicate()
		chunk.shuffle()
		_quest_queue.append_array(chunk)
	_quest_queue = _quest_queue.slice(0, GameManager.TASKS_PER_QUEST)

## Highest rank unlocked so far: rank 1 always; +1 per completed quest (10 tasks).
func unlocked_max_rank() -> int:
	return 1 + int(GameManager.total_tasks_completed / GameManager.TASKS_PER_QUEST)

## Tasks available right now = catalog entries whose rank is unlocked.
func unlocked_tasks() -> Array:
	var max_rank := unlocked_max_rank()
	var out: Array = []
	for task in TASKS:
		if int(task["rank"]) <= max_rank:
			out.append(task)
	return out

func register_task(node: Node) -> void:
	_current_task = node
	# Wire task's finished signal
	if node.has_signal("task_succeeded") and not node.task_succeeded.is_connected(_on_task_succeeded):
		node.task_succeeded.connect(_on_task_succeeded)
	if node.has_signal("task_failed") and not node.task_failed.is_connected(_on_task_failed):
		node.task_failed.connect(_on_task_failed)

func _on_task_succeeded(time_left: float) -> void:
	GameManager.on_task_finished(true, time_left)

func _on_task_failed() -> void:
	GameManager.on_task_finished(false, 0.0)

## Called by TaskBase when it wants to report without signals (fallback)
func report_result(success: bool, time_left: float) -> void:
	GameManager.on_task_finished(success, time_left)
