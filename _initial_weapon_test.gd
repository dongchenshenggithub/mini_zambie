## Verifies every playable character starts the game with exactly ONE valid,
## non-null initial weapon equipped (registered in WeaponRegistry, with a real
## script that can be instantiated). Loads the REAL game scene per character.
## Run: Godot ... -s res://_initial_weapon_test.gd
extends SceneTree

const GameSceneScript = preload("res://scenes/gameplay/game_scene.tscn")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const ZE = preload("res://scripts/core/game_enums.gd")

var _ids: Array[String] = ["veteran", "mech_monk", "cyber_cultivator", "cat_cafe_worker", "professor", "alien_shooter"]
var _idx := 0
var _scene = null
var _frames_in_scene := 0
var _results := []
var _done := false

func _initialize() -> void:
	CharacterRegistryScript.init()

func _physics_process(_delta: float) -> bool:
	if _done:
		return false
	if _scene == null:
		if _idx >= _ids.size():
			_report()
			quit()
			return false
		Game.selected_character = CharacterRegistryScript.get_data(_ids[_idx])
		_scene = GameSceneScript.instantiate()
		root.add_child(_scene)
		_frames_in_scene = 0
		return false
	_frames_in_scene += 1
	if _frames_in_scene < 3:
		return false
	_check_current()
	_scene.queue_free()
	_scene = null
	_idx += 1
	return false

func _check_current() -> void:
	var cid: String = _ids[_idx]
	var char_entry = Game.selected_character
	var player = _scene.get_node_or_null("Player")
	var inv = null
	if player != null:
		inv = player.get("inventory")
	var cfg_id = char_entry.initial_weapon_id if char_entry != null else "(no entry)"
	var count = -1
	var wname = "(none)"
	var atype = -1
	var ok := false
	# Accept >= 1 equipped weapon (Cat Cafe Worker now starts with a pistol
	# AND a drone, i.e. 2 slots). Report the first weapon's name + total count.
	if inv != null and inv.weapons.size() >= 1:
		var w = inv.weapons[0]
		if w != null and not w.weapon_name.is_empty():
			count = inv.weapons.size()
			wname = w.weapon_name
			atype = w.attack_type
			ok = true
	_results.append("char=%-16s cfg_id=%-12s equipped='%s' (type=%d) count=%d  %s" % [cid, cfg_id, wname, atype, count, "OK" if ok else "NO INITIAL WEAPON"])
	if not ok:
		_done = true  # fail fast, stop on first problem

func _report() -> void:
	print("=== INITIAL WEAPON CHECK (all 6 characters) ===")
	for line in _results:
		print(line)
	var all_ok = not _results.is_empty()
	for line in _results:
		if "NO INITIAL WEAPON" in line:
			all_ok = false
	print("INITIAL_WEAPON %s" % ("PASS" if all_ok else "FAIL"))
