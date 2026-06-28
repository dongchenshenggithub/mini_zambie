class_name ZombieHologram
extends ZombieBase

var _revealed: bool = false


func take_damage(amount: float) -> void:
	if not _revealed and randf() < 0.5:
		# 50% dodge chance
		return
	_revealed = true
	super.take_damage(amount)
	# After revealing, speed increases
	current_speed = base_speed * 1.5


func _ready() -> void:
	zombie_type = GameEnums.ZombieType.HOLOGRAM
	super._ready()
