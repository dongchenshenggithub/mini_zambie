class_name WeaponDualBlade
extends WeaponBase

func _init() -> void:
	weapon_name = "双刀"
	attack_type = GameEnums.AttackType.MELEE
	weapon_category = GameEnums.WeaponCategory.MELEE_SHARP
	weapon_weight = 2
	damage = 8.0
	fire_rate = 6.0
	range = 70.0
	effect = GameEnums.StatusEffect.BLEED
	effect_duration = 2.0


func fire() -> void:
	var owner_pos = owner.global_position
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var z = zombie as ZombieBase
		if z:
			var dist = z.global_position.distance_to(owner_pos)
			if dist <= range:
				z.take_damage(get_final_damage())
				if effect != GameEnums.StatusEffect.NONE:
					z.apply_status(effect, effect_duration)
				if owner:
					owner.heal(get_final_damage() * 0.1)
