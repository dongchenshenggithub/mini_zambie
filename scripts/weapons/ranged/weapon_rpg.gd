class_name WeaponRPG
extends WeaponBase

func _init() -> void:
	weapon_name = "火箭炮"
	attack_type = GameEnums.AttackType.RANGED
	weapon_category = GameEnums.WeaponCategory.HEAVY_RANGED
	weapon_weight = 5
	damage = 60.0
	fire_rate = 0.25
	range = 350.0
	splash_radius = 80.0


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
