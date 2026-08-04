## Behavior for Cat Cafe Worker — many followers, low damage.
class_name CatCafeWorkerBehavior
extends HumanBehavior


func on_level_up(new_level: int) -> void:
	# Cat cafe worker gains follower slots faster
	if owner and owner.inventory:
		var bonus_slots = int(new_level / 5)
		if bonus_slots > 0:
			owner.inventory.add_follower_slot(bonus_slots)


func on_weapon_pickup(weapon: WeaponBase) -> void:
	# Cat cafe worker has reduced weapon effectiveness
	if weapon:
		weapon.damage *= 0.8


func on_floor_clear(_floor: int) -> void:
	# Each floor, recruit another cafe cat ally (capped).
	_spawn_cat_ally()


func _spawn_cat_ally() -> void:
	if owner == null:
		return
	var tree = owner.get_tree()
	if tree.get_nodes_in_group("summon").size() >= 6:
		return
	var cat = preload("res://scripts/entities/summon/summon_unit.gd").new()
	cat.owner_node = owner
	cat.damage = 15.0
	cat.range = 220.0
	cat.global_position = owner.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	tree.current_scene.add_child(cat)
