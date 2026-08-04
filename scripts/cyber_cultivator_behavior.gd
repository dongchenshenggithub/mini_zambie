## Behavior for Cyber Cultivator — throw melee weapons remotely.
class_name CyberCultivatorBehavior
extends HumanBehavior


func on_weapon_pickup(weapon: WeaponBase) -> void:
	# Cyber cultivator can only use melee-type weapons
	if weapon.attack_type != GameEnums.AttackType.MELEE:
		print("Cyber Cultivator cannot use %s — only melee weapons" % weapon.weapon_name)
		weapon.queue_free()


func on_physics_process(delta: float) -> void:
	# Qi regen — steady self-healing over time.
	if owner and owner.stats.is_alive():
		owner.heal(3.0 * delta)


func on_level_up(_new_level: int) -> void:
	# Cultivator converts breakthroughs into vitality.
	if owner and owner.stats.is_alive():
		owner.heal(owner.stats.max_health * 0.15)
