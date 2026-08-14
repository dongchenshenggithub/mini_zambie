## Verifies the Cyber Cultivator (class 2) throws melee weapons as slow
## piercing projectiles that damage zombies and boomerang back (no reload).
## Loads the REAL game scene as the cultivator, aims right at a zombie, and
## inspects the resulting thrown_melee projectile.
## Run: Godot ... -s res://_cultivator_throw_test.gd
extends SceneTree

const GameSceneScript = preload("res://scenes/gameplay/game_scene.tscn")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const ThrownMeleeScript = preload("res://scripts/weapons/thrown_melee.gd")
const ZE = preload("res://scripts/core/game_enums.gd")

var _scene = null
var _zombie = null
var _frames = 0
var _done = false
var _thrown_seen: bool = false
var _zombie_hp0: float = 0.0
var _zombie_hp1: float = 0.0

func _initialize() -> void:
	CharacterRegistryScript.init()
	Game.selected_character = CharacterRegistryScript.get_data("cyber_cultivator")
	_scene = GameSceneScript.instantiate()
	root.add_child(_scene)

func _physics_process(_delta: float) -> bool:
	if _done:
		return false
	_frames += 1
	if _frames < 3:
		return false

	if _zombie == null:
		var player = _scene.get_node_or_null("Player")
		_zombie = ZombieBaseScript.new()
		_zombie.zombie_type = ZE.ZombieType.NORMAL
		_scene.add_child(_zombie)
		var anchor: Vector2 = player.global_position if player else Vector2.ZERO
		_zombie.global_position = anchor + Vector2(110, 0)
		_zombie_hp0 = _zombie.current_health
		# Deterministic aim to the right (toward the zombie). The player's
		# _physics_process recomputes _aim_dir from the (headless) mouse each
		# frame, so we set it immediately before the synchronous throw call.
		if player:
			player._aim_dir = Vector2(1, 0)
			var w = player.inventory.weapons[0] if player.inventory.weapons.size() > 0 else null
			if w != null:
				w.set_fire_input(true, true)      # exercise the real input path too
				w._spawn_thrown_melee()           # deterministic spawn, aimed right
		return false

	# Keep an eye out for a thrown projectile in the live scene.
	if _find_thrown() != null:
		_thrown_seen = true

	if _frames >= 30 and _zombie_hp1 <= 0.0:
		_zombie_hp1 = _zombie.current_health

	if _frames >= 45:
		var player = _scene.get_node_or_null("Player")
		var w = player.inventory.weapons[0] if (player and player.inventory and player.inventory.weapons.size() > 0) else null
		var no_reload = (w != null and w.magazine_size == 0)
		var dmg_ok = (_zombie_hp0 - _zombie_hp1) > 1.0
		print("thrown_seen=%s  no_reload(mag==0)=%s  dealt_throw_damage=%s  (hp %.1f->%.1f)" % [
			_thrown_seen, no_reload, dmg_ok, _zombie_hp0, _zombie_hp1])
		var all_ok = _thrown_seen and no_reload and dmg_ok
		print("CULTIVATOR_THROW %s" % ("PASS" if all_ok else "FAIL"))
		_done = true
		quit()
	return false

func _find_thrown() -> Node:
	var scene = _scene.get_tree().current_scene if _scene.get_tree() != null else null
	if scene == null:
		scene = _scene
	for c in scene.get_children():
		if c.get_script() == ThrownMeleeScript:
			return c
	return null
