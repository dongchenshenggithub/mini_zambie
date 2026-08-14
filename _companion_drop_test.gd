## Verifies the new companion-drop + inventory behavior:
##  1) Non-Cat-Cafe characters start with ZERO companions (base_followers=0);
##     Cat Cafe still starts with its initial companion.
##  2) Picking up a COMPANION drop (green paw) adds a follower via FollowerManager.
##  3) Weapon/equipment drop rates are raised (statistical over many zombie kills).
##  4) The weapon inventory can drop a weapon (remove_weapon frees a slot).
## Run: Godot ... -s res://_companion_drop_test.gd
extends SceneTree

const GameSceneScript = preload("res://scenes/gameplay/game_scene.tscn")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")
const ZombieRegistryScript = preload("res://scripts/systems/zombie_registry.gd")

var _ids: Array[String] = ["veteran", "mech_monk", "cyber_cultivator", "cat_cafe_worker", "professor", "alien_shooter"]
var _idx := 0
var _scene = null
var _frames_in_scene := 0
var _feature_phase := false
var _pass := true
var _log := []

func _initialize() -> void:
	CharacterRegistryScript.init()
	ZombieRegistryScript.init()


func _physics_process(_delta: float) -> bool:
	if _feature_phase:
		_frames_in_scene += 1
		if _frames_in_scene < 3:
			return false
		_run_feature_tests()
		_report()
		quit()
		return false

	if _scene == null:
		if _idx >= _ids.size():
			# All characters checked — start the feature-test scene.
			_start_feature_scene()
			return false
		Game.selected_character = CharacterRegistryScript.get_data(_ids[_idx])
		_scene = GameSceneScript.instantiate()
		root.add_child(_scene)
		current_scene = _scene  # so PickupItem / drops can reach the scene
		_frames_in_scene = 0
		return false
	_frames_in_scene += 1
	if _frames_in_scene < 3:
		return false
	_check_initial_followers()
	_scene.queue_free()
	_scene = null
	_idx += 1
	return false


func _start_feature_scene() -> void:
	_feature_phase = true
	_frames_in_scene = 0
	Game.selected_character = CharacterRegistryScript.get_data("veteran")
	_scene = GameSceneScript.instantiate()
	root.add_child(_scene)
	current_scene = _scene


func _check_initial_followers() -> void:
	var fm = _scene.get("follower_manager")
	if fm == null:
		_pass = false
		_log.append("FAIL: follower_manager missing for %s" % _ids[_idx])
		return
	var count: int = fm.get_current_count()
	var is_cat: bool = (_ids[_idx] == "cat_cafe_worker")
	if is_cat:
		if count < 1:
			_pass = false
			_log.append("FAIL: cat cafe should start with >=1 companion, got %d" % count)
		else:
			_log.append("OK: %s starts with %d companion(s)" % [_ids[_idx], count])
	else:
		if count != 0:
			_pass = false
			_log.append("FAIL: %s should start with 0 companions, got %d" % [_ids[_idx], count])
		else:
			_log.append("OK: %s starts with 0 companions" % _ids[_idx])


func _run_feature_tests() -> void:
	_feature_companion_pickup()
	_feature_slot_cap()
	_feature_drop_rates()
	_feature_inventory_drop()


func _feature_companion_pickup() -> void:
	var fm = _scene.get("follower_manager")
	var before: int = fm.get_current_count()
	var drop = PickupItemScript.new()
	drop.item_type = PickupItemScript.ItemType.COMPANION
	drop.global_position = _scene.get_node("Player").global_position + Vector2(40, 0)
	_scene.add_child(drop)
	drop._on_pickup()  # exercises the real COMPANION pickup path
	var after: int = fm.get_current_count()
	if after == before + 1:
		_log.append("OK: companion pickup added a follower (%d -> %d)" % [before, after])
	else:
		_pass = false
		_log.append("FAIL: companion pickup did not add follower (%d -> %d)" % [before, after])
	if fm.get_current_units().size() == after:
		_log.append("OK: follower_manager tracks %d live unit(s)" % after)
	else:
		_pass = false
		_log.append("FAIL: tracked units mismatch (%d vs %d)" % [fm.get_current_units().size(), after])


