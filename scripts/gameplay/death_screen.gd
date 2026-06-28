## Shows death screen with restart/quit buttons.
class_name DeathScreen
extends Control


func _init() -> void:
	size = Vector2(1280, 720)
	modulate = Color(0, 0, 0, 0.7)  # Dark overlay

	# Title label
	var title = Label.new()
	title.text = "你死了"
	title.horizontal_alignment = 1
	title.add_theme_font_size_override("font_size", 48)
	title.position = Vector2(0, 200)
	title.size = Vector2(1280, 60)
	add_child(title)

	# Score label
	var score_label = Label.new()
	score_label.text = "得分: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.position = Vector2(0, 280)
	score_label.size = Vector2(1280, 40)
	score_label.name = "ScoreLabel"
	add_child(score_label)

	# Restart button
	var restart = Button.new()
	restart.text = "重新开始"
	restart.position = Vector2(440, 400)
	restart.size = Vector2(200, 50)
	restart.pressed.connect(_on_restart)
	add_child(restart)

	# Quit button
	var quit = Button.new()
	quit.text = "退出游戏"
	quit.position = Vector2(440, 470)
	quit.size = Vector2(200, 50)
	quit.pressed.connect(_on_quit)
	add_child(quit)


func _on_restart() -> void:
	get_tree().reload_current_scene()


func _on_quit() -> void:
	get_tree().quit()


func set_score(score: int) -> void:
	var sl = get_node_or_null("ScoreLabel")
	if sl is Label:
		sl.text = "得分: %d" % score
