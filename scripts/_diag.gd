extends SceneTree
func _init() -> void:
	var a = preload("res://scripts/map/map_generator.gd")
	var b = preload("res://scripts/ui/transition_banner.gd")
	var c = preload("res://scripts/gameplay/game_scene.gd")
	var d = preload("res://scripts/ui/upgrade_panel.gd")
	print("DIAG map=%s banner=%s scene=%s upgrade=%s" % [a!=null, b!=null, c!=null, d!=null])
	quit()
