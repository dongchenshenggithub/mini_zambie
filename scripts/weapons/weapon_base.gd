## Base class for all weapons. Handles fire rate, damage calculation, cooldown, and durability.
class_name WeaponBase
extends Node2D

@export var weapon_name: String = "Weapon"
@export var damage: float = 10.0
@export var fire_rate: float = 1.0
@export var range: float = 200.0
@export var attack_type: GameEnums.AttackType = GameEnums.AttackType.RANGED
@export var weapon_category: GameEnums.WeaponCategory = GameEnums.WeaponCategory.LIGHT_RANGED
@export var weapon_weight: int = 2

@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0
@export var pierce: int = 0
@export var splash_radius: float = 0.0
@export var effect: GameEnums.StatusEffect = GameEnums.StatusEffect.NONE
@export var effect_duration: float = 0.0

var _fire_cooldown: float = 0.0
var durability: float = 100.0
var durability_decay_rate: float = 1.0  # % per minute
var weapon_owner: Player = null
var equipped_weapon_index: int = 0

var _durability_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if weapon_owner == null or not weapon_owner.stats.is_alive():
		return
	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		try_fire(delta)
		_fire_cooldown = 1.0 / fire_rate

	# Durability decay: 1% per minute
	_durability_timer += delta
	if _durability_timer >= 60.0:
		_durability_timer = 0.0
		durability -= durability_decay_rate


func try_fire(_delta: float) -> void:
	if weapon_owner == null or not weapon_owner.stats.is_alive() or durability <= 0:
		return
	fire()
	_fire_cooldown = 1.0 / fire_rate


func fire() -> void:
	pass


func take_damage_from_zombie() -> void:
	durability -= 10.0


func get_final_damage() -> float:
	if weapon_owner == null:
		return damage
	var stats = weapon_owner.stats as PlayerStats
	var mult = stats.get_damage_multiplier(attack_type)
	var inv = weapon_owner.inventory as WeaponInventory
	if inv:
		mult *= inv.calculate_build_bonus()
	var final = damage * mult
	if randf() < crit_chance:
		final *= crit_multiplier
	return final


func apply_upgrade(upgrade_type: String, value: float) -> void:
	match upgrade_type:
		"damage":
			damage *= (1.0 + value)
		"fire_rate":
			fire_rate *= (1.0 + value)
		"range":
			range *= (1.0 + value)
		"pierce":
			pierce = int(pierce + value)
		"crit_chance":
			crit_chance = minf(0.8, crit_chance + value)
		"splash_radius":
			splash_radius += value
		"effect_duration":
			effect_duration += value


func repair(amount: float) -> void:
	durability = minf(100.0, durability + amount)
