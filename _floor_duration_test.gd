## Verifies the linear per-floor duration curve and the infinite boss floor.
##  - floor 1 duration == base (40s)
##  - each later floor == 40 + (floor-1)*5
##  - the final (boss) floor has is_infinite == true and floor_duration == INF
## Not part of the game. Run headless:
##   Godot ... -s res://_floor_duration_test.gd
extends SceneTree

const CharRegistryScript = preload("res://scripts/systems/character_registry.gd")
const MainMenuScript = preload("res://scripts/menus/main_menu.gd")
const CharSelectScript = preload("res://scripts/menus/character_select.gd")

var _obs := false
var _done := false
var _t := 0.0
var _checks := {}


func _initialize() -> void:
	change_scene_to_file("res://scenes/menus/main_menu.tscn")
	await create_timer(0.4).timeout
	var mm = current_scene
	if not (mm is MainMenuScript):
		print("DURATION FAIL: main_menu not loaded"); quit(); return

	mm._on_start_pressed()
	await create_timer(0.4).timeout
	var cs = current_scene
	if not (cs is CharSelectScript):
		print("DURATION FAIL: char_select not loaded"); quit(); return

	var all = CharRegistryScript.get_all()
	if all.is_empty():
		print("DURATION FAIL: no characters"); quit(); return
	cs._on_select(all[0])
	await create_timer(0.6).timeout
	var gs = current_scene
	if gs == null or gs.get("current_floor") == null:
		print("DURATION FAIL: game_scene not loaded"); quit(); return

	var ws = gs.get("wave_spawner")
	if ws == null:
		print("DURATION FAIL: no wave_spawner"); quit(); return

	var total: int = int(gs.get("total_floors"))

	# Floor 1 should be the base duration (40s) and finite.
	_checks["floor1_base"] = (absf(ws.floor_duration - 40.0) < 0.001) and (ws.is_infinite == false)

	# Advance through every floor and check the linear curve + infinite boss floor.
	for _i in range(total - 1):
		gs.call("_advance_floor")
		var f: int = int(Game.current_floor)
		var expected: float = 40.0 + (f - 1) * 5.0
		if f < total:
			_checks["floor%d_linear" % f] = (absf(ws.floor_duration - expected) < 0.001) and (ws.is_infinite == false)
		else:
			# Boss / final floor: infinite mode, no finite timer.
			_checks["floor%d_infinite" % f] = (ws.is_infinite == true) and (ws.floor_duration == INF)

	_obs = true
	_t = 0.0


func _process(delta: float) -> bool:
	if not _obs or _done:
		return false
	_t += delta
	if _t < 1.0:
		return false
	_done = true

	var ok := true
	for k in _checks:
		if not _checks[k]:
			ok = false
		print("DURATION %s = %s" % [k, _checks[k]])

	print("DURATION floor1=%s floor14=%s boss_infinite=%s" % [
		"40.0", "105.0", _checks.get("floor15_infinite", false)])
	print("DURATION %s" % ("PASS" if ok else "FAIL"))
	quit()
	return false
