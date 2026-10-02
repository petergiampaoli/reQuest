extends Node
## TaskManager — owns the quest sequence and instantiates task scenes.
## Each task is its own scene that extends TaskBase (scripts/tasks/TaskBase.gd).
## A quest is a Quest (array of task scenes) followed by a boss fight.

signal task_will_start(task_name: String, index: int, total: int)

## The boss that ends every quest.
const BOSS_SCENE := "res://scenes/tasks/BossTask.tscn"
const BOSS_NAME := "THE WARDEN"

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
	# Rank 2 — dual-gesture tasks (two inputs at the same time)
	{"id": "ride",     "name": "RIDE",     "scene": "res://scenes/tasks/RideTask.tscn",     "rank": 2},
	{"id": "crank",    "name": "CRANK",    "scene": "res://scenes/tasks/CrankTask.tscn",    "rank": 2},
	{"id": "spin",     "name": "SPIN",     "scene": "res://scenes/tasks/SpinTask.tscn",     "rank": 2},
	{"id": "tightwire","name": "TIGHT-WIRE","scene": "res://scenes/tasks/TightWireTask.tscn","rank": 2},
	{"id": "smith",    "name": "SMITH",    "scene": "res://scenes/tasks/SmithTask.tscn",    "rank": 2},
	{"id": "stomp",    "name": "STOMP",    "scene": "res://scenes/tasks/StompTask.tscn",    "rank": 2},
	{"id": "row",      "name": "ROW",      "scene": "res://scenes/tasks/RowTask.tscn",      "rank": 2},
	{"id": "shove",    "name": "SHOVE",    "scene": "res://scenes/tasks/ShoveTask.tscn",    "rank": 2},
	{"id": "cannon",   "name": "CANNON",   "scene": "res://scenes/tasks/CannonTask.tscn",   "rank": 2},
	{"id": "sweep",    "name": "SWEEP",    "scene": "res://scenes/tasks/SweepTask.tscn",    "rank": 2},
]

var current_quest: Quest = null
var _current_task: Node = null

## Called at quest start — builds a Quest from TASKS_PER_QUEST tasks drawn from unlocked ranks.
func begin_quest() -> void:
	current_quest = Quest.new()
	current_quest.number = GameManager.quest_number
	current_quest.difficulty = GameManager.difficulty
	current_quest.boss_scene = BOSS_SCENE
	current_quest.tasks = _draw_tasks(GameManager.TASKS_PER_QUEST)

func start_next_task() -> void:
	# Fallback: no quest in flight → treat the boss as the next step
	if current_quest == null or current_quest.tasks.is_empty():
		start_boss()
		return

	var path: String = current_quest.tasks.pop_front()
	task_will_start.emit(path.get_file().get_basename(), GameManager.current_task_index + 1, GameManager.TASKS_PER_QUEST)
	# Small inter-task beat — could add a "NEXT: ..." interstitial here
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file(path)

## Called after the last task succeeds — the boss awaits.
## The boss is a TaskBase too, but GameManager routes its result to the boss flow.
func start_boss() -> void:
	GameManager.boss_phase = true
	task_will_start.emit(BOSS_NAME, GameManager.TASKS_PER_QUEST + 1, GameManager.TASKS_PER_QUEST + 1)
	get_tree().change_scene_to_file(BOSS_SCENE)

## Draws `count` task scenes from the unlocked pool (ranks gate availability).
func _draw_tasks(count: int) -> Array[String]:
	var pool := unlocked_tasks()
	if pool.is_empty():
		push_error("[TaskManager] No unlocked tasks!")
		return []
	var scenes: Array[String] = []
	for task in pool:
		scenes.append(String(task["scene"]))
	var out: Array[String] = []
	while out.size() < count:
		var chunk := scenes.duplicate()
		chunk.shuffle()
		out.append_array(chunk)
	return out.slice(0, count)

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
