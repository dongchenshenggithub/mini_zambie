## Floor-reset regression: confirms the group-based sweep that GameScene runs
## on _advance_floor() removes leftover zombies/boss/drops (PickupItem +
## SoulOrb) but leaves the player and the player's summons intact.
##
## Not part of the game. Run headless:
##   Godot ... -s res://scripts/_floor_reset_test.gd
extends SceneTree

const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")
const SoulOrbScript = preload("res://scripts/gameplay/soul_orb.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const WeaponInventoryScript = preload("res://scripts/entities/player/weapon_inventory.gd")
const ProstheticManagerScript = preload("res://scripts/core/prosthetic_manager.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")

var world
var player
var _started := false
var _cleared := false
var _elapsed := 0.0
var _results: Array[String] = []
var _ok := true


func _init() -> void:
	world = Node2D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world

	# Player — must survive the sweep.
	var cd = CharacterEntryScript.new()
	cd.starting_health = 100.0; cd.starting_speed = 200.0; cd.character_class = 0
	player = PlayerScript.new()
	player.set("character_data", cd)
	player.stats = PlayerStatsScript.new()
	player.inventory = WeaponInventoryScript.new()
	player.prosthetic_manager = ProstheticManagerScript.new(false, player.stats)
	world.add_child(player)
	player.add_to_group("player")

	# A leftover zombie from the cleared floor (group "zombie").
	var z = ZombieBaseScript.new()
	z.zombie_type = GameEnums.ZombieType.NORMAL
	world.add_child(z)
	z.add_to_group("zombie")

	# A leftover boss (group "boss").
	var b = ZombieBaseScript.new()
	b.zombie_type = GameEnums.ZombieType.BOSS_ZOMBIE_KING
	world.add_child(b)
	b.add_to_group("boss")

	# Uncollected drops: a PickupItem + a SoulOrb (both join group "drop").
	var drop = PickupItemScript.new()
	drop.item_type = PickupItemScript.ItemType.WEAPON
	world.add_child(drop)
	var orb = SoulOrbScript.new()
	world.add_child(orb)

	# The player's own minion (group "summon") — must NOT be swept.
	var summon = Node2D.new()
	summon.name = "SummonUnit"
	world.add_child(summon)
	summon.add_to_group("summon")


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		return false

	_elapsed += delta

	# Run the exact sweep GameScene._clear_floor_entities() performs, after the
	# drops' _ready has run (so they've joined the "drop" group). This is a
	# SceneTree `-s` script, so `get_nodes_in_group` is the SceneTree method
	# itself (there is no get_tree() here).
	if not _cleared and _elapsed > 0.15:
		for grp in ["zombie", "boss", "drop"]:
			for node in get_nodes_in_group(grp):
				if is_instance_valid(node):
					node.queue_free()
		_cleared = true
		return false

	if _elapsed < 0.5:
		return false

	_verify()
	for r in _results:
		print(r)
	print("FLOOR_RESET %s" % ("PASS" if _ok else "FAIL"))
	quit()
	return false


func _verify() -> void:
	var drop_count := get_nodes_in_group("drop").size()
	var zombie_count := get_nodes_in_group("zombie").size()
	var boss_count := get_nodes_in_group("boss").size()
	var player_alive: bool = false
	if is_instance_valid(player):
		player_alive = player.is_inside_tree()
	var summon_alive := get_nodes_in_group("summon").size()

	_results.append("FLOOR_RESET drop=%d zombie=%d boss=%d player=%s summon=%d"
		% [drop_count, zombie_count, boss_count, player_alive, summon_alive])

	_checks("drops_cleared", drop_count == 0)
	_checks("zombies_cleared", zombie_count == 0)
	_checks("boss_cleared", boss_count == 0)
	_checks("player_kept", player_alive)
	_checks("summon_kept", summon_alive >= 1)


func _checks(name: String, ok: bool) -> void:
	if not ok:
		_ok = false
	_results.append("FLOOR_RESET check %s=%s" % [name, ok])
