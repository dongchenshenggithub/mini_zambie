## Main game scene — orchestrates everything through registries.
## New weapons/zombies/characters/accessories are added by dropping .tres files.
class_name GameScene
extends Node2D

# Explicit preloads (instead of relying on global class-name resolution) keep
# this scene robust regardless of script compilation order in any build context.
const LimbRegistryScript = preload("res://scripts/systems/limb_registry.gd")
const UpgradePanelScript = preload("res://scripts/ui/upgrade_panel.gd")
const DeathScreenScript = preload("res://scripts/gameplay/death_screen.gd")
const TransitionBannerScript = preload("res://scripts/ui/transition_banner.gd")
const MapGeneratorScript = preload("res://scripts/map/map_generator.gd")

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
var _upgrade_open: bool = false
var _pending_level_ups: int = 0
var _transitioning: bool = false
var run_start_time: int = 0
## Current floor bounds (centred on the origin). The player clamps its position
## to this rect; the camera limits its view to it so neither can leave the
## background art.
var _world_bounds := Rect2(-800.0, -500.0, 1600.0, 1000.0)


## Read-only accessor for the active floor bounds. Duck-typed by the player so
## there is no circular import between Player and GameScene.
func get_world_bounds() -> Rect2:
	return _world_bounds



func _ready() -> void:
	# Reset run state so a restart/reload from victory or death starts clean.
	if Game.selected_character != null:
		Game.start_game(Game.selected_character)
	run_start_time = Time.get_ticks_msec()
	if Game._instance != null:
		Game._instance.player_died.connect(_on_player_died)

	# Init all registries (auto-discovers .tres files)
	WeaponRegistry.init()
	ZombieRegistry.init()
	CharacterRegistry.init()
	AccessoryRegistry.init()
	PotionRegistry.init()
	PartRegistry.init()
	LimbRegistryScript.init()
	MapFloorRegistry.init()

	_setup_player()
	_generate_map()
	_start_waves()
	MusicManager.play("gameplay")
	xp_system.leveled_up.connect(_on_leveled_up)
	wave_spawner.floor_cleared.connect(_on_floor_cleared)
	if _is_boss_floor:
		_spawn_boss()


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
	# Keep the whole floor/render layer BEHIND the player and zombies so the
	# character is never hidden under the background art.
	_map_root.z_index = -100
	add_child(_map_root)

	var spawn = _map_root.get_meta("player_spawn", Vector2.ZERO)
	player.global_position = spawn

	# Adopt the floor's bounds and lock the camera to them so the view never
	# drifts into empty space beyond the background.
	_world_bounds = _map_root.get_meta("bounds", _world_bounds)
	if camera != null:
		camera.limit_left = int(_world_bounds.position.x)
		camera.limit_top = int(_world_bounds.position.y)
		camera.limit_right = int(_world_bounds.position.x + _world_bounds.size.x)
		camera.limit_bottom = int(_world_bounds.position.y + _world_bounds.size.y)
		camera.limit_smoothed = true


func _start_waves() -> void:
	wave_spawner.start_waving()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not _upgrade_open:
		_toggle_pause()
		return
	if event.is_action_pressed("status") and not _upgrade_open and not get_tree().paused:
		_open_status_panel()


func _toggle_pause() -> void:
	if get_tree().paused:
		return  # PauseMenu handles its own resume
	var pm = preload("res://scripts/gameplay/pause_menu.gd").new()
	_add_overlay(pm)
	get_tree().paused = true


## Opens the character/inventory status panel (hotkey: I or C) and pauses the
## run. The panel handles its own close (same key / Esc / button) and resumes.
func _open_status_panel() -> void:
	if get_tree().paused:
		return
	var panel = preload("res://scripts/ui/character_panel.gd").new()
	_add_overlay(panel)
	get_tree().paused = true


func _on_floor_cleared(_floor: int) -> void:
	if current_floor >= total_floors:
		return
	if _transitioning:
		return
	_transitioning = true
	var cleared := current_floor
	var next := current_floor + 1
	var theme := MapGeneratorScript.theme_name(MapGeneratorScript.theme_for_floor(next, next == total_floors))
	get_tree().paused = true
	var banner := TransitionBannerScript.new()
	get_tree().root.add_child(banner)
	banner.show_banner(
		"第 %d 层 已清除" % cleared,
		"进入第 %d 层 · %s" % [next, theme],
		1.8,
		Color(0.45, 0.9, 1.0, 1.0),
		_advance_floor_and_resume
	)


