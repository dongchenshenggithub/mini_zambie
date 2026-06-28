## Player stats — HP, speed, armor, damage modifiers, limb bonuses.
class_name PlayerStats
extends Resource

@export var max_health: float = 100.0
@export var movement_speed: float = 200.0
@export var armor: int = 0

@export_range(0.0, 3.0) var damage_multiplier_ranged: float = 1.0
@export_range(0.0, 3.0) var damage_multiplier_melee: float = 1.0
@export_range(0.0, 3.0) var damage_multiplier_summon: float = 1.0
@export_range(0.0, 3.0) var damage_multiplier_spray: float = 1.0
@export_range(0.0, 3.0) var damage_multiplier_laser: float = 1.0

@export var self_heal_rate: float = 0.0

var limb_damage_bonus: float = 0.0
var limb_health_bonus: float = 0.0
var limb_speed_bonus: float = 0.0
var limb_armor_bonus: int = 0
var limb_crit_bonus: float = 0.0

var current_health: float = 0.0
var _last_heal_time: float = 0.0


func _init() -> void:
	current_health = max_health


func get_damage_multiplier(atk_type: GameEnums.AttackType) -> float:
	var mult: float = 1.0
	match atk_type:
		GameEnums.AttackType.RANGED: mult = damage_multiplier_ranged
		GameEnums.AttackType.MELEE: mult = damage_multiplier_melee
		GameEnums.AttackType.SUMMON: mult = damage_multiplier_summon
		GameEnums.AttackType.SPRAY: mult = damage_multiplier_spray
		GameEnums.AttackType.LASER: mult = damage_multiplier_laser
	mult += limb_damage_bonus
	return mult


func get_crit_bonus() -> float:
	return limb_crit_bonus


func _physics_process(delta: float) -> void:
	if self_heal_rate > 0.0 and current_health < max_health + limb_health_bonus:
		_last_heal_time += delta
		if _last_heal_time >= 1.0:
			_last_heal_time = 0.0
			heal(self_heal_rate)


func take_damage(amount: float) -> float:
	var actual_damage = maxf(1.0, amount - armor - limb_armor_bonus)
	current_health = maxi(0.0, current_health - actual_damage)
	return actual_damage


func heal(amount: float) -> void:
	current_health = minf(max_health + limb_health_bonus, current_health + amount)


func is_alive() -> bool:
	return current_health > 0.0
