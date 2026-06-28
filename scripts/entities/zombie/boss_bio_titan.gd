## Boss 2: 生化泰坦
class_name BossBioTitan
extends ZombieBoss

var _shield_active: bool = true


func _ready() -> void:
	zombie_type = GameEnums.ZombieType.BOSS_BIO_TITAN
	super._ready()
	_special_attack_rate = 6.0


func _special_attack() -> void:
	match current_phase:
		1:
			_summon_soldiers()
		2:
			_earthquake()
			_summon_soldiers()
		3:
			_earthquake()
			_summon_soldiers()
			_activate_shield()


func _summon_soldiers() -> void:
	var scene = get_tree().current_scene
	if scene:
		var data = ZombieRegistry.get_data("elite_mecha_soldier")
		if data:
			for i in range(2):
				var instance = data.zombie_script.new()
				instance.global_position = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
				scene.add_child(instance)


func _earthquake() -> void:
	"""AoE damage in a ring around the boss."""
	var target = get_tree().get_first_node_in_group("player") as Player
	if target:
		var dist = global_position.distance_to(target.global_position)
		if dist < 300.0:
			target.take_damage(current_damage * 0.5)


func _activate_shield() -> void:
	pass
