## Base zombie — AI state machine with chase/attack behaviors.
## All zombies spawn at map edge and chase the player.
class_name ZombieBase
extends CharacterBody2D

const LimbRegistry = preload("res://scripts/systems/limb_registry.gd")
const AccessoryRegistry = preload("res://scripts/systems/accessory_registry.gd")
const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")

@export var base_health: float = 100.0
@export var base_speed: float = 50.0
@export var base_damage: float = 10.0
@export var xp_reward: int = 10
@export var zombie_type: GameEnums.ZombieType = GameEnums.ZombieType.NORMAL

var current_health: float = 0.0
var current_speed: float = 0.0
var current_damage: float = 0.0
var _base_modulate: Color = Color.WHITE

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
	_setup_collision()


## Zombies need a collision shape so bullet Area2Ds can detect them via
## body_entered. We keep collision_mask = 0 so they do NOT physically push
## each other / the player (preserving the current free-movement feel) — they
## remain detectable because detection uses the Area's mask vs this body's
## layer, which is untouched (layer 1).
func _setup_collision() -> void:
	var body := CollisionShape2D.new()
	body.name = "Body"
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	body.shape = shape
	collision_layer = 1
	collision_mask = 0
	add_child(body)


func _setup_visuals() -> void:
	var spr = Sprite2D.new()
	spr.texture = PixelLoader.load_texture(_get_zombie_texture_path())
	spr.name = "Visual"
	if spr.texture != null:
		var target := 24.0
		spr.scale = Vector2(target / spr.texture.get_width(), target / spr.texture.get_height())
	if zombie_type == GameEnums.ZombieType.HOLOGRAM:
		# Baked scanline alpha already makes it translucent; tint cyan for projection look.
		spr.modulate = Color(0.7, 1.0, 1.0, 0.85)
	_base_modulate = spr.modulate
	add_child(spr)


func _get_zombie_texture_path() -> String:
	match zombie_type:
		GameEnums.ZombieType.NORMAL: return "res://assets/pixel/zombie_normal.png"
		GameEnums.ZombieType.FAST: return "res://assets/pixel/zombie_fast.png"
		GameEnums.ZombieType.TANK: return "res://assets/pixel/zombie_tank.png"
		GameEnums.ZombieType.SELF_DESTRUCT: return "res://assets/pixel/zombie_self.png"
		GameEnums.ZombieType.MECHA_MUTANT: return "res://assets/pixel/zombie_mecha_mutant.png"
		GameEnums.ZombieType.BIO_SHIELD: return "res://assets/pixel/zombie_bio_shield.png"
		GameEnums.ZombieType.NANOMITE: return "res://assets/pixel/zombie_nanomite.png"
		GameEnums.ZombieType.HOLOGRAM: return "res://assets/pixel/zombie_hologram.png"
		GameEnums.ZombieType.ELITE_BIO_TYRANT: return "res://assets/pixel/zombie_elite_bio_tyrant.png"
		GameEnums.ZombieType.ELITE_MECHA_SOLDIER: return "res://assets/pixel/zombie_elite_mecha_soldier.png"
		GameEnums.ZombieType.ELITE_GENE_FUSION: return "res://assets/pixel/zombie_elite_gene_fusion.png"
		_: return "res://assets/pixel/zombie_normal.png"


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


## Quick white/red flash so the player sees a bullet connect.
func flash_hit() -> void:
	var vis = get_node_or_null("Visual")
	if vis == null:
		return
	vis.modulate = Color(1.0, 0.4, 0.4, 1.0)
	var tw := create_tween()
	tw.tween_property(vis, "modulate", _base_modulate, 0.12)


func die() -> void:
	var xp_sys = get_tree().get_first_node_in_group("xp_system") as XPSystem
	if xp_sys:
		xp_sys.gain_xp(xp_reward)
	Game.score += xp_reward
	Game.kills += 1
	SfxManager.play("enemy_die")
	# Notify the player's class behavior (e.g. Alien Shooter heals on kills).
	if target_player and target_player.behavior:
		target_player.behavior.on_zombie_die(self)
	_drop_loot()
	queue_free()


func _drop_loot() -> void:
	"""Drop soul orbs always, plus random potions / weapons / equipment.
	Weapons and equipment (accessories + prosthetic limbs) come ONLY from
	drops — level-ups are attribute-only. The PickupItem script is
	instantiated directly (not via a .tscn) so drops work regardless of the
	editor's import-cache state for the scene files."""
	var scene = get_tree().current_scene
	if scene == null:
		return
	# Soul orbs always drop.
	var orb = preload("res://scenes/gameplay/soul_orb.tscn").instantiate()
	orb.global_position = global_position
	scene.add_child(orb)

	# Random drops. Equipment (weapon+accessory+parts) = 45% of kills.
	var roll = randf()
	if roll < 0.12:
		_add_drop(scene, PickupItemScript.ItemType.POTION)
	elif roll < 0.27:
		_add_drop(scene, PickupItemScript.ItemType.WEAPON)
	elif roll < 0.42:
		_add_drop(scene, PickupItemScript.ItemType.ACCESSORY)
	elif roll < 0.57:
		_add_drop(scene, PickupItemScript.ItemType.PARTS)


## Spawn a PickupItem of the given type at a slight random offset. Accessories
## and parts get a random definition attached so pickup actually applies it.
func _add_drop(scene: Node, type: int) -> void:
	var drop = PickupItemScript.new()
	drop.item_type = type
	drop.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	if type == PickupItemScript.ItemType.ACCESSORY:
		var all = AccessoryRegistry.get_all()
		if not all.is_empty():
			var data: AccessoryData = all[randi() % all.size()]
			drop.accessory_data = data
			drop.rarity = data.rarity
	elif type == PickupItemScript.ItemType.PARTS:
		drop.limb = LimbRegistry.get_random()
		if drop.limb != null:
			drop.rarity = drop.limb.rarity
	scene.add_child(drop)


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
