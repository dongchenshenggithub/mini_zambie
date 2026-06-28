class_name SprayArea
extends Area2D

@export var radius: float = 60.0
@export var damage: float = 10.0
@export var effect: GameEnums.StatusEffect = GameEnums.StatusEffect.NONE
@export var effect_duration: float = 0.0


func _ready() -> void:
	var shape = CircleShape2D.new()
	shape.radius = radius
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	connect("body_entered", _on_body_entered)
	await get_tree().create_timer(0.3).timeout
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is ZombieBase:
		var zombie = body as ZombieBase
		zombie.take_damage(damage)
		if effect != GameEnums.StatusEffect.NONE:
			zombie.apply_status(effect, effect_duration)
