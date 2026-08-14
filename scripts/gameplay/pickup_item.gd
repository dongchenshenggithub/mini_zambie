## Pickup item — dropped by zombies, auto-collected by the player.
class_name PickupItem
extends Area2D

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const WeaponRegistry = preload("res://scripts/systems/weapon_registry.gd")

enum ItemType { POTION, WEAPON, ACCESSORY, PARTS, COMPANION }

@export var item_type: ItemType = ItemType.POTION
@export var rarity: int = 0  # 0=common, 1=uncommon, 2=rare, 3=epic
@export var limb: LimbSlot = null  # when set, picking up installs a prosthetic limb
var accessory_data: AccessoryData = null  # when set, picking up applies its stat bonuses

var _collected: bool = false


func _ready() -> void:
	_setup_collision()
	connect("body_entered", _on_body_entered)
	_setup_visuals()
	# Membership lets the floor-transition logic (GameScene._clear_floor_entities)
	# sweep away uncollected drops when a new floor loads, instead of leaving
	# previous-floor loot sitting in the new map.
	add_to_group("drop")


## Area2D needs its own collision shape or body_entered never fires — without
## this the drop is visible but can NEVER be picked up.
func _setup_collision() -> void:
	monitoring = true
	monitorable = true
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	var col := CollisionShape2D.new()
	col.name = "PickupShape"
	col.shape = shape
	add_child(col)


func _setup_visuals() -> void:
	# Rarity ring (colored outline behind the icon) so type color and rarity
	# color never conflict — the icon keeps its baked type colour and shape,
	# while a separate ring shows common/uncommon/rare/epic.
	var ring = Sprite2D.new()
	ring.name = "RarityRing"
	ring.texture = PixelLoader.load_texture("res://assets/pixel/rarity_ring.png")
	if ring.texture != null:
		var rt := 28.0
		ring.scale = Vector2(rt / ring.texture.get_width(), rt / ring.texture.get_height())
		var ring_colors := [
			Color(0.6, 0.6, 0.65, 1.0),   # common   – steel grey
			Color(1.0, 0.85, 0.2, 1.0),    # uncommon – gold
			Color(0.3, 0.6, 1.0, 1.0),     # rare     – blue
			Color(0.85, 0.35, 1.0, 1.0),   # epic     – magenta
		]
		ring.modulate = ring_colors[rarity] if rarity < ring_colors.size() else Color.WHITE
	add_child(ring)

	# Main item icon (baked type colour + distinct shape).
	var spr = Sprite2D.new()
	spr.texture = PixelLoader.load_texture(_get_item_texture_path())
	spr.name = "Visual"
	if spr.texture != null:
		var target := 18.0
		spr.scale = Vector2(target / spr.texture.get_width(), target / spr.texture.get_height())
	add_child(spr)
	# Gentle bob so drops clearly read as collectible pickups.
	if spr.texture != null:
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(spr, "position:y", -3.0, 0.6).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_property(spr, "position:y", 3.0, 0.6).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


## Brotato-style magnet: drops drift toward the player when close, and are
## collected on contact (robust even if body_entered somehow misses).
func _physics_process(delta: float) -> void:
	if _collected:
		return
	var player = get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()
	var magnet_range := 90.0
	if dist < magnet_range and dist > 1.0:
		var pull: float = lerp(300.0, 60.0, dist / magnet_range)
		global_position += to_player.normalized() * pull * delta
	if dist < 16.0:
		_on_pickup()


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is Player:
		_on_pickup()


func _on_pickup() -> void:
	if _collected:
		return
	_collected = true
	SfxManager.play("pickup")
	match item_type:
		ItemType.POTION:
			_use_potion()
		ItemType.WEAPON:
			_equip_weapon()
		ItemType.ACCESSORY:
			_equip_accessory()
		ItemType.PARTS:
			_use_parts()
		ItemType.COMPANION:
			_add_companion()
	queue_free()


func _use_potion() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats.is_alive():
		return
	match rarity:
		0: player.heal(player.stats.max_health * 0.1)
		1: player.heal(player.stats.max_health * 0.15)
		2: player.heal(player.stats.max_health * 0.2)
	if player.behavior:
		player.behavior.on_potion_pickup(self)


func _equip_weapon() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats.is_alive():
		return
	var all = WeaponRegistry.get_all()
	# Skip template/broken entries (e.g. base_weapon_data.tres id="__template__"
	# whose weapon_path points at a non-existent script) so a weapon drop
	# always yields a real, equippable weapon.
	all = all.filter(func(w): return w != null and w.weapon_path != "" and ResourceLoader.exists(w.weapon_path))
	if all.is_empty():
		return
	var data = all[randi() % all.size()]
	var weapon = WeaponRegistry.spawn_instance(data)
	if weapon == null:
		return
	# Let the class behavior modify/reject the pickup (e.g. Mech Monk
	# dismantles it for HP, Cyber Cultivator refuses non-melee weapons).
	if player.behavior:
		player.behavior.on_weapon_pickup(weapon)
	if not is_instance_valid(weapon):
		return  # behavior consumed/dismantled it
	var ok = player.inventory.equip_weapon(weapon)
	if ok:
		_toast("获得武器：%s" % weapon.weapon_name)
	else:
		weapon.queue_free()
		_toast("武器栏已满")


