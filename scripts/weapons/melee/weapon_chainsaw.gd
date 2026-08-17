class_name WeaponChainsaw
extends WeaponBase

func _init() -> void:
	weapon_name = "链锯剑"
	attack_type = GameEnums.AttackType.MELEE
	weapon_category = GameEnums.WeaponCategory.MELEE_SHARP
	weapon_weight = 2
	damage = 15.0
	fire_rate = 4.0
	range = 60.0
	effect = GameEnums.StatusEffect.BLEED
	effect_duration = 3.0


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
