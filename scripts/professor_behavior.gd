## Behavior for Professor — laser specialization, turret placement.
class_name ProfessorBehavior
extends HumanBehavior


func on_weapon_pickup(weapon: WeaponBase) -> void:
	# Professor gets bonus damage on laser weapons
	if weapon and weapon.attack_type == GameEnums.AttackType.LASER:
		weapon.damage *= 1.5


func on_potion_pickup(potion: Node2D) -> void:
	# Professor gets bonus healing from potions
	if potion:
		pass  # Bonus handled in pickup_item.gd
