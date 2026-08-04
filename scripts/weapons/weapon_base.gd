## Base class for all weapons. Handles fire rate, damage calculation, cooldown, and durability.
class_name WeaponBase
extends Node2D

@export var weapon_name: String = "Weapon"
@export var damage: float = 10.0
@export var fire_rate: float = 1.0
@export var range: float = 200.0
@export var attack_type: GameEnums.AttackType = GameEnums.AttackType.RANGED
@export var weapon_category: GameEnums.WeaponCategory = GameEnums.WeaponCategory.LIGHT_RANGED
@export var weapon_weight: int = 2

@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0
@export var pierce: int = 0
@export var splash_radius: float = 0.0
@export var effect: GameEnums.StatusEffect = GameEnums.StatusEffect.NONE
@export var effect_duration: float = 0.0

var _fire_cooldown: float = 0.0
var durability: float = 100.0
var durability_decay_rate: float = 1.0  # % per minute
var weapon_owner: Player = null
var equipped_weapon_index: int = 0
## When true the weapon fires on its own (autonomous summons). Player-held
## weapons leave this false and only fire while the fire input is held.
var auto_fire: bool = false

## Fire behaviour. AUTO = hold to keep firing (gated by fire_rate).
## SEMI = one shot per click; tapping faster fires faster up to fire_rate.
var fire_mode: int = GameEnums.FireMode.AUTO

## Magazine / ammo. magazine_size == 0 means the weapon has no clip
## (melee / spray / summon) and fires infinitely. Ranged weapons set a
## clip size + per-weapon reload time.
var magazine_size: int = 0
var current_ammo: int = 0
var reload_time: float = 0.0
var is_reloading: bool = false
var _reload_timer: float = 0.0
var _mag_ready: bool = false

## Buffered fire input, set every physics frame by the player (Player._input
## captures the real key/mouse event and Player._physics_process pushes it
## here). Reading Input.* directly inside _physics_process is unreliable:
## is_action_just_pressed can be missed or is consumed by the first weapon that
## reads it in a frame, so only one of several weapons would ever fire.
var _fire_held: bool = false
var _fire_just_pressed: bool = false

var _durability_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if weapon_owner == null or not weapon_owner.stats.is_alive():
		return
	# Lazily fill the magazine the first time this weapon is processed (covers
	# both .new() and preloaded-instance creation paths, and keeps the HUD
	# from showing 0/mag before the first shot).
	if magazine_size > 0 and not _mag_ready:
		current_ammo = magazine_size
		_mag_ready = true

	if is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_finish_reload()
		# Hold the cooldown at zero so the shot fires the instant reloading ends.
		_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
		_process_durability(delta)
		return

	# Summons self-deploy inside their own subclass; they must never fire from
	# player input, so skip the fire-input gating entirely.
	if attack_type == GameEnums.AttackType.SUMMON:
		_process_durability(delta)
		return

	_fire_cooldown -= delta
	# Decide whether the player (or auto-fire) wants to shoot this frame. The
	# fire state is buffered by the player, not read from Input here.
	# Both AUTO and SEMI fire WHILE the button is held (gated by fire_rate) and
	# on the initial click edge. This keeps several bullets in flight at once
	# instead of "one at a time, next only after the previous disappears" — a
	# single tap still yields exactly one shot because just_pressed fires once
	# and the cooldown then respects fire_rate.
	var want := auto_fire or _fire_held or _fire_just_pressed
	if _fire_cooldown <= 0.0 and want:
		if try_fire(delta):
			_fire_cooldown = 1.0 / fire_rate

	_process_durability(delta)


## Buffers the current fire input for this weapon. Called by the player each
## physics frame with the event-driven fire state (held + edge-triggered
## press), so every weapon sees the same click in the same frame.
func set_fire_input(held: bool, just_pressed: bool) -> void:
	_fire_held = held
	_fire_just_pressed = just_pressed


## Public fire entry point. Returns true if a shot was actually emitted
## (false when out of ammo / reloading / broken). Kept for compatibility with
## direct callers (tests, AI behaviours).
func try_fire(_delta: float) -> bool:
	return _attempt_fire()


func _attempt_fire() -> bool:
	if magazine_size > 0 and not _mag_ready:
		current_ammo = magazine_size
		_mag_ready = true
	if magazine_size > 0 and current_ammo <= 0:
		start_reload()
		return false
	if weapon_owner == null or not weapon_owner.stats.is_alive() or durability <= 0:
		return false
	if magazine_size > 0:
		current_ammo -= 1
		if current_ammo <= 0:
			start_reload()  # auto-reload when the clip runs dry
	# SFX: melee swings, ranged/clip weapons "shoot", summons stay silent here.
	if attack_type == GameEnums.AttackType.MELEE:
		SfxManager.play("swing")
	elif magazine_size > 0:
		SfxManager.play("shoot")
	fire()
	return true


## Begin reloading if the weapon actually uses a magazine and isn't full.
func start_reload() -> void:
	if magazine_size <= 0 or is_reloading or current_ammo >= magazine_size:
		return
	is_reloading = true
	_reload_timer = reload_time
	SfxManager.play("reload")


## Finish reloading (also called directly by tests / logic).
func _finish_reload() -> void:
	is_reloading = false
	current_ammo = magazine_size
	_reload_timer = 0.0


func cancel_reload() -> void:
	is_reloading = false
	_reload_timer = 0.0


func fire() -> void:
	pass


## Direction bullets travel. Player-held weapons follow the mouse via the
## player's aim; override per-weapon only if a different rule is needed.
func _get_attack_direction() -> Vector2:
	if weapon_owner != null:
		return weapon_owner.get_aim_dir()
	return Vector2.RIGHT


func take_damage_from_zombie() -> void:
	durability -= 10.0


func get_final_damage() -> float:
	if weapon_owner == null:
		return damage
	var stats = weapon_owner.stats as PlayerStats
	var mult = stats.get_damage_multiplier(attack_type)
	var inv = weapon_owner.inventory as WeaponInventory
	if inv:
		mult *= inv.calculate_build_bonus()
	var final = damage * mult
	var crit = crit_chance
	if stats:
		crit += stats.get_crit_bonus()
	if randf() < crit:
		final *= crit_multiplier
	return final


func apply_upgrade(upgrade_type: String, value: float) -> void:
	match upgrade_type:
		"damage":
			damage *= (1.0 + value)
		"fire_rate":
			fire_rate *= (1.0 + value)
		"range":
			range *= (1.0 + value)
		"pierce":
			pierce = int(pierce + value)
		"crit_chance":
			crit_chance = minf(0.8, crit_chance + value)
		"splash_radius":
			splash_radius += value
		"effect_duration":
			effect_duration += value
		"magazine":
			magazine_size += int(value)
			current_ammo = magazine_size
		"reload_time":
			reload_time = maxf(0.1, reload_time + value)


func repair(amount: float) -> void:
	durability = minf(100.0, durability + amount)


func _process_durability(delta: float) -> void:
	_durability_timer += delta
	if _durability_timer >= 60.0:
		_durability_timer = 0.0
		durability -= durability_decay_rate
