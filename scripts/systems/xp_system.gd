## Manages XP, leveling, and upgrade generation.
class_name XPSystem
extends Node

signal leveled_up(new_level: int)
signal xp_gained(amount: int)

var current_xp: int = 0
var total_xp: int = 0
var level: int = 1
var xp_to_next_level: int = 50


func _ready() -> void:
	add_to_group("xp_system")


func gain_xp(amount: int) -> void:
	current_xp += amount
	total_xp += amount
	xp_gained.emit(amount)

	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level += 1
		xp_to_next_level = int(xp_to_next_level * 1.3)
		leveled_up.emit(level)
		Game.current_level = level


func get_xp_progress() -> float:
	if xp_to_next_level <= 0:
		return 1.0
	return float(current_xp) / float(xp_to_next_level)


func is_max_level() -> bool:
	return level >= 50
