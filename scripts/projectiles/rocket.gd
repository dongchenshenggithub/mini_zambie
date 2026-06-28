class_name Rocket
extends ProjectileBase

func _ready() -> void:
	super._ready()
	speed = 250.0
	splash_radius = 80.0


func _process(delta: float) -> void:
	super._process(delta)
