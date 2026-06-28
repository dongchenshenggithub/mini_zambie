## Cover object in the map — provides protection from zombie attacks.
class_name CoverObject
extends StaticBody2D


@export var health: float = 50.0
@export var is_destructible: bool = true

var destroyed: bool = false


func take_damage(amount: float) -> void:
	if not is_destructible or destroyed:
		return
	health -= amount
	if health <= 0:
		destroyed = true
		queue_free()
