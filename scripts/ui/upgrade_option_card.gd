## Upgrade option card displayed in the upgrade picker panel.
class_name UpgradeOptionCard
extends Button


var upgrade_data: Dictionary = {}


func setup(data: Dictionary) -> void:
	upgrade_data = data
	text = data.get("label", "Upgrade")


func get_upgrade_data() -> Dictionary:
	return upgrade_data
