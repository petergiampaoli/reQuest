extends TaskBase
## BossTask — the BOSS FIGHT that ends every quest.
## A quest-like challenge, but you must do DOUBLE the work in the SAME time:
## the required hit count is double a normal mash quest's goal, and the boss
## switches between demanding MASH [F] and STOMP [Space/Space] so both hands
## work at once. Stall too long and the boss counters — you fail (lose a heart,
## then retry the boss; it must die to advance to the next difficulty).

const STALL_TIME := 1.4

var required := 44
var hits := 0
var _prompt := "mash"
var _prompt_flip := 0.6
var _stall_left := STALL_TIME

@onready var hp_bar: ProgressBar = $CanvasLayer/BossHpBar
@onready var prompt_label: Label = $CanvasLayer/PromptLabel
@onready var hint: Label = $CanvasLayer/Hint
@onready var boss_body: ColorRect = $Boss/Body
@onready var flash: ColorRect = $Boss/Flash

func _ready() -> void:
	command_text = "BOSS: %s!" % TaskManager.BOSS_NAME
	# Double a normal mash quest's goal (same difficulty formula) — double the work, same time.
	required = 2 * (18 + int(GameManager.difficulty * 6))
	super._ready()
	if _progress_label:
		_progress_label.text = "QUEST %d — BOSS FIGHT" % GameManager.quest_number
	_flash_prompt()

func on_task_start() -> void:
	hits = 0
	_stall_left = STALL_TIME
	_prompt_flip = 0.6
	_prompt = "mash"
	_flash_prompt()
	if hp_bar:
		hp_bar.max_value = required
		hp_bar.value = 0
	_update_hint()

func on_task_tick(_delta: float) -> void:
	if _finished:
		return
	# The boss keeps switching what it demands on its own.
	_prompt_flip -= _delta
	if _prompt_flip <= 0.0:
		_flash_prompt()
	# Boss counters if you stall.
	_stall_left -= _delta
	if _stall_left <= 0.0:
		fail()
		return
	_update_hint()

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	var press := ""
	if event.is_action_pressed("mash"):
		press = "mash"
	elif event.is_action_pressed("action"):
		press = "action"
	else:
		return
	get_viewport().set_input_as_handled()
	if press == _prompt:
		_land_hit()

func _land_hit() -> void:
	hits += gesture_performed(_prompt)
	_stall_left = STALL_TIME
	if hp_bar:
		hp_bar.value = hits
	# Boss reels & flashes white on each hit.
	if boss_body:
		boss_body.position.y = randf_range(4.0, 14.0)
		create_tween().tween_property(boss_body, "position:y", 0.0, 0.08)
	if flash:
		flash.visible = true
		flash.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(flash, "modulate:a", 0.85, 0.05)
		tw.tween_property(flash, "modulate:a", 0.0, 0.08)
		tw.tween_callback(func(): flash.visible = false)
	# Random chance the boss demands the other input right after a hit.
	if randf() < 0.5:
		_flash_prompt()
	if hits >= required:
		succeed()

func _flash_prompt() -> void:
	_prompt = "mash" if _prompt == "action" else "action"
	_prompt_flip = randf_range(0.5, 0.8)
	if prompt_label == null:
		return
	prompt_label.text = "MASH!  [F]" if _prompt == "mash" else "STOMP!  [SPACE]"
	prompt_label.modulate = Color("#ffd24a") if _prompt == "mash" else Color("#ff7a6a")
	prompt_label.scale = Vector2(1.35, 1.35)
	create_tween().tween_property(prompt_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK)

func _update_hint() -> void:
	if hint:
		hint.text = "Slay the boss with %d hits — DOUBLE the work in the SAME time!\nHit the %s now. Boss wind-up: %.1fs" % [
			required, "MASH! [F]" if _prompt == "mash" else "STOMP! [SPACE]", maxf(_stall_left, 0.0)
		]