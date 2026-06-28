class_name WeaponShotgun
extends WeaponBase

func _init() -> void:
	weapon_name = "霰弹枪"
	attack_type = GameEnums.AttackType.RANGED
	weapon_category = GameEnums.WeaponCategory.LIGHT_RANGED
	weapon_weight = 3
	damage = 12.0
	fire_rate = 0.6
	range = 150.0


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
