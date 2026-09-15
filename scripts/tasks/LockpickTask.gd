extends TaskBase
## LockpickTask — "PICK IT!"
## Rotate with A/D or Left/Right to find sweet spot, press [SPACE]/E to pick.
## Baker vibe: rusted dungeon lock, woodcut tumblers.

var sweet_angle: float = 0.0 # degrees  -60..60
var current_angle: float = 0.0
var window_deg: float = 14.0
var wiggle: float = 0.0

@onready var dial: ColorRect = $Dial
@onready var pin: ColorRect = $Dial/Pin
@onready var zone_hint: ColorRect = $Dial/ZoneHint
@onready var feedback: Label = $CanvasLayer/Feedback

func _ready() -> void:
	command_text = "PICK IT!"
	# Narrow window with difficulty
	window_deg = maxf(7.0, 16.0 - GameManager.difficulty * 2.5)
	sweet_angle = randf_range(-52.0, 52.0)
	super._ready()

func on_task_start() -> void:
	current_angle = 0.0
	_update_dial()
	if feedback:
		feedback.text = "A/D or ←→ to turn  •  [SPACE] to pick"
	if zone_hint:
		# Hint is invisible — faint if upgrades help
		zone_hint.visible = GameManager.upgrades["extra_time"] > 0
		zone_hint.position.x = 100.0 + (sweet_angle + 60.0) / 120.0 * 80.0 - zone_hint.size.x / 2

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	var dir := Input.get_axis("move_left", "move_right")
	# Also accept A/D explicitly via same axis; add slight inertia
	current_angle += dir * 95.0 * delta
	current_angle = clampf(current_angle, -60.0, 60.0)
	if dir != 0:
		wiggle += delta * 12.0
	_update_dial()
	# Color feedback
	var dist := absf(current_angle - sweet_angle)
	var t: float = clampf(1.0 - dist / 40.0, 0.0, 1.0)
	if dial:
		dial.modulate = Color(1, 0.35 + t * 0.65, 0.35 + t * 0.65) if t > 0.7 else Color.WHITE
		# shake when close
		if t > 0.75:
			dial.position.x = 590.0 + sin(wiggle) * 2.0
			dial.position.y = 340.0 + cos(wiggle * 1.3) * 1.0

func _update_dial() -> void:
	if dial:
		dial.rotation_degrees = current_angle
	if pin:
		pin.rotation_degrees = -current_angle * 0.6

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("action"):
		var dist := absf(current_angle - sweet_angle)
		if dist <= window_deg:
			# success flash
			if dial:
				dial.color = Color("#7cff7c")
			succeed()
		else:
			if feedback:
				feedback.text = "CLICK. Wrong — try again!"
				feedback.modulate = Color("#ff4a4a")
				create_tween().tween_property(feedback, "modulate", Color.WHITE, 0.25)
			# brief lock jam — nudge away
			current_angle += (randf() - 0.5) * 10.0
			if _time_left < 1.2:
				fail()
		get_viewport().set_input_as_handled()
