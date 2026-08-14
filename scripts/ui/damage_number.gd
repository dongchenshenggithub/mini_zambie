## Floating combat-text that pops above an enemy when it takes damage.
## Added to the live game scene (world space) so it is NOT freed when the
## zombie that spawned it dies. Rises a short distance and fades out, then
## frees itself. Big hits (>= 15% of the victim's max HP) render larger and
## gold-coloured so crits / heavy blows read clearly in the pixel-art chaos.
class_name DamageNumber
extends Node2D

const FLOAT_DIST: float = 32.0
const LIFE: float = 0.7

var _label: Label = null


## world_pos: where it appears (usually the zombie's global_position).
## amount: damage dealt. is_big: render as a gold crit-style number.
func setup(world_pos: Vector2, amount: float, is_big: bool) -> void:
	position = world_pos
	# Small horizontal jitter so stacked hits don't perfectly overlap.
	position.x += randf_range(-7.0, 7.0)

	var font_size := 20
	if is_big:
		font_size = 30

	_label = Label.new()
	add_child(_label)
	_label.text = str(int(round(amount)))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", font_size)
	var col := Color(1.0, 1.0, 1.0, 1.0)
	if is_big:
		col = Color(1.0, 0.85, 0.2, 1.0)
	_label.add_theme_color_override("font_color", col)
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_label.add_theme_constant_override("outline_size", 4)

	# Centre the label on this node (default font isn't monospace, so estimate
	# width from glyph count — close enough for short integer damage values).
	var est_w := _label.text.length() * font_size * 0.58
	_label.position = Vector2(-est_w * 0.5, -font_size * 0.6)

	if is_big:
		_label.scale = Vector2(1.0, 1.0)
		_label.pivot_offset = Vector2(est_w * 0.5, font_size * 0.5)

	_start_tween()


func _start_tween() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y - FLOAT_DIST, LIFE).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_label, "modulate:a", 0.0, LIFE).set_delay(0.12)
	if _label != null and _label.scale == Vector2(1.0, 1.0):
		# Tiny pop on big numbers for extra punch.
		tw.parallel().tween_property(_label, "scale", Vector2(1.25, 1.25), 0.1).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_label, "scale", Vector2(1.0, 1.0), 0.18).set_delay(0.1)
	tw.tween_callback(queue_free)
