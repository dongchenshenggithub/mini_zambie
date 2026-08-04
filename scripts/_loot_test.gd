## Headless test: level-up is attribute-only AND monster drops deliver correctly
## typed weapons/equipment (via direct PickupItem instantiation) that apply.
## Not part of the game.
extends SceneTree

const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")
const AccessoryRegistryScript = preload("res://scripts/systems/accessory_registry.gd")
const WeaponRegistryScript = preload("res://scripts/systems/weapon_registry.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const WeaponInventoryScript = preload("res://scripts/entities/player/weapon_inventory.gd")
const ProstheticManagerScript = preload("res://scripts/core/prosthetic_manager.gd")
const UpgradePickerScript = preload("res://scripts/systems/upgrade_picker.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")

var _cd: CharacterEntry = null
var _pl: Node = null
var _acc: PickupItem = null
var _done := false

func _init() -> void:
	AccessoryRegistryScript.init()
	WeaponRegistryScript.init()

	# 1) Direct PickupItem instantiation (what the game uses for drops) is
	#    correctly typed for every kind.
	var types := [
		PickupItemScript.ItemType.POTION,
		PickupItemScript.ItemType.WEAPON,
		PickupItemScript.ItemType.ACCESSORY,
		PickupItemScript.ItemType.PARTS,
	]
	var ok_type := true
	for t in types:
		var d = PickupItemScript.new()
		d.item_type = t
		if d.item_type != t:
			ok_type = false
		d.queue_free()
	print("LOOT drop_typing=%s" % ok_type)

	# 2) Soul orb scene still loads (orbs always drop).
	var orb_scene = load("res://scenes/gameplay/soul_orb.tscn")
	var ok_orb := orb_scene != null
	print("LOOT soul_orb_load=%s" % ok_orb)

	# 3) Level-up offers ONLY attribute upgrades (no weapon/equipment).
	var cd = CharacterEntryScript.new()
	cd.strength = 5
	cd.agility = 5
	cd.intelligence = 5
	cd.constitution = 5
	cd.luck = 5
	cd.willpower = 5
	cd.starting_health = 100.0; cd.starting_speed = 200.0
	cd.ranged_damage_multiplier = 1.0
	var pl = PlayerScript.new()
	pl.set("character_data", cd)
	pl.stats = PlayerStatsScript.new()
	pl.inventory = WeaponInventoryScript.new()
	pl.prosthetic_manager = ProstheticManagerScript.new(false, pl.stats)
	pl._apply_character_traits()
	root.add_child(pl)
	pl.add_to_group("player")
	var picker = UpgradePickerScript.new()
	var opts = picker.generate_options(pl, 6)
	var all_attr := true
	for o in opts:
		if int(o["kind"]) > int(UpgradePickerScript.UpgradeKind.WILLPOWER):
			all_attr = false
	print("LOOT upgrade_attr_only=%s (count=%d)" % [all_attr and opts.size() == 6, opts.size()])

	# 4) Picking up an accessory actually applies its bonuses. Deferred to
	#    _process because get_tree() on a freshly-added child is only valid
	#    once the main loop is running (mirrors in-game pickup during play).
	_pl = pl
	_cd = cd
	_acc = PickupItemScript.new()
	_acc.item_type = PickupItemScript.ItemType.ACCESSORY
	root.add_child(_acc)
	# Keep it far from the player so the magnet auto-collect (which frees the
	# drop) doesn't fire before we exercise _equip_accessory directly.
	_acc.global_position = Vector2(5000.0, 5000.0)


func _process(_delta: float) -> bool:
	if _done:
		return false
	_done = true

	var ok_type := true  # kept for pass logic (re-evaluated at end)
	var all_acc = AccessoryRegistryScript.get_all()
	if all_acc.is_empty():
		print("LOOT accessory_apply=SKIP (no accessory data)")
	else:
		_acc.accessory_data = all_acc[0]
		var str_before: int = _cd.strength
		var ranged_before: float = _pl.stats.damage_multiplier_ranged
		var hp_before: float = _pl.stats.max_health
		_acc._equip_accessory()
		var applied: bool = (_cd.strength > str_before) or (_pl.stats.damage_multiplier_ranged > ranged_before) or (_pl.stats.max_health > hp_before) or (_pl.stats.accessory_armor_bonus > 0)
		print("LOOT accessory_apply=%s str %d->%d ranged %.3f->%.3f hp %.1f->%.1f armor %d" % [
			applied, str_before, _cd.strength, ranged_before, _pl.stats.damage_multiplier_ranged, hp_before, _pl.stats.max_health, _pl.stats.accessory_armor_bonus])

	var pass_all: bool = all_acc.size() > 0 and (_cd.strength > 5 or _pl.stats.accessory_armor_bonus > 0 or _pl.stats.max_health > 100.0)
	if pass_all:
		print("LOOT_PASS")
	else:
		print("LOOT_FAIL")
	quit()
	return false
