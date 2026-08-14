## Unified follower/companion manager.
## Spawns auto-attacking companion units at game start (base_followers) and
## enforces the per-character max_followers cap. All runtime follower additions
## (e.g. Cat Cafe Worker's per-floor recruit) route through this manager so
## the cap is always respected and the counter stays accurate.
##
## Each character class has one or more follower TYPES. A follower type is:
##   [damage, range, attack_rate, body_shape, body_color, body_accent]
## Cat Cafe has 5 distinct combat companions (pirate cat / dog meat / owl /
## plush bear / dragon); every other class gets a single tuned companion.
## Damage is scaled by the owner's summon multiplier at spawn time so per-class
## summon bonuses (e.g. Cat Cafe's +50%) are actually applied.
class_name FollowerManager
extends Node

const SummonUnitScript = preload("res://scripts/entities/summon/summon_unit.gd")

signal follower_spawned(unit: Node2D)
signal follower_count_changed(count: int)

var owner_player: Player = null
var _scene_root: Node = null
## Live list of spawned companion units (kept so the inventory panel can list
## and dismiss them). Entries are removed on dismiss; naturally-killed units
## are filtered out via is_instance_valid() in get_current_units().
var _units: Array = []

## Per-character-class follower TYPE lists. Entry shape:
##   [damage, range, attack_rate, body_shape, body_color, body_accent, attack_style]
## attack_style: 0 = ranged beam, 1 = melee guard (orbits owner + defends).
## Body shapes: 0=circle 1=square 2=triangle 3=diamond 4=bear.
## Accents: 0=none 1=pirate band 2=owl eyes 3=dragon heart.
const CLASS_TYPES := {
	0: [[30.0, 170.0, 0.7, 0, Color(0.55, 0.82, 0.48), 0, 0]],                                # Veteran: green orb (ranged)
	1: [[42.0, 95.0, 0.7, 2, Color(0.68, 0.58, 0.88), 0, 1]],                                # Mech Monk: purple triangle (melee guard)
	2: [[24.0, 190.0, 0.9, 0, Color(0.48, 0.88, 0.88), 0, 0]],                               # Cultivator: cyan orb (ranged)
	3: [
		[26.0, 200.0, 0.9, 1, Color(0.85, 0.28, 0.28), 1, 0],   # Pirate Cat  (red, eye-band, ranged)
		[40.0, 95.0, 0.9, 2, Color(0.62, 0.42, 0.26), 0, 1],    # Dog Meat     (brown, melee guard)
		[18.0, 260.0, 0.5, 0, Color(0.55, 0.66, 0.82), 2, 0],   # Owl          (grey-blue, sharp, ranged)
		[16.0, 90.0, 1.2, 4, Color(0.95, 0.62, 0.78), 0, 1],    # Plush Bear   (pink, melee guard)
		[50.0, 220.0, 1.0, 3, Color(0.82, 0.85, 0.32), 3, 0],   # Dragon       (gold-green, heart, ranged)
	],
	4: [[36.0, 210.0, 0.7, 1, Color(0.72, 0.78, 1.0), 0, 0]],                                  # Professor: blue bot (ranged)
	5: [[34.0, 180.0, 0.8, 3, Color(0.82, 0.58, 1.0), 0, 0]],                                 # Alien: magenta diamond (ranged)
}

## Round-robin index per class so recruits cycle through a class's types
## (Cat Cafe recruits eventually field all 5 companions).
var _rr := {}


func setup(player: Player, scene_root: Node) -> void:
	owner_player = player
	_scene_root = scene_root


## Spawn `count` companions at game start for the given character class.
## Respects max_followers cap — stops early if the cap would be exceeded.
func spawn_initial(character_class: int, count: int) -> void:
	var list := _config_list(character_class)
	if list.is_empty():
		return
	for i in range(count):
		if not can_add():
			break
		var idx := _next_index(character_class, list.size())
		_spawn_one(list[idx])


