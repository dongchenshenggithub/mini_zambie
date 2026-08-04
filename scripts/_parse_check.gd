extends SceneTree
const GameScene = preload("res://scripts/gameplay/game_scene.gd")
const HUDScript = preload("res://scripts/ui/hud.gd")
const MenuScript = preload("res://scripts/menus/main_menu.gd")
const DeathScript = preload("res://scripts/gameplay/death_screen.gd")
const UpgradeScript = preload("res://scripts/ui/upgrade_panel.gd")
const PauseScript = preload("res://scripts/gameplay/pause_menu.gd")
func _init() -> void:
	print("PARSE_OK game_scene=%s hud=%s menu=%s death=%s upgrade=%s pause=%s" % [
		GameScene != null, HUDScript != null, MenuScript != null, DeathScript != null, UpgradeScript != null, PauseScript != null])
	quit()
