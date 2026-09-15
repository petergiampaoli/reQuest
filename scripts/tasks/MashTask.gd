extends TaskBase
## MashTask — "HAMMER THE ANVIL!"
## Mash [F] / [X] as fast as you can. Baker-style: a blacksmith hammer slamming.

var required: int = 22
var count: int = 0

@onready var bar: ProgressBar = $CanvasLayer/MashBar
@onready var btn: Button = $CanvasLayer/MashButton
@onready var anvil: ColorRect = $Anvil

func _ready() -> void:
	command_text = "HAMMER THE ANVIL!"
	# Scale difficulty
	required = 18 + int(GameManager.difficulty * 6)
	super._ready()

func on_task_start() -> void:
	count = 0
	if bar:
		bar.max_value = required
		bar.value = 0
	# Hook button
	if btn:
		btn.pressed.connect(_on_mash)

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("mash"):
		_on_mash()
		get_viewport().set_input_as_handled()

func _on_mash() -> void:
	count += 1
	if bar:
		bar.value = count
	# Anvil bump
	if anvil:
		anvil.position.y = 340 - randf() * 6
		create_tween().tween_property(anvil, "position:y", 340, 0.06)
		anvil.modulate = Color(1.4, 1.4, 1.0) if count % 2 == 0 else Color.WHITE
		create_tween().tween_property(anvil, "modulate", Color.WHITE, 0.08)
	if count >= required:
		succeed()

func on_task_tick(_delta: float) -> void:
	if btn:
		btn.text = "HAMMER! %d/%d  [F]" % [count, required]
