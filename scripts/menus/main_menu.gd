## Main menu screen.
class_name MainMenu
extends Control

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	_add_bg()
	MusicManager.play("menu")
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


## Pixel-art city backdrop behind the menu.
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


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/character_select.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
