## Global game state — accessible via `Game`.
## Signals are emitted through `_instance` to work from static context.
class_name Game
extends Node

signal level_up(new_level: int)
signal player_died
signal wave_complete(wave_number: int)
signal boss_spawned
signal shop_opened

static var _instance: Game = null

static var selected_character: CharacterEntry = null
static var player_build_direction: int = 0
static var current_level: int = 1
static var current_wave: int = 1
static var current_floor: int = 1
static var score: int = 0
static var kills: int = 0
## Spendable currency earned by killing zombies — used by the between-floor shop.
## Kept separate from `score` so spending in the shop doesn't cannibalise the
## end-of-run performance metric.
static var souls: int = 0
static var is_game_active: bool = false
static var is_paused: bool = false


func _ready() -> void:
	_instance = self


static func start_game(character: CharacterEntry) -> void:
	selected_character = character
	player_build_direction = character.build_direction
	current_level = 1
	current_wave = 1
	current_floor = 1
	score = 0
	kills = 0
	souls = 0
	is_game_active = true
	is_paused = false


static func end_game() -> void:
	is_game_active = false
	if _instance:
		_instance.player_died.emit()


static func advance_wave() -> void:
	current_wave += 1
	if _instance:
		_instance.wave_complete.emit(current_wave)


static func advance_floor() -> void:
	current_floor += 1


static func spawn_boss() -> void:
	if _instance:
		_instance.boss_spawned.emit()
