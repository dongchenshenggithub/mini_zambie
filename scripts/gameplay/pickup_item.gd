## Pickup item — dropped by zombies, auto-collected by follower.
class_name PickupItem
extends Area2D

enum ItemType { POTION, WEAPON, ACCESSORY, PARTS }

@export var item_type: ItemType = ItemType.POTION
@export var rarity: int = 0  # 0=common, 1=uncommon, 2=rare, 3=epic


func _ready() -> void:
	connect("body_entered", _on_body_entered)
	_setup_visuals()


func _setup_visuals() -> void:
	var colors := [Color(0.8, 0.2, 0.2, 1.0), Color(0.8, 0.6, 0.2, 1.0), Color(0.2, 0.4, 0.8, 1.0), Color(0.8, 0.2, 0.8, 1.0)]
	var vis = ColorRect.new()
	vis.position = Vector2(-5, -5)
	vis.size = Vector2(10, 10)
	vis.color = colors[rarity] if rarity < colors.size() else Color.WHITE
	vis.name = "Visual"
	add_child(vis)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_on_pickup()
		queue_free()


func _on_pickup() -> void:
	match item_type:
		ItemType.POTION:
			_use_potion()
		ItemType.WEAPON:
			_equip_weapon()
		ItemType.ACCESSORY:
			_equip_accessory()
		ItemType.PARTS:
			_use_parts()


func _use_potion() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player or not player.stats.is_alive():
		return
	match rarity:
		0: player.heal(player.stats.max_health * 0.1)
		1: player.heal(player.stats.max_health * 0.15)
		2: player.heal(player.stats.max_health * 0.2)


func _equip_weapon() -> void:
	pass  # Handled in game scene


func _equip_accessory() -> void:
	pass  # Handled in game scene


func _use_parts() -> void:
	"""Repair weapon durability or heal mech monk."""
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	if player.character_data and player.character_data.character_class == 1:
		player.heal(player.stats.max_health * 0.05)
	else:
		for weapon in player.inventory.weapons:
			if weapon.durability < 100.0:
				weapon.repair(20.0)
				break
