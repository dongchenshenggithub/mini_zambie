## Death screen with a full run summary: score, floor reached, kills, and
## survival time, plus buttons to restart or return to the main menu.
## process_mode is ALWAYS so its buttons keep working while the tree is paused.
class_name DeathScreen
extends Control

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

var _score: int = 0
var _floor: int = 1
var _kills: int = 0
var _survived_ms: int = 0
var _character_name: String = ""
var _char_label: Label = null
var _stats_label: Label = null
var _overlay: ColorRect = null
var _restart_btn: Button = null
var _quit_btn: Button = null


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Stretch anchors to the full rect. The actual size is applied in _ready,
	# because this screen is added directly under the root Viewport (a Window,
	# not a Control) — so PRESET_FULL_RECT has no parent Control to measure
	# against and would otherwise leave the size at (0,0), rendering nothing.
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
	overlay.color = Color(0, 0, 0, 0.78)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_overlay = overlay

	# Centered content column.
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	var title := Label.new()
	title.text = "你死了"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	vbox.add_child(title)

	var name_label := Label.new()
	name_label.name = "CharLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 26)
	vbox.add_child(name_label)
	_char_label = name_label

	var stats_label := Label.new()
	stats_label.name = "StatsLabel"
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 30)
	vbox.add_child(stats_label)
	_stats_label = stats_label

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(hbox)

	var restart := Button.new()
	restart.text = "重新开始"
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
	# Force full-viewport size (see _init note). Children use full-rect
	# anchors, so they expand to fill once the parent has a real size.
	size = get_viewport_rect().size


## Build a death screen pre-populated with the run summary.
static func create(score: int, floor_reached: int, kills: int, survived_ms: int, character_name: String) -> DeathScreen:
	var ds = DeathScreen.new()
	ds._score = score
	ds._floor = floor_reached
	ds._kills = kills
	ds._survived_ms = survived_ms
	ds._character_name = character_name
	ds._refresh()
	return ds


func _refresh() -> void:
	if _char_label != null and _character_name != "":
		_char_label.text = "角色: %s" % _character_name
	if _stats_label != null:
		var total_secs = int(_survived_ms / 1000.0)
		var mm = int(total_secs / 60)
		var ss = total_secs % 60
		_stats_label.text = "最终得分: %d\n到达楼层: %d / 15\n击杀丧尸: %d\n存活时间: %02d:%02d" % [_score, _floor, _kills, mm, ss]


func _on_restart() -> void:
	if get_tree():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/character_select.tscn")
	queue_free()


func _on_quit() -> void:
	if get_tree():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
		queue_free()
