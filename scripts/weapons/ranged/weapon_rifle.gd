class_name WeaponRifle
extends WeaponBase

func _init() -> void:
	weapon_name = "精准步枪"
	attack_type = GameEnums.AttackType.RANGED
	weapon_category = GameEnums.WeaponCategory.LIGHT_RANGED
	weapon_weight = 2
	damage = 25.0
	fire_rate = 0.8
	range = 400.0
	crit_chance = 0.25
	crit_multiplier = 2.5
	pierce = 2


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
