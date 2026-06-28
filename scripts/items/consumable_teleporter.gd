## Teleporter — short-range dash.
class_name ConsumableTeleporter
extends ItemBase


func _init() -> void:
	item_name = "传送器"
	item_category = GameEnums.ItemCategory.TELEPORTER


func use(player: Player) -> void:
	var dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	player.velocity = dir * 500.0
	player.move_and_slide()
