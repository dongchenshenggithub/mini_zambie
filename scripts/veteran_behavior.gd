## Behavior for Veteran — balanced, self-healing.
class_name VeteranBehavior
extends HumanBehavior


func on_player_take_damage(amount: float) -> void:
	super.on_player_take_damage(amount)
	if character_entry:
		owner.heal(character_entry.heal_rate * 0.05)


func on_floor_clear(_floor: int) -> void:
	# Veteran steadies between floors with a solid self-heal.
	if owner and owner.stats.is_alive():
		owner.heal(owner.stats.max_health * 0.25)
