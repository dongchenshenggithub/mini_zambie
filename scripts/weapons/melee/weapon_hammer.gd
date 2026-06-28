class_name WeaponHammer
extends WeaponBase

func _init() -> void:
	weapon_name = "战锤"
	attack_type = GameEnums.AttackType.MELEE
	weapon_category = GameEnums.WeaponCategory.HEAVY_MELEE_BLUNT
	weapon_weight = 6
	damage = 30.0
	fire_rate = 0.8
	range = 100.0


func fire() -> void:
	var owner_pos = owner.global_position
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var z = zombie as ZombieBase
		if z:
			var dist = z.global_position.distance_to(owner_pos)
			if dist <= range:
				z.take_damage(get_final_damage())