func _advance_floor_and_resume() -> void:
	_advance_floor()
	_transitioning = false
	get_tree().paused = false


func _advance_floor() -> void:
	current_floor += 1
	Game.advance_floor()
	_generate_map()
	if player and player.behavior:
		player.behavior.on_floor_clear(current_floor)
	if _is_boss_floor:
		_spawn_boss()
	else:
		wave_spawner.start_floor()


func _spawn_boss() -> void:
	wave_spawner.stop_waving()
	var boss_type = wave_spawner.pick_boss_for_floor(current_floor)
	var boss = wave_spawner.create_boss(boss_type)
	if boss == null:
		return
	var spawn = _map_root.get_meta("boss_spawn", player.global_position + Vector2(0, -400.0)) if _map_root else (player.global_position + Vector2(0, -400.0))
	boss.global_position = spawn
	add_child(boss)
	MusicManager.play("boss")
	Game.spawn_boss()
	if player and player.behavior:
		player.behavior.on_boss_enter()
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	_show_victory_screen()


## Adds a full-screen UI overlay on a dedicated high canvas layer so it always
## composites ABOVE the HUD/Player-UI canvas layers (layer 1) and the world
## (layer 0). Putting overlays directly under root (layer 0) lets the HUD's
## CanvasLayer (layer 1) draw over them in the real Forward+ renderer, which is
## why the death/victory/upgrade screens were invisible in-editor.
## Controls get wrapped in a fresh CanvasLayer; nodes that already ARE a
## CanvasLayer (e.g. UpgradePanel) are added directly to avoid nested layers.
func _add_overlay(control: Node) -> void:
	if control is CanvasLayer:
		control.layer = 100
		get_tree().root.add_child(control)
		return
	var layer := CanvasLayer.new()
	layer.name = "OverlayLayer"
	layer.layer = 100
	layer.add_child(control)
	control.tree_exiting.connect(layer.queue_free)
	get_tree().root.add_child(layer)


func _show_victory_screen() -> void:
	MusicManager.play("victory")
	var vs = preload("res://scripts/gameplay/victory_screen.gd").new()
	vs.set_score(Game.score, current_floor)
	_add_overlay(vs)


func _on_player_died() -> void:
	MusicManager.play("death")
	var survived_ms := Time.get_ticks_msec() - run_start_time
	var char_name := ""
	if Game.selected_character != null:
		char_name = Game.selected_character.name
	var ds = DeathScreenScript.create(Game.score, Game.current_floor, Game.kills, survived_ms, char_name)
	_add_overlay(ds)
	get_tree().paused = true



func _on_leveled_up(new_level: int) -> void:
	print("Level up! New level: %d" % new_level)
	# Surface the level-up to the player's class behavior (per-class bonuses).
	if player and player.behavior:
		player.behavior.on_level_up(new_level)
	# A single XP gain can cross multiple levels; queue them so each gets its
	# own upgrade panel instead of opening several at once.
	_pending_level_ups += 1
	_try_open_upgrade_panel()


func _try_open_upgrade_panel() -> void:
	if _upgrade_open or _pending_level_ups <= 0:
		return
	_upgrade_open = true
	_pending_level_ups -= 1
	# Pause for a beat and show a "level up" banner so the panel doesn't snap
	# open mid-combat. The banner fades out and then opens the panel.
	get_tree().paused = true
	SfxManager.play("levelup")
	var lvl := Game.current_level
	var banner := TransitionBannerScript.new()
	get_tree().root.add_child(banner)
	banner.show_banner(
		"升级！LV %d" % lvl,
		"选择一项强化",
		1.1,
		Color(1.0, 0.85, 0.3, 1.0),
		_open_upgrade_panel
	)


func _open_upgrade_panel() -> void:
	var picker := UpgradePicker.new()
	var options := picker.generate_options(player, 6)
	var panel := UpgradePanelScript.new()
	_add_overlay(panel)
	panel.option_chosen.connect(_on_upgrade_chosen.bind(picker, panel))
	panel.show_options(options)


func _on_upgrade_chosen(upgrade_data: Dictionary, picker: UpgradePicker, panel: UpgradePanelScript) -> void:
	picker.apply_upgrade(upgrade_data, player)
	picker.queue_free()
	_upgrade_open = false
	_try_open_upgrade_panel()
