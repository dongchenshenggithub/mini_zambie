## Main player character.
class_name Player
extends CharacterBody2D

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const AccessoryDataScript = preload("res://scripts/accessory_data.gd")

const BASE_SPEED: float = 200.0

@export var stats: PlayerStats = PlayerStats.new()
@export var inventory: WeaponInventory
@export var prosthetic_manager: ProstheticManager
@export var character_data: CharacterEntry

var behavior: CharacterBehavior = null
## Display-only list of equipped accessories (their stat bonuses are merged into
## character_data/stats; this list lets the status panel show what was equipped).
var equipped_accessories: Array[AccessoryDataScript] = []
var _visual: Sprite2D = null
var _weapon_visual: Sprite2D = null
var _aim_dir: Vector2 = Vector2.RIGHT
var _flash_timer: float = 0.0
var _original_color: Color = Color.WHITE
## Buffered fire input, set by _input (event-driven, 100% reliable) and pushed
## to every weapon each physics frame. This avoids reading Input.* inside the
## weapons' _physics_process, which is unreliable in Godot 4 (a quick click can
## be missed, and is_action_just_pressed is consumed by the first weapon that
## reads it in a frame — leaving only one of several weapons able to fire).
var _fire_held: bool = false
var _fire_just_pressed: bool = false


func _ready() -> void:
	add_to_group("player")
	stats.current_health = stats.max_health
	if inventory == null:
		inventory = WeaponInventory.new()
		add_child(inventory)
	if prosthetic_manager == null:
		prosthetic_manager = ProstheticManager.new(false, stats)
		add_child(prosthetic_manager)
	if inventory:
		inventory.weapon_equipped.connect(_on_weapon_equipped)
	_apply_character_traits()
	_create_behavior()
	_setup_visuals()


func _setup_visuals() -> void:
	var vis = _create_player_visual()
	vis.name = "Visual"
	add_child(vis)
	_create_weapon_visual()


## Held-weapon sprite that aims toward the nearest zombie.
func _create_weapon_visual() -> void:
	_weapon_visual = Sprite2D.new()
	_weapon_visual.name = "WeaponVisual"
	_weapon_visual.scale = Vector2(1.1, 1.1)
	_weapon_visual.visible = false
	add_child(_weapon_visual)
	_refresh_weapon_visual()


func _on_weapon_equipped(_idx: int, _w: WeaponBase) -> void:
	_refresh_weapon_visual()


func _refresh_weapon_visual() -> void:
	if _weapon_visual == null or inventory == null:
		return
	if inventory.weapons.is_empty():
		_weapon_visual.visible = false
		return
	var cat: int = inventory.weapons[-1].weapon_category
	var tex = PixelLoader.load_texture(_weapon_icon_path(cat))
	if tex != null:
		_weapon_visual.texture = tex
	_weapon_visual.visible = true


func _weapon_icon_path(cat: int) -> String:
	match cat:
		GameEnums.WeaponCategory.LIGHT_RANGED: return "res://assets/pixel/weapon_rifle.png"
		GameEnums.WeaponCategory.HEAVY_RANGED: return "res://assets/pixel/weapon_heavy_ranged.png"
		GameEnums.WeaponCategory.MELEE_SHARP: return "res://assets/pixel/weapon_blade.png"
		GameEnums.WeaponCategory.MELEE_BLUNT: return "res://assets/pixel/weapon_blunt.png"
		GameEnums.WeaponCategory.HEAVY_MELEE_BLUNT: return "res://assets/pixel/weapon_heavy_blunt.png"
		GameEnums.WeaponCategory.LIGHT_LASER: return "res://assets/pixel/weapon_laser.png"
		GameEnums.WeaponCategory.HEAVY_LASER: return "res://assets/pixel/weapon_heavy_laser.png"
		GameEnums.WeaponCategory.THROWABLE: return "res://assets/pixel/weapon_throw.png"
		GameEnums.WeaponCategory.EXPLOSIVE: return "res://assets/pixel/weapon_explosive.png"
		GameEnums.WeaponCategory.SUMMON: return "res://assets/pixel/weapon_summon.png"
		GameEnums.WeaponCategory.SPRAY_EFFECT: return "res://assets/pixel/weapon_spray.png"
		_: return "res://assets/pixel/weapon_icon.png"


## Points the held weapon at the mouse cursor (keeps last direction as a
## fallback when the cursor sits right on top of the player).
func _compute_aim_dir() -> void:
	var mp := get_global_mouse_position()
	if global_position.distance_to(mp) > 1.0:
		_aim_dir = (mp - global_position).normalized()


## Mouse-aim direction, shared with weapons so bullets fly where the cursor points.
func get_aim_dir() -> Vector2:
	return _aim_dir


func _create_player_visual() -> Sprite2D:
	_visual = Sprite2D.new()
	var cls: int = 0
	if character_data:
		cls = character_data.character_class
	var tex = PixelLoader.load_texture("res://assets/pixel/player_%d.png" % cls)
	if tex != null:
		_visual.texture = tex
	_visual.scale = Vector2(1.3, 1.3)
	_visual.modulate = _original_color
	_visual.visible = true
	return _visual


