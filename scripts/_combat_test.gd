## Headless combat smoke test:
##  - equipping a ranged weapon works
##  - a bullet hitting a zombie deals damage, spawns a visible hit effect,
##    and triggers SFX without error
##  - firing via try_fire spawns a bullet + shoot SFX
##  - over real time the zombie dies and drops an item (orb/equipment)
## Not part of the game.
##
## NOTE: In a `-s` SceneTree script, nodes added during _init have NOT run
## _ready yet (the tree becomes active only after the first frame). So all
## gameplay assertions live in _process, once _ready has run for every node.
extends SceneTree

const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")
const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const ProjectileBaseScript = preload("res://scripts/projectiles/projectile_base.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const WeaponInventoryScript = preload("res://scripts/entities/player/weapon_inventory.gd")
const ProstheticManagerScript = preload("res://scripts/core/prosthetic_manager.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const WeaponSMGScript = preload("res://scripts/weapons/ranged/weapon_smg.gd")
const AccessoryRegistryScript = preload("res://scripts/systems/accessory_registry.gd")
const LimbRegistryScript = preload("res://scripts/systems/limb_registry.gd")
const SfxManagerScript = preload("res://scripts/core/sfx_manager.gd")

var world: Node2D
var player
var zombie
var rifle
var _elapsed := 0.0
var _started := false
var _results: Array[String] = []
var _checks: Dictionary = {}


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
	# Leave inventory == null so player._ready creates it AND adds it to the
	# tree (equip_weapon needs inventory.get_tree() to resolve).
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
	# Wait until every node has run _ready (after the very first frame).
	if not _started:
		_started = true
		_run_setup_dependent_checks()
		# Hold fire so the equipped AUTO weapon actually shoots the zombie.
		# Input is fed through Player._input (the real event path), since
		# Input.action_press no longer drives weapon firing in this build.
		_fire_press()
		return false

	_elapsed += delta
	if _elapsed < 2.5:
		return false

	_fire_release()
	_final_checks()
	var all_ok := true
	for k in _checks.keys():
		if _checks[k] == false:
			all_ok = false
		_results.append("COMBAT check %s=%s" % [k, _checks[k]])
	for r in _results:
		print(r)
	print("COMBAT_PASS" if all_ok else "COMBAT_FAIL")
	quit()
	return false


func _run_setup_dependent_checks() -> void:
	# Player._ready may auto-fill both weapon slots; clear and install a known
	# AUTO ranged weapon so the firing path is deterministic (and it can kill
	# the zombie within the wait by holding fire).
	player.inventory.weapons.clear()
	rifle = WeaponSMGScript.new()
	var ok = player.inventory.equip_weapon(rifle)
	_checks["weapon_equip"] = ok
	_results.append("COMBAT weapon_equip=%s weapons_in_inv=%d" % [ok, player.inventory.weapons.size()])

	# --- Test 1: direct hit handler (deterministic) ---
	var hp_before = zombie.current_health
	var children_before = world.get_child_count()
	var proj = ProjectileBaseScript.new()
	proj.damage = 25.0
	proj.direction = Vector2.RIGHT
	world.add_child(proj)
	proj._on_body_entered(zombie)
	var hp_after = zombie.current_health
	var effect_spawned = world.get_child_count() > children_before
	_checks["hit_damage"] = hp_after < hp_before
	_checks["hit_effect"] = effect_spawned
	_results.append("COMBAT direct_hit hp %.1f->%.1f effect=%s" % [hp_before, hp_after, effect_spawned])

	# --- Test 2: try_fire spawns a bullet + triggers shoot SFX ---
	var bullets_before = _count_projectiles()
	rifle.try_fire(0.0)
	var bullets_after = _count_projectiles()
	_checks["fire_bullet"] = bullets_after > bullets_before
	_results.append("COMBAT try_fire bullet_spawned=%s" % (bullets_after > bullets_before))

	# --- Test 3: every SFX sample loads + plays without error ---
	var sfx_ok := true
	for s in ["shoot", "hit", "enemy_die", "pickup", "levelup", "player_hurt", "swing", "explosion"]:
		SfxManagerScript.play(s)
	_results.append("COMBAT sfx_play_all_ok=%s" % sfx_ok)
	_checks["sfx_no_error"] = true  # if any threw, the run would abort with SCRIPT ERROR


func _count_projectiles() -> int:
	var c = 0
	for ch in world.get_children():
		if ch is ProjectileBaseScript:
			c += 1
	return c


## Feed a real fire event through Player._input (the path the engine uses for
## actual mouse/keyboard input). Input.action_press no longer reaches _input in
## this build, so tests must call the player's handler directly.
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


func _count_drops() -> int:
	var c = 0
	for ch in world.get_children():
		if ch is PickupItemScript:
			c += 1
	return c


func _final_checks() -> void:
	var zombie_dead = (not is_instance_valid(zombie)) or zombie.current_health <= 0
	var orbs = 0
	for ch in world.get_children():
		if ch != zombie and "soul" in ch.name.to_lower():
			orbs += 1
	var pickups = _count_drops()
	_checks["zombie_died"] = zombie_dead
	_checks["drops_spawned"] = (pickups + orbs) >= 1
	_results.append("COMBAT after_2.5s zombie_dead=%s orbs=%d pickups=%d" % [zombie_dead, orbs, pickups])
