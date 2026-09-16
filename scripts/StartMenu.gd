extends Control

@onready var btn_start: Button = $Center/Panel/VBox/BtnStart
@onready var btn_continue: Button = $Center/Panel/VBox/BtnContinue
@onready var btn_exit: Button = $Center/Panel/VBox/BtnExit
@onready var label_save: Label = $Center/Panel/VBox/SaveInfo
@onready var btn_wipe: Button = $Center/Panel/VBox/BtnWipe
@onready var btn_shop: Button = $Center/Panel/VBox/BtnShop

func _ready() -> void:
	btn_start.pressed.connect(_on_start)
	btn_continue.pressed.connect(_on_continue)
	btn_exit.pressed.connect(_on_exit)
	btn_wipe.pressed.connect(_on_wipe)
	btn_shop.pressed.connect(_on_shop)

	var has_save := SaveManager.has_save()
	btn_continue.disabled = not has_save

	if has_save:
		label_save.text = "Quest %d  |  Gold %d  |  Lives %d" % [GameManager.quest_number, GameManager.gold, GameManager.lives]
	else:
		label_save.text = "No save — a new legend awaits."

	# Title wobble
	var title: Label = $Center/Panel/VBox/Title
	create_tween().set_loops().tween_property(title, "scale", Vector2(1.04, 1.04), 0.7).set_trans(Tween.TRANS_SINE)
	create_tween().set_loops().tween_property(title, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE).set_delay(0.7)

func _on_start() -> void:
	# New quest — does not wipe gold/upgrades unless user chose wipe
	GameManager.start_new_quest()

func _on_continue() -> void:
	# Continue to Long Rest (safe hub) or next quest if mid-quest
	if GameManager.current_task_index > 0 and GameManager.current_task_index < GameManager.TASKS_PER_QUEST:
		GameManager.start_new_quest()
	else:
		get_tree().change_scene_to_file("res://scenes/LongRest.tscn")

func _on_exit() -> void:
	SaveManager.save_game(GameManager)
	get_tree().quit()

func _on_wipe() -> void:
	GameManager.reset_progress()
	label_save.text = "Progress wiped. New legend."
	btn_continue.disabled = true

func _on_shop() -> void:
	GameManager.shop_return_scene = "res://scenes/StartMenu.tscn"
	get_tree().change_scene_to_file("res://scenes/Shop.tscn")
