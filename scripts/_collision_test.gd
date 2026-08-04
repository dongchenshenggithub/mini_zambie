extends SceneTree

func _init() -> void:
	# Minimal world with one zombie and one bullet fired into it.
	var world := Node2D.new()
	get_root().add_child(world)

	var ZombieBaseScript = load("res://scripts/entities/zombie/zombie_base.gd")
	var z = ZombieBaseScript.new()
	z.zombie_type = GameEnums.ZombieType.NORMAL  # base_health 50
	z.global_position = Vector2(200, 200)
	world.add_child(z)
	await physics_frame
	await physics_frame

	var ProjectileScript = load("res://scripts/projectiles/projectile_base.gd")
	var p = ProjectileScript.new()
	p.direction = Vector2.RIGHT
	p.speed = 400.0
	p.damage = 100.0          # More than enough to kill (50 hp)
	p.range = 9999.0
	p.global_position = Vector2(150, 200)  # 50px left of zombie, flies in
	world.add_child(p)

	# Let the bullet travel into the zombie and the area detect the overlap.
	for i in range(30):
		await physics_frame

	var dead := not is_instance_valid(z)
	if dead:
		print("COLLISION_TEST PASS: zombie killed by bullet")
	elif z.current_health < 50.0:
		print("COLLISION_TEST PASS: zombie took damage (hp=%s)" % z.current_health)
	else:
		print("COLLISION_TEST FAIL: zombie hp unchanged (%s), bullet alive=%s pos=%s" % [z.current_health, is_instance_valid(p), (p.global_position if is_instance_valid(p) else Vector2.ZERO)])
	quit()
