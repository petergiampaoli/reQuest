extends TaskBase
## SortTask — "SORT THE LOOT!"
## Click/move items to correct chest. Simplified: click 5 coins to pocket them. Tests mouse interaction.

var needed: int = 5
var collected: int = 0

@onready var counter: Label = $CanvasLayer/Counter

func _ready() -> void:
	command_text = "GRAB THE LOOT!"
	needed = 5 + int(GameManager.difficulty)
	super._ready()

func on_task_start() -> void:
	collected = 0
	_spawn_coins(needed + 2) # extra decoys that don't count? Actually all count for simplicity
	_update_counter()

func _spawn_coins(n: int) -> void:
	for i in n:
		var coin := Button.new()
		coin.text = "◉"
		coin.custom_minimum_size = Vector2(56, 56)
		coin.size = Vector2(56, 56)
		coin.position = Vector2(randf_range(120, 1160), randf_range(180, 560))
		# Woodcut coin look
		coin.add_theme_font_size_override("font_size", 28)
		var col: Color = Color("#ffd94c") if i < needed else Color("#8c8c8c")
		coin.add_theme_color_override("font_color", col)
		coin.pressed.connect(func():
			if _finished:
				return
			collected += 1
			_update_counter()
			coin.queue_free()
			# Pop effect
			if collected >= needed:
				succeed()
		)
		add_child(coin)
		# Drift animation
		var t := create_tween().set_loops()
		t.tween_property(coin, "position:y", coin.position.y + 8, 0.6 + randf() * 0.4).set_trans(Tween.TRANS_SINE)
		t.tween_property(coin, "position:y", coin.position.y, 0.6 + randf() * 0.4).set_trans(Tween.TRANS_SINE)

func _update_counter() -> void:
	if counter:
		counter.text = "%d / %d" % [collected, needed]
