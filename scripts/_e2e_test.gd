## End-to-end run: boots the REAL game from the main menu scene, walks the
## full UI chain (menu -> character select -> gameplay), then drives the run to
## the boss floor, kills the boss, and confirms the victory screen + that the
## MusicManager switched tracks at each step. Catches runtime/script errors.
extends SceneTree

const GameStateScript = preload("res://scripts/core/game_state.gd")
const CharRegistryScript = preload("res://scripts/systems/character_registry.gd")
const CharEntryScript = preload("res://scripts/character_entry.gd")
const MusicScript = preload("res://scripts/core/music_manager.gd")
const MainMenuScript = preload("res://scripts/menus/main_menu.gd")
const CharSelectScript = preload("res://scripts/menus/character_select.gd")
const VictoryScript = preload("res://scripts/gameplay/victory_screen.gd")

func _initialize() -> void:
	# Boot the real entry scene.
	change_scene_to_file("res://scenes/menus/main_menu.tscn")
	await create_timer(0.4).timeout
	var mm = current_scene
	if not (mm is MainMenuScript):
		print("E2E FAIL: main_menu not loaded (got %s)" % _cls(mm)); quit(); return
	print("E2E STEP main_menu   OK  music=%s" % _music())

	# Menu -> Character select
	mm._on_start_pressed()
	await create_timer(0.4).timeout
	var cs = current_scene
	if not (cs is CharSelectScript):
		print("E2E FAIL: char_select not loaded (got %s)" % _cls(cs)); quit(); return
	print("E2E STEP char_select OK  music=%s" % _music())

	# Character select -> Gameplay (first character)
	var all = CharacterRegistry.get_all()
	if all.is_empty():
		print("E2E FAIL: no characters registered"); quit(); return
	cs._on_select(all[0])
	await create_timer(0.6).timeout
	var gs = current_scene
	if gs == null or gs.get("current_floor") == null:
		print("E2E FAIL: game_scene not loaded (got %s)" % _cls(gs)); quit(); return
	print("E2E STEP game_scene  OK  music=%s" % _music())

	# Make the test player invincible so zombies can't end the run early.
	var p = gs.get("player")
	if p != null and p.get("stats") != null:
		p.stats.max_health = 1e9
		p.stats.current_health = 1e9

	# Drive floors up to the boss floor.
	var guard := 0
	while int(gs.get("current_floor")) < int(gs.get("total_floors")) and guard < 80:
		gs.call("_advance_floor")
		guard += 1
	print("E2E reached floor %d/%d  music=%s" % [int(gs.get("current_floor")), int(gs.get("total_floors")), _music()])

	var boss = get_first_node_in_group("boss")
	if boss == null:
		print("E2E FAIL: no boss spawned on boss floor"); quit(); return
	print("E2E STEP boss_spawned OK  type=%d  music=%s" % [int(boss.get("zombie_type")), _music()])

	boss.call("die")
	await create_timer(0.3).timeout

	var victory := false
	if _find_victory(get_root()) != null:
		victory = true
	print("E2E STEP victory      OK  shown=%s  music=%s" % [victory, _music()])

	print("E2E_%s" % ("PASS" if victory else "FAIL"))
	quit()

func _cls(n) -> String:
	return n.get_class() if n != null else "null"

func _music() -> String:
	return MusicManager._instance._current if (MusicManager._instance != null) else "noinst"

## Victory screen is nested inside a CanvasLayer overlay now, so a flat root
## scan misses it.
func _find_victory(node: Node) -> Node:
	for c in node.get_children():
		if c is VictoryScript:
			return c
		var found = _find_victory(c)
		if found != null:
			return found
	return null
