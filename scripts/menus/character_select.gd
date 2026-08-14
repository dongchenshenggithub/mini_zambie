## Character selection screen — 2-row × 3-col grid of avatar cards.
## Each card shows a pixel-art portrait, the character's name, and a short
## trait description. Clicking a card selects that character and starts the
## game. Returns to the main menu via the back button.
class_name CharacterSelect
extends Control

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

@onready var title_label: Label = $Center/Title
@onready var grid: GridContainer = $Center/Grid
@onready var back_btn: Button = $Center/BackButton

var selected_character: CharacterEntry = null


func _ready() -> void:
	CharacterRegistry.init()
	MusicManager.play("menu")
	_add_bg()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 20)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	_build_cards()


func _build_cards() -> void:
	for char_entry in CharacterRegistry.get_all():
		var card := Button.new()
		card.text = ""
		card.custom_minimum_size = Vector2(300, 240)
		card.focus_mode = Control.FOCUS_NONE
		_apply_card_style(card)

		var vbox := VBoxContainer.new()
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)

		var avatar := TextureRect.new()
		avatar.texture = PixelLoader.load_texture(
			"res://assets/pixel/portrait_%s.png" % char_entry.id)
		avatar.custom_minimum_size = Vector2(128, 128)
		avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(avatar)

		var name_label := Label.new()
		name_label.text = char_entry.name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(name_label)

		var trait_label := Label.new()
		trait_label.text = char_entry.description
		trait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		trait_label.custom_minimum_size = Vector2(0, 64)
		trait_label.add_theme_font_size_override("font_size", 13)
		trait_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(trait_label)

		card.pressed.connect(_on_select.bind(char_entry))
		grid.add_child(card)


func _on_select(char_entry: CharacterEntry) -> void:
	selected_character = char_entry
	_start_game(char_entry)


func _apply_card_style(card: Button) -> void:
	card.add_theme_stylebox_override("normal", _make_stylebox(
		Color(0.10, 0.09, 0.15, 0.90), Color(0.47, 0.43, 0.67, 1.0)))
	card.add_theme_stylebox_override("hover", _make_stylebox(
		Color(0.19, 0.16, 0.28, 0.95), Color(0.63, 0.55, 0.86, 1.0)))
	card.add_theme_stylebox_override("pressed", _make_stylebox(
		Color(0.24, 0.20, 0.43, 0.95), Color(0.78, 0.67, 1.0, 1.0)))
	card.add_theme_stylebox_override("focus", _make_stylebox(
		Color(0.10, 0.09, 0.15, 0.90), Color(0.47, 0.43, 0.67, 1.0)))


func _make_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


## Pixel-art city backdrop behind the screen.
func _add_bg() -> void:
	var tex = PixelLoader.load_texture("res://assets/pixel/menu_bg.png")
	if tex == null:
		return
	var bg := TextureRect.new()
	bg.name = "MenuBG"
	bg.texture = tex
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)


func _start_game(cd: CharacterEntry) -> void:
	Game.selected_character = cd
	Game.player_build_direction = cd.build_direction
	get_tree().change_scene_to_file("res://scenes/gameplay/game_scene.tscn")