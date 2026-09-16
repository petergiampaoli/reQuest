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

# Trinkets — bought at the shop (Long Rest / Start Menu). Equipped in slots, effects per quest.
var owned_trinkets: Dictionary = {}        # id -> count
var equipped_trinkets: Array[String] = []  # up to MAX_TRINKET_SLOTS
var trinket_auto_used: bool = false        # stone of grace used this quest (resets at quest start)
var shop_return_scene: String = "res://scenes/LongRest.tscn"

# --- Constants ---
const BASE_TASK_TIME: float = 10.0
const UPGRADE_COSTS := {
	"extra_time": 15,
	"extra_life": 25,
	"gold_bonus": 20,
}
const MAX_TRINKET_SLOTS: int = 3

# Trinket catalog — id -> {name, desc, cost, max_owned, max_equipped}
const TRINKETS := {
	"heart_charm": {
		"name": "Heart Charm",
		"desc": "+1 heart. Restores you to 3 hearts (+1 per charm) at quest start.",
		"cost": 60,
		"max_owned": 1,
		"max_equipped": 1,
	},
	"gold_purse": {
		"name": "Golden Purse",
		"desc": "+50% gold from each task victory. Stacks.",
		"cost": 45,
		"max_owned": 2,
		"max_equipped": 2,
	},
	"stone_of_grace": {
		"name": "Stone of Grace",
		"desc": "Auto-completes your next failed task. Once per quest.",
		"cost": 90,
		"max_owned": 1,
		"max_equipped": 1,
	},
}

func _ready() -> void:
	SaveManager.load_game(self)

func start_new_quest() -> void:
	current_task_index = 0
	successes_this_quest = 0
	trinket_auto_used = false
	# Heart Charm: restore to full hearts + extra per charm equipped
	if heart_trinket_count() > 0:
		lives = maxi(lives, 3 + heart_trinket_count())
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
		# Golden Purse multiplier
		bonus = int(bonus * gold_bonus_multiplier())
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
	owned_trinkets = {}
	equipped_trinkets = []
	trinket_auto_used = false
	SaveManager.save_game(self)

# --- Trinket helpers ---
func trinket_count(id: String) -> int:
	return int(owned_trinkets.get(id, 0))

func equipped_count(id: String) -> int:
	return equipped_trinkets.count(id)

func heart_trinket_count() -> int:
	return equipped_count("heart_charm")

func gold_bonus_multiplier() -> float:
	return 1.0 + 0.5 * equipped_count("gold_purse")

func buy_trinket(id: String) -> bool:
	if not TRINKETS.has(id):
		return false
	if trinket_count(id) >= int(TRINKETS[id]["max_owned"]):
		return false
	var cost: int = int(TRINKETS[id]["cost"])
	if gold < cost:
		return false
	gold -= cost
	owned_trinkets[id] = trinket_count(id) + 1
	SaveManager.save_game(self)
	return true

func toggle_trinket_equip(id: String) -> bool:
	if trinket_count(id) <= 0:
		return false
	if equipped_trinkets.has(id):
		equipped_trinkets.erase(id)
		SaveManager.save_game(self)
		return true
	if equipped_trinkets.size() >= MAX_TRINKET_SLOTS:
		return false
	if equipped_count(id) >= int(TRINKETS[id]["max_equipped"]):
		return false
	equipped_trinkets.append(id)
	SaveManager.save_game(self)
	return true

## Called by TaskBase.fail() — consumes the Stone of Grace once per quest.
func prepare_auto_complete() -> bool:
	if equipped_trinkets.has("stone_of_grace") and not trinket_auto_used:
		trinket_auto_used = true
		return true
	return false
