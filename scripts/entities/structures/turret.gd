## Stationary auto-turret placed by the Professor. Fires at the nearest zombie
## in range on a fixed cadence. Placed into the GameScene so it persists across
## floors until the run ends.
class_name Turret
extends Node2D

const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")

@export var damage: float = 32.0
@export var range: float = 290.0
@export var attack_rate: float = 0.8

var _attack_timer: float = 0.0


func _ready() -> void:
	_setup_visuals()


func _setup_visuals() -> void:
	# Base pad
	var base := _poly(_circle_pts(11.0), Color(0.35, 0.4, 0.5))
	add_child(base)
	# Turret dome
	var dome := _poly(_circle_pts(7.0), Color(0.7, 0.75, 0.85))
	dome.position = Vector2(0, -2)
	add_child(dome)
	# Barrel
	var barrel := ColorRect.new()
	barrel.position = Vector2(-2, -16)
	barrel.size = Vector2(4, 12)
	barrel.color = Color(0.9, 0.9, 0.95)
	add_child(barrel)


func _physics_process(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0:
		_attack()
		_attack_timer = attack_rate


func _attack() -> void:
	var best: ZombieBase = null
	var best_dist: float = range
	for z in get_tree().get_nodes_in_group("zombie"):
		var zb := z as ZombieBase
		if zb:
			var d := zb.global_position.distance_to(global_position)
			if d <= best_dist:
				best_dist = d
				best = zb
	if best != null:
		best.take_damage(damage)
		_spawn_beam(best.global_position)
		if best.has_method("flash_hit"):
			best.flash_hit()


func _spawn_beam(to_pos: Vector2) -> void:
	var line := Line2D.new()
	line.add_point(Vector2.ZERO)
	line.add_point(to_pos - global_position)
	line.width = 3.0
	line.default_color = Color(1.0, 0.5, 0.3, 1.0)
	add_child(line)
	var tw := create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.15)
	tw.tween_callback(line.queue_free)


# --- visual helpers ---
func _circle_pts(r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		p.append(Vector2(cos(a), sin(a)) * r)
	return p


func _poly(pts: PackedVector2Array, col: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = col
	return poly
