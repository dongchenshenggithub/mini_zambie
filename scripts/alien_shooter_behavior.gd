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
