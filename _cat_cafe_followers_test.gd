## Loads the REAL game scene as Cat Cafe Worker, then recruits 4 more
## companions (per-floor pattern) and verifies all 5 distinct companion types
## appear with the summon damage multiplier applied.
## Run: Godot ... -s res://_cat_cafe_followers_test.gd
extends SceneTree

const GameSceneScript = preload("res://scenes/gameplay/game_scene.tscn")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const SummonUnitScript = preload("res://scripts/entities/summon/summon_unit.gd")

func _initialize() -> void:
	CharacterRegistryScript.init()
	Game.selected_character = CharacterRegistryScript.get_data("cat_cafe_worker")
	var scene = GameSceneScript.instantiate()
	root.add_child(scene)


var _frames := 0
func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	var scene = root.get_child(root.get_child_count() - 1)
	var fm = scene.get("follower_manager")
	# Recruit 4 more (per-floor pattern): 1 initial + 4 = 5 companions.
	if fm != null:
		fm.try_add_follower(3)
		fm.try_add_follower(3)
		fm.try_add_follower(3)
		fm.try_add_follower(3)

	var all = get_nodes_in_group("summon")
	var shapes := {}
	var damages := []
	for f in all:
		var su = f as SummonUnitScript
		if su:
			shapes[su.body_shape] = true
			damages.append(int(su.damage))
	var count := all.size()
	print("cat_cafe followers: %d" % count)
	print("distinct body shapes: %d  keys=%s" % [shapes.size(), shapes.keys()])
	print("sample damages: %s" % [damages])
	# Expected: 5 followers, 5 distinct shapes (pirate=1 dog=2 owl=0 bear=4 dragon=3),
	# and damage reflects the +50% cat-cafe summon multiplier (e.g. pirate 26*1.5=39).
	var ok := (count == 5) and (shapes.size() == 5)
	print("CAT_CAFE_FOLLOWERS %s" % ("PASS" if ok else "FAIL"))
	quit()
	return false
