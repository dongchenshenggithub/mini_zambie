extends SceneTree
func _init() -> void:
	var paths = [
		"res://scripts/gameplay/pickup_item.gd",
		"res://scripts/systems/upgrade_picker.gd",
		"res://scripts/entities/zombie/zombie_base.gd",
		"res://scripts/entities/player/player_stats.gd",
	]
	for p in paths:
		var r = load(p)
		print("LOAD ", p, " -> ", r)
	quit()
