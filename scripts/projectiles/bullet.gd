class_name Bullet
extends ProjectileBase

func _ready() -> void:
	super._ready()
	speed = 600.0


func _process(delta: float) -> void:
	super._process(delta)
