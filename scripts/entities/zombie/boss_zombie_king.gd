## Boss 1: 尸王·零号病人
class_name BossZombieKing
extends ZombieBoss

var _spawn_timer: float = 0.0


func _ready() -> void:
	zombie_type = GameEnums.ZombieType.BOSS_ZOMBIE_KING
	super._ready()
	_special_attack_rate = 5.0


func _special_attack() -> void:
	match current_phase:
		1:
			_spawn_minions()
		2:
			_spawn_minions()
			_release_poison_cloud()
		3:
			_spawn_minions()
			_release_poison_cloud()
			_fullscreen_charge()


func _spawn_minions() -> void:
	var scene = get_tree().current_scene
	if scene:
		var data = ZombieRegistry.get_data("normal")
		if data:
			for i in range(2):
				var instance = data.zombie_script.new()
				instance.global_position = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
				scene.add_child(instance)


func _release_poison_cloud() -> void:
	var target = get_tree().get_first_node_in_group("player") as Player
	if target and global_position.distance_to(target.global_position) < 250.0:
		target.take_damage(current_damage * 0.25)
	_spawn_puff(Color(0.4, 0.9, 0.2, 0.6), 90.0)


func _fullscreen_charge() -> void:
	var target = get_tree().get_first_node_in_group("player") as Player
	if target:
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * 300.0
		move_and_slide()
