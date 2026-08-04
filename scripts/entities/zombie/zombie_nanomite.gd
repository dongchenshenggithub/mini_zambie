class_name ZombieNanomite
extends ZombieBase

var _armor_down_timer: float = 0.0


func _ready() -> void:
	zombie_type = GameEnums.ZombieType.NANOMITE
	super._ready()


func take_damage(amount: float) -> void:
	super.take_damage(amount)
	# Apply armor down debuff to player
	if owner:
		var player = get_tree().get_first_node_in_group("player") as Player
		if player:
			player.stats.armor = max(0, player.stats.armor - 2)
			_armor_down_timer = 5.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _armor_down_timer > 0:
		_armor_down_timer -= delta
