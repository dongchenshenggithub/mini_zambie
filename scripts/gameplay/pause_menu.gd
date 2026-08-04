## Pause overlay — shown when the player presses pause.
## process_mode is ALWAYS so its buttons keep working while the tree is paused.
class_name PauseMenu
extends Control

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(1280, 720)

	# Dim with a separate ColorRect behind the content (NOT a black `modulate`,
	# which would darken the buttons/text and make the menu look blank).
	var tex = PixelLoader.load_texture("res://assets/pixel/menu_bg.png")
	if tex != null:
		var bg := TextureRect.new()
		bg.name = "MenuBG"
		bg.texture = tex
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	move_child(dim, 1)

	var title = Label.new()
	title.text = "已暂停"
	title.horizontal_alignment = 1
	title.add_theme_font_size_override("font_size", 48)
	title.position = Vector2(0, 220)
	title.size = Vector2(1280, 60)
	add_child(title)

	var resume = Button.new()
	resume.text = "继续游戏"
	resume.position = Vector2(440, 360)
	resume.size = Vector2(200, 50)
	resume.pressed.connect(_on_resume)
	add_child(resume)

	var quit = Button.new()
	quit.text = "退出到主菜单"
	quit.position = Vector2(440, 430)
	quit.size = Vector2(200, 50)
	quit.pressed.connect(_on_quit)
	add_child(quit)

	# Allow un-pausing with the pause key/button too.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_resume()


func _on_resume() -> void:
	if get_tree():
		get_tree().paused = false
	queue_free()


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	queue_free()
