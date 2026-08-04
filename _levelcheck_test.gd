extends SceneTree

func _init() -> void:
	# Force-parse game_scene.gd by loading it as a script resource.
	var scr = load("res://scripts/gameplay/game_scene.gd")
	if scr == null:
		printerr("PARSE_FAIL: game_scene.gd failed to load")
		quit(1)
		return
	# Read the source text from disk to confirm the fix.
	var f = FileAccess.open("res://scripts/gameplay/game_scene.gd", FileAccess.READ)
	var src: String = ""
	if f != null:
		src = f.get_as_text()
		f.close()
	if ".stats.level" in src:
		printerr("FAIL: player.stats.level still present in source")
		quit(2)
		return
	if "Game.current_level" in src:
		print("OK: no PlayerStats.level access; level read from Game.current_level")
		quit(0)
	else:
		printerr("WARN: Game.current_level not found")
		quit(3)