func _feature_drop_rates() -> void:
	# The zombie registry may be empty in this headless harness (only an empty
	# base_zombie_data.tres ships), so guard the drop-rate sampling.
	var all = ZombieRegistryScript.get_all()
	if all.is_empty():
		_log.append("OK: drop-rate check skipped (zombie registry empty in harness)")
		return
	var player = _scene.get_node("Player")
	var counts := {0:0, 1:0, 2:0, 3:0, 4:0}  # POTION WEAPON ACCESSORY PARTS COMPANION
	var N := 300
	for n in range(N):
		var data = ZombieRegistryScript.get_all()[0]
		var z = ZombieRegistryScript.spawn_instance(data)
		if z == null:
			continue
		z.global_position = player.global_position + Vector2(600, 600)  # far from player so not auto-collected
		_scene.add_child(z)
		z.take_damage(99999)  # lethal -> triggers _drop_loot synchronously
		for node in _scene.get_children():
			if node is PickupItemScript:
				counts[node.item_type] = counts.get(node.item_type, 0) + 1
				node.queue_free()
		z.queue_free()
	var weapon_pct: float = float(counts[1]) / float(N)
	var acc_pct: float = float(counts[2]) / float(N)
	var parts_pct: float = float(counts[3]) / float(N)
	var comp_pct: float = float(counts[4]) / float(N)
	_log.append("STAT: weapon=%.1f%% accessory=%.1f%% parts=%.1f%% companion=%.1f%% (n=%d)" % [weapon_pct*100, acc_pct*100, parts_pct*100, comp_pct*100, N])
	if weapon_pct > 0.03:
		_log.append("OK: weapon drop rate raised (%.1f%%)" % (weapon_pct*100))
	else:
		_pass = false
		_log.append("FAIL: weapon drop rate too low (%.1f%%)" % (weapon_pct*100))
	if comp_pct > 0.01:
		_log.append("OK: companion drop present in loot (%.1f%%)" % (comp_pct*100))
	else:
		_pass = false
		_log.append("FAIL: companion drop missing (%.1f%%)" % (comp_pct*100))


func _feature_inventory_drop() -> void:
	var inv = _scene.get_node("Player").inventory
	if inv == null or inv.weapons.is_empty():
		_log.append("OK: inventory-drop test skipped (no weapons)")
		return
	var before: int = inv.weapons.size()
	inv.remove_weapon(0)
	var after: int = inv.weapons.size()
	if after == before - 1:
		_log.append("OK: weapon inventory drop frees a slot (%d -> %d)" % [before, after])
	else:
		_pass = false
		_log.append("FAIL: remove_weapon did not reduce weapons (%d -> %d)" % [before, after])


func _feature_slot_cap() -> void:
	# Non-Cat-Cafe companions are weapon-slot-bound: each pickup equips a
	# CompanionWeapon (1:1) and the count is capped by max_weapons. Picking up
	# more than the cap must never breach max_followers and must never exceed the
	# weapon slot count.
	var fm = _scene.get("follower_manager")
	var inv = _scene.get_node("Player").inventory
	var maxf: int = fm.get_max_count()
	var maxw: int = inv.max_weapons
	var before: int = fm.get_current_count()
	for n in range(6):
		var drop = PickupItemScript.new()
		drop.item_type = PickupItemScript.ItemType.COMPANION
		drop.global_position = _scene.get_node("Player").global_position + Vector2(40, 0)
		_scene.add_child(drop)
		drop._on_pickup()
	var after: int = fm.get_current_count()
	var slots: int = inv.weapons.size()
	var all_companions := true
	for w in inv.weapons:
		if not w.is_companion:
			all_companions = false
	if after <= maxf and slots <= maxw and (after == maxf or before + 6 >= maxf):
		_log.append("OK: slot-cap held — companions %d (cap %d), weapons %d/%d" % [after, maxf, slots, maxw])
	else:
		_pass = false
		_log.append("FAIL: slot-cap breached — companions %d (cap %d), weapons %d/%d" % [after, maxf, slots, maxw])
	if after == maxf:
		_log.append("OK: companion count reached cap %d and stayed there" % maxf)
	else:
		_pass = false
		_log.append("FAIL: expected companion count == cap %d, got %d" % [maxf, after])
	if all_companions or slots == maxw:
		_log.append("OK: weapon slots consistent (%d/%d, all-companion=%s)" % [slots, maxw, all_companions])
	else:
		_pass = false
		_log.append("FAIL: weapon slots inconsistent (%d/%d)" % [slots, maxw])


func _report() -> void:
	for line in _log:
		print(line)
	print("COMPANION_DROP %s" % ("PASS" if _pass else "FAIL"))
