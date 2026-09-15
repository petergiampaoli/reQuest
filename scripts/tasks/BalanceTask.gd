extends TaskBase
## BalanceTask — "DON'T SPILL!"
## Keep the ale mug centered on the tray. Tray tilts with A/D, Left/Right, or mouse.
## Physics-ish: mug slides with gravity relative to tilt; keep inside tray for full duration.

var tilt: float = 0.0 # radians, -0.45..0.45
var mug_offset: float = 0.0 # -1..1 relative to tray
var mug_vel: float = 0.0
var time_balanced: float = 0.0
var required_hold: float = 3.2 # seconds of good balance needed (not necessarily contiguous, but near end)

@onready var tray: ColorRect = $Tray
@onready var mug: ColorRect = $Tray/Mug
@onready var zone: ColorRect = $Tray/Zone
@onready var hint: Label = $CanvasLayer/Hint

func _ready() -> void:
	command_text = "DON'T SPILL!"
	# Slightly harder = faster slide
	required_hold = 2.8 + GameManager.difficulty * 0.35
	super._ready()

func on_task_start() -> void:
	tilt = 0.0
	mug_offset = randf_range(-0.25, 0.25)
	mug_vel = 0.0
	time_balanced = 0.0
	_update_visuals()
	if hint:
		hint.text = "A/D or ←→ keep the ale centered!"

func on_task_tick(delta: float) -> void:
	if _finished:
		return
	# Tilt input
	var dir := Input.get_axis("move_left", "move_right")
	# Mouse also controls tilt if held
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mp := get_viewport().get_mouse_position()
		var want := (mp.x - 640.0) / 360.0 # -1..1
		dir = clampf(want * 1.6, -1.0, 1.0)
	tilt += dir * 1.9 * delta
	tilt = clampf(tilt, -0.52, 0.52)
	# Mug physics: accelerates toward downhill (tilt) + small random wobble
	var gravity: float = tilt * 3.8
	var friction: float = 1.8
	mug_vel += gravity * delta
	mug_vel -= mug_vel * friction * delta
	mug_vel += randf_range(-0.06, 0.06) * delta * GameManager.difficulty
	mug_offset += mug_vel * delta
	# Clamp sliding off tray = fail
	if absf(mug_offset) > 0.92:
		mug_offset = clampf(mug_offset, -0.92, 0.92)
		if mug:
			mug.modulate = Color("#ff4a4a")
		fail()
		return
	_update_visuals()
	# Balance window: centered 0.38 width
	var balanced: bool = absf(mug_offset) < 0.28
	if balanced:
		time_balanced += delta
		if tray:
			tray.modulate = Color("#7cff7c")
		if hint:
			hint.text = "Steady… %.1f / %.1f" % [time_balanced, required_hold]
			hint.modulate = Color("#7cff7c")
	else:
		# Decay slowly, not reset — forgiving
		time_balanced -= delta * 0.35
		time_balanced = maxf(time_balanced, 0.0)
		if tray:
			tray.modulate = Color(1, 0.85, 0.55) if absf(mug_offset) < 0.5 else Color("#ff9a4a")
		if hint and time_balanced < 0.1:
			hint.text = "A/D or ←→ keep the ale centered!"
			hint.modulate = Color.WHITE
	# Win condition: hold long enough before timer expires (or survive whole timer with forgiving tally)
	if time_balanced >= required_hold:
		succeed()
	# Alternative: if timer almost done and we stayed mostly balanced, also succeed
	if _time_left < 0.2 and time_balanced >= required_hold * 0.65:
		succeed()

func _update_visuals() -> void:
	if tray:
		tray.rotation = tilt * 0.55
	if mug:
		# Place mug along tray local x
		var tray_half: float = (tray.size.x / 2) - mug.size.x / 2 - 6.0
		mug.position.x = tray.size.x / 2 - mug.size.x / 2 + mug_offset * tray_half
		# Bob slightly
		mug.position.y = 6.0 + sin(Time.get_ticks_msec() * 0.006) * 1.0
