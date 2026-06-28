## XP progress bar UI element.
class_name XPBar
extends ProgressBar


func _process(_delta: float) -> void:
	var xp_sys = get_tree().get_first_node_in_group("xp_system") as XPSystem
	if xp_sys:
		value = xp_sys.get_xp_progress()
		max_value = 1.0
