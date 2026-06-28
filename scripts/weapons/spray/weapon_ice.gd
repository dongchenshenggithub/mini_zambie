class_name WeaponIce
extends WeaponBase

func _init() -> void:
	weapon_name = "冰冻喷射器"
	attack_type = GameEnums.AttackType.SPRAY
	weapon_category = GameEnums.WeaponCategory.SPRAY_EFFECT
	weapon_weight = 4
	damage = 4.0
	fire_rate = 3.0
	range = 120.0
	effect = GameEnums.StatusEffect.FREEZE
	effect_duration = 2.0


func fire() -> void:
	var owner_pos = owner.global_position
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var z = zombie as ZombieBase
		if z:
			var dist = z.global_position.distance_to(owner_pos)
			if dist <= range:
				z.take_damage(get_final_damage())
				z.apply_status(GameEnums.StatusEffect.FREEZE, effect_duration)
