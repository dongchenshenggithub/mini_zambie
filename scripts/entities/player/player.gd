## Main player character.
class_name Player
extends CharacterBody2D

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const AccessoryDataScript = preload("res://scripts/accessory_data.gd")
const WorldHealthBarScript = preload("res://scripts/ui/world_health_bar.gd")

const BASE_SPEED: float = 200.0

@export var stats: PlayerStats = PlayerStats.new()
@export var inventory: WeaponInventory
@export var prosthetic_manager: ProstheticManager
var character_data: CharacterEntry = null:
	set(v):
		_character_data = v
		_refresh_character_visual()
	get:
		return _character_data
var _character_data: CharacterEntry = null

var behavior: CharacterBehavior = null
## Display-only list of equipped accessories (their stat bonuses are merged into
## character_data/stats; this list lets the status panel show what was equipped).
var equipped_accessories: Array[AccessoryDataScript] = []
var _visual: Sprite2D = null
var _visual_class: int = -1
var _weapon_visual: Sprite2D = null
var _health_bar = null  # WorldHealthBar instance (typed at runtime)
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
## Last touch position in viewport space; used as a fallback for _aim_dir
## when no mouse events are present (touchscreen devices).
var _last_touch_pos: Vector2 = Vector2.ZERO

## --- animation state machine (spritesheet 4x4) ---
const ANIM_HFRAMES := 4
const ANIM_VFRAMES := 4
var _anim_state: String = "idle"
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _attack_anim_timer: float = 0.0

## Per-anim config: row index, unique frame count, fps.
const _ANIM_ROW := {"idle": 0, "walk": 1, "attack": 2, "hurt": 3}
const _ANIM_FRAMES := {"idle": 2, "walk": 4, "attack": 3, "hurt": 2}
const _ANIM_FPS := {"idle": 2.0, "walk": 10.0, "attack": 12.0, "hurt": 8.0}


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
	# Health bar floating above the player's head (world space).
	_health_bar = WorldHealthBarScript.new()
	_health_bar.name = "HealthBar"
	add_child(_health_bar)
	_update_health_bar()


## Held-weapon sprite that aims toward the nearest zombie.
func _create_weapon_visual() -> void:
	_weapon_visual = Sprite2D.new()
	_weapon_visual.name = "WeaponVisual"
	_weapon_visual.scale = Vector2(0.55, 0.55)
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
## On touchscreens `get_global_mouse_position()` returns (0,0), so we also
## track the last touch position here and use it as a fallback.
func _compute_aim_dir() -> void:
	var mp := get_global_mouse_position()
	if _last_touch_pos != Vector2.ZERO:
		mp = _last_touch_pos
	if global_position.distance_to(mp) > 1.0:
		_aim_dir = (mp - global_position).normalized()


## Mouse-aim direction, shared with weapons so bullets fly where the cursor points.
func get_aim_dir() -> Vector2:
	return _aim_dir


## Animation state machine — picks idle / walk / attack / hurt based on
## game state and advances the Sprite2D frame within the spritesheet row.
func _update_animation(delta: float) -> void:
	if _visual == null or _visual.texture == null:
		return

	# Determine desired animation state (priority order).
	var state := "idle"
	if _flash_timer > 0:
		state = "hurt"
	elif _attack_anim_timer > 0:
		state = "attack"
	elif velocity.length_squared() > 1.0:
		state = "walk"

	# Reset frame counter when state changes.
	if state != _anim_state:
		_anim_state = state
		_anim_frame = 0
		_anim_timer = 0.0
		_visual.frame = _ANIM_ROW[state] * ANIM_HFRAMES

	# Advance frame at the animation's fps.
	_anim_timer -= delta
	if _anim_timer <= 0.0:
		_anim_timer = 1.0 / _ANIM_FPS[state]
		var fc: int = _ANIM_FRAMES[state]
		_anim_frame = (_anim_frame + 1) % fc
		_visual.frame = _ANIM_ROW[state] * ANIM_HFRAMES + _anim_frame


func _create_player_visual() -> Sprite2D:
	_visual = Sprite2D.new()
	var cls: int = 0
	if character_data:
		cls = character_data.character_class
	_visual_class = cls
	var tex = PixelLoader.load_texture("res://assets/pixel/player_%d.png" % cls)
	if tex != null:
		_visual.texture = tex
	_visual.hframes = ANIM_HFRAMES
	_visual.vframes = ANIM_VFRAMES
	_visual.frame = 0
	_visual.scale = Vector2(0.65, 0.65)
	_visual.modulate = _original_color
	_visual.visible = true
	return _visual


## Re-applies the correct character spritesheet when character_data is assigned
## after the visual was already built (e.g. assigned post-_ready).
func _refresh_character_visual() -> void:
	if _visual == null:
		return
	var cls: int = 0
	if character_data:
		cls = character_data.character_class
	_visual_class = cls
	var tex = PixelLoader.load_texture("res://assets/pixel/player_%d.png" % cls)
	if tex != null:
		_visual.texture = tex
	_visual.hframes = ANIM_HFRAMES
	_visual.vframes = ANIM_VFRAMES


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

	# Attack-anim timer: keep attack pose while firing, or for a short
	# window after a single click (SEMI).
	if _fire_held:
		_attack_anim_timer = 0.18
	elif _attack_anim_timer > 0:
		_attack_anim_timer -= delta

	_update_animation(delta)


## Capture fire / reload input here (event-driven) instead of polling Input
## inside _physics_process. Reliable for both quick clicks and held fire, and
## works for keyboard (Space) and gamepad as well as the mouse.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_last_touch_pos = event.position
	elif event is InputEventScreenDrag:
		_last_touch_pos = event.position
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
		inventory.max_weapons = character_data.max_weapons
		prosthetic_manager.is_mech_monk = (character_data.character_class == 1)
	# Derive combat stats (multipliers/speed/armor/crit) from the base attributes
	# so that attribute upgrades actually change how the player fights.
	recompute_combat_stats()


func _create_behavior() -> void:
	if behavior != null:
		return
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
	_update_health_bar()


func take_damage(amount: float) -> void:
	_flash_timer = 0.15
	SfxManager.play("player_hurt")
	if behavior:
		behavior.on_player_take_damage(amount)
	var _actual = stats.take_damage(amount)
	_update_health_bar()
	if not stats.is_alive():
		if behavior:
			behavior.on_player_die()
		Game.end_game()
		call_deferred("queue_free")


func heal(amount: float) -> void:
	stats.heal(amount)
	_update_health_bar()


## Push current/max HP into the floating health bar above the player's head.
func _update_health_bar() -> void:
	if _health_bar != null and stats != null:
		_health_bar.set_health(stats.current_health, stats.max_health)
