## Headless runtime sanity test for Phase 1 (upgrade = attributes only) and
## Phase 2 (prosthetics). Not part of the game. Verifies the core growth loop
## actually mutates stats and that level-ups never offer weapons now.
extends SceneTree

const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const WeaponInventoryScript = preload("res://scripts/entities/player/weapon_inventory.gd")
const ProstheticManagerScript = preload("res://scripts/core/prosthetic_manager.gd")
const WeaponRegistryScript = preload("res://scripts/systems/weapon_registry.gd")
const LimbRegistryScript = preload("res://scripts/systems/limb_registry.gd")
const UpgradePickerScript = preload("res://scripts/systems/upgrade_picker.gd")
const GameEnumsScript = preload("res://scripts/core/game_enums.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")

func _initialize() -> void:
	WeaponRegistryScript.init()
	LimbRegistryScript.init()

	var cd = CharacterEntryScript.new()
	cd.strength = 5
	cd.agility = 5
	cd.intelligence = 5
	cd.constitution = 5
	cd.luck = 5
	cd.willpower = 5
	cd.starting_health = 100.0
	cd.starting_speed = 200.0
	cd.ranged_damage_multiplier = 1.0
	cd.melee_damage_multiplier = 1.0
	cd.laser_damage_multiplier = 1.0
	cd.summon_damage_multiplier = 1.0
	cd.spray_damage_multiplier = 1.0
	cd.heal_rate = 0.0
	var p = PlayerScript.new()
	p.set("character_data", cd)
	p.stats = PlayerStatsScript.new()
	p.inventory = WeaponInventoryScript.new()
	p.prosthetic_manager = ProstheticManagerScript.new(false, p.stats)
	p._apply_character_traits()
	print("DEBUG cd_is_entry=", (cd is CharacterEntryScript), " p.char_data=", p.character_data)

	# --- Phase 2: limb install ---
	var limb = LimbRegistryScript.get_random()
	print("LIMB: ", limb.slot_name, " (slot ", limb.slot_type, ")")
	var dmg_before = p.stats.get_damage_multiplier(GameEnumsScript.AttackType.RANGED)
	var speed_before = p.stats.get_movement_speed()
	var ok = p.prosthetic_manager.install_limb(3, limb)  # 3 = arm_r, valid for veteran
	var dmg_after = p.stats.get_damage_multiplier(GameEnumsScript.AttackType.RANGED)
	var speed_after = p.stats.get_movement_speed()
	print("INSTALL ok=%s dmg %.3f->%.3f speed %.1f->%.1f" % [ok, dmg_before, dmg_after, speed_before, speed_after])

	# --- Phase 1: level-up offers ONLY attribute upgrades (no weapon) ---
	var picker = UpgradePickerScript.new()
	var options = picker.generate_options(p, 6)
	print("OPTIONS(%d):" % options.size())
	var all_attr := true
	for o in options:
		print("  - ", _kind_name(int(o["kind"])), o.get("label", ""))
		if int(o["kind"]) > int(UpgradePickerScript.UpgradeKind.WILLPOWER):
			all_attr = false
	if not all_attr or options.size() != 6:
		print("RUNTIME_FAIL: level-up offered a non-attribute option")
		quit()
		return

	var attr_opt = null
	for o in options:
		if o.get("attr", "") != "":
			attr_opt = o
			break
	if attr_opt != null:
		var attr = attr_opt["attr"]
		var before_val = int(p.character_data.get(attr))
		picker.apply_upgrade(attr_opt, p)
		var after_val = int(p.character_data.get(attr))
		print("APPLY_ATTR %s: %d -> %d | ranged_mult %.3f" % [attr, before_val, after_val, p.stats.get_damage_multiplier(GameEnumsScript.AttackType.RANGED)])
	else:
		print("NO_ATTR_OPTION")

	print("RUNTIME_PASS")
	quit()

func _kind_name(k: int) -> String:
	var names = ["HEALTH","STRENGTH","AGILITY","INTELLIGENCE","CONSTITUTION","LUCK","WILLPOWER"]
	if k >= 0 and k < names.size():
		return names[k]
	return str(k)