func _physics_process(delta: float) -> void:
	if _flash_timer > 0:
		_flash_timer -= delta
		if _visual:
			_visual.modulate = Color(1.0, 0.4, 0.4, 1.0) if _flash_timer > 0.05 else _original_color
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
	velocity = direction * stats.get_movement_speed()
	move_and_slide()

	# Keep the player inside the current floor's bounds so it can never walk
	# off the background art. The bounds come from GameScene (duck-typed to
	# avoid a circular import); a small margin keeps the sprite fully on-screen.
	var gs = get_tree().current_scene
	if gs != null and gs.has_method("get_world_bounds"):
		var b = gs.get_world_bounds()
		var m := 22.0
		global_position.x = clamp(global_position.x, b.position.x + m, b.position.x + b.size.x - m)
		global_position.y = clamp(global_position.y, b.position.y + m, b.position.y + b.size.y - m)

	# Weapons fire when the player holds the fire input (mouse / Space /
	# trigger). WeaponBase._physics_process honors fire_rate + the input, so
	# we deliberately do NOT call try_fire() here.

	# Aim the held weapon visual at the mouse cursor.
	_compute_aim_dir()
	if _weapon_visual and _weapon_visual.visible:
		_weapon_visual.rotation = _aim_dir.angle()
		_weapon_visual.position = _aim_dir * 15.0

	# Push the buffered fire input to every weapon so all of them fire on the
	# same click/hold. The edge (_fire_just_pressed) is consumed after this one
	# physics frame so a single click yields exactly one shot per weapon.
	if inventory:
		for w in inventory.weapons:
			w.set_fire_input(_fire_held, _fire_just_pressed)
	_fire_just_pressed = false


## Capture fire / reload input here (event-driven) instead of polling Input
## inside _physics_process. Reliable for both quick clicks and held fire, and
## works for keyboard (Space) and gamepad as well as the mouse.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fire") and not event.is_echo():
		_fire_held = true
		_fire_just_pressed = true
	elif event.is_action_released("fire"):
		_fire_held = false
	if event.is_action_pressed("reload") and not event.is_echo():
		if inventory:
			for w in inventory.weapons:
				w.start_reload()


func _apply_character_traits() -> void:
	if character_data:
		stats.max_health = character_data.starting_health
		stats.current_health = stats.max_health
		stats.movement_speed = character_data.starting_speed
		stats.damage_multiplier_ranged = character_data.ranged_damage_multiplier
		stats.damage_multiplier_melee = character_data.melee_damage_multiplier
		stats.damage_multiplier_summon = character_data.summon_damage_multiplier
		stats.damage_multiplier_spray = character_data.spray_damage_multiplier
		stats.damage_multiplier_laser = character_data.laser_damage_multiplier
		stats.self_heal_rate = character_data.heal_rate
		inventory.build_direction = character_data.build_direction
		inventory.max_followers = character_data.max_followers
		prosthetic_manager.is_mech_monk = (character_data.character_class == 1)
	# Derive combat stats (multipliers/speed/armor/crit) from the base attributes
	# so that attribute upgrades actually change how the player fights.
	recompute_combat_stats()


func _create_behavior() -> void:
	if character_data:
		behavior = BehaviorFactory.create_behavior(
			character_data.character_class, self, character_data
		)


## Maps the character's base attributes (strength/agility/...) onto the combat
## stats that weapons and damage calculations actually read. Preserves each
## character's innate class multipliers (the bonus grows from attribute points
## above the baseline of 5). Call this after any attribute upgrade.
func recompute_combat_stats() -> void:
	var cd := character_data
	if cd == null or stats == null:
		return
	var PER_POINT := 0.03          # +3% damage multiplier per attribute point above baseline
	var above_str := maxf(0.0, float(cd.strength) - 5.0)
	var above_agi := maxf(0.0, float(cd.agility) - 5.0)
	var above_int := maxf(0.0, float(cd.intelligence) - 5.0)
	var above_con := maxf(0.0, float(cd.constitution) - 5.0)
	var above_lck := maxf(0.0, float(cd.luck) - 5.0)
	var above_wil := maxf(0.0, float(cd.willpower) - 5.0)

	stats.damage_multiplier_melee = cd.melee_damage_multiplier + above_str * PER_POINT
	stats.damage_multiplier_ranged = cd.ranged_damage_multiplier + above_agi * PER_POINT
	stats.damage_multiplier_laser = cd.laser_damage_multiplier + above_int * PER_POINT
	stats.damage_multiplier_summon = cd.summon_damage_multiplier + above_int * PER_POINT
	stats.damage_multiplier_spray = cd.spray_damage_multiplier + above_wil * PER_POINT
	stats.movement_speed = cd.starting_speed + above_agi * 4.0
	stats.armor = int(above_con)                 # +1 armor per point above baseline
	stats.crit_bonus = above_lck * 0.01          # +1% crit per point above baseline
	stats.self_heal_rate = cd.heal_rate + above_wil * 0.2

	# Accessory bonuses (装备) — additive so they survive recomputes.
	stats.armor += stats.accessory_armor_bonus
	stats.movement_speed += stats.accessory_speed_bonus
	stats.damage_multiplier_ranged += stats.accessory_ranged_mult
	stats.damage_multiplier_melee += stats.accessory_melee_mult
	stats.damage_multiplier_laser += stats.accessory_laser_mult
	stats.damage_multiplier_summon += stats.accessory_summon_mult
	stats.damage_multiplier_spray += stats.accessory_spray_mult
	stats.crit_bonus += stats.accessory_crit_bonus


func take_damage(amount: float) -> void:
	_flash_timer = 0.15
	SfxManager.play("player_hurt")
	if behavior:
		behavior.on_player_take_damage(amount)
	var _actual = stats.take_damage(amount)
	if not stats.is_alive():
		if behavior:
			behavior.on_player_die()
		Game.end_game()
		call_deferred("queue_free")


func heal(amount: float) -> void:
	stats.heal(amount)
