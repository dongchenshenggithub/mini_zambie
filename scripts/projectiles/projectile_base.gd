## Base projectile — moves forward and damages zombies on collision.
class_name ProjectileBase
extends Area2D

@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 500.0
@export var damage: float = 10.0
@export var range: float = 300.0
@export var pierce: int = 0
@export var splash_radius: float = 0.0
@export var effect: GameEnums.StatusEffect = GameEnums.StatusEffect.NONE
@export var effect_duration: float = 0.0

var _distance_traveled: float = 0.0
var _hits: int = 0


func _ready() -> void:
	connect("body_entered", _on_body_entered)
	_setup_visuals()


func _setup_visuals() -> void:
	var vis = ColorRect.new()
	vis.position = Vector2(-4, -4)
	vis.size = Vector2(8, 8)
	vis.color = _get_projectile_color()
	vis.name = "Visual"
	add_child(vis)


func _get_projectile_color() -> Color:
	if splash_radius > 0:
		return Color(1.0, 0.5, 0.0, 1.0)  # Orange rocket
	elif pierce > 0:
		return Color(0.5, 0.5, 1.0, 1.0)  # Blue electric
	elif effect != GameEnums.StatusEffect.NONE:
		match effect:
			GameEnums.StatusEffect.BURN: return Color(1.0, 0.3, 0.0, 1.0)
			GameEnums.StatusEffect.FREEZE: return Color(0.3, 0.8, 1.0, 1.0)
			GameEnums.StatusEffect.POISON: return Color(0.3, 1.0, 0.3, 1.0)
		return Color(1.0, 1.0, 0.0, 1.0)
	return Color(1.0, 1.0, 0.0, 1.0)  # Yellow bullet


func _process(delta: float) -> void:
	var move_amount = speed * delta
	_distance_traveled += move_amount
	if _distance_traveled > range:
		queue_free()
		return
	position += direction * move_amount


func _on_body_entered(body: Node2D) -> void:
	if body is ZombieBase:
		var zombie = body as ZombieBase
		zombie.take_damage(damage)
		if effect != GameEnums.StatusEffect.NONE:
			zombie.apply_status(effect, effect_duration)
		if splash_radius > 0:
			_apply_splash(zombie.global_position)
		_hits += 1
		if _hits > pierce:
			queue_free()


func _apply_splash(center: Vector2) -> void:
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var z = zombie as ZombieBase
		if z and z.global_position.distance_to(center) <= splash_radius:
			z.take_damage(damage * 0.5)
