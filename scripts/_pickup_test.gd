extends SceneTree
const PickupItem = preload("res://scripts/gameplay/pickup_item.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStats = preload("res://scripts/entities/player/player_stats.gd")
const WeaponInventory = preload("res://scripts/entities/player/weapon_inventory.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const WeaponRegistry = preload("res://scripts/systems/weapon_registry.gd")

var world: Node2D
var player
var drop_acc
var drop_weapon
var _started := false
var _elapsed := 0.0
var _acc_shape := false
var _acc_hp_before := 0.0
var _wpn_before := 0


func _init() -> void:
	WeaponRegistry.init()
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
	player.stats = PlayerStats.new()
	world.add_child(player)
	player.add_to_group("player")

	# Accessory drop (verifies stat application)
	drop_acc = PickupItem.new()
	drop_acc.item_type = PickupItem.ItemType.ACCESSORY
	drop_acc.accessory_data = load("res://resources/accessories/acc_iron_plate.tres")
	drop_acc.global_position = player.global_position + Vector2(60, 0)
	world.add_child(drop_acc)

	# Weapon drop (verifies weapon collection + the template filter)
	drop_weapon = PickupItem.new()
	drop_weapon.item_type = PickupItem.ItemType.WEAPON
	drop_weapon.global_position = player.global_position + Vector2(60, 60)
	world.add_child(drop_weapon)


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		_acc_shape = is_instance_valid(drop_acc) and drop_acc.get_node_or_null("PickupShape") != null
		# Baselines read here (after _ready) since inventory/stats finish in _ready.
		_acc_hp_before = player.stats.max_health
		_wpn_before = player.inventory.weapons.size()
		print("PICKUP acc_has_shape=%s" % _acc_shape)
		return false
	_elapsed += delta
	if _elapsed < 1.2:
		return false
	var acc_hp_after = player.stats.max_health
	var wpn_after = player.inventory.weapons.size()
	print("PICKUP acc_hp_before=%s acc_hp_after=%s" % [_acc_hp_before, acc_hp_after])
	print("PICKUP wpn_before=%s wpn_after=%s" % [_wpn_before, wpn_after])
	var ok = _acc_shape and acc_hp_after > _acc_hp_before and wpn_after > _wpn_before
	print("PICKUP_PASS" if ok else "PICKUP_FAIL")
	quit()
	return false
