extends SceneTree
func _initialize() -> void:
	var paths = ["menu","gameplay","boss","victory","death"]
	var ok = true
	for p in paths:
		var res = load("res://assets/music/%s.wav" % p)
		var cls = res.get_class() if res != null else "NULL"
		var len = -1.0
		if res is AudioStreamWAV:
			len = res.get_length()
		print("MUSIC %s -> %s len=%.2f" % [p, cls, len])
		if res == null or not (res is AudioStreamWAV):
			ok = false
	print("MUSIC_RESULT %s" % ("OK" if ok else "FAIL"))
	quit()
