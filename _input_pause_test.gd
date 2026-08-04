extends SceneTree

var _flag := false
var _frames := 0
var _always: Control


func _init() -> void:
	_always = Control.new()
	_always.name = "AlwaysNode"
	_always.process_mode = Node.PROCESS_MODE_ALWAYS

	var gds := GDScript.new()
	gds.source_code = (
		'extends Control\n' +
		'var _hit := false\n' +
		'func _unhandled_input(event: InputEvent) -> void:\n' +
		'    if event.is_action_pressed("pause"):\n' +
		'        _hit = true\n' +
		'func _get_flag() -> bool:\n' +
		'    return _hit\n'
	)
	gds.reload()
	_always.set_script(gds)
	root.add_child(_always)

	# Pause the tree, then push a "pause" (Esc) key event like the real game.
	paused = true
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = true
	Input.parse_input_event(ev)


func _process(_d: float) -> bool:
	_frames += 1
	if _frames >= 4:
		if _always != null and _always.has_method("_get_flag"):
			_flag = _always._get_flag()
		print("INPUT_PAUSE flag=%s (true => _unhandled_input fires while paused)" % _flag)
		print("INPUT_PAUSE_PASS" if _flag else "INPUT_PAUSE_FAIL")
		quit()
	return false
