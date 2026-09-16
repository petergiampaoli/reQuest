extends Control
## Long Rest — camp scene between quests. Save/exit safe, choose path, buy upgrades.

@onready var lbl_stats: Label = $Center/Panel/VBox/Stats
@onready var btn_save: Button = $Center/Panel/VBox/RowSave/BtnSave
@onready var btn_exit: Button = $Center/Panel/VBox/RowSave/BtnExit
@onready var btn_quest_forest: Button = $Center/Panel/VBox/RowPaths/BtnForest
@onready var btn_quest_crypt: Button = $Center/Panel/VBox/RowPaths/BtnCrypt
@onready var btn_quest_tower: Button = $Center/Panel/VBox/RowPaths/BtnTower
@onready var btn_shop: Button = $Center/Panel/VBox/RowSave/BtnShop
@onready var upgrade_container: VBoxContainer = $Center/Panel/VBox/Upgrades

func _ready() -> void:
	btn_save.pressed.connect(_on_save)
	btn_exit.pressed.connect(_on_exit)
	btn_quest_forest.pressed.connect(func(): _start_path("forest"))
	btn_quest_crypt.pressed.connect(func(): _start_path("crypt"))
	btn_quest_tower.pressed.connect(func(): _start_path("tower"))
	btn_shop.pressed.connect(_on_shop)

	_refresh()
	_build_upgrades()
	_show_trinkets()

func _refresh() -> void:
	lbl_stats.text = "LONG REST — Quest %d complete  |  %d/%d this quest  |  Gold %d  |  Lives %d" % [
		GameManager.quest_number - 1, GameManager.successes_this_quest, GameManager.TASKS_PER_QUEST, GameManager.gold, GameManager.lives
	]

func _build_upgrades() -> void:
	for c in upgrade_container.get_children():
		c.queue_free()
	for id in GameManager.UPGRADE_COSTS.keys():
		var cost: int = GameManager.UPGRADE_COSTS[id] + GameManager.upgrades[id] * 5
		var lvl: int = GameManager.upgrades[id]
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s Lv.%d  (%d gold)" % [id.capitalize(), lvl, cost]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		btn.text = "Buy"
		btn.disabled = GameManager.gold < cost
		btn.pressed.connect(func(): _buy(id))
		row.add_child(lbl)
		row.add_child(btn)
		upgrade_container.add_child(row)

func _buy(id: String) -> void:
	if GameManager.try_buy_upgrade(id):
		_refresh()
		_build_upgrades()

func _on_save() -> void:
	SaveManager.save_game(GameManager)
	lbl_stats.text += "  — SAVED!"

func _on_exit() -> void:
	SaveManager.save_game(GameManager)
	get_tree().change_scene_to_file("res://scenes/StartMenu.tscn")

func _on_shop() -> void:
	GameManager.shop_return_scene = "res://scenes/LongRest.tscn"
	get_tree().change_scene_to_file("res://scenes/Shop.tscn")

func _show_trinkets() -> void:
	var names: Array[String] = []
	for id in GameManager.equipped_trinkets:
		var def: Dictionary = GameManager.TRINKETS.get(id, {})
		names.append("🧿 %s" % def.get("name", id))
	var lbl: Label = $Center/Panel/VBox/TrinketStatus
	lbl.text = "Equipped trinkets: %s" % ("none" if names.is_empty() else "  •  ".join(names))

func _start_path(path: String) -> void:
	# Path choice modifies next quest difficulty / flavor (stub — extend with TaskManager filters)
	match path:
		"forest":
			GameManager.difficulty = maxf(1.0, GameManager.difficulty * 0.95)
		"crypt":
			GameManager.difficulty *= 1.1
		"tower":
			GameManager.difficulty *= 1.18
	SaveManager.save_game(GameManager)
	GameManager.start_new_quest()
