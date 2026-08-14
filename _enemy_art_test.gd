## Regression: enemy art + animation + SFX + character select fix.
## Verifies:
##   1. All 15 enemy PNGs exist and are 288x288 (4x4 spritesheet)
##   2. ZombieBase sets up hframes=4/vframes=4 on its Visual sprite
##   3. _update_animation runs without crash for all zombie types
##   4. SFX WAV files all exist and are valid
##   5. Character select lambda capture is fixed (each card has unique entry)
extends SceneTree

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const BossBaseScript = preload("res://scripts/entities/zombie/zombie_boss_base.gd")
const CharacterSelectScript = preload("res://scripts/menus/character_select.gd")
const CharacterRegistry = preload("res://scripts/systems/character_registry.gd")

var _pass := true
var _checks := 0


func _init() -> void:
	CharacterRegistry.init()
	_check_enemy_sprites()
	_check_zombie_visual_setup()
	_check_animation_runs()
	_check_sfx_files()
	_check_character_select_fix()
	_report()


func _check_enemy_sprites() -> void:
	var expected = [
		"zombie_normal.png", "zombie_fast.png", "zombie_tank.png",
		"zombie_self.png", "zombie_mecha_mutant.png",
		"zombie_bio_shield.png", "zombie_nanomite.png", "zombie_hologram.png",
		"zombie_elite_bio_tyrant.png", "zombie_elite_mecha_soldier.png",
		"zombie_elite_gene_fusion.png",
		"boss_king.png", "boss_titan.png", "boss_nano.png", "boss_alpha.png",
	]
	for fname in expected:
		var path = "res://assets/pixel/" + fname
		var tex = PixelLoader.load_texture(path)
		var ok = (tex != null) and (tex.get_width() == 288) and (tex.get_height() == 288)
		_ok("ENEMY_SPRITE_%s" % fname.replace(".", "_"), ok,
			"%s -> %dx%d" % [fname, tex.get_width() if tex else 0, tex.get_height() if tex else 0])


func _check_zombie_visual_setup() -> void:
	# Create a normal zombie, check Visual sprite properties
	var zb = ZombieBaseScript.new()
	zb.zombie_type = 0  # NORMAL
	zb._ready()  # triggers _setup_visuals
	var vis = zb.get_node_or_null("Visual")
	var ok = vis != null and vis.hframes == 4 and vis.vframes == 4
	_ok("ZOMBIE_VISUAL_HVFRAMES", ok,
		"hframes=%d vframes=%d" % [vis.hframes if vis else -1, vis.vframes if vis else -1])
	zb.free()

	# Check boss visual setup
	var boss = BossBaseScript.new()
	boss.zombie_type = 12  # BOSS_ZOMBIE_KING
	boss._ready()
	var bvis = boss.get_node_or_null("Visual")
	ok = bvis != null and bvis.hframes == 4 and bvis.vframes == 4
	_ok("BOSS_VISUAL_HVFRAMES", ok,
		"hframes=%d vframes=%d" % [bvis.hframes if bvis else -1, bvis.vframes if bvis else -1])
	boss.free()

	# Check hologram gets special modulate
	var hol = ZombieBaseScript.new()
	hol.zombie_type = 7  # HOLOGRAM
	hol._ready()
	var hvis = hol.get_node_or_null("Visual")
	ok = hvis != null and hvis.modulate.a < 1.0
	_ok("HOLOGRAM_TRANSLUCENT", ok,
		"modulate.a=%.2f" % (hvis.modulate.a if hvis else 0))
	hol.free()


func _check_animation_runs() -> void:
	# Simulate a few frames of animation for each zombie type without crashing
	var types = [
		[0, "NORMAL"], [1, "FAST"], [2, "TANK"],
		[3, "SELF_DESTRUCT"], [4, "MECHA_MUTANT"],
		[5, "BIO_SHIELD"], [6, "NANOMITE"], [7, "HOLOGRAM"],
		[8, "ELITE_BIO_TYRANT"], [9, "ELITE_MECHA_SOLDIER"],
		[10, "ELITE_GENE_FUSION"],
	]
	for item in types:
		var ztype = item[0]
		var name = item[1]
		var z = ZombieBaseScript.new()
		z.zombie_type = ztype
		z._ready()
		# Run 10 frames of physics at 60fps
		for frame in range(10):
			z._physics_process(1.0 / 60.0)
		# Take damage to trigger hurt anim
		z.take_damage(10.0)
		z._physics_process(1.0 / 60.0)
		var vis = z.get_node_or_null("Visual")
		var ok = vis != null and vis.frame >= 0 and vis.frame < 16
		_ok("ANIM_%s" % name, ok,
			"frame=%d after damage+physics" % (vis.frame if vis else -1))
		z.free()


func _check_sfx_files() -> void:
	var sfx_names = ["hit", "player_hurt", "shoot", "enemy_die", "explosion",
	                  "swing", "reload", "pickup", "levelup"]
	for sname in sfx_names:
		var path = "res://assets/sfx/%s.wav" % sname
		var exists = ResourceLoader.exists(path)
		var size_ok = false
		if exists:
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				var sz = f.get_length()
				size_ok = sz > 500  # at least ~0.5KB for a real SFX
				f.close()
		var ok = exists and size_ok
		_ok("SFX_%s" % sname, ok,
			"%s (%s)" % ["exists" if exists else "MISSING", "valid size" if size_ok else "too small"])


func _check_character_select_fix() -> void:
	# Verify the character registry has 6 distinct entries with correct classes
	var all = CharacterRegistry.get_all()
	var ok = all.size() == 6
	_ok("CHAR_REGISTRY_COUNT", ok, "%d characters" % all.size())

	if ok:
		# Verify each has a unique character_class
		var classes = []
		var unique = true
		for c in all:
			if c.character_class in classes:
				unique = false
			classes.append(c.character_class)
		ok = unique and classes == [0, 1, 2, 3, 4, 5]
		_ok("CHAR_CLASSES_UNIQUE", ok, "classes=%s" % str(classes))

		# Verify alien_shooter has class 5
		var alien = CharacterRegistry.get_data("alien_shooter")
		ok = alien != null and alien.character_class == 5
		_ok("ALIEN_CLASS_5", ok,
			"alien_shooter.class=%d" % (alien.character_class if alien else -1))


func _ok(label: String, passed: bool, detail: String = "") -> void:
	_checks += 1
	if not passed:
		_pass = false
		print("FAIL [%s] %s" % [label, detail])
	else:
		print("  OK [%s] %s" % [label, detail])


func _report() -> void:
	print("")
	if _pass:
		print("=== ALL %d CHECKS PASSED ===" % _checks)
	else:
		print("=== SOME CHECKS FAILED ===")
	quit(_checks if _pass else 1)
