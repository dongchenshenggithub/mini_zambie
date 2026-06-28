## Main game scene — orchestrates everything through registries.
## New weapons/zombies/characters/accessories are added by dropping .tres files.
class_name GameScene
extends Node2D

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: HUD = $HUD
@onready var xp_system: XPSystem = $XPSystem
@onready var wave_spawner: WaveSpawner = $WaveSpawner

var current_floor: int = 1
var total_floors: int = 15
var _map_root: Node2D = null
var _is_boss_floor: bool = false
var _shop_unlocked: bool = false


func _ready() -> void:
	# Init all registries (auto-discovers .tres files)
	WeaponRegistry.init()
	ZombieRegistry.init()
	CharacterRegistry.init()
	AccessoryRegistry.init()
	PotionRegistry.init()
	PartRegistry.init()
	MapFloorRegistry.init()

	_setup_player()
	_generate_map()
	_start_waves()
	xp_system.leveled_up.connect(_on_leveled_up)


func _setup_player() -> void:
	if player == null:
		player = preload("res://scripts/entities/player/player.gd").new()
		player.name = "Player"
		add_child(player)
		player.add_to_group("player")

	var char_entry = Game.selected_character
	if char_entry:
		player.character_data = char_entry

	if player.stats == null:
		player.stats = PlayerStats.new()
	if player.inventory == null:
		player.inventory = WeaponInventory.new()
		player.add_child(player.inventory)
	if player.prosthetic_manager == null:
		var is_mech = (char_entry and char_entry.character_class == 1)
		player.prosthetic_manager = ProstheticManager.new(is_mech, player.stats)
		player.add_child(player.prosthetic_manager)

	player._apply_character_traits()
	_equip_initial_weapon_from_registry()


func _equip_initial_weapon_from_registry() -> void:
	var char_entry = Game.selected_character
	if not char_entry:
		return
	var inv = player.inventory as WeaponInventory
	var weapon_data = WeaponRegistry.get_data(char_entry.initial_weapon_id)
	if weapon_data:
		var weapon = WeaponRegistry.spawn_instance(weapon_data)
		inv.equip_weapon(weapon)


func _generate_map() -> void:
	if _map_root:
		_map_root.queue_free()

	_is_boss_floor = (current_floor == total_floors)
	var gen = MapGenerator.new()
	_map_root = gen.generate_floor(current_floor, _is_boss_floor)
	_map_root.name = "Floor_%d" % current_floor
	add_child(_map_root)

	var spawn = _map_root.get_meta("player_spawn", Vector2.ZERO)
	player.global_position = spawn


func _start_waves() -> void:
	wave_spawner.start_waving()



func _on_leveled_up(new_level: int) -> void:
	if player and player._visual:
		player._visual.color = Color(0.0, 1.0, 0.0, 1.0)
	print("Level up! New level: %d" % new_level)
	_show_upgrade_panel()

func _show_upgrade_panel() -> void:
	var picker = UpgradePicker.new()
	var options = picker.generate_options(player, 6)
	for opt in options:
		print("Upgrade option: %s" % opt.get("label", "Unknown"))
	picker.queue_free()
