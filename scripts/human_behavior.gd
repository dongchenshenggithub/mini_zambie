## Default behavior for human characters.
class_name HumanBehavior
extends CharacterBehavior


func on_player_take_damage(amount: float) -> void:
	if not owner or not owner.stats.is_alive():
		return
	if character_entry and character_entry.can_heal_self and character_entry.heal_rate > 0.0:
		owner.heal(character_entry.heal_rate * 0.1)
