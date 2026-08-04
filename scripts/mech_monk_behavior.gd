## Behavior for Mech Monk — disassemble weapons for HP, no self-healing.
class_name MechMonkBehavior
extends CharacterBehavior


func on_weapon_pickup(weapon: WeaponBase) -> void:
	# Mech monk cannot equip weapons — dismantle for HP instead
	if owner:
		var heal_amount = weapon.damage * 0.5
		owner.heal(owner.stats.max_health * heal_amount / 100.0)
		print("Mech Monk dismantled %s for %.0f HP" % [weapon.weapon_name, heal_amount])
		weapon.queue_free()


func on_parts_pickup(parts: Node2D) -> void:
	# Mech monk eats parts for small HP restore
	if owner:
		owner.heal(owner.stats.max_health * 0.05)


func on_potion_pickup(potion: Node2D) -> void:
	# Mech monk cannot use potions — ignore
	pass


func on_floor_clear(_floor: int) -> void:
	# Mech monk has no lifesteal, so a big floor-clear heal is its sustain.
	if owner and owner.stats.is_alive():
		owner.heal(owner.stats.max_health * 0.4)


func on_physics_process(delta: float) -> void:
	# Slow self-repair over time (tanky, no active healing otherwise).
	if owner and owner.stats.is_alive():
		owner.heal(2.0 * delta)
