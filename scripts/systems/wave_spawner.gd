## Wave spawner — manages zombie waves and difficulty scaling.
class_name WaveSpawner
extends Node

@export var spawn_interval: float = 1.5
@export var zombies_per_wave: int = 5
@export var max_zombies_on_screen: int = 30
@export var spawn_radius_min: float = 400.0
@export var spawn_radius_max: float = 600.0

var _spawn_timer: float = 0.0
var _wave_number: int = 0
var _is_waving: bool = false


signal wave_started(wave_num: int)
signal wave_cleared(wave_num: int)


func _physics_process(delta: float) -> void:
	if not _is_waving:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		var player = get_tree().get_first_node_in_group("player") as Player
		if player:
			var active = get_tree().get_nodes_in_group("zombie").size()
			if active < max_zombies_on_screen:
				spawn_wave()
		_spawn_timer = spawn_interval


func start_waving() -> void:
	_is_waving = true
	_wave_number = 0


func stop_waving() -> void:
	_is_waving = false


func spawn_wave() -> void:
	_wave_number += 1
	wave_started.emit(_wave_number)
	Game.advance_wave()

	var count = minf(zombies_per_wave + _wave_number, max_zombies_on_screen)
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	for i in range(count):
		var zombie_script = _select_zombie_type()
		if zombie_script:
			var instance = zombie_script.new()
			var angle = randf() * TAU
			var dist = randf_range(spawn_radius_min, spawn_radius_max)
			instance.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
			get_tree().current_scene.add_child(instance)


func _select_zombie_type() -> Script:
	var wave = _wave_number

	# Boss at floor 15
	if wave >= 15 and randf() < 0.10:
		return _select_boss()

	# Fallback: normal zombie
	return preload("res://scripts/entities/zombie/zombie_base.gd")


func _select_boss() -> Script:
	var bosses = [
		preload("res://scripts/entities/zombie/boss_zombie_king.gd"),
		preload("res://scripts/entities/zombie/boss_bio_titan.gd"),
		preload("res://scripts/entities/zombie/boss_nano_core.gd"),
		preload("res://scripts/entities/zombie/boss_experiment_alpha.gd"),
	]
	return bosses[randi() % bosses.size()]
