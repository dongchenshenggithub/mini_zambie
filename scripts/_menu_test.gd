## Headless menu/UI smoke test (Phase 6 art wiring).
## Instantiates the menu, character-select, and death screens to confirm the
## new pixel-bg / portrait / card-frame code paths run without SCRIPT ERRORs.
extends SceneTree

func _initialize() -> void:
	var mm = preload("res://scenes/menus/main_menu.tscn").instantiate()
	root.add_child(mm)
	print("MAIN_MENU_OK")

	var cs = preload("res://scenes/menus/character_select.tscn").instantiate()
	root.add_child(cs)
	print("CHAR_SELECT_OK")

	var ds = preload("res://scripts/gameplay/death_screen.gd").create(999, 1, 5, 30000, "测试角色")
	root.add_child(ds)
	print("DEATH_OK")

	var t = Timer.new()
	t.wait_time = 0.5
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(func():
		print("MENU_DONE")
		quit()
	)
	root.add_child(t)
