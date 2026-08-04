## Headless verification of the new fire model:
##  - player-held weapons read the player's mouse-aim direction
##  - weapons do NOT auto-fire without the fire input held
##  - holding the fire input spawns bullets (respecting fire_rate)
##  - releasing the fire input stops firing
##  - autonomous summon weapons self-deploy without any input
## Not part of the game.
extends SceneTree

const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const WeaponInventoryScript = preload("res://scripts/entities/player/weapon_inventory.gd")
const ProstheticManagerScript = preload("res://scripts/core/prosthetic_manager.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const WeaponRifleScript = preload("res://scripts/weapons/ranged/weapon_rifle.gd")
const ProjectileBaseScript = preload("res://scripts/projectiles/projectile_base.gd")
const WeaponMechDogScript = preload("res://scripts/weapons/summon/weapon_mechdog.gd")
const SummonUnitScript = preload("res://scripts/entities/summon/summon_unit.gd")

var world: Node2D
var player
var rifle
var mechdog
var _started := false
var _checks: Dictionary = {}
var _info: Array[String] = []


func _init() -> void:
	world = Node2D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world

	var cd = CharacterEntryScript.new()
	for f in ["strength", "agility", "intelligence", "constitution", "luck", "willpower"]:
		cd.set(f, 5)
	cd.starting_health = 100.0
	cd.starting_speed = 200.0
	cd.ranged_damage_multiplier = 1.0
	cd.character_class = 0
	player = PlayerScript.new()
	player.set("character_data", cd)
	player.stats = PlayerStatsScript.new()
	player.prosthetic_manager = ProstheticManagerScript.new(false, player.stats)
	world.add_child(player)
	player.global_position = Vector2.ZERO
	player.add_to_group("player")


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		_run()
		return false
	var all_ok := true
	for k in _checks.keys():
		if _checks[k] == false:
			all_ok = false
	for k in _checks.keys():
		print("FIREMODE %s=%s" % [k, _checks[k]])
	for i in _info:
		print("FIREMODE_INFO " + i)
	print("FIREMODE_PASS" if all_ok else "FIREMODE_FAIL")
	quit()
	return false


func _run() -> void:
	player.inventory.weapons.clear()
	rifle = WeaponRifleScript.new()
	rifle.auto_fire = false
	player.inventory.equip_weapon(rifle)

	# 1) Weapon reads the player's aim direction (mouse-driven in the real game).
	var aim := Vector2(0.6, 0.8).normalized()
	player._aim_dir = aim
	var wdir = rifle._get_attack_direction()
	_checks["weapon_reads_aim"] = wdir.is_equal_approx(aim)

	# 2) Mouse-aim formula: the headless cursor sits at world origin, so put
	#    the player to its right and confirm the aim swings back toward the
	#    cursor (left) — i.e. it tracks the mouse, not a zombie.
	player.global_position = Vector2(400, 0)
	player._aim_dir = Vector2(1, 0)  # stale value pointing right
	player._compute_aim_dir()
	_info.append("mouse_aim_x=%.3f" % player._aim_dir.x)
	_checks["aim_follows_mouse"] = player._aim_dir.x < -0.5

	# 3) No auto-fire without the fire input held.
	rifle.set_fire_input(false, false)
	var before = _count_proj()
	for i in range(10):
		rifle._physics_process(0.1)
	var after_idle = _count_proj()
	_checks["no_auto_fire"] = after_idle == before

	# 4) Firing on input spawns a bullet (SEMI: one shot per press).
	rifle.set_fire_input(true, true)
	rifle._physics_process(0.1)
	rifle.set_fire_input(false, false)
	for i in range(9):
		rifle._physics_process(0.1)
	var after_click = _count_proj()
	_checks["click_fires"] = after_click > after_idle

	# 5) Releasing stops firing (no new bullets appear).
	for i in range(10):
		rifle.set_fire_input(false, false)
		rifle._physics_process(0.1)
	var after_release = _count_proj()
	_checks["release_stops"] = after_release <= after_click

	# 6) Autonomous summon weapon self-deploys with no input.
	player.inventory.weapons.clear()
	mechdog = WeaponMechDogScript.new()
	mechdog.auto_fire = false
	player.inventory.equip_weapon(mechdog)
	var summon_before = _count_summon()
	mechdog._physics_process(0.1)
	var summon_after = _count_summon()
	_checks["summon_auto_deploy"] = summon_after > summon_before


func _count_proj() -> int:
	var c = 0
	for ch in world.get_children():
		if ch is ProjectileBaseScript:
			c += 1
	return c


func _count_summon() -> int:
	var c = 0
	for ch in world.get_children():
		if ch is SummonUnitScript:
			c += 1
	return c
