## Summoned unit — follows player or stays stationary, auto-attacks zombies.
## Visual identity (shape / color / accent) is configured per follower type by
## FollowerManager, so different characters — and Cat Cafe's 5 distinct
## companions — look unique without needing a separate sprite file per type.
class_name SummonUnit
extends Node2D

@export var damage: float = 10.0
@export var range: float = 150.0
@export var follow_owner: bool = true
## Visual identity (set by FollowerManager per follower type).
@export var body_shape: int = 0       # 0=circle 1=square 2=triangle 3=diamond 4=bear
@export var body_color: Color = Color(0.48, 0.88, 0.88)
@export var body_accent: int = 0      # 0=none 1=pirate band 2=owl eyes 3=dragon heart
@export var beam_color: Color = Color(1.0, 0.9, 0.4, 1.0)
## Attack style: 0 = ranged beam (default), 1 = melee guard (orbits the owner,
## intercepts zombies that get close to the owner, and strikes in melee).
@export var attack_style: int = 0
@export var orbit_radius: float = 44.0   # distance kept from owner while guarding
@export var orbit_speed: float = 1.7     # angular speed (rad/s) while orbiting
@export var guard_range: float = 130.0   # defend zombies within this distance of the OWNER
var _orbit_angle: float = 0.0

var owner_node: Player = null
## Back-link to the CompanionWeapon that spawned this unit (non-Cat-Cafe only).
## Null for Cat Cafe's directly-recruited companions. Used by the inventory panel
## to dismiss the owning weapon (freeing its slot) when the unit is dismissed.
var companion_weapon: Node = null


func _ready() -> void:
	add_to_group("summon")
	_setup_visuals()


func _setup_visuals() -> void:
	var vis := Node2D.new()
	vis.name = "Visual"
	add_child(vis)
	match body_shape:
		1: _paint_poly(vis, _square_pts(), body_color)
		2: _paint_poly(vis, _tri_pts(), body_color)
		3: _paint_poly(vis, _diamond_pts(), body_color)
		4: _paint_bear(vis)
		_: _paint_poly(vis, _circle_pts(), body_color)
	match body_accent:
		1: _paint_rect(vis, Rect2(-8, -3, 16, 4), Color(0.08, 0.08, 0.08))
		2:
			_paint_poly(vis, _tiny_circle(Vector2(-3.5, -2.0)), Color.WHITE)
			_paint_poly(vis, _tiny_circle(Vector2(3.5, -2.0)), Color.WHITE)
		3: _paint_poly(vis, _tiny_circle(Vector2(0, 1.0)), Color(0.9, 0.22, 0.22))


var _attack_timer: float = 0.0
var _attack_rate: float = 1.0
var _hp: float = 100.0
var _respawn_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if owner_node == null or not owner_node.stats.is_alive():
		queue_free()
		return

	_attack_timer -= delta
	if _attack_timer <= 0:
		if attack_style == 1:
			_melee_attack()
		else:
			_attack()
		_attack_timer = _attack_rate

	if _hp <= 0:
		_respawn_timer -= delta
		if _respawn_timer <= 0:
			_hp = 100.0

	if follow_owner and owner_node:
		if attack_style == 1:
			_orbit_and_guard(delta)
		else:
			var target_pos = owner_node.global_position + Vector2(40, 0)
			global_position = global_position.lerp(target_pos, 5.0 * delta)


## Melee guard behavior: circles the owner and actively defends them. Zombies
## that wander within `guard_range` of the OWNER are treated as threats and the
## guard moves to intercept + strike them; otherwise it just orbits.
func _orbit_and_guard(delta: float) -> void:
	_orbit_angle += orbit_speed * delta
	var center := owner_node.global_position
	var threat: ZombieBase = _nearest_threat_to_owner()
	var desired: Vector2
	if threat != null:
		# Sit between the owner and the threat so it blocks/clears the approach.
		var to_threat := (threat.global_position - center).normalized()
		desired = center + to_threat * (orbit_radius * 0.6)
	else:
		desired = center + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * orbit_radius
	global_position = global_position.lerp(desired, 8.0 * delta)


