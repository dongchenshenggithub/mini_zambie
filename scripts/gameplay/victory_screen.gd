## Victory screen shown after the final boss is defeated.
class_name VictoryScreen
extends Control

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

var _score_label: Label = null
var _overlay: ColorRect = null
var _restart_btn: Button = null
var _quit_btn: Button = null


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Anchors only; the real size is set in _ready (see death_screen for why).
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Optional pixel-art backdrop, dimmed on its own (NOT via root modulate,
	# which would black out every child including the text/buttons).
	var tex = PixelLoader.load_texture("res://assets/pixel/menu_bg.png")
	if tex != null:
		var bg := TextureRect.new()
		bg.texture = tex
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.modulate = Color(1, 1, 1, 0.25)
		add_child(bg)

	# Dark overlay as a SEPARATE child (keeps text/buttons fully visible).
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_overlay = overlay

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)

	var title := Label.new()
	title.text = "通关胜利！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	vbox.add_child(title)

	var score_label := Label.new()
	score_label.name = "ScoreLabel"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(score_label)
	_score_label = score_label

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(hbox)

	var restart := Button.new()
	restart.text = "再玩一次"
	restart.custom_minimum_size = Vector2(220, 54)
	restart.pressed.connect(_on_restart)
	hbox.add_child(restart)
	_restart_btn = restart

	var quit := Button.new()
	quit.text = "返回主菜单"
	quit.custom_minimum_size = Vector2(220, 54)
	quit.pressed.connect(_on_quit)
	hbox.add_child(quit)
	_quit_btn = quit


func _ready() -> void:
	size = get_viewport_rect().size


func _on_restart() -> void:
	get_tree().reload_current_scene()
	queue_free()


func _on_quit() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	queue_free()


func set_score(score: int, floor_reached: int) -> void:
	if _score_label != null:
		_score_label.text = "得分: %d    到达楼层: %d" % [score, floor_reached]
