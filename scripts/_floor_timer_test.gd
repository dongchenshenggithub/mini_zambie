## Regression for survive-mode floors (timer-based clear, infinite spawning).
## Boots the real game, makes the player invincible, and switches the floor to a
## short timer (6s) with NO kill requirement. The player never fires, so zombies
## are never cleared by the player. If the floor still advances, it proves the
## new timer-based clear (not the old "clear all zombies" rule), and that waves
## spawn continuously past the old 3-wave/floor cap.
## Not part of the game.
extends SceneTree

const CharRegistryScript = preload("res://scripts/systems/character_registry.gd")
const MainMenuScript = preload("res://scripts/menus/main_menu.gd")
const CharSelectScript = preload("res://scripts/menus/character_select.gd")

var _obs := false
var _done := false
var _t := 0.0
var _start_floor := 1


func _initialize() -> void:
	change_scene_to_file("res://scenes/menus/main_menu.tscn")
	await create_timer(0.4).timeout
	var mm = current_scene
	if not (mm is MainMenuScript):
		print("FLOOR_TIMER FAIL: main_menu not loaded"); quit(); return

	mm._on_start_pressed()
	await create_timer(0.4).timeout
	var cs = current_scene
	if not (cs is CharSelectScript):
		print("FLOOR_TIMER FAIL: char_select not loaded"); quit(); return

	var all = CharRegistryScript.get_all()
	if all.is_empty():
		print("FLOOR_TIMER FAIL: no characters"); quit(); return
	cs._on_select(all[0])
	await create_timer(0.6).timeout
	var gs = current_scene
	if gs == null or gs.get("current_floor") == null:
		print("FLOOR_TIMER FAIL: game_scene not loaded"); quit(); return

	var p = gs.get("player")
	if p != null and p.get("stats") != null:
		p.stats.max_health = 1e9
		p.stats.current_health = 1e9

	# Switch to survive-mode: a 6s timer, no kill requirement.
	var ws = gs.get("wave_spawner")
	if ws == null:
		print("FLOOR_TIMER FAIL: no wave_spawner"); quit(); return
	ws.floor_duration = 6.0

	_start_floor = int(gs.get("current_floor"))
	print("FLOOR_TIMER start_floor=%d" % _start_floor)

	_obs = true
	_t = 0.0


func _process(delta: float) -> bool:
	if not _obs or _done:
		return false
	_t += delta
	if _t < 11.0:
		return false

	_done = true
	var gs = current_scene
	var end_floor = int(gs.get("current_floor")) if gs != null else -1
	var waves = int(Game.current_wave)
	var p = gs.get("player") if gs != null else null
	var player_alive = is_instance_valid(p) and p.stats.current_health > 0

	# The player never fired, so under the OLD logic (clear all zombies) the
	# floor would never advance. Advancing proves the timer-based clear.
	var advanced = end_floor > _start_floor
	# Old logic capped spawning at 3 waves/floor; survive-mode must exceed it.
	var continuous = waves > 3
	var ok = advanced and continuous and player_alive
	print("FLOOR_TIMER end_floor=%d waves=%d player_alive=%s" % [end_floor, waves, player_alive])
	print("FLOOR_TIMER advanced=%s continuous=%s" % [advanced, continuous])
	print("FLOOR_TIMER %s" % ("PASS" if ok else "FAIL"))
	quit()
	return false
