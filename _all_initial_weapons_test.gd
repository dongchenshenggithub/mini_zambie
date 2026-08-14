## Comprehensive check of every character's INITIAL WEAPON, run against the
## REAL game scene with `current_scene` properly set (so summon weapons like the
## cat-cafe drone can actually deploy instead of hitting a null add_child).
## For the cat-cafe worker we also verify the drone companion really spawns.
## Run: Godot ... -s res://_all_initial_weapons_test.gd
extends SceneTree

const GameSceneScript = preload("res://scenes/gameplay/game_scene.tscn")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const SummonUnitScript = preload("res://scripts/entities/summon/summon_unit.gd")

var _ids: Array[String] = ["veteran", "mech_monk", "cyber_cultivator", "cat_cafe_worker", "professor", "alien_shooter"]
var _idx := 0
var _scene = null
var _frames := 0
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
			return false
		Game.selected_character = CharacterRegistryScript.get_data(_ids[_idx])
		_scene = GameSceneScript.instantiate()
		root.add_child(_scene)
		current_scene = _scene  # <-- makes weapon_drone.add_child(_drone) valid
		_frames = 0
		return false
	_frames += 1
	if _frames < 45:
		return false
	_check()
	_scene.queue_free()
	_scene = null
	_idx += 1
	return false

func _count_summon_units(node: Node) -> int:
	var n := 0
	if node.get_script() == SummonUnitScript:
		n += 1
	for c in node.get_children():
		n += _count_summon_units(c)
	return n

func _check() -> void:
	var cid: String = _ids[_idx]
	var player = _scene.get_node_or_null("Player")
	var inv = player.get("inventory") if player else null
	var wcount = inv.weapons.size() if inv else -1
	var wname = "(none)"
	var wok := false
	if wcount >= 1 and inv.weapons[0] != null and not inv.weapons[0].weapon_name.is_empty():
		wname = inv.weapons[0].weapon_name
		wok = true
	var su := _count_summon_units(_scene)
	# For cat-cafe, base_followers=1, so a working drone means 2 summon units.
	var tag := ""
	if cid == "cat_cafe_worker":
		tag = " (drone_deployed=%s)" % ("YES" if su >= 2 else "NO")
	_results.append("char=%-16s weapon='%s' slots=%d ok=%s summon_units=%d%s" % [cid, wname, wcount, "Y" if wok else "N", su, tag])

func _report() -> void:
	print("=== ALL INITIAL WEAPONS (real scene, current_scene set) ===")
	var all_ok := true
	for line in _results:
		print(line)
		if "ok=N" in line:
			all_ok = false
		if "drone_deployed=NO" in line:
			all_ok = false
	print("ALL_INITIAL_WEAPONS %s" % ("PASS" if all_ok else "FAIL"))
	quit()
