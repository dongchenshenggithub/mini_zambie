class_name WeaponElectric
extends WeaponBase

func _init() -> void:
	weapon_name = "电磁步枪"
	attack_type = GameEnums.AttackType.RANGED
	weapon_category = GameEnums.WeaponCategory.HEAVY_RANGED
	weapon_weight = 4
	damage = 18.0
	fire_rate = 2.0
	range = 300.0
	pierce = 5


func fire() -> void:
	var dir := _get_attack_direction()
	var bolt = preload("res://scenes/gameplay/electric_beam.tscn").instantiate()
	bolt.position = owner.global_position
	bolt.direction = dir
	bolt.damage = get_final_damage()
	bolt.range = range
	bolt.pierce = pierce
	get_tree().current_scene.add_child(bolt)


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
