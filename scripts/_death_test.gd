extends SceneTree
const MainMenuScript = preload("res://scripts/menus/main_menu.gd")
const CharSelectScript = preload("res://scripts/menus/character_select.gd")
const DeathScript = preload("res://scripts/gameplay/death_screen.gd")
const CharRegistryScript = preload("res://scripts/systems/character_registry.gd")

## Verifies the real death chain AND that the death screen is actually visible
## (root not modColor(0,0,0,..) blacked out, stats text present, overlay + buttons exist).
func _initialize() -> void:
	change_scene_to_file("res://scenes/menus/main_menu.tscn")
	await create_timer(0.4).timeout
	current_scene._on_start_pressed()
	await create_timer(0.4).timeout
	var cs = current_scene
	var all = CharacterRegistry.get_all()
	cs._on_select(all[0])
	await create_timer(0.6).timeout
	var gs = current_scene
	if gs == null:
		print("DEATH FAIL: no game scene"); quit(); return

	# Simulate a played run: 7 floors, 42 kills, score 1234.
	Game.score = 1234
	Game.kills = 42
	Game.current_floor = 7

	var p = gs.get("player")
	p.take_damage(999999.0)
	await create_timer(0.4).timeout

	var ds = _find_death(get_root())
	if ds == null:
		print("DEATH FAIL: death screen not found under root"); quit(); return
	var sl = ds._stats_label if ds != null else null
	var ch = ds._char_label if ds != null else null

	# Visual sanity: root must NOT be modulated to black, stats text filled.
	var mod_ok = (ds != null and ds.modulate == Color(1, 1, 1, 1))
	var stats_ok = (sl != null and "最终得分" in sl.text and "到达楼层" in sl.text)
	var has_overlay = (ds != null and ds._overlay != null)
	var has_restart = (ds != null and ds._restart_btn != null and ds._restart_btn.text == "重新开始")
	var has_quit = (ds != null and ds._quit_btn != null and ds._quit_btn.text == "返回主菜单")

	print("DEATH screen_present=%s paused=%s" % [ds != null, paused])
	print("DEATH root_not_dimmed=%s has_overlay=%s" % [mod_ok, has_overlay])
	print("DEATH CharLabel=%s" % (ch.text if ch != null else "none"))
	print("DEATH StatsLabel=%s" % (sl.text if sl != null else "none"))
	print("DEATH buttons: restart=%s quit=%s" % [has_restart, has_quit])
	var ok = (ds != null and paused and mod_ok and stats_ok and has_overlay and has_restart and has_quit)
	print("DEATH_TEST %s" % ("PASS" if ok else "FAIL"))

	# Verify the return-to-menu button actually navigates back.
	if ds != null:
		ds._on_quit()
		await create_timer(0.5).timeout
		var cur = current_scene
		var back = (cur != null and cur is MainMenuScript)
		print("DEATH back_to_menu=%s unpaused=%s" % [back, not paused])
	quit()

## Recursively find the death screen (it is now nested inside a CanvasLayer
## overlay, so a flat root scan misses it).
func _find_death(node: Node) -> Node:
	for c in node.get_children():
		if c is DeathScript:
			return c
		var found = _find_death(c)
		if found != null:
			return found
	return null
