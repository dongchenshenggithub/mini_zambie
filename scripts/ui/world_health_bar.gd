## A slim health bar that floats above a world entity (used above the
## player's head). Drawn in world space so it tracks the camera and sits on
## top of sprites. Call set_health() whenever HP changes.
class_name WorldHealthBar
extends Node2D

const BAR_W: float = 46.0
const BAR_H: float = 6.0
const Y_OFFSET: float = -46.0

var _cur: float = 1.0
var _max: float = 1.0


func _ready() -> void:
	z_index = 12  # draw above player sprite and zombies


func set_health(cur: float, maxv: float) -> void:
	_cur = maxf(0.0, cur)
	_max = maxf(0.001, maxv)
	queue_redraw()


func _draw() -> void:
	var x := -BAR_W * 0.5
	var y := Y_OFFSET
	var ratio := clampf(_cur / _max, 0.0, 1.0)
	# Dark backing so the bar reads on any background.
	draw_rect(Rect2(x - 1.0, y - 1.0, BAR_W + 2.0, BAR_H + 2.0), Color(0.05, 0.05, 0.07, 0.85))
	# Fill: green when healthy, red when low.
	var fill_col := Color(0.25, 0.9, 0.35, 1.0)
	if ratio <= 0.3:
		fill_col = Color(0.95, 0.3, 0.2, 1.0)
	elif ratio <= 0.6:
		fill_col = Color(0.95, 0.8, 0.25, 1.0)
	draw_rect(Rect2(x, y, BAR_W * ratio, BAR_H), fill_col)
	# Thin outline.
	draw_rect(Rect2(x, y, BAR_W, BAR_H), Color(0.0, 0.0, 0.0, 0.7), false, 1.0)
