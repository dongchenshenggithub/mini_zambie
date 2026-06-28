## XP chip — grants instant experience.
class_name ConsumableXPChip
extends ItemBase


func _init() -> void:
	item_name = "经验芯片"
	item_category = GameEnums.ItemCategory.XP_CHIP


func use(player: Player) -> void:
	var xp_sys = get_tree().get_first_node_in_group("xp_system") as XPSystem
	if xp_sys:
		xp_sys.gain_xp(50)
