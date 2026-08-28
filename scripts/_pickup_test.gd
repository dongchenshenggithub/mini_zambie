extends SceneTree
const PickupItem = preload("res://scripts/gameplay/pickup_item.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const WeaponInventory = preload("res://scripts/entities/player/weapon_inventory.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const WeaponRegistry = preload("res://scripts/systems/weapon_registry.gd")
const StorageBox = preload("res://scripts/systems/storage_box.gd")

var world: Node2D
var player
var drop_acc
var drop_weapon
var _started := false
var _elapsed := 0.0
var _acc_shape := false
var _storage_count_before := 0
var _wpn_before := 0


func _init() -> void:
	WeaponRegistry.init()
	StorageBox.init()
	world = Node2D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world

	var cd = CharacterEntryScript.new()
	cd.strength = 5; cd.agility = 5; cd.intelligence = 5
	cd.constitution = 5; cd.luck = 5; cd.willpower = 5
	cd.starting_health = 100.0; cd.starting_speed = 200.0
	cd.ranged_damage_multiplier = 1.0; cd.character_class = 0
	player = PlayerScript.new()
	player.set("character_data", cd)
	player.stats = PlayerStatsScript.new()
	world.add_child(player)
	player.add_to_group("player")

	# Accessory drop
	drop_acc = PickupItem.new()
	drop_acc.item_type = PickupItem.ItemType.ACCESSORY
	drop_acc.accessory_data = load("res://resources/accessories/acc_iron_plate.tres")
	drop_acc.global_position = player.global_position + Vector2(60, 0)
	world.add_child(drop_acc)

	# Weapon drop
	drop_weapon = PickupItem.new()
	drop_weapon.item_type = PickupItem.ItemType.WEAPON
	drop_weapon.global_position = player.global_position + Vector2(60, 60)
	world.add_child(drop_weapon)


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		_acc_shape = is_instance_valid(drop_acc) and drop_acc.get_node_or_null("PickupShape") != null
		_storage_count_before = StorageBox.get_weapon_count()
		_wpn_before = player.inventory.weapons.size()
		print("PICKUP acc_has_shape=%s" % _acc_shape)
		print("PICKUP storage_before=%d weapons_before=%d" % [_storage_count_before, _wpn_before])
		return false
	_elapsed += delta
	if _elapsed < 1.2:
		return false
	
	var storage_count_after = StorageBox.get_weapon_count()
	var wpn_after = player.inventory.weapons.size()
	
	print("PICKUP storage_after=%d weapons_after=%d" % [storage_count_after, wpn_after])
	
	# Check that items were stored (not auto-equipped)
	var ok = _acc_shape and storage_count_after > _storage_count_before
	print("PICKUP %s" % ("PASS" if ok else "FAIL"))
	quit()
	return false
