## Wave spawner — manages zombie waves and difficulty scaling.
## P0-1: now actually spawns the full roster of zombie types (incl. all 11
## non-boss variants) instead of only the generic normal zombie, so the
## distinct pixel art and behaviors are visible in real play.
## P0-2: tracks waves-per-floor and emits floor_cleared once the floor's
## waves are spawned AND the screen is empty, driving floor progression.
class_name WaveSpawner
extends Node

const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const ZombieSelfDestructScript = preload("res://scripts/entities/zombie/zombie_self_destruct.gd")
const ZombieMechaMutantScript = preload("res://scripts/entities/zombie/zombie_mecha_mutant.gd")
const ZombieBioShieldScript = preload("res://scripts/entities/zombie/zombie_bio_shield.gd")
const ZombieNanomiteScript = preload("res://scripts/entities/zombie/zombie_nanomite.gd")
const ZombieHologramScript = preload("res://scripts/entities/zombie/zombie_hologram.gd")
const ZombieEliteBioTyrantScript = preload("res://scripts/entities/zombie/zombie_elite_bio_tyrant.gd")
const ZombieEliteMechaSoldierScript = preload("res://scripts/entities/zombie/zombie_elite_mecha_soldier.gd")
const ZombieEliteGeneFusionScript = preload("res://scripts/entities/zombie/zombie_elite_gene_fusion.gd")
const BossZombieKingScript = preload("res://scripts/entities/zombie/boss_zombie_king.gd")
const BossBioTitanScript = preload("res://scripts/entities/zombie/boss_bio_titan.gd")
const BossNanoCoreScript = preload("res://scripts/entities/zombie/boss_nano_core.gd")
const BossExperimentAlphaScript = preload("res://scripts/entities/zombie/boss_experiment_alpha.gd")

@export var spawn_interval: float = 1.5
@export var zombies_per_wave: int = 5
@export var max_zombies_on_screen: int = 30
@export var spawn_radius_min: float = 400.0
@export var spawn_radius_max: float = 600.0
## Survive-mode: a floor ends when this many seconds have elapsed — NOT when a
## fixed number of zombies is killed. Waves keep spawning indefinitely until the
## timer runs out (difficulty escalates, capped by max_zombies_on_screen).
@export var floor_duration: float = 90.0

var _spawn_timer: float = 0.0
var _wave_number: int = 0
var _is_waving: bool = false
var _waves_this_floor: int = 0
var _floor_active: bool = false
var _floor_time: float = 0.0


signal wave_started(wave_num: int)
signal wave_cleared(wave_num: int)
signal floor_cleared(floor_num: int)


func _ready() -> void:
	add_to_group("wave_spawner")


func get_time_remaining() -> float:
	return maxf(0.0, floor_duration - _floor_time)


