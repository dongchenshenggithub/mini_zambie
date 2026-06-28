## Health potion — restores 30% of max HP.
class_name ConsumablePotion
extends ItemBase


func _init() -> void:
	item_name = "生命药水"
	item_category = GameEnums.ItemCategory.POTION


func use(player: Player) -> void:
	player.heal(player.stats.max_health * 0.3)
