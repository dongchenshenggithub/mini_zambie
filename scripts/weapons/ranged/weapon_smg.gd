class_name WeaponSMG
extends WeaponBase

func _init() -> void:
	weapon_name = "冲锋枪"
	attack_type = GameEnums.AttackType.RANGED
	weapon_category = GameEnums.WeaponCategory.LIGHT_RANGED
	weapon_weight = 2
	damage = 8.0
	fire_rate = 8.0
	range = 250.0
	splash_radius = 15.0


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


func _get_attack_direction() -> Vector2:
	var nearest := _find_nearest_zombie()
	if nearest:
		return (nearest.global_position - owner.global_position).normalized()
	return Vector2.RIGHT


func _find_nearest_zombie() -> Node2D:
	var scene = get_tree().current_scene
	if not scene:
		return null
	var closest: Node2D = null
	var closest_dist := INF
	for child in scene.get_children():
		if child is ZombieBase:
			var dist = child.global_position.distance_to(owner.global_position)
			if dist < closest_dist and dist <= range:
				closest_dist = dist
				closest = child
	return closest