func _nearest_threat_to_owner() -> ZombieBase:
	if owner_node == null:
		return null
	var center := owner_node.global_position
	var best: ZombieBase = null
	var best_dist := guard_range
	for z in get_tree().get_nodes_in_group("zombie"):
		var zb := z as ZombieBase
		if zb:
			var d := zb.global_position.distance_to(center)
			if d <= best_dist:
				best_dist = d
				best = zb
	return best


func _melee_attack() -> void:
	if owner_node == null:
		return
	# Prioritize a zombie threatening the owner (defend), else the nearest one
	# within melee reach of the guard itself.
	var target: ZombieBase = _nearest_threat_to_owner()
	if target == null:
		var best_dist := range
		for z in get_tree().get_nodes_in_group("zombie"):
			var zb := z as ZombieBase
			if zb:
				var d := zb.global_position.distance_to(global_position)
				if d <= best_dist:
					best_dist = d
					target = zb
	if target != null:
		target.take_damage(damage)
		if target.has_method("flash_hit"):
			target.flash_hit()
		_spawn_slash(target.global_position)


func _attack() -> void:
	if owner_node == null:
		return
	# Engage the NEAREST zombie within range, measured from the follower's own
	# position (each companion acts independently instead of camping on the
	# player). A short-lived beam + target flash make the damage clearly visible.
	var best: ZombieBase = null
	var best_dist: float = range
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var z := zombie as ZombieBase
		if z:
			var d := z.global_position.distance_to(global_position)
			if d <= best_dist:
				best_dist = d
				best = z
	if best != null:
		best.take_damage(damage)
		_spawn_beam(best.global_position)
		if best.has_method("flash_hit"):
			best.flash_hit()


## Short-lived white slash arc so melee guards' hits are clearly visible.
func _spawn_slash(to_pos: Vector2) -> void:
	var arc := Polygon2D.new()
	var pts := PackedVector2Array()
	var base := to_pos - global_position
	var ang := base.angle()
	for i in range(7):
		var a := ang - 0.5 + float(i) / 6.0 * 1.0
		pts.append(Vector2(cos(a), sin(a)) * 16.0)
	arc.polygon = pts
	arc.color = Color(1.0, 1.0, 1.0, 0.9)
	add_child(arc)
	var tw := create_tween()
	tw.tween_property(arc, "modulate:a", 0.0, 0.12)
	tw.tween_callback(arc.queue_free)


## Draws a short-lived beam from the follower to its target so the player can
## clearly see the companion dealing damage.
func _spawn_beam(to_pos: Vector2) -> void:
	var line := Line2D.new()
	line.add_point(Vector2.ZERO)
	line.add_point(to_pos - global_position)
	line.width = 2.0
	line.default_color = beam_color
	add_child(line)
	var tw := create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.12)
	tw.tween_callback(line.queue_free)


func take_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0:
		_respawn_timer = 10.0


func _physics_process_respawn(delta: float) -> void:
	if _hp <= 0:
		_respawn_timer -= delta
		if _respawn_timer <= 0:
			_hp = 100.0


# --- visual helpers ---------------------------------------------------------
func _circle_pts() -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		p.append(Vector2(cos(a), sin(a)) * 9.0)
	return p


func _square_pts() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-7, -7), Vector2(7, -7), Vector2(7, 7), Vector2(-7, 7)])


func _tri_pts() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -10), Vector2(-9, 8), Vector2(9, 8)])


func _diamond_pts() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -11), Vector2(9, 0), Vector2(0, 11), Vector2(-9, 0)])


func _tiny_circle(c: Vector2) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(8):
		var a := TAU * float(i) / 8.0
		p.append(c + Vector2(cos(a), sin(a)) * 2.5)
	return p


func _paint_poly(parent: Node, pts: PackedVector2Array, col: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = col
	parent.add_child(poly)


func _paint_rect(parent: Node, r: Rect2, col: Color) -> void:
	var rect := ColorRect.new()
	rect.position = r.position
	rect.size = r.size
	rect.color = col
	parent.add_child(rect)


func _paint_bear(parent: Node) -> void:
	_paint_poly(parent, _circle_pts(), body_color)
	_paint_poly(parent, _tiny_circle(Vector2(-6, -7)), body_color)
	_paint_poly(parent, _tiny_circle(Vector2(6, -7)), body_color)
