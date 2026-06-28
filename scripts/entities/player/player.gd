## Main player character.
class_name Player
extends CharacterBody2D

const BASE_SPEED: float = 200.0

@export var stats: PlayerStats = PlayerStats.new()
@export var inventory: WeaponInventory
@export var prosthetic_manager: ProstheticManager
@export var character_data: CharacterEntry

var behavior: CharacterBehavior = null
var _visual: ColorRect = null
var _flash_timer: float = 0.0
var _original_color: Color = Color(0.0, 1.0, 0.0, 1.0)


func _ready() -> void:
	add_to_group("player")
	stats.current_health = stats.max_health
	if inventory == null:
		inventory = WeaponInventory.new()
		add_child(inventory)
	if prosthetic_manager == null:
		prosthetic_manager = ProstheticManager.new(false, stats)
		add_child(prosthetic_manager)
	_apply_character_traits()
	_create_behavior()
	_setup_visuals()


func _setup_visuals() -> void:
	var vis = _create_player_visual()
	vis.name = "Visual"
	add_child(vis)


func _create_player_visual() -> ColorRect:
	_visual = ColorRect.new()
	_visal.position = Vector2(-32, -32)
	_visual.size = Vector2(64, 64)
	_visual.color = _original_color
	_visual.visible = true
	return _visual


func _physics_process(delta: float) -> void:
	if _flash_timer > 0:
		_flash_timer -= delta
		if _visual:
			_visual.color = Color.WHITE if _flash_timer > 0.05 else _original_color
	stats._physics_process(delta)
	if not stats.is_alive():
		return
	if behavior:
		behavior.on_physics_process(delta)
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	velocity = direction * stats.movement_speed
	move_and_slide()
	for weapon in inventory.weapons:
		weapon.try_fire(delta)


func _apply_character_traits() -> void:
	if character_data:
		stats.max_health = character_data.starting_health
		stats.current_health = stats.max_health
		stats.movement_speed = character_data.starting_speed
		stats.damage_multiplier_ranged = character_data.ranged_damage_multiplier
		stats.damage_multiplier_meele = character_data.melee_damage_multiplier
		stats.damage_multiplier_summon = character_data.summon_damage_multiplier
		stats.damage_multiplier_spray = character_data.spray_damage_multiplier
		stats.damage_multiplier_laser = character_data.laser_damage_multiplier
		stats.self_heal_rate = character_data.heal_rate
		inventory.build_direction = character_data.build_direction
		inventory.max_followers = character_data.max_followers
		prosthetic_manager.is_mech_monk = (character_data.character_class == 1)


func _create_behavior() -> void:
	if character_data:
		behavior = BehaviorFactory.create_behavior(
			character_data.character_class, self, character_data
		)


func take_damage(amount: float) -> void:
	_flash_timer = 0.15
	if behavior:
		behavior.on_player_take_damage(amount)
	var _actual = stats.take_damage(amount)
	if not stats.is_alive():
		if behavior:
			behavior.on_player_die()
		_show_death_screen()
		Game.end_game()
		call_deferred("queue_free")


func heal(amount: float) -> void:
	stats.heal(amount)


func _show_death_screen() -> void:
	var ds = preload("res://scripts/gameplay/death_screen.gd").new()
	ds.set_score(Game.score)
	get_tree().root.add_child(ds)
