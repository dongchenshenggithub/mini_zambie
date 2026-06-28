class_name ZombieBioShield
extends ZombieBase

var shield_active: bool = true
var shield_hp: float = 0.0


func _ready() -> void:
	zombie_type = GameEnums.ZombieType.BIO_SHIELD
	super._ready()
	shield_hp = base_health * 0.5


func take_damage(amount: float) -> void:
	if shield_active:
		shield_hp -= amount
		if shield_hp <= 0:
			shield_active = false
			base_health *= 0.5  # Vulnerable after shield breaks
			current_health = base_health
	else:
		super.take_damage(amount)