func get_floor_progress() -> float:
	return clampf(_floor_time / floor_duration, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if not (_is_waving and _floor_active):
		return

	_floor_time += delta

	# Survive-mode: keep spawning waves on the interval until the floor timer
	# expires. Difficulty escalates with the within-floor wave count plus the
	# current floor, and is capped by max_zombies_on_screen. The floor ends on
	# the timer, NOT when the screen is cleared.
	if _floor_time < floor_duration:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			var player = get_tree().get_first_node_in_group("player") as Player
			if player and get_tree().get_nodes_in_group("zombie").size() < max_zombies_on_screen:
				spawn_wave()
			_spawn_timer = spawn_interval
		return

	# Timer elapsed: the floor is cleared regardless of remaining zombies.
	_floor_active = false
	floor_cleared.emit(Game.current_floor)


func start_waving() -> void:
	_is_waving = true
	_wave_number = 0
	start_floor()


func start_floor() -> void:
	_waves_this_floor = 0
	_wave_number = 0
	_floor_time = 0.0
	_spawn_timer = 0.0
	_floor_active = true


func stop_waving() -> void:
	_is_waving = false
	_floor_active = false


func spawn_wave() -> void:
	_wave_number += 1
	_waves_this_floor += 1
	wave_started.emit(_wave_number)
	Game.advance_wave()
	# Difficulty scales with the within-floor wave count AND the current floor,
	# so later floors start meaner. The on-screen count still caps at
	# max_zombies_on_screen.
	var floor_offset := (Game.current_floor - 1) * 3
	var diff_wave := _wave_number + floor_offset
	var count = minf(zombies_per_wave + _wave_number, max_zombies_on_screen)
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	for i in range(count):
		var zombie = create_zombie(_roll_zombie_type(diff_wave))
		if zombie:
			var angle = randf() * TAU
			var dist = randf_range(spawn_radius_min, spawn_radius_max)
			zombie.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
			get_tree().current_scene.add_child(zombie)


## Difficulty curve: each wave unlocks one more zombie type until the full
## roster is in rotation by wave ~12.
func _roll_zombie_type(wave: int) -> GameEnums.ZombieType:
	var pool: Array[GameEnums.ZombieType] = [GameEnums.ZombieType.NORMAL]
	if wave >= 2: pool.append(GameEnums.ZombieType.FAST)
	if wave >= 3: pool.append(GameEnums.ZombieType.TANK)
	if wave >= 4: pool.append(GameEnums.ZombieType.SELF_DESTRUCT)
	if wave >= 5: pool.append(GameEnums.ZombieType.MECHA_MUTANT)
	if wave >= 6: pool.append(GameEnums.ZombieType.NANOMITE)
	if wave >= 7: pool.append(GameEnums.ZombieType.BIO_SHIELD)
	if wave >= 8: pool.append(GameEnums.ZombieType.HOLOGRAM)
	if wave >= 10: pool.append(GameEnums.ZombieType.ELITE_BIO_TYRANT)
	if wave >= 11: pool.append(GameEnums.ZombieType.ELITE_MECHA_SOLDIER)
	if wave >= 12: pool.append(GameEnums.ZombieType.ELITE_GENE_FUSION)
	return pool[randi() % pool.size()]


## Builds the correct zombie instance for a given type. Subtype scripts set
## their own `zombie_type` in _ready (so stats + texture resolve correctly);
## FAST/TANK have no dedicated script, so we instantiate the base and assign
## the type before the node enters the tree.
func create_zombie(type: GameEnums.ZombieType) -> Node2D:
	match type:
		GameEnums.ZombieType.NORMAL: return ZombieBaseScript.new()
		GameEnums.ZombieType.FAST:
			var z = ZombieBaseScript.new()
			z.zombie_type = GameEnums.ZombieType.FAST
			return z
		GameEnums.ZombieType.TANK:
			var z = ZombieBaseScript.new()
			z.zombie_type = GameEnums.ZombieType.TANK
			return z
		GameEnums.ZombieType.SELF_DESTRUCT: return ZombieSelfDestructScript.new()
		GameEnums.ZombieType.MECHA_MUTANT: return ZombieMechaMutantScript.new()
		GameEnums.ZombieType.BIO_SHIELD: return ZombieBioShieldScript.new()
		GameEnums.ZombieType.NANOMITE: return ZombieNanomiteScript.new()
		GameEnums.ZombieType.HOLOGRAM: return ZombieHologramScript.new()
		GameEnums.ZombieType.ELITE_BIO_TYRANT: return ZombieEliteBioTyrantScript.new()
		GameEnums.ZombieType.ELITE_MECHA_SOLDIER: return ZombieEliteMechaSoldierScript.new()
		GameEnums.ZombieType.ELITE_GENE_FUSION: return ZombieEliteGeneFusionScript.new()
		_: return ZombieBaseScript.new()


## Returns a fresh boss instance for the given boss type.
func create_boss(boss_type: GameEnums.ZombieType) -> ZombieBoss:
	match boss_type:
		GameEnums.ZombieType.BOSS_ZOMBIE_KING: return BossZombieKingScript.new()
		GameEnums.ZombieType.BOSS_BIO_TITAN: return BossBioTitanScript.new()
		GameEnums.ZombieType.BOSS_NANO_CORE: return BossNanoCoreScript.new()
		GameEnums.ZombieType.BOSS_EXPERIMENT_ALPHA: return BossExperimentAlphaScript.new()
		_: return BossZombieKingScript.new()


## Picks which boss caps the final floor (cycles for variety on replays).
func pick_boss_for_floor(floor_num: int) -> GameEnums.ZombieType:
	var bosses := [
		GameEnums.ZombieType.BOSS_ZOMBIE_KING,
		GameEnums.ZombieType.BOSS_BIO_TITAN,
		GameEnums.ZombieType.BOSS_NANO_CORE,
		GameEnums.ZombieType.BOSS_EXPERIMENT_ALPHA,
	]
	return bosses[floor_num % bosses.size()]
