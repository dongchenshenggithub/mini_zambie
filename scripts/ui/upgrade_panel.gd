## In-game level-up upgrade panel.
## Built entirely in code (no .tscn) and instantiated at runtime, mirroring the
## death_screen pattern. Pauses the tree while open; the panel itself runs with
## PROCESS_MODE_ALWAYS so it stays interactive while everything else is frozen.
extends CanvasLayer
class_name UpgradePanel

signal option_chosen(upgrade_data: Dictionary)

const UpgradeOptionCardScene = preload("res://scripts/ui/upgrade_option_card.gd")

var _options: Array[Dictionary] = []


func show_options(options: Array[Dictionary]) -> void:
	_options = options
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100  # render above the HUD

	# Dim background that also swallows clicks meant for the game underneath.
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(760, 460)
	# Animate the panel in so it doesn't snap into view after the banner.
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	panel.scale = Vector2(0.9, 0.9)
	center.add_child(panel)
	var panel_tw := create_tween()
	panel_tw.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.22)
	panel_tw.parallel().tween_property(panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "升级！选择一项强化"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "点击卡片应用强化"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	vbox.add_child(hint)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	vbox.add_child(grid)

	for opt in _options:
		var card: UpgradeOptionCard = UpgradeOptionCardScene.new()
		card.setup(opt)
		card.custom_minimum_size = Vector2(220, 96)
		card.add_theme_font_size_override("font_size", 18)
		card.pressed.connect(_on_card_pressed.bind(card))
		grid.add_child(card)

	get_tree().paused = true


func _on_card_pressed(card: UpgradeOptionCard) -> void:
	get_tree().paused = false
	option_chosen.emit(card.upgrade_data)
	queue_free()
