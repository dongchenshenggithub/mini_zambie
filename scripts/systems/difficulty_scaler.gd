## Dynamically scales difficulty based on player level and wave.
class_name DifficultyScaler
extends Node

@export var base_zombie_health_scale: float = 1.15
@export var base_zombie_speed_scale: float = 1.05
@export var base_zombie_damage_scale: float = 1.10


func scale_zombie_stats(base_health: float, base_speed: float, base_damage: float, wave: int) -> Dictionary:
	var health = base_health * pow(base_zombie_health_scale, wave - 1)
	var speed = base_speed * pow(base_zombie_speed_scale, wave - 1)
	var damage = base_damage * pow(base_zombie_damage_scale, wave - 1)
	return {"health": health, "speed": speed, "damage": damage}
