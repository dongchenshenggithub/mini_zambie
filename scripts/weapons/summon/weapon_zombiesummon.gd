class_name WeaponZombieSummon
extends WeaponBase

var _summoned: Node2D = null

func _init() -> void:
	weapon_name = "丧尸仆从"
	attack_type = GameEnums.AttackType.SUMMON
	weapon_category = GameEnums.WeaponCategory.SUMMON
	weapon_weight = 3
	damage = 20.0
	fire_rate = 1.0
	range = 100.0
	auto_fire = false
	fire_mode = GameEnums.FireMode.SEMI


func fire() -> void:
	if _summoned == null:
		_summoned = preload("res://scripts/entities/summon/summon_unit.gd").new()
		_summoned.owner_node = owner
		_summoned.damage = get_final_damage()
		_summoned.range = range
		_summoned.follow_owner = true
		get_tree().current_scene.add_child(_summoned)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Autonomous summon: deploy once on its own, no player input needed.
	if _summoned == null and weapon_owner != null and weapon_owner.stats.is_alive():
		fire()
