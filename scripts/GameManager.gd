extends Node
## GameManager — global state for reQuest
## Tracks quest progress, gold, difficulty, and routing.

signal quest_started
signal quest_completed(success_count: int, total: int)
signal gold_changed(new_gold: int)
signal lives_changed(new_lives: int)

# --- Run state ---
var gold: int = 0:
	set(v):
		gold = v
		gold_changed.emit(gold)

var lives: int = 3:
	set(v):
		lives = v
		lives_changed.emit(lives)

# Quest = 10 micro-tasks then Long Rest
const TASKS_PER_QUEST: int = 10
var current_task_index: int = 0  # 0..9 within current quest
var quest_number: int = 1        # increments after each Long Rest
var successes_this_quest: int = 0
var total_successes: int = 0
var total_tasks_completed: int = 0  # counts both success + fail across run
var total_failures: int = 0
var difficulty: float = 1.0      # scales timer down / speed up

# Last death snapshot — read by GameOver screen
var last_run_stats: Dictionary = {}

# Upgrade state (spent at Long Rest)
var upgrades: Dictionary = {
	"extra_time": 0,  # +0.5s per level
	"extra_life": 0,
	"gold_bonus": 0,  # +1 gold per task win per level
}

# --- Constants ---
const BASE_TASK_TIME: float = 10.0
const UPGRADE_COSTS := {
	"extra_time": 15,
	"extra_life": 25,
	"gold_bonus": 20,
}

func _ready() -> void:
	SaveManager.load_game(self)

func start_new_quest() -> void:
	current_task_index = 0
	successes_this_quest = 0
	# slight ramp each quest
	difficulty = 1.0 + (quest_number - 1) * 0.12
	quest_started.emit()
	TaskManager.start_next_task()

func on_task_finished(success: bool, time_left: float) -> void:
	total_tasks_completed += 1
	if success:
		successes_this_quest += 1
		total_successes += 1
		var bonus: int = 5 + upgrades["gold_bonus"] * 2
		# speed bonus: leftover time
		bonus += int(time_left)
		gold += bonus
	else:
		total_failures += 1
		lives -= 1
		if lives <= 0:
			_game_over()
			return

	current_task_index += 1

	if current_task_index >= TASKS_PER_QUEST:
		quest_completed.emit(successes_this_quest, TASKS_PER_QUEST)
		quest_number += 1
		SaveManager.save_game(self)
		get_tree().change_scene_to_file("res://scenes/LongRest.tscn")
	else:
		TaskManager.start_next_task()

func _game_over() -> void:
	# Snapshot stats BEFORE reset — GameOver screen reads this
	var quests_cleared: int = max(0, quest_number - 1)
	var tasks_this_run: int = total_tasks_completed
	last_run_stats = {
		"total_tasks_completed": tasks_this_run,
		"total_successes": total_successes,
		"total_failures": total_failures,
		"successes_this_quest": successes_this_quest,
		"quests_cleared": quests_cleared,
		"gold": gold,
		"quest_reached": quest_number,
		"tasks_in_final_quest": current_task_index + 1, # include the failing one
	}
	# Reset but keep gold / upgrades for roguelite feel — adjust if you want hard reset
	lives = 3
	quest_number = 1
	current_task_index = 0
	successes_this_quest = 0
	difficulty = 1.0
	SaveManager.save_game(self)
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func get_task_time() -> float:
	var t: float = BASE_TASK_TIME / difficulty
	t += upgrades["extra_time"] * 0.5
	# Clamp: allow 3s min, 12s max (design says extend/shorten)
	return clampf(t, 3.0, 12.0)

func try_buy_upgrade(id: String) -> bool:
	if not UPGRADE_COSTS.has(id):
		return false
	var cost: int = UPGRADE_COSTS[id] + upgrades[id] * 5  # scaling cost
	if gold < cost:
		return false
	gold -= cost
	upgrades[id] += 1
	if id == "extra_life":
		lives += 1
	SaveManager.save_game(self)
	return true

func reset_progress() -> void:
	gold = 0
	lives = 3
	quest_number = 1
	current_task_index = 0
	successes_this_quest = 0
	total_successes = 0
	total_tasks_completed = 0
	total_failures = 0
	last_run_stats = {}
	difficulty = 1.0
	upgrades = {"extra_time": 0, "extra_life": 0, "gold_bonus": 0}
	SaveManager.save_game(self)
