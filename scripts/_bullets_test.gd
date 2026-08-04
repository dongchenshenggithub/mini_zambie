## Measures simultaneous on-screen projectiles for each fire mode while the
## fire input is HELD, plus a rapid-click SEMI run. Confirms whether the
## "one bullet at a time" feel comes from cooldown > bullet lifetime.
extends SceneTree

const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const WeaponInventoryScript = preload("res://scripts/entities/player/weapon_inventory.gd")
const ProstheticManagerScript = preload("res://scripts/core/prosthetic_manager.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const ProjectileBaseScript = preload("res://scripts/projectiles/projectile_base.gd")
const WeaponRifleScript = preload("res://scripts/weapons/ranged/weapon_rifle.gd")
const WeaponShotgunScript = preload("res://scripts/weapons/ranged/weapon_shotgun.gd")
const WeaponRPGScript = preload("res://scripts/weapons/ranged/weapon_rpg.gd")
const WeaponSMGScript = preload("res://scripts/weapons/ranged/weapon_smg.gd")

var world: Node2D
var player
var _t := 0.0
var _phase := 0
var _weapons := []
var _widx := 0
var _cur = null
var _max_sim := 0
var _total := 0
var _last_total := 0
var _report := []
var _click_timer := 0.0
var _rapid := false
var _phase2 := false


func _init() -> void:
	world = Node2D.new(); world.name = "World"; root.add_child(world)
	current_scene = world
	var cd = CharacterEntryScript.new()
	cd.character_class = 0; cd.starting_health = 100.0; cd.starting_speed = 200.0
	player = PlayerScript.new(); player.set("character_data", cd)
	player.stats = PlayerStatsScript.new()
	player.prosthetic_manager = ProstheticManagerScript.new(false, player.stats)
	world.add_child(player)
	player.global_position = Vector2.ZERO
	player.add_to_group("player")
	_weapons = [WeaponRifleScript, WeaponShotgunScript, WeaponRPGScript, WeaponSMGScript]


func _install(idx: int) -> void:
	player.inventory.weapons.clear()
	var w = _weapons[idx].new()
	player.inventory.equip_weapon(w)
	_cur = w
	_max_sim = 0
	_total = 0
	_last_total = 0
	_report.append("== %s mode=%s rate=%.2f range=%.0f cd=%.3f life=%.3f ==" % [
		w.weapon_name,
		"AUTO" if w.fire_mode == GameEnums.FireMode.AUTO else "SEMI",
		w.fire_rate, w.range, 1.0 / w.fire_rate, w.range / 600.0])


func _process(delta: float) -> bool:
	if _cur == null:
		_install(_widx)
		_fire_press()
		return false

	_t += delta
	if _rapid:
		# Simulate a click every 0.08s (12.5 clicks/sec) for SEMI.
		_click_timer += delta
		if _click_timer >= 0.08:
			_click_timer = 0.0
			_fire_release()
			_fire_press()

	var sim := _count_projectiles()
	_max_sim = maxi(_max_sim, sim)

	if _t >= 1.5:
		if not _rapid:
			_report.append("  HELD 1.5s -> max_simultaneous=%d" % _max_sim)
			_fire_release()
			# For SEMI weapons, also measure a rapid-click burst.
			if _cur != null and _cur.fire_mode == GameEnums.FireMode.SEMI:
				_rapid = true
				_phase2 = true
				_t = 0.0
				_max_sim = 0
				return false
			else:
				_advance()
		else:
			_report.append("  RAPIDCLICK 1.5s -> max_simultaneous=%d" % _max_sim)
			_rapid = false
			_advance()
	return false


func _advance() -> void:
	_widx += 1
	_cur = null
	_t = 0.0
	if _widx >= _weapons.size():
		for r in _report:
			print(r)
		print("BULLETS_TEST DONE")
		quit()


func _count_projectiles() -> int:
	var c = 0
	for ch in world.get_children():
		if ch is ProjectileBaseScript:
			c += 1
	return c


func _fire_press() -> void:
	var ev := InputEventAction.new(); ev.action = &"fire"; ev.pressed = true
	player._input(ev)


func _fire_release() -> void:
	var ev := InputEventAction.new(); ev.action = &"fire"; ev.pressed = false
	player._input(ev)
