class_name WeaponTurret
extends WeaponBase

var _turret: Node2D = null

func _init() -> void:
	weapon_name = "哨戒炮"
	attack_type = GameEnums.AttackType.SUMMON
	weapon_category = GameEnums.WeaponCategory.SUMMON
	weapon_weight = 3
	damage = 15.0
	fire_rate = 2.0
	range = 200.0


func fire() -> void:
	if _turret == null:
		_turret = preload("res://scripts/entities/summon/summon_unit.gd").new()
		_turret.owner_node = owner
		_turret.damage = get_final_damage()
		_turret.range = range
		_turret.follow_owner = false
		_turret.position = owner.position + Vector2(range, 0)
		get_tree().current_scene.add_child(_turret)
