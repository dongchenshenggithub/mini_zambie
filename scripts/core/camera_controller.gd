## Camera follows the player smoothly.
class_name CameraController
extends Camera2D

@export var smoothing: float = 8.0
@onready var target_player: Node2D = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if target_player:
		position = position.lerp(target_player.position, smoothing * delta)
