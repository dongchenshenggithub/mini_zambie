class_name WeaponElectric
extends WeaponBase

func _init() -> void:
	weapon_name = "电磁步枪"
	attack_type = GameEnums.AttackType.RANGED
	weapon_category = GameEnums.WeaponCategory.HEAVY_RANGED
	weapon_weight = 4
	damage = 18.0
	fire_rate = 4.0
	range = 300.0
	pierce = 5
	fire_mode = GameEnums.FireMode.AUTO
	magazine_size = 18
	current_ammo = 18
	reload_time = 2.4


func fire() -> void:
	var dir := _get_attack_direction()
	var bolt = preload("res://scenes/gameplay/electric_beam.tscn").instantiate()
	bolt.position = owner.global_position
	bolt.direction = dir
	bolt.damage = get_final_damage()
	bolt.range = range
	bolt.pierce = pierce
	get_tree().current_scene.add_child(bolt)
