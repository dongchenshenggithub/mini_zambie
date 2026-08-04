extends SceneTree
## Reproduces the real open/close flow for the character status panel:
##  - opening pauses the tree and the panel is VISIBLE (white modulate, dim overlay)
##  - pressing the "status" key again CLOSES it and resumes
## Not part of the game.

const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const WeaponRegistry = preload("res://scripts/systems/weapon_registry.gd")
const LimbRegistryScript = preload("res://scripts/systems/limb_registry.gd")
const CharacterPanelScript = preload("res://scripts/ui/character_panel.gd")

var world: Node2D
var player: Player
var panel_ref: Control = null
var _elapsed := 0.0
var _started := false
var _open_checked := false
var _close_sent := false
var _checks: Dictionary = {}


func _init() -> void:
	world = Node2D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world

	var cd = CharacterEntryScript.new()
	cd.name = "测试角色"
	cd.character_class = 0
	cd.strength = 7; cd.agility = 6; cd.constitution = 5
	cd.starting_health = 100.0; cd.starting_speed = 200.0
	player = PlayerScript.new()
	player.character_data = cd
	player.stats = PlayerStatsScript.new()
	world.add_child(player)
	player.add_to_group("player")
	WeaponRegistry.init()
	LimbRegistryScript.init()


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		# equip a weapon, a limb, an accessory so the panel has content
		var all = WeaponRegistry.get_all().filter(
			func(w): return w != null and w.weapon_path != "" and ResourceLoader.exists(w.weapon_path))
		if not all.is_empty():
			player.inventory.equip_weapon(WeaponRegistry.spawn_instance(all[0]))
		var limbs = LimbRegistryScript.get_all()
		if not limbs.is_empty():
			player.prosthetic_manager.install_limb(2, limbs[0])
		var acc = load("res://resources/accessories/acc_iron_plate.tres")
		if acc != null:
			player.equipped_accessories.append(acc)
		_open_panel()
		return false

	_elapsed += delta

	if not _open_checked and _elapsed >= 0.15:
		_open_checked = true
		var valid = is_instance_valid(panel_ref)
		var white = valid and panel_ref.modulate == Color(1, 1, 1, 1)
		var has_dim = valid and panel_ref.has_node("Dim")
		var paused = self.paused  # SceneTree.paused
		_checks["panel_visible"] = valid and white and has_dim
		_checks["tree_paused"] = paused
		print("OPEN valid=%s white_modulate=%s has_dim=%s paused=%s" % [valid, white, has_dim, paused])

	if not _close_sent and _elapsed >= 0.35:
		_close_sent = true
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_I          # "status" action (I)
		ev.pressed = true
		Input.parse_input_event(ev)
		print("CLOSE event sent")

	if _elapsed >= 0.6:
		var still_valid = is_instance_valid(panel_ref)
		var resumed = not self.paused
		_checks["closed"] = not still_valid
		_checks["resumed"] = resumed
		print("AFTER close still_valid=%s resumed=%s" % [still_valid, resumed])
		var all_ok := true
		for k in _checks.keys():
			if not _checks[k]:
				all_ok = false
			print("FLOW %s=%s" % [k, _checks[k]])
		print("STATUS_FLOW_PASS" if all_ok else "STATUS_FLOW_FAIL")
		quit()
	return false


func _open_panel() -> void:
	var panel = CharacterPanelScript.new()
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(layer)
	layer.add_child(panel)
	panel_ref = panel
	paused = true
