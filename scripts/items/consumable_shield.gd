## Shield fragment — grants temporary armor for 30 seconds.
class_name ConsumableShield
extends ItemBase


func _init() -> void:
	item_name = "护甲碎片"
	item_category = GameEnums.ItemCategory.SHIELD


func use(player: Player) -> void:
	player.stats.armor += 2
	# Remove after 30 seconds
	var timer = get_tree().create_timer(30.0)
	timer.timeout.connect(func(): player.stats.armor = maxi(0, player.stats.armor - 2))
