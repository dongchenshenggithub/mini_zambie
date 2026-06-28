class_name ElectricBeam
extends ProjectileBase

func _ready() -> void:
	super._ready()
	speed = 1000.0
	pierce = 5


func _process(delta: float) -> void:
	super._process(delta)
