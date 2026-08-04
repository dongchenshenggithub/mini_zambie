## Boss 3: 纳米核心
class_name BossNanoCore
extends ZombieBoss


func _ready() -> void:
	zombie_type = GameEnums.ZombieType.BOSS_NANO_CORE
	super._ready()
	_special_attack_rate = 4.0


func _special_attack() -> void:
	match current_phase:
		1:
			_nano_swarm()
		2:
			_split()
			_nano_swarm()
		3:
			_split()
			_nano_swarm()
			_absorb_zombies()


func _nano_swarm() -> void:
	var target = get_tree().get_first_node_in_group("player") as Player
	if target and global_position.distance_to(target.global_position) < 280.0:
		target.take_damage(current_damage * 0.3)
	_spawn_puff(Color(0.6, 0.9, 1.0, 0.6), 110.0)


func _split() -> void:
	"""Splits into 2 mini nanomites."""
	var scene = get_tree().current_scene
	if scene:
		for i in range(2):
			var m = preload("res://scripts/entities/zombie/zombie_nanomite.gd").new()
			m.global_position = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
			scene.add_child(m)


func _absorb_zombies() -> void:
	"""Absorbs nearby zombies to heal."""
	var healed = 0.0
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var z = zombie as ZombieBase
		if z and z.global_position.distance_to(global_position) < 200.0:
			healed += 10.0
	current_health = minf(base_health, current_health + healed)
