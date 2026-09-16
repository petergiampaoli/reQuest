extends Control
## Trinket Shop — buy + equip trinkets at any rest point.
## Catalog lives in GameManager.TRINKETS.

@onready var lbl_gold: Label = $Center/Panel/VBox/Hud/Gold
@onready var lbl_slots: Label = $Center/Panel/VBox/Hud/Slots
@onready var list: VBoxContainer = $Center/Panel/VBox/List
@onready var btn_back: Button = $Center/Panel/VBox/RowBack/BtnBack

var back_scene: String = "res://scenes/LongRest.tscn"

func _ready() -> void:
	# Allow Start Menu to set return target
	if GameManager.shop_return_scene != "":
		back_scene = GameManager.shop_return_scene
	btn_back.pressed.connect(_on_back)
	_rebuild()

func _rebuild() -> void:
	for c in list.get_children():
		c.queue_free()

	lbl_gold.text = "Gold %d" % GameManager.gold
	lbl_slots.text = "Trinket Slots: %d / %d" % [GameManager.equipped_trinkets.size(), GameManager.MAX_TRINKET_SLOTS]

	for id in GameManager.TRINKETS.keys():
		var def: Dictionary = GameManager.TRINKETS[id]
		list.add_child(_build_row(id, def))

func _build_row(id: String, def: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)

	var name_lbl := Label.new()
	name_lbl.text = "🧿 %s  (owned %d)" % [def["name"], GameManager.trinket_count(id)]
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color("#ffd94c"))
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "%s" % def["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.76, 1))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_lbl)

	row.add_child(info)

	# Equip / unequip toggle
	var equip_btn := Button.new()
	var equipped: bool = GameManager.equipped_trinkets.has(id)
	equip_btn.text = "Unequip" if equipped else "Equip"
	equip_btn.disabled = GameManager.trinket_count(id) <= 0
	equip_btn.pressed.connect(func():
		GameManager.toggle_trinket_equip(id)
		_rebuild()
	)
	row.add_child(equip_btn)

	# Buy button
	var buy_btn := Button.new()
	var owned: int = GameManager.trinket_count(id)
	if owned >= int(def["max_owned"]):
		buy_btn.text = "Owned (max)"
		buy_btn.disabled = true
	else:
		var cost: int = int(def["cost"])
		buy_btn.text = "Buy — %d gold" % cost
		buy_btn.disabled = GameManager.gold < cost
		buy_btn.pressed.connect(func():
			GameManager.buy_trinket(id)
			_rebuild()
		)
	row.add_child(buy_btn)

	return row

func _on_back() -> void:
	get_tree().change_scene_to_file(back_scene)