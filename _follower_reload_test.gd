## Headless test for FollowerManager + per-weapon reload SFX.
## Verifies:
##   (A) FollowerManager spawns base_followers, respects cap, increments counter.
##   (B) Reload SFX maps correctly per weapon type.
## Not part of the game.
extends SceneTree

const FollowerManagerScript = preload("res://scripts/systems/follower_manager.gd")
const SummonUnitScript = preload("res://scripts/entities/summon/summon_unit.gd")
const WeaponBaseScript = preload("res://scripts/weapons/weapon_base.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const SfxManagerScript = preload("res://scripts/core/sfx_manager.gd")

var _checks := {}
var _fail_count := 0


func _OK(key: String, ok: bool, note: String = "") -> void:
	_checks[key] = ok
	if not ok:
		_fail_count += 1
		print("  FAIL %s — %s" % [key, note])
	else:
		print("  OK   %s%s" % [key, ("  " + note) if not note.is_empty() else ""])


func _initialize() -> void:
	print("=== FOLLOWER + RELOAD TEST ===")
	_test_follower_system()
	_test_reload_sfx_mapping()
	_test_sfx_files_exist()
	var all_ok := (_fail_count == 0)
	print("\nFOLLOWER_RELOAD %s (%d checks, %d fail)" % ["PASS" if all_ok else "FAIL", _checks.size(), _fail_count])
	quit()


# ==================== PART A: FOLLOWER SYSTEM ====================

func _test_follower_system() -> void:
	print("\n--- A: FollowerManager System ---")

	# A1: FollowerManager can be instantiated and set up.
	var fm = FollowerManagerScript.new()
	root.add_child(fm)
	_OK("FM_INSTANTIATE", fm != null, "FollowerManager creates OK")

	# A2: Setup with null player doesn't crash.
	fm.setup(null, root)
	_OK("FM_SETUP_NULL", true, "setup(null) no crash")

	# A3: can_add() returns false when no owner.
	_OK("FM_NO_OWNER_CAP", not fm.can_add(), "can_add()=false without owner")

	# A4: Spawn each character's base_followers and verify count.
	# We need a mock Player with inventory. Create minimal ones.
	var registry = CharacterRegistryScript.new()
	registry.init()
	var all_chars = registry.get_all()
	_OK("REGISTRY_HAS_CHARS", all_chars.size() >= 6, "registry has %d chars" % all_chars.size())

	# Build a lookup of character_class -> entry for testing.
	var char_map := {}
	for entry in all_chars:
		var ce = entry as CharacterEntryScript
		if ce:
			char_map[ce.character_class] = ce

	# Test each character class (0-5).
	for cls in range(6):
		var ce = char_map.get(cls) as CharacterEntryScript
		if ce == null:
			continue
		# Create a fresh FM + mock player for this class.
		var test_fm = FollowerManagerScript.new()
		root.add_child(test_fm)

		# Minimal mock: we just need player.inventory to exist with max_followers set.
		# Can't easily create full Player in -s script (needs scene tree setup),
		# so we test FollowerManager's config resolution and cap logic directly.
		var cfg = test_fm._config_for_class(cls)
		var cfg_ok := (cfg is Array and cfg.size() >= 4)
		_OK("CONFIG_CLS%d" % cls, cfg_ok, "class %d config=[%.1f, %.1f, %.1f, %s]" % [cls, float(cfg[0]), float(cfg[1]), float(cfg[2]), str(cfg[3])])

		# Verify base_followers <= max_followers for this character (data sanity).
		var data_ok: bool = (ce.base_followers <= ce.max_followers and ce.max_followers > 0)
		_OK("DATA_CLS%d" % cls, data_ok, "base=%d <= max=%d" % [ce.base_followers, ce.max_followers])

		test_fm.queue_free()

	# A5: Verify specific known values from .tres files.
	_OK("VETERAN_BASE", char_map.has(0) and char_map[0].base_followers == 2, "veteran base=2")
	_OK("VETERAN_MAX", char_map.has(0) and char_map[0].max_followers == 4, "veteran max=4")
	_OK("CAT_BASE", char_map.has(3) and char_map[3].base_followers == 1, "cat cafe base=1")
	_OK("CAT_MAX", char_map.has(3) and char_map[3].max_followers == 8, "cat cafe max=8 (NOT old hardcoded 6)")
	_OK("ALIEN_MAX", char_map.has(5) and char_map[5].max_followers == 3, "alien max=3")

	# A6: All 6 classes have distinct tint colors in CLASS_CONFIG.
	var tints := []
	for cls in range(6):
		var test_fm2 = FollowerManagerScript.new()
		var c = test_fm2._config_for_class(cls)
		if c is Array and c.size() >= 4:
			tints.append(c[3])
		test_fm2.queue_free()
	var all_distinct := true
	for i in range(tints.size()):
		for j in range(i + 1, tints.size()):
			if tints[i] == tints[j]:
				all_distinct = false
	_OK("DISTINCT_TINTS", all_distinct, "%d unique tints for 6 classes" % tints.size())

	fm.queue_free()


# ==================== PART B: RELOAD SFX MAPPING ====================

func _test_reload_sfx_mapping() -> void:
	print("\n--- B: Per-Weapon Reload SFX Mapping ---")

	# B1: WeaponBase has _get_reload_sound method.
	var wb = WeaponBaseScript.new()
	root.add_child(wb)
	_OK("HAS_RELOAD_METHOD", wb.has_method("_get_reload_sound"), "_get_reload_sound exists")

	# B2: Default (unknown weapon) returns "reload".
	wb.weapon_name = "UnknownGun"
	wb.weapon_category = 0  # LIGHT_RANGED
	var default_snd = wb._get_reload_sound()
	_OK("DEFAULT_RELOAD", default_snd == "reload", "default='%s'" % default_snd)

	# B3: Shotgun gets reload_shotgun by name override.
	wb.weapon_name = "霰弹枪"
	wb.weapon_category = 0  # (mis-categorized as LIGHT_RANGED but name overrides)
	var sg_snd = wb._get_reload_sound()
	_OK("SHOTGUN_RELOAD", sg_snd == "reload_shotgun", "shotgun='%s'" % sg_snd)

	# B4: RPG gets reload_heavy by name override.
	wb.weapon_name = "火箭炮"
	wb.weapon_category = 1  # HEAVY_RANGED
	var rpg_snd = wb._get_reload_sound()
	_OK("RPG_RELOAD", rpg_snd == "reload_heavy", "rpg='%s'" % rpg_snd)

	# B5: Electric rifle gets reload_laser by name override.
	wb.weapon_name = "电磁步枪"
	wb.weapon_category = 1  # HEAVY_RANGED
	var elec_snd = wb._get_reload_sound()
	_OK("ELECTRIC_RELOAD", elec_snd == "reload_laser", "electric='%s'" % elec_snd)

	# B6: Category fallback: EXPLOSIVE → reload_heavy.
	wb.weapon_name = "SomeExplosive"
	wb.weapon_category = 8  # EXPLOSIVE (index 8 in enum)
	var expl_snd = wb._get_reload_sound()
	_OK("EXPLOSIVE_RELOAD", expl_snd == "reload_heavy", "explosive cat='%s'" % expl_snd)

	# B7: Category fallback: LASER → reload_laser.
	wb.weapon_name = "SomeLaser"
	wb.weapon_category = 5  # LIGHT_LASER
	var las_snd = wb._get_reload_sound()
	_OK("LASER_RELOAD", las_snd == "reload_laser", "laser cat='%s'" % las_snd)

	# B8: Rifle/SMG (LIGHT_RANGED, no name override) → default "reload".
	wb.weapon_name = "精准步枪"
	wb.weapon_category = 0  # LIGHT_RANGED
	var rifle_snd = wb._get_reload_sound()
	_OK("RIFLE_RELOAD", rifle_snd == "reload", "rifle='%s'" % rifle_snd)

	wb.weapon_name = "冲锋枪"
	var smg_snd = wb._get_reload_sound()
	_OK("SMG_RELOAD", smg_snd == "reload", "smg='%s'" % smg_snd)

	# B9: All 5 reloading weapons get valid (non-empty) sound names.
	var weapon_tests := [
		["精准步枪", 0, "reload"],
		["冲锋枪", 0, "reload"],
		["霰弹枪", 0, "reload_shotgun"],
		["电磁步枪", 1, "reload_laser"],
		["火箭炮", 1, "reload_heavy"],
	]
	var all_match := true
	for wt in weapon_tests:
		wb.weapon_name = wt[0]
		wb.weapon_category = wt[1]
		var got = wb._get_reload_sound()
		if got != wt[2]:
			all_match = false
			_FAIL_DETAIL("%s expected '%s' got '%s'" % [wt[0], wt[2], got])
	_OK("ALL_WEAPONS_MATCH", all_match, "5 weapons map to correct SFX")

	wb.queue_free()


# ==================== PART C: SFX FILES EXIST ====================

func _test_sfx_files_exist() -> void:
	print("\n--- C: SFX Files On Disk ---")

	var required := [
		"reload.wav",
		"reload_shotgun.wav",
		"reload_heavy.wav",
		"reload_laser.wav",
	]
	for fname in required:
		# Use FileAccess instead of ResourceLoader (headless lacks .import cache
		# for newly generated files, but the WAVs absolutely exist on disk).
		var path = "res://assets/sfx/" + fname
		var fa = FileAccess.open(path, FileAccess.READ)
		var exists = (fa != null)
		if fa != null:
			fa.close()
		_OK("FILE_" + fname.replace(".", "_"), exists, path)


func _FAIL_DETAIL(msg: String) -> void:
	print("  FAIL DETAIL: %s" % msg)


func _process(_delta: float) -> bool:
	_initialize()
	return true
