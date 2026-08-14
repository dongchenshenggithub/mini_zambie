## Behavior for Cat Cafe Worker — many followers, low damage.
class_name CatCafeWorkerBehavior
extends HumanBehavior

const FollowerManagerScript = preload("res://scripts/systems/follower_manager.gd")


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
	# Each floor, recruit another cafe cat ally (respects max_followers cap).
	_spawn_cat_ally()


func _spawn_cat_ally() -> void:
	if owner == null:
		return
	# Route through the unified FollowerManager so the per-character cap
	# (max_followers=8 for cat cafe worker, NOT the old hardcoded 6) is
	# enforced and current_followers stays accurate.
	var tree = owner.get_tree()
	if tree == null:
		return
	var gs = tree.current_scene
	if gs and gs.has_method("get") and gs.get("follower_manager") != null:
		var fm = gs.get("follower_manager") as FollowerManagerScript
		if fm:
			fm.try_add_follower(3)  # 3 = CharacterClass.CAT_CAFE_WORKER
