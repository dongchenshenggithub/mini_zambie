## Reusable full-screen transition banner.
## Shows a centred main title + subtitle with a scale/fade-in, holds for
## `duration` seconds, then fades out and invokes `callback`. Designed to run
## while the tree is PAUSED (process_mode = ALWAYS) so it can bridge level-up and
## floor-clear moments without the game feeling like it "snaps" to a new state.
extends CanvasLayer
class_name TransitionBanner

var _content: Control
var _bg: ColorRect
var _callback: Callable
var _done: bool = false


## `main_text` is the big headline, `sub_text` the smaller line beneath it.
## `accent` colours the headline. `callback` fires after the banner fades out.
func show_banner(main_text: String, sub_text: String, duration: float, accent: Color, callback: Callable) -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_callback = callback

	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.0)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)
	_content = vbox

	var title := Label.new()
	title.text = main_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", accent)
	vbox.add_child(title)

	if sub_text != "":
		var sub := Label.new()
		sub.text = sub_text
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.add_theme_font_size_override("font_size", 24)
		sub.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92, 1.0))
		vbox.add_child(sub)

	# Animate in from slightly small + transparent, then hold, then fade out.
	_content.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_content.scale = Vector2(0.82, 0.82)
	_bg.color = Color(0.0, 0.0, 0.0, 0.0)

	var tw := create_tween()
	tw.tween_property(_content, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.30)
	tw.parallel().tween_property(_content, "scale", Vector2(1.06, 1.06), 0.30).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(_bg, "color", Color(0.0, 0.0, 0.0, 0.55), 0.30)
	tw.tween_interval(maxf(0.2, duration - 0.6))
	tw.tween_property(_content, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.30)
	tw.parallel().tween_property(_bg, "color", Color(0.0, 0.0, 0.0, 0.0), 0.30)
	tw.tween_callback(_finish)


func _finish() -> void:
	if _done:
		return
	_done = true
	var cb := _callback
	queue_free()
	if cb.is_valid():
		cb.call()
