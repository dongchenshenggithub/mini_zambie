class_name WeaponWaterJet
extends WeaponBase

func _init() -> void:
	weapon_name = "高压水枪"
	attack_type = GameEnums.AttackType.SPRAY
	weapon_category = GameEnums.WeaponCategory.SPRAY_EFFECT
	weapon_weight = 3
	damage = 10.0
	fire_rate = 2.5
	range = 130.0
	effect = GameEnums.StatusEffect.KNOCKBACK
	effect_duration = 0.5


func fire() -> void:
	var owner_pos = owner.global_position
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var z = zombie as ZombieBase
		if z:
			var dist = z.global_position.distance_to(owner_pos)
			if dist <= range:
				z.take_damage(get_final_damage())
				var dir = (z.global_position - owner_pos).normalized()
				z.apply_knockback(dir * 300.0)
