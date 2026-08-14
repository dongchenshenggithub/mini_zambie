## Headless test for the melee attack-range + slash-trail feature.
##  - equipping a melee weapon works
##  - firing a melee weapon spawns a MeleeTrail node on the player
##  - the swing list is non-empty right after a swing (trail is animating)
##  - after a physics frame the persistent range ring is shown (range display)
##  - melee still damages a zombie in range (no regression in hit logic)
## Not part of the game.
extends SceneTree

const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const ChainsawScript = preload("res://scripts/weapons/melee/weapon_chainsaw.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")

var world: Node2D
var player
var zombie
var chainsaw
var _started := false
var _elapsed := 0.0
var _checks: Dictionary = {}

func _init() -> void:
	world = Node2D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world

	var cd = CharacterEntryScript.new()
	cd.strength = 5; cd.agility = 5; cd.intelligence = 5
	cd.constitution = 5; cd.luck = 5; cd.willpower = 5
	cd.starting_health = 100.0; cd.starting_speed = 200.0
	cd.character_class = 0
	player = PlayerScript.new()
	player.set("character_data", cd)
	player.stats = PlayerStatsScript.new()
	world.add_child(player)
	player.global_position = Vector2.ZERO
	player.add_to_group("player")

	zombie = ZombieBaseScript.new()
	zombie.zombie_type = GameEnums.ZombieType.NORMAL
	zombie.global_position = Vector2(40, 0)   # within chainsaw range (60)
	world.add_child(zombie)
	zombie.add_to_group("zombie")
	zombie.target_player = player


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		_setup_and_fire()
		return false

	_elapsed += delta
	if _elapsed < 0.1:
		return false

	_final_checks()
	var all_ok := true
	for k in _checks.keys():
		if _checks[k] == false:
			all_ok = false
		print("MELEE_TRAIL check %s=%s" % [k, _checks[k]])
	print("MELEE_TRAIL_PASS" if all_ok else "MELEE_TRAIL_FAIL")
	quit()
	return false


func _setup_and_fire() -> void:
	# Equip a melee weapon.
	chainsaw = ChainsawScript.new()
	var ok = player.inventory.equip_weapon(chainsaw)
	_checks["melee_equip"] = ok

	# Fire it once.
	var hp_before = zombie.current_health
	chainsaw.try_fire(0.0)
	var hp_after = zombie.current_health

	# Trail node should now exist on the player.
	var trail = player.get_node_or_null("MeleeTrail")
	_checks["trail_node_exists"] = trail != null
	_checks["melee_damaged_zombie"] = hp_after < hp_before
	if trail != null:
		# A swing should have been appended synchronously by trigger().
		_checks["swing_active"] = (trail._swings.size() > 0)
	else:
		_checks["swing_active"] = false


func _final_checks() -> void:
	var trail = player.get_node_or_null("MeleeTrail")
	if trail == null:
		_checks["range_ring_shown"] = false
		return
	# After a physics frame the auto range-ring should be active at the weapon's reach.
	_checks["range_ring_shown"] = trail._show_ring and abs(trail._range_active - chainsaw.range) < 0.5
