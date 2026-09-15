extends Node
## TaskManager — owns the quest sequence and instantiates task scenes.
## Each task is its own scene that extends TaskBase (scripts/tasks/TaskBase.gd).

signal task_will_start(task_name: String, index: int, total: int)

# Add new task scenes here — they get shuffled per quest
var task_pool: Array[String] = [
	"res://scenes/tasks/MashTask.tscn",
	"res://scenes/tasks/DodgeTask.tscn",
	"res://scenes/tasks/ParryTask.tscn",
	"res://scenes/tasks/SortTask.tscn",
	"res://scenes/tasks/LockpickTask.tscn",
	"res://scenes/tasks/ArcherTask.tscn",
	"res://scenes/tasks/StirTask.tscn",
	"res://scenes/tasks/SealTask.tscn",
	"res://scenes/tasks/ChantTask.tscn",
	"res://scenes/tasks/BalanceTask.tscn",
]

var _quest_queue: Array[String] = []
var _current_task: Node = null

func start_next_task() -> void:
	# Build queue at start of quest
	if _quest_queue.is_empty():
		_build_queue()

	if _quest_queue.is_empty():
		push_error("[TaskManager] No tasks in pool!")
		return

	var path: String = _quest_queue.pop_front()
	task_will_start.emit(path.get_file().get_basename(), GameManager.current_task_index + 1, GameManager.TASKS_PER_QUEST)
	# Small inter-task beat — could add a "NEXT: ..." interstitial here
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file(path)

func _build_queue() -> void:
	_quest_queue = task_pool.duplicate()
	_quest_queue.shuffle()
	# If we need 10 tasks but pool is smaller, cycle with shuffle
	while _quest_queue.size() < GameManager.TASKS_PER_QUEST:
		var extra := task_pool.duplicate()
		extra.shuffle()
		_quest_queue.append_array(extra)
	_quest_queue = _quest_queue.slice(0, GameManager.TASKS_PER_QUEST)

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
