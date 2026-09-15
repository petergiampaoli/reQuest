extends TaskBase
## ParryTask — "PARRY!"
## A bar slides back and forth; press [SPACE]/E when marker is in gold zone.

var marker_pos: float = 0.0
var marker_dir: float = 1.0
var speed: float = 260.0
var input_done: bool = false

@onready var track: ColorRect = $Track
@onready var zone: ColorRect = $Track/Zone
@onready var marker: ColorRect = $Track/Marker
@onready var prompt: Label = $CanvasLayer/Prompt

func _ready() -> void:
	command_text = "PARRY!"
	speed = 220.0 + GameManager.difficulty * 80.0
	super._ready()

func on_task_start() -> void:
	marker_pos = 0.0
	marker_dir = 1.0
	input_done = false
	if prompt:
		prompt.text = "[SPACE] / [E] when in GOLD!"

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	# Move marker 0..1 ping-pong
	marker_pos += marker_dir * speed * delta / 340.0
	if marker_pos > 1.0:
		marker_pos = 1.0
		marker_dir = -1.0
	elif marker_pos < 0.0:
		marker_pos = 0.0
		marker_dir = 1.0

	if marker and track:
		marker.position.x = marker_pos * (track.size.x - marker.size.x)

	# Visual urgency near end
	if _time_left < 1.5 and prompt:
		prompt.modulate = Color("#ff4a4a") if int(_time_left * 6) % 2 == 0 else Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if _finished or input_done:
		return
	if event.is_action_pressed("action"):
		input_done = true
		_check_parry()
		get_viewport().set_input_as_handled()

func _check_parry() -> void:
	# Gold zone is centered 0.42..0.58 (tightens with difficulty)
	var half: float = maxf(0.06, 0.10 / GameManager.difficulty)
	var zone_center: float = 0.5
	var zone_min: float = zone_center - half
	var zone_max: float = zone_center + half
	# Update zone visuals to reflect actual hit window
	if zone and track:
		zone.position.x = zone_min * track.size.x
		zone.size.x = (zone_max - zone_min) * track.size.x

	if marker_pos >= zone_min and marker_pos <= zone_max:
		succeed()
	else:
		fail()
