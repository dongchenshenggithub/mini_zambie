## Behavior for Cyber Cultivator — throw melee weapons remotely.
class_name CyberCultivatorBehavior
extends HumanBehavior


func on_weapon_pickup(weapon: WeaponBase) -> void:
	# Cyber cultivator can only use melee-type weapons
	if weapon.attack_type != GameEnums.AttackType.MELEE:
		print("Cyber Cultivator cannot use %s — only melee weapons" % weapon.weapon_name)
		weapon.queue_free()
