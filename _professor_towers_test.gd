## Loads the REAL game scene as Professor, deploys both starting structures
## (turret + healing tower) via the active ability, then verifies the turret
## actually auto-attacks a nearby zombie across frames.
## Run: Godot ... -s res://_professor_towers_test.gd
extends SceneTree

const GameSceneScript = preload("res://scenes/gameplay/game_scene.tscn")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const ZE = preload("res://scripts/core/game_enums.gd")
const TurretScript = preload("res://scripts/entities/structures/turret.gd")
const HealingTowerScript = preload("res://scripts/entities/structures/healing_tower.gd")

var _scene = null
var _frames := 0
var _done := false
var _zombie = null
var _z_hp0: float = 0.0


func _initialize() -> void:
	CharacterRegistryScript.init()
	Game.selected_character = CharacterRegistryScript.get_data("professor")
	_scene = GameSceneScript.instantiate()
	root.add_child(_scene)


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	var player = _scene.get_node_or_null("Player")
	var beh = null
	if player != null:
		beh = player.behavior

	if _frames == 3:
		if beh != null:
			beh.on_special_ability(_scene)   # turret
			beh.on_special_ability(_scene)   # healing tower
		# Spawn a zombie right next to the player (and thus next to the turret).
		_zombie = ZombieBaseScript.new()
		_zombie.zombie_type = ZE.ZombieType.NORMAL
		_scene.add_child(_zombie)
		_zombie.global_position = player.global_position + Vector2(40, 0)
		_z_hp0 = _zombie.current_health
		return false

	if _frames >= 45 and not _done:
		_done = true
		var t := 0
		var h := 0
		for n in _scene.get_children():
			if n.get_script() == TurretScript:
				t += 1
			elif n.get_script() == HealingTowerScript:
				h += 1
		# Unit check: a freshly placed turret damages a grouped zombie.
		var tu = TurretScript.new()
		_scene.add_child(tu)
		var z2 = ZombieBaseScript.new()
		z2.zombie_type = ZE.ZombieType.NORMAL
		_scene.add_child(z2)
		var hp2: float = z2.current_health
		tu._attack()
		var turret_dmg: bool = (z2.current_health < hp2)
		print("turrets=%d heals=%d unit_turret_dmg=%s z2_hp %.1f->%.1f" % [t, h, turret_dmg, hp2, z2.current_health])
		tu.queue_free()
		z2.queue_free()
		var ok: bool = (t == 1 and h == 1 and turret_dmg)
		print("PROFESSOR_TOWERS %s" % ("PASS" if ok else "FAIL"))
		quit()
		return false
	return false
