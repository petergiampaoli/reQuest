extends HBoxContainer
## HeartsDisplay — shows 3 hearts (supports extra lives via extra_life upgrades)
## Listens to GameManager.lives_changed. Used by TaskBase, but can be dropped anywhere.

const HEART_FULL := "♥"
const HEART_EMPTY := "♡"

var heart_labels: Array[Label] = []

func _ready() -> void:
	# Build initial 3 hearts if not already built in scene
	if get_child_count() == 0:
		for i in 3:
			var l := _make_heart_label()
			add_child(l)
			heart_labels.append(l)
	else:
		for c in get_children():
			if c is Label:
				heart_labels.append(c)

	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)

	_update_hearts(GameManager.lives)
	GameManager.lives_changed.connect(_update_hearts)

func _make_heart_label() -> Label:
	var l := Label.new()
	l.text = HEART_FULL
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 36)
	l.add_theme_color_override("font_color", Color("#ff4a4a"))
	l.add_theme_color_override("font_outline_color", Color("#1a1208"))
	l.add_theme_constant_override("outline_size", 6)
	return l

# Called via signal, int param
func _update_hearts(new_lives: int) -> void:
	# Ensure we have enough labels for extra lives (up to 6)
	while heart_labels.size() < new_lives:
		var l := _make_heart_label()
		add_child(l)
		heart_labels.append(l)
	# If lives shrank due to fail, animate the lost heart
	var prev_visible := 0
	for lbl in heart_labels:
		if lbl.visible and lbl.modulate.a > 0.5:
			prev_visible += 1
	# Toggle visibility
	for i in heart_labels.size():
		var filled: bool = i < new_lives
		var lbl: Label = heart_labels[i]
		lbl.visible = true
		if filled:
			lbl.text = HEART_FULL
			lbl.modulate = Color("#ff4a4a")
			lbl.scale = Vector2.ONE
		else:
			# If this heart just got emptied, pop then fade
			if lbl.text == HEART_FULL:
				_animate_loss(lbl)
			else:
				lbl.text = HEART_EMPTY
				lbl.modulate = Color("#5a3a3a")
	# Hide extra beyond max 6 if needed — keep but dim
	for i in range(new_lives, heart_labels.size()):
		if heart_labels[i].text == HEART_FULL:
			pass # already animated
		else:
			heart_labels[i].modulate = Color("#3a2a2a")

func _animate_loss(lbl: Label) -> void:
	# Pop + fade to empty
	var tw := create_tween()
	tw.tween_property(lbl, "scale", Vector2(1.4, 1.4), 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(lbl, "scale", Vector2(0.6, 0.6), 0.14)
	tw.tween_callback(func():
		lbl.text = HEART_EMPTY
		lbl.modulate = Color("#5a3a3a")
		lbl.scale = Vector2.ONE
		var tw2 := create_tween()
		tw2.tween_property(lbl, "scale", Vector2(1.08, 1.08), 0.10)
		tw2.tween_property(lbl, "scale", Vector2.ONE, 0.10)
	)
