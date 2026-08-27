## Pickup item — dropped by zombies.
## Now stores items in the storage box instead of auto-equipping.
## Player manages loadout at the between-floor shop screen.
class_name PickupItem
extends Area2D

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const WeaponRegistry = preload("res://scripts/systems/weapon_registry.gd")
const AccessoryRegistry = preload("res://scripts/systems/accessory_registry.gd")
const StorageBox = preload("res://scripts/systems/storage_box.gd")

enum ItemType { POTION, WEAPON, ACCESSORY, PARTS, COMPANION }

@export var item_type: ItemType = ItemType.POTION
@export var rarity: int = 0
@export var limb: LimbSlot = null
var accessory_data: AccessoryData = null

var _collected: bool = false


func _ready() -> void:
	_setup_collision()
	connect("body_entered", _on_body_entered)
	_setup_visuals()
	add_to_group("drop")


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
	var ring = Sprite2D.new()
	ring.name = "RarityRing"
	ring.texture = PixelLoader.load_texture("res://assets/pixel/rarity_ring.png")
	if ring.texture != null:
		var rt := 28.0
		ring.scale = Vector2(rt / ring.texture.get_width(), rt / ring.texture.get_height())
		var ring_colors := [
			Color(0.6, 0.6, 0.65, 1.0),
			Color(1.0, 0.85, 0.2, 1.0),
			Color(0.3, 0.6, 1.0, 1.0),
			Color(0.85, 0.35, 1.0, 1.0),
		]
		ring.modulate = ring_colors[rarity] if rarity < ring_colors.size() else Color.WHITE
	add_child(ring)

	var spr = Sprite2D.new()
	spr.texture = PixelLoader.load_texture(_get_item_texture_path())
	spr.name = "Visual"
	if spr.texture != null:
		var target := 18.0
		spr.scale = Vector2(target / spr.texture.get_width(), target / spr.texture.get_height())
	add_child(spr)
	if spr.texture != null:
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(spr, "position:y", -3.0, 0.6).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_property(spr, "position:y", 3.0, 0.6).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


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
			_store_weapon()
		ItemType.ACCESSORY:
			_store_accessory()
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


func _store_weapon() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats.is_alive():
		return
	var all = WeaponRegistry.get_all()
	all = all.filter(func(w): return w != null and w.weapon_path != "" and ResourceLoader.exists(w.weapon_path))
	if all.is_empty():
		return
	var data = all[randi() % all.size()]
	# Store in box instead of equipping
	var id = StorageBox.add_weapon(data)
	if id != "":
		_toast("获得武器：%s" % data.name)
	else:
		_toast("武器储物箱已满")


func _store_accessory() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats.is_alive():
		return
	if accessory_data == null:
		player.heal(player.stats.max_health * 0.1)
		return
	# Store in box instead of equipping
	var id = StorageBox.add_accessory(accessory_data)
	if id != "":
		_toast("获得配件：%s" % accessory_data.name)
	else:
		_toast("配件储物箱已满")


func _use_parts() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	if player.behavior:
		player.behavior.on_parts_pickup(self)
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
	var target_slot: int = -1
	if pm.can_equip(limb.slot_type) and pm.get_limb(limb.slot_type) == null:
		target_slot = limb.slot_type
	else:
		for s in valid_slots:
			if pm.get_limb(s) == null:
				target_slot = s
				break
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


func _get_item_texture_path() -> String:
	match item_type:
		ItemType.POTION: return "res://assets/pixel/item_potion.png"
		ItemType.WEAPON: return "res://assets/pixel/item_weapon.png"
		ItemType.ACCESSORY: return "res://assets/pixel/item_accessory.png"
		ItemType.PARTS: return "res://assets/pixel/item_parts.png"
		ItemType.COMPANION: return "res://assets/pixel/item_companion.png"
		_: return "res://assets/pixel/item_potion.png"
