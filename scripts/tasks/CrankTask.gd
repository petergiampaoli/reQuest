extends TaskBase
## CrankTask — "OPEN THREE CHESTS."
## The wheel spins automatically. Press F when the pointer crosses the gold zone.
## Land the required number of catches before the timer expires.

const CENTER: Vector2 = Vector2(640, 340)
const RADIUS: float = 190.0
const SPIN_SPEED: float = 3.0
const BASE_CATCHES: int = 3
const HOT_ARC: float = 0.45
const MIN_TARGET_GAP: float = 1.2

var needle_angle: float = 0.0
var target_angle: float = 0.0
var catches: int = 0
var required_catches: int = BASE_CATCHES
var progress_label: Label = null

func _ready() -> void:
	required_catches = _required_catches()
	command_text = "OPEN %s CHESTS." % _number_word(required_catches)
	super._ready()

func on_task_start() -> void:
	catches = 0
	needle_angle = 0.0
	target_angle = _pick_target_angle()
	progress_label = get_node_or_null("CanvasLayer/ProgressLabel")
	if progress_label == null:
		progress_label = _add_progress_label()
	progress_label.text = "0/%d" % required_catches
	_queue_redraw()
	_set_hint("Press F when the needle crosses gold")

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	# Automatic spin — the only input is the F/mash button.
	needle_angle = fposmod(needle_angle + SPIN_SPEED * delta, TAU)
	var hot: bool = absf(_norm_angle(needle_angle - target_angle)) < HOT_ARC
	queue_redraw()

	if Input.is_action_just_pressed("mash") and hot:
		gesture_performed("mash")
		catches += 1
		target_angle = _pick_target_angle()
		if progress_label:
			progress_label.text = "%d/%d" % [catches, required_catches]
		if catches >= required_catches:
			succeed()

## Base 3 catches; +1 for every 0.5 difficulty above 1.0.
func _required_catches() -> int:
	return BASE_CATCHES + maxi(0, int((GameManager.difficulty - 1.0) * 2.0))

## Pick a new gold zone that isn't already under the pointer.
func _pick_target_angle() -> float:
	var a := randf() * TAU
	var guard := 0
	while absf(_norm_angle(a - needle_angle)) < MIN_TARGET_GAP and guard < 24:
		a = randf() * TAU
		guard += 1
	return a

func _number_word(n: int) -> String:
	match n:
		3: return "THREE"
		4: return "FOUR"
		5: return "FIVE"
		6: return "SIX"
		7: return "SEVEN"
		8: return "EIGHT"
		_: return str(n)

func _norm_angle(a: float) -> float:
	return fposmod(a + PI, TAU) - PI

func _draw() -> void:
	var c := CENTER
	# Wheel body
	draw_circle(c, RADIUS * 0.42, Color(0.16, 0.10, 0.05))
	draw_arc(c, RADIUS * 0.42, 0, TAU, 48, Color("#6b5a3e"), 6.0, true)
	# Target zone
	var hot: bool = absf(_norm_angle(needle_angle - target_angle)) < HOT_ARC
	draw_sector(c, target_angle - HOT_ARC, target_angle + HOT_ARC, RADIUS, Color("#ffd94c") if hot else Color(0.55, 0.45, 0.22))
	# Pointer
	var tip := Vector2.from_angle(needle_angle)
	var p_from := c + tip * 30.0
	var p_to := c + tip * RADIUS
	draw_line(p_from, p_to, Color("#7cff7c"), 4.0)
	draw_circle(p_to, 8.0, Color("#c9b56a"))

func draw_sector(center: Vector2, from: float, to: float, radius: float, color: Color) -> void:
	var pts: PackedVector2Array = [center]
	var steps: int = 20
	for i in steps + 1:
		var a: float = lerpf(from, to, float(i) / float(steps))
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(pts, color)

func _queue_redraw() -> void:
	queue_redraw()

func _add_progress_label() -> Label:
	var label := Label.new()
	label.name = "ProgressLabel"
	label.text = "0/%d" % required_catches
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1, 0.851, 0.298))
	label.add_theme_color_override("font_outline_color", Color(0.09, 0.07, 0.03))
	label.add_theme_constant_override("outline_size", 6)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -100.0
	label.offset_top = 540.0
	label.offset_right = 100.0
	label.offset_bottom = 576.0
	get_node("CanvasLayer").add_child(label)
	return label

func _set_hint(text: String) -> void:
	var hint: Label = get_node_or_null("CanvasLayer/Hint")
	if hint:
		hint.text = text
