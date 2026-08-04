## Behavior for Alien Shooter — glass cannon, consumes zombie flesh.
class_name AlienShooterBehavior
extends CharacterBehavior


func on_zombie_die(zombie: ZombieBase) -> void:
	# Alien shooter eats zombie flesh to heal
	if owner and character_entry and character_entry.heal_rate > 0.0:
		owner.heal(character_entry.heal_rate * 2.0)  # 2x healing from consumption


func on_weapon_pickup(weapon: WeaponBase) -> void:
	# Alien shooter has reduced melee damage
	if weapon.attack_type == GameEnums.AttackType.MELEE:
		weapon.damage *= 0.7


func on_floor_clear(_floor: int) -> void:
	# Glass cannon: opens each new floor with a destructive pulse.
	if owner == null:
		return
	for z in owner.get_tree().get_nodes_in_group("zombie"):
		var zb = z as ZombieBase
		if zb:
			zb.take_damage(50.0)


func on_level_up(_new_level: int) -> void:
	# Ramping ranged damage as the alien adapts.
	if owner and owner.stats.is_alive():
		owner.stats.damage_multiplier_ranged += 0.03
