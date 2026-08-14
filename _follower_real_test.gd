## Loads the REAL game scene, spawns a zombie next to the player, and invokes a
## follower's _attack() directly inside the live tree to confirm the group-based
## damage path actually works (the -s SceneTree group/tree quirks made the
## isolated test unreliable).
## Run: Godot ... -s res://_follower_real_test.gd
extends SceneTree

const GameSceneScript = preload("res://scenes/gameplay/game_scene.tscn")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const ZE = preload("res://scripts/core/game_enums.gd")

var _scene = null
var _zombie = null
var _frames = 0
var _done = false

func _initialize() -> void:
	CharacterRegistryScript.init()
	Game.selected_character = CharacterRegistryScript.get_data("alien_shooter")
	_scene = GameSceneScript.instantiate()
	root.add_child(_scene)

func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3 or _done:
		return false
	_done = true

	var player = _scene.get_node_or_null("Player")
	var followers = get_nodes_in_group("summon")
	print("followers spawned in scene: %d" % followers.size())
	if followers.is_empty():
		print("REALSCENE_FOLLOWER FAIL (no followers spawned)")
		quit()
		return false

	# Spawn a zombie right next to the player.
	_zombie = ZombieBaseScript.new()
	_zombie.zombie_type = ZE.ZombieType.NORMAL
	_scene.add_child(_zombie)
	var anchor: Vector2 = player.global_position if player else Vector2.ZERO
	_zombie.global_position = anchor + Vector2(20, 0)
	# Place the follower right next to the zombie so the new (follower-position)
	# targeting has a valid in-range target — in real play the follower lerps to
	# the player within ~1s, so this just removes the test's frame-lag artifact.
	var f = followers[0] as Node2D
	f.global_position = _zombie.global_position + Vector2(15, 0)
	var hp0: float = _zombie.current_health
	# Invoke the real attack path inside the live tree.
	if f.has_method("_attack"):
		f._attack()
	var hp1: float = _zombie.current_health
	print("follower.global=%s zombie.global=%s" % [f.global_position, _zombie.global_position])
	print("zombie hp %.1f -> %.1f (delta %.1f)" % [hp0, hp1, hp0 - hp1])
	print("REALSCENE_FOLLOWER %s" % ("PASS" if (hp0 - hp1) > 1.0 else "FAIL"))
	quit()
	return false
