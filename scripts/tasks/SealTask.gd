extends TaskBase
## SealTask — "SEAL IT!"
## Drag the wax stamp onto the letter. Mouse drag / touch drag / WASD+Action.
## Medieval chancery + modern drag interaction.

var dragging: bool = false
var stamp_pos: Vector2 = Vector2(380, 380)
var stamp_grab_offset: Vector2 = Vector2.ZERO
var letter_rect: Rect2 = Rect2(Vector2(560, 220), Vector2(280, 360))
var stamp_size: Vector2 = Vector2(72, 72)
var wasd_pos: Vector2 = Vector2(380, 380)

@onready var letter: ColorRect = $Letter
@onready var stamp: ColorRect = $Stamp
@onready var hint: Label = $CanvasLayer/Hint
@onready var drop_zone: ColorRect = $Letter/DropZone

func _ready() -> void:
	command_text = "SEAL IT!"
	super._ready()

func on_task_start() -> void:
	stamp_pos = Vector2(320, 380)
	wasd_pos = stamp_pos
	dragging = false
	if letter:
		letter_rect = Rect2(letter.position, letter.size)
	if stamp:
		stamp.position = stamp_pos - stamp.size / 2
		stamp.modulate = Color.WHITE
	if drop_zone:
		drop_zone.modulate.a = 0.35
	if hint:
		hint.text = "Drag the seal onto the letter!"

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	# WASD alternative for controller/no-mouse: move stamp
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() > 0.1:
		wasd_pos += dir * 420.0 * delta
		wasd_pos.x = clampf(wasd_pos.x, 40, 1240)
		wasd_pos.y = clampf(wasd_pos.y, 120, 680)
		if dragging or dir.length() > 0.2:
			stamp_pos = wasd_pos
			if stamp:
				stamp.position = stamp_pos - stamp.size / 2
	# Drop check: stamp center inside letter's wax circle (center of drop_zone)
	if drop_zone and stamp:
		var stamp_center := stamp_pos
		var zone_center := drop_zone.global_position + drop_zone.size / 2 if drop_zone.get_parent() is ColorRect else letter_rect.get_center()
		# Use letter center if drop_zone weird
		if letter:
			zone_center = letter.position + Vector2(letter.size.x / 2, letter.size.y * 0.72)
		var d := stamp_center.distance_to(zone_center)
		if d < 46:
			drop_zone.modulate = Color("#7cff7c")
			drop_zone.modulate.a = 0.7
			if dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_do_seal()
			# WASD seal: press action while in zone
			if Input.is_action_just_pressed("action") and dir.length() < 0.1:
				# avoid instant — require deliberate
				pass
		else:
			drop_zone.modulate = Color("#ffd94c")
			drop_zone.modulate.a = 0.35
		# Auto-seal for WASD when holding action in zone
		if d < 46 and Input.is_action_pressed("action") and dir.length() > 0:
			# If using WASD, holding action = pressing seal
			if Input.is_action_just_pressed("action"):
				_do_seal()

func _do_seal() -> void:
	if _finished:
		return
	if stamp:
		stamp.modulate = Color("#ff7c7c")
		create_tween().tween_property(stamp, "scale", Vector2(0.85, 0.85), 0.08).set_trans(Tween.TRANS_BACK)
		create_tween().tween_property(stamp, "scale", Vector2.ONE, 0.12)
	succeed()

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start drag if on stamp
			if stamp and Rect2(stamp.position, stamp.size).has_point(event.position):
				dragging = true
				stamp_grab_offset = event.position - stamp_pos
				if hint:
					hint.text = ""
		else:
			if dragging:
				dragging = false
				# Check drop on release
				var zone_center: Vector2 = letter.position + Vector2(letter.size.x / 2, letter.size.y * 0.72) if letter else Vector2(640, 360)
				if stamp_pos.distance_to(zone_center) < 52:
					_do_seal()
	elif event is InputEventMouseMotion and dragging:
		stamp_pos = event.position - stamp_grab_offset
		if stamp:
			stamp.position = stamp_pos - stamp.size / 2
	elif event.is_action_pressed("action") and not dragging:
		# Controller press-to-seal: if stamp near zone
		var zone_center: Vector2 = letter.position + Vector2(letter.size.x / 2, letter.size.y * 0.72) if letter else Vector2(640, 360)
		if stamp_pos.distance_to(zone_center) < 52:
			_do_seal()
