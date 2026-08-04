## Headless test for the character/inventory status panel:
##  - the "status" input action exists (I / C hotkeys)
##  - the panel builds without error
##  - it reads the equipped weapon, installed limb, and equipped accessory
## Not part of the game.
extends SceneTree

const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const WeaponRegistry = preload("res://scripts/systems/weapon_registry.gd")
const LimbRegistryScript = preload("res://scripts/systems/limb_registry.gd")
const CharacterPanelScript = preload("res://scripts/ui/character_panel.gd")

var world: Node2D
var player: Player
var _done: bool = false


func _init() -> void:
	world = Node2D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world

	var cd = CharacterEntryScript.new()
	cd.name = "测试角色"
	cd.character_class = 0
	cd.strength = 7
	cd.agility = 6
	cd.constitution = 5
	cd.starting_health = 100.0
	cd.starting_speed = 200.0

	player = PlayerScript.new()
	player.character_data = cd
	player.stats = PlayerStatsScript.new()
	world.add_child(player)   # player._ready builds inventory + prosthetic_manager
	player.add_to_group("player")

	WeaponRegistry.init()
	LimbRegistryScript.init()


func _process(_delta: float) -> bool:
	if _done:
		return false
	_done = true

	# Equip a real weapon, install a limb, and record one accessory.
	var all = WeaponRegistry.get_all().filter(
		func(w): return w != null and w.weapon_path != "" and ResourceLoader.exists(w.weapon_path))
	if not all.is_empty():
		var w = WeaponRegistry.spawn_instance(all[0])
		player.inventory.equip_weapon(w)
	var limbs = LimbRegistryScript.get_all()
	if not limbs.is_empty():
		player.prosthetic_manager.install_limb(2, limbs[0])   # arm_l slot
	var acc = load("res://resources/accessories/acc_iron_plate.tres")
	if acc != null:
		player.equipped_accessories.append(acc)

	var weapons_before = player.inventory.weapons.size()
	var limb_before = player.prosthetic_manager.get_limb(2) != null
	var acc_before = player.equipped_accessories.size()
	var has_status_action = InputMap.has_action("status")

	# Open the status panel (mirrors game_scene._open_status_panel).
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	world.add_child(layer)
	var panel = CharacterPanelScript.new()
	layer.add_child(panel)   # panel._ready reads player group + builds UI now

	var panel_valid = is_instance_valid(panel)
	print("STATUS has_action=%s weapons=%d limb_installed=%s acc=%d panel_valid=%s" % [
		has_status_action, weapons_before, limb_before, acc_before, panel_valid])
	print("STATUS_PASS" if (has_status_action and weapons_before > 0 and limb_before and acc_before > 0 and panel_valid) else "STATUS_FAIL")
	quit()
	return false
