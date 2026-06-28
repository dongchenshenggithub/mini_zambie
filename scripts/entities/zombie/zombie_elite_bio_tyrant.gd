class_name ZombieEliteBioTyrant
extends ZombieBase

func _ready() -> void:
	zombie_type = GameEnums.ZombieType.ELITE_BIO_TYRANT
	super._ready()


func take_damage(amount: float) -> void:
	super.take_damage(amount)
