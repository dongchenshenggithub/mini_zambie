class_name WeaponSMG
extends WeaponBase

func _init() -> void:
	weapon_name = "冲锋枪"
	attack_type = GameEnums.AttackType.RANGED
	weapon_category = GameEnums.WeaponCategory.LIGHT_RANGED
	weapon_weight = 2
	damage = 8.0
	fire_rate = 11.0
	range = 250.0
	splash_radius = 15.0
	fire_mode = GameEnums.FireMode.AUTO
	magazine_size = 32
	current_ammo = 32
	reload_time = 1.9


func fire() -> void:
	var dir := _get_attack_direction()
	var spread := 0.15
	for _i in range(3):
		var proj = preload("res://scenes/gameplay/bullet.tscn").instantiate()
		proj.position = owner.global_position
		proj.direction = dir.rotated(randf_range(-spread, spread))
		proj.damage = get_final_damage()
		proj.range = range
		proj.pierce = 0
		proj.splash_radius = splash_radius
		get_tree().current_scene.add_child(proj)
