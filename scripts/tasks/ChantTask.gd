extends TaskBase
## ChantTask — "CHANT!"
## Simon-style: 4 runes flash in sequence, player repeats via Arrow keys / WASD / face buttons.
## Input mapping: Up/W = ᛉ, Right/D = ᛟ, Down/S = ᛝ, Left/A = ᛗ

var sequence: Array[int] = [] # 0..3
var showing: bool = true
var show_index: int = 0
var show_timer: float = 0.0
var input_index: int = 0
var seq_len: int = 4

@onready var runes: Array = [] # filled in on_task_start
@onready var prompt: Label = $CanvasLayer/Prompt

func _ready() -> void:
	command_text = "CHANT!"
	seq_len = 3 + int(GameManager.difficulty) # 3..6
	seq_len = clampi(seq_len, 3, 5)
	super._ready()

func on_task_start() -> void:
	# Build sequence
	sequence.clear()
	for i in seq_len:
		sequence.append(randi() % 4)
	showing = true
	show_index = 0
	show_timer = 0.45
	input_index = 0
	runes = [$Rune0, $Rune1, $Rune2, $Rune3]
	for r in runes:
		if r:
			r.modulate = Color.WHITE
			r.scale = Vector2.ONE
	if prompt:
		prompt.text = "Watch…"
	_ensure_rune_labels()

func _ensure_rune_labels() -> void:
	var glyphs := ["ᛉ", "ᛟ", "ᛝ", "ᛗ"]
	for i in 4:
		var node: Label = get_node_or_null("Rune%d" % i)
		if node and node is Label:
			node.text = glyphs[i]
			node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	if showing:
		show_timer -= delta
		if show_timer <= 0:
			# clear previous
			if show_index > 0:
				var prev: int = sequence[show_index - 1]
				var n: Node = runes[prev] if prev < runes.size() else null
				if n:
					n.modulate = Color.WHITE
					n.scale = Vector2.ONE
			if show_index < sequence.size():
				var idx: int = sequence[show_index]
				var node: Node = runes[idx] if idx < runes.size() else null
				if node:
					node.modulate = Color("#ffd94c")
					node.scale = Vector2(1.25, 1.25)
					# ping
					create_tween().tween_property(node, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
				show_index += 1
				show_timer = 0.55 if show_index < sequence.size() else 0.4
			else:
				# Done showing
				showing = false
				if prompt:
					prompt.text = "Repeat!  WASD / Arrows"
				for r in runes:
					if r:
						r.modulate = Color(0.95, 0.95, 0.9)
		return
	# Listening phase — timeout is TaskBase timer; nothing else tick

func _unhandled_input(event: InputEvent) -> void:
	if _finished or showing:
		return
	var pressed: int = -1
	if event.is_action_pressed("move_up"):
		pressed = 0
	elif event.is_action_pressed("move_right"):
		pressed = 1
	elif event.is_action_pressed("move_down"):
		pressed = 2
	elif event.is_action_pressed("move_left"):
		pressed = 3
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_W, KEY_UP: pressed = 0
			KEY_D, KEY_RIGHT: pressed = 1
			KEY_S, KEY_DOWN: pressed = 2
			KEY_A, KEY_LEFT: pressed = 3
	if pressed == -1:
		return
	# Feedback
	var node: Node = runes[pressed] if pressed < runes.size() else null
	if node:
		node.modulate = Color("#7cff7c") if pressed == sequence[input_index] else Color("#ff4a4a")
		create_tween().tween_property(node, "modulate", Color.WHITE, 0.22)
	get_viewport().set_input_as_handled()
	if pressed == sequence[input_index]:
		input_index += 1
		if input_index >= sequence.size():
			succeed()
	else:
		# Wrong rune
		if node:
			create_tween().tween_property(node, "position:y", node.position.y + 8, 0.06).set_trans(Tween.TRANS_BACK)
		fail()
