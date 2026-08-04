class_name WeaponDrone
extends WeaponBase

var _drone: Node2D = null

func _init() -> void:
	weapon_name = "无人机"
	attack_type = GameEnums.AttackType.SUMMON
	weapon_category = GameEnums.WeaponCategory.SUMMON
	weapon_weight = 2
	damage = 5.0
	fire_rate = 3.0
	range = 250.0
	auto_fire = false
	fire_mode = GameEnums.FireMode.SEMI


func fire() -> void:
	if _drone == null:
		_drone = preload("res://scripts/entities/summon/summon_unit.gd").new()
		_drone.owner_node = owner
		_drone.damage = get_final_damage()
		_drone.range = range
		_drone.follow_owner = true
		get_tree().current_scene.add_child(_drone)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	# Autonomous summon: deploy once on its own, no player input needed.
	if _drone == null and weapon_owner != null and weapon_owner.stats.is_alive():
		fire()
	if _drone and _drone.is_inside_tree():
		_drone._physics_process(delta)
