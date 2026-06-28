class_name ZombieSelfDestruct
extends ZombieBase

func _ready() -> void:
	zombie_type = GameEnums.ZombieType.SELF_DESTRUCT
	super._ready()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist < 30.0:
			explode()


func explode() -> void:
	if target_player:
		target_player.take_damage(50.0)
		# Splash damage
		for zombie in get_tree().get_nodes_in_group("zombie"):
			var z = zombie as ZombieBase
			if z and z.global_position.distance_to(global_position) < 100.0:
				z.take_damage(30.0)
	queue_free()
