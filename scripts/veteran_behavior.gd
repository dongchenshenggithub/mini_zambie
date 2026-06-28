## Behavior for Veteran — balanced, self-healing.
class_name VeteranBehavior
extends HumanBehavior


func on_player_take_damage(amount: float) -> void:
	super.on_player_take_damage(amount)
	if character_entry:
		owner.heal(character_entry.heal_rate * 0.05)
