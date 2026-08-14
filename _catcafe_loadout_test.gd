## Verifies the Cat Cafe Worker's full combat loadout in the REAL game scene:
##   - starts with BOTH a pistol ("手枪") and the drone ("无人机") -> 2 weapon slots
##   - the drone auto-deploys a companion (summon present)
##   - recruiting followers fills the roster and at least one companion is a
##     MELEE GUARD (attack_style == 1) that orbits/defends the owner
## Run: Godot ... -s res://_catcafe_loadout_test.gd
extends SceneTree

const GameSceneScript = preload("res://scenes/gameplay/game_scene.tscn")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const SummonUnitScript = preload("res://scripts/entities/summon/summon_unit.gd")

var _scene = null
var _frames := 0
var _done := false

func _initialize() -> void:
	CharacterRegistryScript.init()

func _physics_process(_delta: float) -> bool:
	if _done:
		return false
	if _scene == null:
		Game.selected_character = CharacterRegistryScript.get_data("cat_cafe_worker")
		_scene = GameSceneScript.instantiate()
		root.add_child(_scene)
		current_scene = _scene
		_frames = 0
		return false
	_frames += 1
	if _frames < 30:
		return false
	_check()
	return false

func _count_summon_units(node: Node) -> int:
	var n := 0
	if node.get_script() == SummonUnitScript:
		n += 1
	for c in node.get_children():
		n += _count_summon_units(c)
	return n

func _gather_summon_units(node: Node, out: Array) -> void:
	if node.get_script() == SummonUnitScript:
		out.append(node)
	for c in node.get_children():
		_gather_summon_units(c, out)

func _check() -> void:
	var player = _scene.get_node_or_null("Player")
	var inv = player.get("inventory") if player else null
	var names: Array[String] = []
	var slots := -1
	if inv != null:
		slots = inv.weapons.size()
		for w in inv.weapons:
			if w != null:
				names.append(w.weapon_name)
	var has_pistol := false
	var has_drone := false
	for n in names:
		if "手枪" in n:
			has_pistol = true
		if "无人机" in n:
			has_drone = true

	# Recruit followers up to the cap to cycle through all 5 cat-cafe types
	# (round-robin) so melee-guard types (dog meat, plush bear) get spawned.
	var fm = _scene.get("follower_manager")
	var recruited := 0
	if fm != null:
		for i in range(12):
			if fm.try_add_follower(3):
				recruited += 1
	var units: Array = []
	_gather_summon_units(_scene, units)
	var melee_guards := 0
	for u in units:
		if int(u.get("attack_style")) == 1:
			melee_guards += 1

	var ok := has_pistol and has_drone and (slots == 2) and (melee_guards >= 1)
	print("=== CAT CAFE LOADOUT ===")
	print("weapon_slots=%d names=%s" % [slots, names])
	print("has_pistol=%s has_drone=%s" % [has_pistol, has_drone])
	print("total_summon_units=%d recruited_followers=%d melee_guards=%d" % [_count_summon_units(_scene), recruited, melee_guards])
	print("CAT_CAFE_LOADOUT %s" % ("PASS" if ok else "FAIL"))
	quit()

func _report() -> void:
	pass
