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

## Accessory (装备) bonus accumulators. Filled by PickupItem._equip_accessory()
## and re-added every recompute so they survive the per-level-up recompute.
var accessory_armor_bonus: int = 0
var accessory_speed_bonus: float = 0.0
var accessory_ranged_mult: float = 0.0
var accessory_melee_mult: float = 0.0
var accessory_laser_mult: float = 0.0
var accessory_summon_mult: float = 0.0
var accessory_spray_mult: float = 0.0
var accessory_crit_bonus: float = 0.0

## Base crit bonus derived from the 幸运 (luck) attribute via Player.recompute_combat_stats().
var crit_bonus: float = 0.0

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
	return limb_crit_bonus + crit_bonus


## Effective movement speed including any equipped prosthetic leg bonuses.
## Previously limb_speed_bonus existed but was never applied, so leg prosthetics
## had no effect on actual movement — this fixes that.
func get_movement_speed() -> float:
	return movement_speed + limb_speed_bonus


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
