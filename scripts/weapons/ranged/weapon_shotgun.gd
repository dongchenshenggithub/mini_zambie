class_name WeaponShotgun
extends WeaponBase

func _init() -> void:
	weapon_name = "霰弹枪"
	attack_type = GameEnums.AttackType.RANGED
	weapon_category = GameEnums.WeaponCategory.LIGHT_RANGED
	weapon_weight = 3
	damage = 12.0
	fire_rate = 1.2
	range = 150.0
	fire_mode = GameEnums.FireMode.SEMI
	magazine_size = 6
	current_ammo = 6
	reload_time = 2.2


func fire() -> void:
	var dir := _get_attack_direction()
	var pellets := 6
	var spread_angle := 0.5
	for i in range(pellets):
		var angle = -spread_angle / 2.0 + (spread_angle / float(pellets - 1)) * i
		var proj = preload("res://scenes/gameplay/bullet.tscn").instantiate()
		proj.position = owner.global_position
		proj.direction = dir.rotated(angle)
		proj.damage = get_final_damage()
		proj.range = range
		get_tree().current_scene.add_child(proj)
