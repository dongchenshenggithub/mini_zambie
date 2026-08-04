extends SceneTree
func _initialize() -> void:
	await create_timer(0.2).timeout
	var root = get_root()
	var mgr = root.get_node_or_null("Music")
	if mgr == null:
		print("MUSIC autoload node = MISSING")
		quit()
		return
	print("MUSIC autoload node = OK current_before=%s" % mgr._current)
	for t in ["menu","gameplay","boss","victory","death"]:
		mgr._do_play(t, true)
		await create_timer(0.05).timeout
		print("MUSIC %s -> current=%s playing=%s" % [t, mgr._current, mgr._player.playing])
	mgr._player.stop()
	print("MUSIC_TEST PASS")
	quit()
