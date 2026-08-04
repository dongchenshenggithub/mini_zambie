## Boss 4: C国实验体α — hardest boss
class_name BossExperimentAlpha
extends ZombieBoss


func _ready() -> void:
	zombie_type = GameEnums.ZombieType.BOSS_EXPERIMENT_ALPHA
	super._ready()
	_special_attack_rate = 4.0


func _physics_process(delta: float) -> void:
	if _reverse_timer > 0:
		_reverse_timer -= delta
	super._physics_process(delta)


func take_damage(amount: float) -> void:
	if _reverse_timer > 0:
		super.take_damage(amount * 0.5)
	else:
		super.take_damage(amount)


func _special_attack() -> void:
	match current_phase:
		1:
			_laser_scan()
			_summon_mecha()
		2:
			_laser_scan()
			_summon_mecha()
			_reverse_shield()
		3:
			_laser_scan()
			_summon_mecha()
			_reverse_shield()
			_speed_boost()


func _laser_scan() -> void:
	"""Full screen laser scan — instant damage if in line of fire."""
	var target = get_tree().get_first_node_in_group("player") as Player
	if target:
		target.take_damage(current_damage * 0.3)


func _summon_mecha() -> void:
	var scene = get_tree().current_scene
	if scene:
		var data = ZombieRegistry.get_data("mecha_mutant")
		if data:
			for i in range(2):
				var instance = data.zombie_script.new()
				instance.global_position = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
				scene.add_child(instance)


func _reverse_shield() -> void:
	_reverse_timer = 6.0
	_spawn_puff(Color(1.0, 0.3, 0.3, 0.6), 110.0)


var _reverse_timer: float = 0.0


func _speed_boost() -> void:
	current_speed = base_speed * 1.5
