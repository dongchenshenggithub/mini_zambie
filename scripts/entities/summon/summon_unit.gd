## Summoned unit — follows player or stays stationary, auto-attacks zombies.
class_name SummonUnit
extends Node2D

@export var damage: float = 10.0
@export var range: float = 150.0
@export var follow_owner: bool = true

var owner_node: Player = null
func _ready() -> void:
	_setup_visuals()


func _setup_visuals() -> void:
	var vis = ColorRect.new()
	vis.position = Vector2(-8, -8)
	vis.size = Vector2(16, 16)
	vis.color = Color(0.2, 0.8, 0.2, 1.0)  # Green summon
	vis.name = "Visual"
	add_child(vis)
var _attack_timer: float = 0.0
var _attack_rate: float = 1.0
var _hp: float = 100.0
var _respawn_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if owner_node == null or not owner_node.stats.is_alive():
		queue_free()
		return

	_attack_timer -= delta
	if _attack_timer <= 0:
		_attack()
		_attack_timer = _attack_rate

	if follow_owner and owner_node:
		var target_pos = owner_node.global_position + Vector2(40, 0)
		global_position = global_position.lerp(target_pos, 5.0 * delta)


func _attack() -> void:
	if owner_node == null:
		return
	var owner_pos = owner_node.global_position
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var z = zombie as ZombieBase
		if z:
			var dist = z.global_position.distance_to(owner_pos)
			if dist <= range:
				z.take_damage(damage)
				break


func take_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0:
		_respawn_timer = 10.0


func _physics_process_respawn(delta: float) -> void:
	if _hp <= 0:
		_respawn_timer -= delta
		if _respawn_timer <= 0:
			_hp = 100.0
