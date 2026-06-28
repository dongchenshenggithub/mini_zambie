class_name ZombieMechaMutant
extends ZombieBase

func _ready() -> void:
	zombie_type = GameEnums.ZombieType.MECHA_MUTANT
	super._ready()


func fire() -> void:
	"""Mecha mutants shoot at the player from range."""
	pass
