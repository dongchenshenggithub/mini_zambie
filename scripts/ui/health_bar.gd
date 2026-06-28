## Health bar UI element.
class_name HealthBar
extends ProgressBar


func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player:
		value = player.stats.current_health
		max_value = player.stats.max_health + (player.stats.limb_health_bonus if player.stats else 0)
