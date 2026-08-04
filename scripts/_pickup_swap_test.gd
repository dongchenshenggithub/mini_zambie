## Verifies that picking up weapons through the REAL PickupItem path equips
## them, and that a 3rd pickup SWAPS the 2nd slot instead of being ignored
## (the old "武器栏已满" dead-end the user complained about).
extends SceneTree

const GameScript = preload("res://scripts/core/game_state.gd")
const CharEntry = preload("res://scripts/character_entry.gd")
const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")
const WeaponRegistry = preload("res://scripts/systems/weapon_registry.gd")

var _phase := 0
var _t := 0.0
var _player = null
var _pickups := 0
var _seen := []


func _initialize() -> void:
	var cd = CharEntry.new()
	cd.character_class = 0
	cd.initial_weapon_id = "rifle"
	cd.starting_health = 200.0; cd.starting_speed = 200.0
	GameScript.start_game(cd)
	var scene = preload("res://scenes/gameplay/game_scene.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene


func _process(delta: float) -> bool:
	var player = get_first_node_in_group("player")
	if player == null:
		return false
	_player = player

	if _phase == 0:
		_t += delta
		if _t < 0.6:
			return false
		var n0: int = player.inventory.weapons.size()
		print("SWAP start_weapons=%d registry_size=%d" % [n0, WeaponRegistry.get_all().size()])
		if n0 < 1:
			print("SWAP no initial weapon -> FAIL"); quit(); return false
		_phase = 1
		_t = 0.0
		return false

	if _phase == 1:
		# Drop a weapon pickup on the player and collect it.
		var drop = PickupItemScript.new()
		drop.item_type = PickupItemScript.ItemType.WEAPON
		current_scene.add_child(drop)
		drop.global_position = player.global_position
		drop._on_pickup()
		_pickups += 1
		var names := ""
		for w in player.inventory.weapons:
			names += w.weapon_name + ","
		_seen.append(names)
		print("SWAP pickup#%d weapons=%d [%s]" % [_pickups, player.inventory.weapons.size(), names.trim_suffix(",")])
		# After 3 pickups we should still be at MAX 2 but with swapped contents.
		if _pickups >= 3:
			_phase = 2
		return false

	if _phase == 2:
		# Validate: size stayed capped at 2 (swap, never ignored).
		var ok: bool = player.inventory.weapons.size() == 2
		# The equipped set must have changed at least once across pickups
		# (i.e. swap actually happened, not a stuck duplicate).
		var changed := false
		for s in _seen:
			if s != _seen[0]:
				changed = true
		print("SWAP seen_sets=%s" % _seen)
		print("SWAP %s" % ("PASS" if (ok and changed) else "FAIL"))
		quit()
		return false
	return false
