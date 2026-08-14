## Stationary healing tower placed by the Professor. Periodically heals the
## player when within range. Placed into the GameScene so it persists across
## floors until the run ends.
class_name HealingTower
extends Node2D

@export var heal_per_tick: float = 8.0
@export var heal_range: float = 190.0
@export var heal_rate: float = 1.0

var _timer: float = 0.0


func _ready() -> void:
	_setup_visuals()


func _setup_visuals() -> void:
	var base := _poly(_circle_pts(11.0), Color(0.22, 0.45, 0.32))
	add_child(base)
	var core := _poly(_circle_pts(6.0), Color(0.4, 0.95, 0.55))
	add_child(core)
	# White cross
	var v := ColorRect.new()
	v.position = Vector2(-1.5, -7.0)
	v.size = Vector2(3.0, 14.0)
	v.color = Color.WHITE
	add_child(v)
	var h := ColorRect.new()
	h.position = Vector2(-7.0, -1.5)
	h.size = Vector2(14.0, 3.0)
	h.color = Color.WHITE
	add_child(h)


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0:
		_heal()
		_timer = heal_rate


func _heal() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not (player is Player):
		return
	if not player.stats.is_alive():
		return
	if player.global_position.distance_to(global_position) <= heal_range:
		player.heal(heal_per_tick)
		_pulse()


func _pulse() -> void:
	var ring := _poly(_circle_pts(heal_range), Color(0.3, 1.0, 0.5, 0.22))
	add_child(ring)
	var tw := create_tween()
	tw.tween_property(ring, "modulate:a", 0.0, 0.4)
	tw.tween_callback(ring.queue_free)


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
