class_name WeaponRifle
extends WeaponBase

func _init() -> void:
	weapon_name = "精准步枪"
	attack_type = GameEnums.AttackType.RANGED
	weapon_category = GameEnums.WeaponCategory.LIGHT_RANGED
	weapon_weight = 2
	damage = 25.0
	fire_rate = 6.0
	range = 400.0
	crit_chance = 0.25
	crit_multiplier = 2.5
	pierce = 2
	fire_mode = GameEnums.FireMode.SEMI
	magazine_size = 8
	current_ammo = 8
	reload_time = 1.4


func fire() -> void:
	var dir := _get_attack_direction()
	var proj = preload("res://scenes/gameplay/bullet.tscn").instantiate()
	proj.position = owner.global_position
	proj.direction = dir
	proj.damage = get_final_damage()
	proj.range = range
	proj.pierce = pierce
	proj.splash_radius = splash_radius
	proj.effect = effect
	proj.effect_duration = effect_duration
	get_tree().current_scene.add_child(proj)
