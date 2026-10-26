extends TaskBase
## ChantTask — "CHANT!"
## Simon-style: 4 rune stones flash in sequence, player repeats via Arrow keys / WASD / face buttons.
## Input mapping: Up/W = ᛉ [W], Right/D = ᛟ [D], Down/S = ᛝ [S], Left/A = ᛗ [A]

const RUNE_GLYPHS := ["ᛉ", "ᛟ", "ᛝ", "ᛗ"]
const RUNE_KEYS := ["W", "D", "S", "A"]

var sequence: Array[int] = [] # 0..3
var showing: bool = true
var show_index: int = 0
var show_t: float = 0.0
var input_index: int = 0
var seq_len: int = 4

var runes: Array = [] # filled in on_task_start
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
	show_t = 0.45
	input_index = 0
	runes = [$Rune0, $Rune1, $Rune2, $Rune3]
	for r in runes:
		if r:
			r.modulate = Color.WHITE
			r.scale = Vector2.ONE
	if prompt:
		prompt.text = "Watch…"
	_build_rune_stones()

# ---------------------------------------------------------------------------
# Stone rune tablets — cel-shaded carved stone
# ---------------------------------------------------------------------------

func _build_rune_stones() -> void:
	for i in 4:
		var root := get_node_or_null("Rune%d" % i) as Node2D
		if root == null:
			continue
		for child in root.get_children():
			child.free()
		_build_rune_stone(root, i)

func _build_rune_stone(root: Node2D, index: int) -> void:
	var outer := _stone_outer()
	var face := _scaled(outer, 0.94)
	var panel := _stone_panel()

	# Slab: dark outline + hard bevel highlights/shadows + flat stone face.
	_poly(root, outer, Color("#14120f"))
	var bevel_shadow := _poly(root, face, Color("#403c34"))
	bevel_shadow.position = Vector2(3, 3)
	var bevel_light := _poly(root, face, Color("#9a9384"))
	bevel_light.position = Vector2(-3, -3)
	_poly(root, face, Color("#6b6659"))

	# Recessed panel the rune is chiselled into.
	_poly(root, _scaled(panel, 1.05), Color("#2a2721"))
	var panel_shadow := _poly(root, panel, Color("#2e2b25"))
	panel_shadow.position = Vector2(-2, -2)
	var panel_light := _poly(root, panel, Color("#8a8476"))
	panel_light.position = Vector2(2, 2)
	_poly(root, panel, Color("#4c483f"))

	_add_crack(root, index)

	# Engraved rune: dark cut with a light lower-right lip.
	var glyph: String = String(RUNE_GLYPHS[index])
	var rune_rect := Rect2(-58, -50, 116, 76)
	_label(root, glyph, rune_rect.position + Vector2(-2, -2), rune_rect.size, 64, Color("#211e19"), Color("#211e19"), 3)
	_label(root, glyph, rune_rect.position + Vector2(2, 2), rune_rect.size, 64, Color("#b9b2a2"), Color("#b9b2a2"), 3)
	_label(root, glyph, rune_rect.position, rune_rect.size, 64, Color("#2b2721"), Color("#2b2721"), 3)

	# Associated key letter underneath the symbol.
	_label(root, "[%s]" % String(RUNE_KEYS[index]), Vector2(-40, 32), Vector2(80, 24), 18, Color("#ffd94c"), Color("#1a1208"), 4)

func _stone_outer() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-64, -86), Vector2(60, -86), Vector2(74, -72), Vector2(74, -16),
		Vector2(68, 48), Vector2(54, 84), Vector2(-46, 86), Vector2(-70, 74),
		Vector2(-74, 20), Vector2(-70, -50),
	])

func _stone_panel() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-52, -58), Vector2(48, -58), Vector2(58, -48), Vector2(58, 22),
		Vector2(52, 52), Vector2(42, 60), Vector2(-42, 60), Vector2(-56, 50),
		Vector2(-58, 18), Vector2(-56, -40),
	])

func _add_crack(root: Node2D, index: int) -> void:
	var cracks := [
		PackedVector2Array([Vector2(-66, -58), Vector2(-54, -40), Vector2(-60, -24)]),
		PackedVector2Array([Vector2(66, 28), Vector2(60, 42), Vector2(64, 62)]),
		PackedVector2Array([Vector2(-62, 52), Vector2(-52, 58)]),
		PackedVector2Array([Vector2(58, -60), Vector2(66, -48)]),
	]
	var pts: PackedVector2Array = cracks[index % cracks.size()]
	var crack := Line2D.new()
	crack.points = pts
	crack.width = 2.0
	crack.default_color = Color("#35312a")
	root.add_child(crack)

	var lit_pts := PackedVector2Array()
	for p in pts:
		lit_pts.append(p + Vector2(1.5, 1.5))
	var lit := Line2D.new()
	lit.points = lit_pts
	lit.width = 1.0
	lit.default_color = Color("#8a8476")
	root.add_child(lit)

# ---------------------------------------------------------------------------
# Sequence flow
# ---------------------------------------------------------------------------

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	if showing:
		show_t -= delta
		if show_t <= 0:
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
				show_t = 0.55 if show_index < sequence.size() else 0.4
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
	match pressed:
		0: gesture_performed("move_up")
		1: gesture_performed("move_right")
		2: gesture_performed("move_down")
		3: gesture_performed("move_left")
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
		# Wrong rune — shake the stone and settle it back.
		if node:
			var start_y: float = node.position.y
			var tw := create_tween()
			tw.tween_property(node, "position:y", start_y + 8.0, 0.06).set_trans(Tween.TRANS_BACK)
			tw.tween_property(node, "position:y", start_y, 0.08)
		fail()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _poly(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = color
	parent.add_child(p)
	return p

func _scaled(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p * factor)
	return out

func _label(parent: Node, text: String, pos: Vector2, size: Vector2, font_size: int, color: Color, outline_color: Color, outline_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outline_size > 0:
		l.add_theme_color_override("font_outline_color", outline_color)
		l.add_theme_constant_override("outline_size", outline_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
