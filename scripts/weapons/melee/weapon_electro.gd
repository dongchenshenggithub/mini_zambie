class_name WeaponElectro
extends WeaponBase

func _init() -> void:
	weapon_name = "电击棒"
	attack_type = GameEnums.AttackType.MELEE
	weapon_category = GameEnums.WeaponCategory.MELEE_BLUNT
	weapon_weight = 3
	damage = 12.0
	fire_rate = 1.5
	range = 80.0
	effect = GameEnums.StatusEffect.STUN
	effect_duration = 1.5


func fire() -> void:
	var owner_pos = owner.global_position
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var z = zombie as ZombieBase
		if z:
			var dist = z.global_position.distance_to(owner_pos)
			if dist <= range:
				z.take_damage(get_final_damage())
				z.apply_knockback((z.global_position - owner_pos).normalized() * 200.0)
