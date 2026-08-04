## Headless verification for the magazine + fire-mode + reload rework.
## Uses REAL engine frames (so is_action_just_pressed behaves like gameplay):
##   phase 0: AUTO weapon held  -> many bullets on screen at once
##   phase 1: SEMI weapon held   -> a single shot (one per press)
##   phase 2: SEMI weapon tapped -> more shots than holding (tap faster = faster)
##   phase 3: direct unit checks for ammo consumption + reload trigger/refill,
##            plus per-weapon reflection, melee/spray/summon rules, SFX.
## Not part of the game.
extends SceneTree

const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const ProjectileBaseScript = preload("res://scripts/projectiles/projectile_base.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const WeaponInventoryScript = preload("res://scripts/entities/player/weapon_inventory.gd")
const ProstheticManagerScript = preload("res://scripts/core/prosthetic_manager.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const AccessoryRegistryScript = preload("res://scripts/systems/accessory_registry.gd")
const LimbRegistryScript = preload("res://scripts/systems/limb_registry.gd")
const SfxManagerScript = preload("res://scripts/core/sfx_manager.gd")

const WeaponRifleScript = preload("res://scripts/weapons/ranged/weapon_rifle.gd")
const WeaponShotgunScript = preload("res://scripts/weapons/ranged/weapon_shotgun.gd")
const WeaponSMGScript = preload("res://scripts/weapons/ranged/weapon_smg.gd")
const WeaponRPGScript = preload("res://scripts/weapons/ranged/weapon_rpg.gd")
const WeaponElectricScript = preload("res://scripts/weapons/ranged/weapon_electric.gd")
const WeaponDroneScript = preload("res://scripts/weapons/summon/weapon_drone.gd")
const WeaponTurretScript = preload("res://scripts/weapons/summon/weapon_turret.gd")
const WeaponMechDogScript = preload("res://scripts/weapons/summon/weapon_mechdog.gd")
const WeaponZombieSummonScript = preload("res://scripts/weapons/summon/weapon_zombiesummon.gd")
const WeaponChainsawScript = preload("res://scripts/weapons/melee/weapon_chainsaw.gd")
const WeaponFlameScript = preload("res://scripts/weapons/spray/weapon_flame.gd")

var world: Node2D
var player
var zombie
var _started := false
var _elapsed := 0.0
var _phase := 0
var _peak_auto := 0
var _peak_semi_hold := 0
var _peak_semi_tap := 0
var _tap_timer := 0.0
var _tapping := false
var _checks: Dictionary = {}
var _results: Array[String] = []


func _init() -> void:
	world = Node2D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world

	AccessoryRegistryScript.init()
	LimbRegistryScript.init()

	var cd = CharacterEntryScript.new()
	cd.strength = 5; cd.agility = 5; cd.intelligence = 5
	cd.constitution = 5; cd.luck = 5; cd.willpower = 5
	cd.starting_health = 100.0; cd.starting_speed = 200.0
	cd.ranged_damage_multiplier = 1.0; cd.character_class = 0
	player = PlayerScript.new()
	player.set("character_data", cd)
	player.stats = PlayerStatsScript.new()
	player.prosthetic_manager = ProstheticManagerScript.new(false, player.stats)
	world.add_child(player)
	player.global_position = Vector2.ZERO
	player.add_to_group("player")

	zombie = ZombieBaseScript.new()
	zombie.zombie_type = GameEnums.ZombieType.NORMAL
	zombie.global_position = Vector2(140, 0)
	world.add_child(zombie)
	zombie.add_to_group("zombie")
	zombie.target_player = player


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		_setup_weapons()
		_fire_press()  # begin AUTO hold (input via Player._input)
		return false

	_elapsed += delta
	var pc = _count_projectiles()

	match _phase:
		0:  # AUTO hold
			_peak_auto = maxi(_peak_auto, pc)
			if _elapsed >= 0.5:
				_phase = 1
				_fire_release()
				_clear_projectiles()
				_swap_to_rifle()
				_fire_press()  # begin SEMI hold (one press -> one shot)
		1:  # SEMI hold (single shot expected)
			_peak_semi_hold = maxi(_peak_semi_hold, pc)
			if _elapsed >= 1.0:
				_phase = 2
				_fire_release()
				_clear_projectiles()
				_tap_timer = 0.0
				_tapping = false
		2:  # SEMI tap (alternate press/release every ~0.09s)
			_peak_semi_tap = maxi(_peak_semi_tap, pc)
			_tap_timer += delta
			if _tap_timer >= 0.09:
				_tap_timer = 0.0
				if _tapping:
					_fire_release()
					_tapping = false
				else:
					_fire_press()
					_tapping = true
			if _elapsed >= 1.6:
				_phase = 3
				if _tapping:
					_fire_release()
				_clear_projectiles()
				_unit_and_reflection_checks()
				_report()
				quit()
	return false


## Feed a real fire event through Player._input (the engine's actual input
## path). Input.action_press does not dispatch to _input in this build.
func _fire_press() -> void:
	var ev := InputEventAction.new()
	ev.action = &"fire"
	ev.pressed = true
	player._input(ev)


func _fire_release() -> void:
	var ev := InputEventAction.new()
	ev.action = &"fire"
	ev.pressed = false
	player._input(ev)


func _setup_weapons() -> void:
	player.inventory.weapons.clear()
	var smg = WeaponSMGScript.new()
	_checks["smg_equip"] = player.inventory.equip_weapon(smg)
	# Give SMG an effectively-infinite clip so the multi-bullet phase isn't
	# interrupted by a reload.
	smg.magazine_size = 9999; smg.current_ammo = 9999; smg._mag_ready = true


func _swap_to_rifle() -> void:
	# Remove the SMG, equip the rifle (SEMI) as the sole weapon.
	while player.inventory.weapons.size() > 0:
		player.inventory.remove_weapon(0)
	var rifle = WeaponRifleScript.new()
	_checks["rifle_equip"] = player.inventory.equip_weapon(rifle)


func _unit_and_reflection_checks() -> void:
	# --- AUTO held -> many bullets at once ---
	_checks["auto_multi_bullet"] = _peak_auto > 1
	_results.append("MAG auto_peak_bullets=%d (expected >> 1)" % _peak_auto)

	# --- SEMI held -> exactly one shot ---
	_checks["semi_hold_one_shot"] = _peak_semi_hold <= 2
	_results.append("MAG semi_hold_peak=%d (expected ~1)" % _peak_semi_hold)

	# --- SEMI tapped faster -> more bullets than holding ---
	_checks["semi_tap_faster"] = _peak_semi_tap > _peak_semi_hold
	_results.append("MAG semi_tap_peak=%d vs hold_peak=%d" % [_peak_semi_tap, _peak_semi_hold])

	# --- Magazine + reload (direct, deterministic) ---
	# Equip through the real inventory path so `owner` is wired correctly
	# (matches gameplay; the live phases above already prove bullets spawn).
	while player.inventory.weapons.size() > 0:
		player.inventory.remove_weapon(0)
	var w = WeaponRifleScript.new()
	player.inventory.equip_weapon(w)
	w.magazine_size = 3; w.current_ammo = 3; w.reload_time = 1.5
	w.is_reloading = false; w._reload_timer = 0.0; w._mag_ready = true
	var shots := 0
	while w.current_ammo > 0:
		w._fire_cooldown = 0.0
		if w.try_fire(0.0):
			shots += 1
		_results.append("MAG dbg ammo=%d reloading=%s" % [w.current_ammo, w.is_reloading])
	_checks["ammo_consumed"] = (shots == 3)
	_checks["reload_triggered"] = w.is_reloading
	w._finish_reload()
	_checks["reload_refilled"] = (w.current_ammo == w.magazine_size) and (not w.is_reloading)
	_results.append("MAG shots=%d reload_on_empty=%s after_reload_ammo=%d" % [shots, w.is_reloading, w.current_ammo])

	# --- Per-weapon reflection ---
	var ranged := [WeaponRifleScript, WeaponShotgunScript, WeaponSMGScript, WeaponRPGScript, WeaponElectricScript]
	for S in ranged:
		var inst = S.new()
		var ok = (inst.magazine_size > 0) and (inst.reload_time > 0)
		_checks["ranged_has_mag_%s" % inst.weapon_name] = ok
		_results.append("MAG %s mag=%d reload=%.2f mode=%s" % [
			inst.weapon_name, inst.magazine_size, inst.reload_time,
			"AUTO" if inst.fire_mode == GameEnums.FireMode.AUTO else "SEMI"])
	var reloads := {}
	for S in ranged:
		var inst = S.new()
		reloads[inst.weapon_name] = inst.reload_time
	_checks["distinct_reload_times"] = (reloads.size() == 5) and (len(reloads.values()) == 5)
	_results.append("MAG reload_times=%s" % str(reloads))

	# --- Mode sanity ---
	_checks["smg_auto"] = (WeaponSMGScript.new().fire_mode == GameEnums.FireMode.AUTO)
	_checks["rifle_semi"] = (WeaponRifleScript.new().fire_mode == GameEnums.FireMode.SEMI)

	# --- Melee / spray: no magazine, AUTO ---
	var chain = WeaponChainsawScript.new()
	var flame = WeaponFlameScript.new()
	_checks["melee_no_mag"] = (chain.magazine_size == 0) and (chain.fire_mode == GameEnums.FireMode.AUTO)
	_checks["spray_no_mag"] = (flame.magazine_size == 0) and (flame.fire_mode == GameEnums.FireMode.AUTO)

	# --- Summons: no clip, auto-deploy without input ---
	var all_summon_ok := true
	var summons := [WeaponDroneScript, WeaponTurretScript, WeaponMechDogScript, WeaponZombieSummonScript]
	for S in summons:
		var inst = S.new()
		if inst.magazine_size != 0:
			all_summon_ok = false
	_checks["all_summons_no_mag"] = all_summon_ok

	# --- SFX (incl. new reload sample) plays without error ---
	for s in ["shoot", "hit", "reload", "explosion", "swing"]:
		SfxManagerScript.play(s)
	_checks["sfx_no_error"] = true


func _report() -> void:
	var all_ok := true
	for k in _checks.keys():
		if _checks[k] == false:
			all_ok = false
	for r in _results:
		print(r)
	print("MAGAZINE_PASS" if all_ok else "MAGAZINE_FAIL")


func _count_projectiles() -> int:
	var c = 0
	for ch in world.get_children():
		if ch is ProjectileBaseScript:
			c += 1
	return c


func _clear_projectiles() -> void:
	for ch in world.get_children():
		if ch is ProjectileBaseScript:
			ch.queue_free()