func _equip_accessory() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats.is_alive():
		return
	if accessory_data == null:
		# No data attached (shouldn't happen) — fall back to a small heal.
		player.heal(player.stats.max_health * 0.1)
		return
	var cd = player.character_data
	if cd == null:
		return
	# Attribute bonuses feed recompute_combat_stats via character_data, so they
	# persist across the run (the same path level-up stat boosts use).
	cd.strength += accessory_data.strength_bonus
	cd.agility += accessory_data.agility_bonus
	cd.intelligence += accessory_data.intelligence_bonus
	cd.constitution += accessory_data.constitution_bonus
	cd.luck += accessory_data.luck_bonus
	cd.willpower += accessory_data.willpower_bonus
	# Direct stat bonuses accumulate on the player's stats; recompute_combat_stats
	# re-adds these every call so they survive the per-level-up recompute.
	var s = player.stats
	s.max_health += accessory_data.health_bonus
	player.heal(accessory_data.health_bonus)
	s.accessory_armor_bonus += accessory_data.armor_bonus
	s.accessory_speed_bonus += accessory_data.speed_bonus
	s.accessory_ranged_mult += accessory_data.ranged_damage_mult
	s.accessory_melee_mult += accessory_data.melee_damage_mult
	s.accessory_laser_mult += accessory_data.laser_damage_mult
	s.accessory_summon_mult += accessory_data.summon_damage_mult
	s.accessory_spray_mult += accessory_data.spray_damage_mult
	s.accessory_crit_bonus += accessory_data.crit_chance_bonus
	player.recompute_combat_stats()
	if player.equipped_accessories != null:
		player.equipped_accessories.append(accessory_data)
	_toast("装备：%s" % accessory_data.name)


func _use_parts() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	if player.behavior:
		player.behavior.on_parts_pickup(self)
	# If this drop carries a prosthetic limb, install it. Otherwise fall back
	# to the repair/heal behaviour (PartData-style consumable).
	if limb != null:
		_install_limb(player)
		return
	if player.character_data and player.character_data.character_class == 1:
		player.heal(player.stats.max_health * 0.05)
	else:
		for weapon in player.inventory.weapons:
			if weapon.durability < 100.0:
				weapon.repair(20.0)
				break


func _install_limb(player: Player) -> void:
	var pm = player.prosthetic_manager
	if pm == null:
		return
	var valid_slots: Array[int] = []
	for s in [0, 1, 2, 3, 4, 5]:
		if pm.can_equip(s):
			valid_slots.append(s)
	if valid_slots.is_empty():
		_toast("无法装备义肢：%s（无可用槽位）" % limb.slot_name)
		return

	# Prefer the limb's own slot when the player can use it and it's empty.
	var target_slot: int = -1
	if pm.can_equip(limb.slot_type) and pm.get_limb(limb.slot_type) == null:
		target_slot = limb.slot_type
	else:
		for s in valid_slots:
			if pm.get_limb(s) == null:
				target_slot = s
				break
	# No empty slot — replace the first available one.
	if target_slot == -1:
		target_slot = valid_slots[0]

	var ok = pm.install_limb(target_slot, limb)
	if ok:
		_toast("装备义肢：%s" % limb.slot_name)
	else:
		_toast("义肢安装失败：%s" % limb.slot_name)


func _toast(text: String) -> void:
	var h = get_tree().get_first_node_in_group("hud") as HUD
	if h and h.has_method("show_toast"):
		h.show_toast(text)


## Companion (护卫) pickup.
##   - Cat Cafe (class 3) is the pure summoner: companions are uncapped by weapon
##     slots and recruited directly through FollowerManager (try_add_follower).
##   - Every other character gains companions ONLY through "companion weapons":
##     picking one up equips a CompanionWeapon that OCCUPIES one weapon slot and
##     spawns a 1:1 linked follower. The companion count is therefore implicitly
##     capped by the number of free weapon slots (max_weapons), so non-Cat-Cafe
##     characters can never exceed that many companions.
func _add_companion() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player == null or not player.stats.is_alive():
		return
	var cls: int = -1
	if player.character_data != null:
		cls = player.character_data.character_class

	# Cat Cafe: add straight through FollowerManager, uncapped by weapon slots.
	if cls == 3:
		var fm = null
		var gs = get_tree().current_scene
		if gs != null and gs.has_method("get") and gs.get("follower_manager") != null:
			fm = gs.get("follower_manager")
		if fm != null and fm.has_method("try_add_follower"):
			if fm.try_add_follower(cls):
				_toast("获得护卫！")
			else:
				_toast("护卫栏已满")
		return

	# Other characters: a companion occupies one weapon slot (1:1). The cap is
	# the number of free weapon slots, so the companion count can never exceed
	# max_weapons (their follower cap is set equal to max_weapons in the registry).
	var fm = null
	var gs = get_tree().current_scene
	if gs != null and gs.has_method("get") and gs.get("follower_manager") != null:
		fm = gs.get("follower_manager")
	if fm == null or not fm.has_method("can_add") or not fm.can_add():
		_toast("护卫栏已满")
		return
	var inv = player.inventory as WeaponInventory
	if inv == null:
		return
	var cw = preload("res://scripts/weapons/companion_weapon.gd").new()
	cw.weapon_name = "护卫"
	# equip_weapon() emits weapon_equipped -> GameScene spawns the linked follower.
	inv.equip_weapon(cw)
	_toast("装备护卫武器")


func _get_item_texture_path() -> String:
	match item_type:
		ItemType.POTION: return "res://assets/pixel/item_potion.png"
		ItemType.WEAPON: return "res://assets/pixel/item_weapon.png"
		ItemType.ACCESSORY: return "res://assets/pixel/item_accessory.png"
		ItemType.PARTS: return "res://assets/pixel/item_parts.png"
		ItemType.COMPANION: return "res://assets/pixel/item_companion.png"
		_: return "res://assets/pixel/item_potion.png"
