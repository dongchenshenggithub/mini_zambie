## Upgrade option card displayed in the upgrade picker panel.
class_name UpgradeOptionCard
extends Button

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

var upgrade_data: Dictionary = {}


func _ready() -> void:
	# Apply a pixel-bordered card frame behind the icon + label.
	var st = StyleBoxTexture.new()
	st.texture = PixelLoader.load_texture("res://assets/pixel/card_bg.png")
	add_theme_stylebox_override("normal", st)
	add_theme_stylebox_override("hover", st)
	add_theme_stylebox_override("pressed", st)
	add_theme_stylebox_override("focus", st)
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT


func setup(data: Dictionary) -> void:
	upgrade_data = data
	text = data.get("label", "Upgrade")
	var kind = int(data.get("kind", -1))
	icon = PixelLoader.load_texture(_kind_icon_path(kind))


func _kind_icon_path(kind: int) -> String:
	match kind:
		0: return "res://assets/pixel/icon_health.png"
		1: return "res://assets/pixel/icon_strength.png"
		2: return "res://assets/pixel/icon_agility.png"
		3: return "res://assets/pixel/icon_intelligence.png"
		4: return "res://assets/pixel/icon_constitution.png"
		5: return "res://assets/pixel/icon_luck.png"
		6: return "res://assets/pixel/icon_willpower.png"
		7: return "res://assets/pixel/icon_weapon.png"
		_: return "res://assets/pixel/icon_weapon.png"


func get_upgrade_data() -> Dictionary:
	return upgrade_data
