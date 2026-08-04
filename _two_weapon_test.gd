## Engine-driven firing test (physics runs normally; we only feed input
## through Player._input, the same path the engine uses for real mouse/keys).
## Verifies:
##   A) one click fires BOTH weapons (>=2 projectiles)
##   B) a single SEMI weapon on one click fires exactly one bullet (no spray)
##   C) an AUTO weapon held sprays (peak >= 2)
extends SceneTree

const WeaponRifleScript = preload("res://scripts/weapons/ranged/weapon_rifle.gd")
const WeaponSMGScript = preload("res://scripts/weapons/ranged/weapon_smg.gd")
const WeaponShotgunScript = preload("res://scripts/weapons/ranged/weapon_shotgun.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const ProstheticManagerScript = preload("res://scripts/core/prosthetic_manager.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const AccessoryRegistryScript = preload("res://scripts/systems/accessory_registry.gd")
const LimbRegistryScript = preload("res://scripts/systems/limb_registry.gd")
const ProjectileBaseScript = preload("res://scripts/projectiles/projectile_base.gd")

var world: Node2D
var player
var _checks: Dictionary = {}
var _results: Dictionary = {}
var _phase := 0
var _fc := 0
var _peak := 0


func _init() -> void:
	world = Node2D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world
	AccessoryRegistryScript.init()
	LimbRegistryScript.init()
	var cd = CharacterEntryScript.new()
	cd.character_class = 0
	player = PlayerScript.new()
	player.set("character_data", cd)
	player.stats = PlayerStatsScript.new()
	player.prosthetic_manager = ProstheticManagerScript.new(false, player.stats)
	world.add_child(player)
	player.global_position = Vector2.ZERO
	player.add_to_group("player")


func _process(_delta: float) -> bool:
	_fc += 1
	match _phase:
		0:
			# --- A: two SEMI weapons, ONE click ---
			if _fc == 1:
				player.inventory.weapons.clear()
				player.inventory.equip_weapon(WeaponRifleScript.new())   # SEMI
				player.inventory.equip_weapon(WeaponShotgunScript.new()) # SEMI
				_press_fire()
			if _fc == 2:
				_release_fire()
			if _fc >= 5:
				var a = _count_proj()
				_checks["one_click_fires_both"] = a >= 2
				_results["A"] = "two SEMI one click projectiles=%d (expect>=2)" % a
				_clear_proj_sync()
				_phase = 1
				_fc = 0
		1:
			# --- B: single SEMI (rifle) ONE click -> exactly one bullet ---
			if _fc == 1:
				player.inventory.weapons.clear()
				player.inventory.equip_weapon(WeaponRifleScript.new()) # SEMI
				_press_fire()
			if _fc == 2:
				_release_fire()
			if _fc >= 5:
				var b = _count_proj()
				_checks["semi_one_bullet_per_click"] = b == 1
				_results["B"] = "single SEMI one click bullets=%d (expect==1)" % b
				_clear_proj_sync()
				_phase = 2
				_fc = 0
		2:
			# --- C: single AUTO (SMG) HELD -> sprays (peak >= 2) ---
			if _fc == 1:
				player.inventory.weapons.clear()
				player.inventory.equip_weapon(WeaponSMGScript.new()) # AUTO
				_press_fire()
			if _fc >= 1 and _fc <= 20:
				_peak = maxi(_peak, _count_proj())
			if _fc >= 20:
				_release_fire()
				_checks["auto_hold_sprays"] = _peak >= 2
				_results["C"] = "AUTO held peak=%d (expect>=2)" % _peak
				_phase = 3
				_fc = 0
		3:
			for k in _results.keys():
				print(_results[k])
			var all_ok := true
			for k in _checks.keys():
				if _checks[k] == false:
					all_ok = false
			print("TWO_WEAPON_PASS" if all_ok else "TWO_WEAPON_FAIL")
			quit()
	return false


func _press_fire() -> void:
	var ev := InputEventAction.new()
	ev.action = &"fire"
	ev.pressed = true
	player._input(ev)


func _release_fire() -> void:
	var ev := InputEventAction.new()
	ev.action = &"fire"
	ev.pressed = false
	player._input(ev)


func _count_proj() -> int:
	var c = 0
	for ch in world.get_children():
		if ch is ProjectileBaseScript:
			c += 1
	return c


func _clear_proj_sync() -> void:
	var to_remove := []
	for ch in world.get_children():
		if ch is ProjectileBaseScript:
			to_remove.append(ch)
	for ch in to_remove:
		world.remove_child(ch)
		ch.free()
