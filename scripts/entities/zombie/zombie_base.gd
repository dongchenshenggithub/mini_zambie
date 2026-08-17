## Base zombie — AI state machine with chase/attack behaviors.
## All zombies spawn at map edge and chase the player.
class_name ZombieBase
extends CharacterBody2D

const LimbRegistry = preload("res://scripts/systems/limb_registry.gd")
const AccessoryRegistry = preload("res://scripts/systems/accessory_registry.gd")
const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")
const DamageNumberScript = preload("res://scripts/ui/damage_number.gd")

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

## --- animation state machine (spritesheet 4x4) ---
var _visual_ref: Sprite2D = null
var _anim_state: String = "walk"
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _hurt_timer: float = 0.0

const ANIM_HFRAMES := 4
const ANIM_VFRAMES := 4
const _ANIM_ROW := {"idle": 0, "walk": 1, "attack": 2, "hurt": 3}
const _ANIM_FRAMES := {"idle": 2, "walk": 4, "attack": 3, "hurt": 2}
const _ANIM_FPS := {"idle": 2.0, "walk": 8.0, "attack": 10.0, "hurt": 12.0}

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
		spr.scale = Vector2(0.65, 0.65)
		spr.hframes = ANIM_HFRAMES
		spr.vframes = ANIM_VFRAMES
	_visual_ref = spr
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
		_update_animation(delta)
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

	# Advance hurt timer
	if _hurt_timer > 0:
		_hurt_timer -= delta

	_update_animation(delta)

	# Bleed damage over time
	if _bleed_timer > 0:
		_bleed_timer -= delta
		take_damage(_bleed_damage * delta)
		if _bleed_timer <= 0:
			_bleed_damage = 0.0


## Animation state machine — picks idle / walk / attack / hurt based on
## game state and advances the Sprite2D frame within the spritesheet row.
func _update_animation(delta: float) -> void:
	if _visual_ref == null or _visual_ref.texture == null:
		return

	# Determine desired animation state (priority order).
	var anim := "walk"
	if _hurt_timer > 0:
		anim = "hurt"
	elif target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist < 45.0:
			anim = "attack"
	elif state == State.STUNNED or state == State.FROZEN:
		anim = "idle"

	# Reset frame counter when state changes.
	if anim != _anim_state:
		_anim_state = anim
		_anim_frame = 0
		_anim_timer = 0.0
		_visual_ref.frame = _ANIM_ROW[anim] * ANIM_HFRAMES

	# Advance frame at the animation's fps.
	_anim_timer -= delta
	if _anim_timer <= 0.0:
		_anim_timer = 1.0 / _ANIM_FPS[anim]
		var fc: int = _ANIM_FRAMES[anim]
		_anim_frame = (_anim_frame + 1) % fc
		_visual_ref.frame = _ANIM_ROW[anim] * ANIM_HFRAMES + _anim_frame


func take_damage(amount: float) -> void:
	current_health -= amount
	_hurt_timer = 0.15
	# Floating damage number for the player to read. Big hits (>=15% of max
	# HP) render as gold crit-style numbers. Added to the live scene so it
	# survives the zombie dying on this same hit.
	var is_big := amount >= base_health * 0.15
	_spawn_damage_number(amount, is_big)
	if current_health <= 0:
		die()


## Spawn a DamageNumber in world space above this zombie.
func _spawn_damage_number(amount: float, is_big: bool) -> void:
	if amount <= 0.0:
		return
	var dn = DamageNumberScript.new()
	var scene = get_tree().current_scene
	if scene != null:
		scene.add_child(dn)
		dn.setup(global_position, amount, is_big)
	elif get_parent() != null:
		get_parent().add_child(dn)
		dn.setup(global_position, amount, is_big)


## Quick white/red flash so the player sees a bullet connect.
func flash_hit() -> void:
	_hurt_timer = 0.15
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
	# Souls are the shop currency — earned on every kill, scaled down from the
	# XP reward so a floor's worth of kills buys a few items rather than dozens.
	Game.souls += max(1, roundi(xp_reward * 0.3))
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

	# Random drops. Raised after feedback that weapons/equipment felt too
	# scarce to build a loadout: weapon 6%, accessory 5%, parts 3%, companion
	# (护卫) 4%, potion 12%. Soul orbs (XP) are unaffected.
	var roll = randf()
	if roll < 0.12:
		_add_drop(scene, PickupItemScript.ItemType.POTION)
	elif roll < 0.18:
		_add_drop(scene, PickupItemScript.ItemType.WEAPON)
	elif roll < 0.23:
		_add_drop(scene, PickupItemScript.ItemType.ACCESSORY)
	elif roll < 0.26:
		_add_drop(scene, PickupItemScript.ItemType.PARTS)
	elif roll < 0.30:
		_add_drop(scene, PickupItemScript.ItemType.COMPANION)


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
		GameEnums.StatusEffect.BLEED:
			# Bleed: damage over time, stacks
			_bleed_timer = duration
			_bleed_damage = base_health * 0.02
		GameEnums.StatusEffect.SLOW:
			var old_speed = current_speed
			current_speed *= 0.6
			await get_tree().create_timer(duration).timeout
			if is_inside_tree():
				current_speed = old_speed
		GameEnums.StatusEffect.ARMOR_DOWN:
			# Reduce zombie effective armor (placeholder)
			pass


var _bleed_timer: float = 0.0
var _bleed_damage: float = 0.0


func apply_knockback(direction: Vector2) -> void:
	velocity = direction
	move_and_slide()
