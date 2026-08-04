## Headless parse/load validator. Not part of the game — used to catch
## syntax and reference errors across the whole project without the editor.
extends SceneTree

func _initialize() -> void:
	_scan_and_load("res://scripts")
	_scan_and_load("res://resources")
	print("VALIDATION_DONE")
	quit()

func _scan_and_load(dir: String) -> void:
	var d = DirAccess.open(dir)
	if d == null:
		printerr("Cannot open ", dir)
		return
	d.list_dir_begin()
	var f = d.get_next()
	while f != "":
		if f.begins_with("."):
			f = d.get_next()
			continue
		var full = dir + "/" + f
		if d.current_is_dir():
			_scan_and_load(full)
		elif f.ends_with(".gd") or f.ends_with(".tres") or f.ends_with(".tscn"):
			var res = load(full)
			if res == null:
				printerr("LOAD_FAIL: ", full)
			else:
				print("OK: ", full)
		f = d.get_next()
