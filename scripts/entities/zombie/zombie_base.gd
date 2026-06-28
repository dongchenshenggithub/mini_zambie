## Base zombie — AI state machine with chase/attack behaviors.
## All zombies spawn at map edge and chase the player.
class_name ZombieBase
extends CharacterBody2D

@export var base_health: float = 100.0
@export var base_speed: float = 50.0
@export var base_damage: float = 10.0
@export var xp_reward: int = 10
@export var zombie_type: GameEnums.ZombieType = GameEnums.ZombieType.NORMAL

var current_health: float = 0.0
var current_speed: float = 0.0
var current_damage: float = 0.0

var state: State = State.CHASE
var target_player: Player = null

enum State { CHASE, ATTACK, STUNNED, FROZEN }


func _ready() -> void:
	add_to_group("zombie")
	_configure_type()
	current_health = base_health
	current_speed = base_speed
	current_damage = base_damage
	_setup_visuals()


func _setup_visuals() -> void:
	var vis = ColorRect.new()
	vis.position = Vector2(-12, -12)
	vis.size = Vector2(24, 24)
	vis.color = _get_zombie_color()
	vis.name = "Visual"
	add_child(vis)


func _get_zombie_color() -> Color:
	match zombie_type:
		GameEnums.ZombieType.NORMAL: return Color(0.6, 0.3, 0.3, 1.0)  # Red
		GameEnums.ZombieType.FAST: return Color(0.8, 0.8, 0.2, 1.0)     # Yellow
		GameEnums.ZombieType.TANK: return Color(0.4, 0.4, 0.4, 1.0)     # Gray
		GameEnums.ZombieType.SELF_DESTRUCT: return Color(1.0, 0.4, 0.0, 1.0)  # Orange
		GameEnums.ZombieType.MECHA_MUTANT: return Color(0.5, 0.5, 0.8, 1.0)  # Purple
		GameEnums.ZombieType.BIO_SHIELD: return Color(0.2, 0.6, 0.2, 1.0)  # Green
		GameEnums.ZombieType.NANOMITE: return Color(0.6, 0.2, 0.6, 1.0)  # Magenta
		GameEnums.ZombieType.HOLOGRAM: return Color(0.3, 0.8, 0.8, 0.5)  # Cyan transparent
		GameEnums.ZombieType.ELITE_BIO_TYRANT: return Color(1.0, 0.0, 0.0, 1.0)  # Dark red
		GameEnums.ZombieType.ELITE_MECHA_SOLDIER: return Color(0.0, 0.0, 1.0, 1.0)  # Blue
		GameEnums.ZombieType.ELITE_GENE_FUSION: return Color(1.0, 1.0, 0.0, 1.0)  # Gold
		_: return Color(0.5, 0.2, 0.2, 1.0)  # Default red


