## Boots the REAL GameScene (authentic wiring: GameScene -> Player -> weapons)
## and measures, with the fire input HELD, how many bullets are simultaneously
## on screen. Then equips a 2nd weapon and re-measures to confirm dual-wield
## multi-fire works through the real pickup/equip path.
extends SceneTree

const GameScript = preload("res://scripts/core/game_state.gd")
const CharEntry = preload("res://scripts/character_entry.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const WeaponInventoryScript = preload("res://scripts/entities/player/weapon_inventory.gd")
const ProstheticManagerScript = preload("res://scripts/core/prosthetic_manager.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const ProjectileBaseScript = preload("res://scripts/projectiles/projectile_base.gd")
const WeaponSMGScript = preload("res://scripts/weapons/ranged/weapon_smg.gd")
const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")

var _phase := 0
var _t := 0.0
var _settle := 0.0
var _max_sim := 0
var _peak_timeline := ""
var _player = null
var _fired_hold := false


func _initialize() -> void:
	var cd = CharEntry.new()
	cd.character_class = 0
	cd.strength = 5; cd.agility = 5; cd.intelligence = 5
	cd.constitution = 5; cd.luck = 5; cd.willpower = 5
	cd.starting_health = 200.0; cd.starting_speed = 200.0
	cd.ranged_damage_multiplier = 1.0; cd.melee_damage_multiplier = 1.0
	cd.laser_damage_multiplier = 1.0; cd.summon_damage_multiplier = 1.0
	cd.spray_damage_multiplier = 1.0; cd.heal_rate = 0.0
	cd.initial_weapon_id = "rifle"
	GameScript.start_game(cd)
	var scene = preload("res://scenes/gameplay/game_scene.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene


func _process(delta: float) -> bool:
	var player = get_first_node_in_group("player") as PlayerScript
	if player == null:
		return false
	_player = player

	if _phase == 0:
		# Let the scene settle (map gen, HUD, initial weapon equip).
		_settle += delta
		if _settle < 0.6:
			return false
		var nw: int = player.inventory.weapons.size()
		print("PHASE0 weapons_at_start=%d" % nw)
		if nw < 1:
			print("REALTIME no initial weapon -> FAIL")
			quit(); return false
		# Begin HOLDING fire.
		var ev := InputEventAction.new(); ev.action = &"fire"; ev.pressed = true
		player._input(ev)
		_fired_hold = true
		_phase = 1
		_t = 0.0
		return false

	if _phase == 1:
		_t += delta
		var sim := _count_bullets()
		_max_sim = maxi(_max_sim, sim)
		if int(_t * 10) % 2 == 0:
			_peak_timeline += "%d," % sim
		if _t >= 2.0:
			print("PHASE1 HELD 2s max_simultaneous=%d timeline=[%s]" % [_max_sim, _peak_timeline.trim_suffix(",")])
			# Release fire, then equip a 2nd weapon via the REAL equip path.
			var ev2 := InputEventAction.new(); ev2.action = &"fire"; ev2.pressed = false
			player._input(ev2)
			var smg = WeaponSMGScript.new()
			var ok = player.inventory.equip_weapon(smg)
			print("PHASE1 equip2nd ok=%s weapons=%d" % [ok, player.inventory.weapons.size()])
			_phase = 2
			_t = 0.0
			_max_sim = 0
			_peak_timeline = ""
			# Hold fire again.
			var ev3 := InputEventAction.new(); ev3.action = &"fire"; ev3.pressed = true
			player._input(ev3)
		return false

	if _phase == 2:
		_t += delta
		var sim := _count_bullets()
		_max_sim = maxi(_max_sim, sim)
		if int(_t * 10) % 2 == 0:
			_peak_timeline += "%d," % sim
		if _t >= 2.0:
			print("PHASE2 DUAL-WIELD HELD 2s max_simultaneous=%d timeline=[%s]" % [_max_sim, _peak_timeline.trim_suffix(",")])
			var dual_ok = _max_sim > 5  # clearly more than a single slow weapon
			print("REALTIME %s" % ("PASS" if dual_ok else "FAIL"))
			quit()
		return false
	return false


var _bullets := 0


func _count_bullets() -> int:
	_bullets = 0
	_count_recursive(current_scene)
	return _bullets


func _count_recursive(n: Node) -> void:
	if n is ProjectileBaseScript:
		_bullets += 1
	for ch in n.get_children():
		_count_recursive(ch)
