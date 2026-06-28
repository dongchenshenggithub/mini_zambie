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