func _configure_type() -> void:
	match zombie_type:
		GameEnums.ZombieType.NORMAL:
			base_health = 50.0; base_speed = 50.0; base_damage = 10.0; xp_reward = 10
		GameEnums.ZombieType.FAST:
			base_health = 35.0; base_speed = 90.0; base_damage = 6.0; xp_reward = 15
		GameEnums.ZombieType.TANK:
			base_health = 150.0; base_speed = 25.0; base_damage = 20.0; xp_reward = 15
		GameEnums.ZombieType.SELF_DESTRUCT:
			base_health = 25.0; base_speed = 60.0; base_damage = 50.0; xp_reward = 12
		GameEnums.ZombieType.MECHA_MUTANT:
			base_health = 100.0; base_speed = 65.0; base_damage = 15.0; xp_reward = 30
		GameEnums.ZombieType.BIO_SHIELD:
			base_health = 200.0; base_speed = 35.0; base_damage = 30.0; xp_reward = 35
		GameEnums.ZombieType.NANOMITE:
			base_health = 75.0; base_speed = 75.0; base_damage = 20.0; xp_reward = 25
		GameEnums.ZombieType.HOLOGRAM:
			base_health = 40.0; base_speed = 90.0; base_damage = 12.0; xp_reward = 20
		GameEnums.ZombieType.ELITE_BIO_TYRANT:
			base_health = 400.0; base_speed = 45.0; base_damage = 50.0; xp_reward = 100
		GameEnums.ZombieType.ELITE_MECHA_SOLDIER:
			base_health = 500.0; base_speed = 35.0; base_damage = 60.0; xp_reward = 120
		GameEnums.ZombieType.ELITE_GENE_FUSION:
			base_health = 300.0; base_speed = 60.0; base_damage = 40.0; xp_reward = 90
		GameEnums.ZombieType.BOSS_ZOMBIE_KING:
			base_health = 2500.0; base_speed = 40.0; base_damage = 100.0; xp_reward = 500
		GameEnums.ZombieType.BOSS_BIO_TITAN:
			base_health = 4000.0; base_speed = 25.0; base_damage = 150.0; xp_reward = 800
		GameEnums.ZombieType.BOSS_NANO_CORE:
			base_health = 3000.0; base_speed = 30.0; base_damage = 120.0; xp_reward = 600
		GameEnums.ZombieType.BOSS_EXPERIMENT_ALPHA:
			base_health = 5000.0; base_speed = 35.0; base_damage = 200.0; xp_reward = 1000


func _physics_process(delta: float) -> void:
	if state == State.STUNNED or state == State.FROZEN:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if target_player == null:
		target_player = get_tree().get_first_node_in_group("player") as Player

	if target_player:
		var dir = (target_player.global_position - global_position).normalized()
		velocity = dir * current_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist < 40.0:
			target_player.take_damage(current_damage * delta)


func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0:
		die()


func die() -> void:
	var xp_sys = get_tree().get_first_node_in_group("xp_system") as XPSystem
	if xp_sys:
		xp_sys.gain_xp(xp_reward)
	Game.score += xp_reward
	_drop_loot()
	queue_free()


func _drop_loot() -> void:
	"""Drop soul orbs, potions, weapons, accessories, parts."""
	var scene = get_tree().current_scene
	if scene:
		# Soul orbs always drop
		var orb = preload("res://scenes/gameplay/soul_orb.tscn").instantiate()
		orb.global_position = global_position
		scene.add_child(orb)

		# Random drops
		var roll = randf()
		if roll < 0.2:
			_drop_potion(scene)
		elif roll < 0.25:
			_drop_weapon(scene)
		elif roll < 0.30:
			_drop_accessory(scene)
		elif roll < 0.40:
			_drop_parts(scene)


func _drop_potion(scene: Node) -> void:
	var potion = preload("res://scenes/gameplay/potion.tscn").instantiate()
	potion.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	scene.add_child(potion)


func _drop_weapon(scene: Node) -> void:
	var weapon = preload("res://scenes/gameplay/weapon_drop.tscn").instantiate()
	weapon.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	scene.add_child(weapon)


func _drop_accessory(scene: Node) -> void:
	var accessory = preload("res://scenes/gameplay/accessory_drop.tscn").instantiate()
	accessory.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	scene.add_child(accessory)


func _drop_parts(scene: Node) -> void:
	var parts = preload("res://scenes/gameplay/parts_drop.tscn").instantiate()
	parts.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	scene.add_child(parts)


func apply_status(effect: GameEnums.StatusEffect, duration: float) -> void:
	match effect:
		GameEnums.StatusEffect.FREEZE:
			state = State.FROZEN
			current_speed = 0.0
			await get_tree().create_timer(duration).timeout
			if is_inside_tree():
				state = State.CHASE
				current_speed = base_speed
		GameEnums.StatusEffect.STUN:
			state = State.STUNNED
			await get_tree().create_timer(duration).timeout
			if is_inside_tree():
				state = State.CHASE


func apply_knockback(direction: Vector2) -> void:
	velocity = direction
	move_and_slide()
