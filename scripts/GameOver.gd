extends Control
## GameOver — death screen. Shows run stats from GameManager.last_run_stats.

@onready var title: Label = $Center/Panel/VBox/Title
@onready var subtitle: Label = $Center/Panel/VBox/Subtitle
@onready var stats: Label = $Center/Panel/VBox/Stats
@onready var detail: Label = $Center/Panel/VBox/Detail
@onready var btn_retry: Button = $Center/Panel/VBox/Row/BtnRetry
@onready var btn_menu: Button = $Center/Panel/VBox/Row/BtnMenu

func _ready() -> void:
	btn_retry.pressed.connect(_on_retry)
	btn_menu.pressed.connect(_on_menu)

	# Pull snapshot; fallback if accessed directly (e.g. debug)
	var s: Dictionary = GameManager.last_run_stats
	if s.is_empty():
		# Build from live state as fallback
		s = {
			"total_tasks_completed": GameManager.total_tasks_completed,
			"total_successes": GameManager.total_successes,
			"total_failures": GameManager.total_failures,
			"quests_cleared": max(0, GameManager.quest_number - 1),
			"gold": GameManager.gold,
			"quest_reached": GameManager.quest_number,
			"tasks_in_final_quest": GameManager.current_task_index,
		}

	var tasks: int = int(s.get("total_tasks_completed", 0))
	var succ: int = int(s.get("total_successes", 0))
	var fail: int = int(s.get("total_failures", 0))
	var quests: int = int(s.get("quests_cleared", 0))
	var gold: int = int(s.get("gold", 0))
	var q_reached: int = int(s.get("quest_reached", 1))

	# Title flavor based on performance
	if tasks == 0:
		title.text = "YOU DIED"
		subtitle.text = "Not a single task survived."
	elif succ == 0:
		title.text = "YOU DIED"
		subtitle.text = "The dungeon claimed you early."
	elif float(succ) / max(1, tasks) > 0.75:
		title.text = "LEGEND FALLEN"
		subtitle.text = "A heroic run — the bards will sing of it."
	elif quests >= 2:
		title.text = "QUEST ENDED"
		subtitle.text = "Many quests cleared. Rest well, adventurer."
	else:
		title.text = "YOU DIED"
		subtitle.text = "The reQuest continues without you…"

	# Main stats block — emphasize tasks completed as requested
	var rate: float = (100.0 * succ / max(1, tasks)) if tasks > 0 else 0.0
	stats.text = "Tasks Completed:  %d\nSucceeded:  %d  •  Failed:  %d  (%.0f%%)\nQuests Cleared: %d  (reached Quest %d)" % [tasks, succ, fail, rate, quests, q_reached]

	detail.text = "Gold hoarded: %d  •  Total Tasks (lifetime): %d\n\nYour ♥ ran out. 3 hearts per run — fail a task, lose a heart." % [gold, GameManager.total_tasks_completed]

	# Animate in
	title.scale = Vector2(1.25, 1.25)
	title.modulate.a = 0.0
	create_tween().tween_property(title, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	create_tween().tween_property(title, "modulate:a", 1.0, 0.25)
	stats.modulate.a = 0.0
	create_tween().tween_property(stats, "modulate:a", 1.0, 0.4).set_delay(0.2)

func _on_retry() -> void:
	# Start fresh quest; lives already reset to 3 in _game_over
	GameManager.start_new_quest()

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("action"):
		_on_retry()
	elif event.is_action_pressed("ui_cancel"):
		_on_menu()
