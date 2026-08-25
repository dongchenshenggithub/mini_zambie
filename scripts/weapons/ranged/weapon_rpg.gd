class_name WeaponRPG
extends WeaponBase

func _init() -> void:
	weapon_name = "火箭炮"
	attack_type = GameEnums.AttackType.RANGED
	weapon_category = GameEnums.WeaponCategory.HEAVY_RANGED
	weapon_weight = 5
	damage = 60.0
	fire_rate = 0.8
	range = 350.0
	splash_radius = 80.0
	fire_mode = GameEnums.FireMode.SEMI
	magazine_size = 3
	current_ammo = 3
	reload_time = 3.2


func fire() -> void:
	var dir := _get_attack_direction()
	var rocket = preload("res://scenes/gameplay/rocket.tscn").instantiate()
	rocket.position = owner.global_position
	rocket.direction = dir
	rocket.damage = get_final_damage()
	rocket.range = range
	rocket.splash_radius = splash_radius
	rocket.effect = effect
	rocket.effect_duration = effect_duration
	get_tree().current_scene.add_child(rocket)
