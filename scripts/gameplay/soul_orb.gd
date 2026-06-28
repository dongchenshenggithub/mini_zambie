## Soul orb — dropped by zombies, flies toward player.
class_name SoulOrb
extends Area2D

var target_player: Player = null
var speed: float = 300.0
var value: int = 1


func _ready() -> void:
	connect("body_entered", _on_body_entered)
	_setup_visuals()
	target_player = get_tree().get_first_node_in_group("player") as Player


func _setup_visuals() -> void:
	var vis = ColorRect.new()
	vis.position = Vector2(-6, -6)
	vis.size = Vector2(12, 12)
	vis.color = Color(0.2, 0.8, 0.2, 1.0)  # Green orb
	vis.name = "Visual"
	add_child(vis)


func _physics_process(delta: float) -> void:
	if target_player:
		var dir = (target_player.global_position - global_position).normalized()
		global_position += dir * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var xp_sys = get_tree().get_first_node_in_group("xp_system") as XPSystem
		if xp_sys:
			xp_sys.gain_xp(value * 10)
		queue_free()