## Try to add one more follower at runtime (Cat Cafe Worker per-floor recruit,
## upgrade that grants +follower, etc.). Returns true if spawned.
func try_add_follower(character_class: int) -> bool:
	var list := _config_list(character_class)
	if list.is_empty() or not can_add():
		return false
	var idx := _next_index(character_class, list.size())
	_spawn_one(list[idx])
	return true


func can_add() -> bool:
	if owner_player == null or owner_player.inventory == null:
		return false
	return owner_player.inventory.current_followers < owner_player.inventory.max_followers


func get_current_count() -> int:
	if owner_player != null and owner_player.inventory != null:
		return owner_player.inventory.current_followers
	return 0


func get_max_count() -> int:
	if owner_player != null and owner_player.inventory != null:
		return owner_player.inventory.max_followers
	return 0


## Return the live companion units (skipping any that have died/been freed).
func get_current_units() -> Array:
	var alive := []
	for u in _units:
		if is_instance_valid(u):
			alive.append(u)
	return alive


## Dismiss a specific companion (inventory panel "解散" button). Frees the node
## and decrements the inventory counter so the cap frees up for future drops.
func dismiss_unit(unit: Node2D) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false
	var idx := _units.find(unit)
	if idx < 0:
		return false
	_units.remove_at(idx)
	if owner_player != null and owner_player.inventory != null:
		owner_player.inventory.current_followers = max(0, owner_player.inventory.current_followers - 1)
		owner_player.inventory.follower_count_changed.emit(owner_player.inventory.current_followers)
	unit.queue_free()
	return true


func _config_list(cls: int) -> Array:
	if CLASS_TYPES.has(cls):
		return CLASS_TYPES[cls]
	return []


func _next_index(cls: int, n: int) -> int:
	var i := 0
	if _rr.has(cls):
		i = _rr[cls]
	_rr[cls] = (i + 1) % n
	return i


func _spawn_one(type_arr: Array) -> Node2D:
	if owner_player == null or _scene_root == null:
		return
	var f = SummonUnitScript.new()
	f.owner_node = owner_player

	# Apply the owner's summon damage multiplier so per-class summon bonuses
	# (Cat Cafe +50%, etc.) actually take effect on the companions.
	var summon_mult := 1.0
	if owner_player.stats != null:
		summon_mult = owner_player.stats.damage_multiplier_summon
	f.damage = float(type_arr[0]) * summon_mult
	f.range = float(type_arr[1])
	f._attack_rate = float(type_arr[2])
	f.body_shape = int(type_arr[3])
	f.body_color = type_arr[4]
	f.body_accent = int(type_arr[5])
	# 7th element selects ranged (0) vs melee guard (1); default to ranged.
	f.attack_style = 0
	if type_arr.size() > 6:
		f.attack_style = int(type_arr[6])

	# Scatter around the player in a ring so they don't stack on one pixel.
	var angle: float = randf() * TAU
	var dist: float = randf_range(28.0, 55.0)
	f.global_position = owner_player.global_position + Vector2(cos(angle), sin(angle)) * dist

	_scene_root.add_child(f)
	_units.append(f)

	# Bump the inventory counter (this is the single source of truth for the cap).
	if owner_player.inventory != null:
		owner_player.inventory.current_followers += 1
		owner_player.inventory.follower_count_changed.emit(owner_player.inventory.current_followers)

	follower_spawned.emit(f)
	return f


## Spawn exactly one companion for `character_class` and return the unit (or
## null if the cap is reached / no config). Used by CompanionWeapon so the
## caller can link weapon<->unit. Respects the per-character max_followers cap.
func spawn_unit_for_companion(character_class: int) -> Node2D:
	var list := _config_list(character_class)
	if list.is_empty() or not can_add():
		return null
	var idx := _next_index(character_class, list.size())
	return _spawn_one(list[idx])
