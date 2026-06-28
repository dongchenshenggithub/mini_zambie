class_name WeaponMechDog
extends WeaponBase

var _dog: Node2D = null

func _init() -> void:
	weapon_name = "机械狗"
	attack_type = GameEnums.AttackType.SUMMON
	weapon_category = GameEnums.WeaponCategory.SUMMON
	weapon_weight = 2
	damage = 10.0
	fire_rate = 2.5
	range = 120.0


func fire() -> void:
	if _dog == null:
		_dog = preload("res://scripts/entities/summon/summon_unit.gd").new()
		_dog.owner_node = owner
		_dog.damage = get_final_damage()
		_dog.range = range
		_dog.follow_owner = true
		get_tree().current_scene.add_child(_dog)
