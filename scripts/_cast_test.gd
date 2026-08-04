## Headless test: instantiate every ZombieType (regular + boss) and a player
## to confirm each resolves to a pixel texture without runtime error.
extends SceneTree

var PixelLoader = preload("res://scripts/core/pixel_loader.gd")
var ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
var ZombieBossScript = preload("res://scripts/entities/zombie/zombie_boss_base.gd")

func _initialize() -> void:
	var types = [
		GameEnums.ZombieType.NORMAL, GameEnums.ZombieType.FAST,
		GameEnums.ZombieType.TANK, GameEnums.ZombieType.SELF_DESTRUCT,
		GameEnums.ZombieType.MECHA_MUTANT, GameEnums.ZombieType.BIO_SHIELD,
		GameEnums.ZombieType.NANOMITE, GameEnums.ZombieType.HOLOGRAM,
		GameEnums.ZombieType.ELITE_BIO_TYRANT, GameEnums.ZombieType.ELITE_MECHA_SOLDIER,
		GameEnums.ZombieType.ELITE_GENE_FUSION,
		GameEnums.ZombieType.BOSS_ZOMBIE_KING, GameEnums.ZombieType.BOSS_BIO_TITAN,
		GameEnums.ZombieType.BOSS_NANO_CORE, GameEnums.ZombieType.BOSS_EXPERIMENT_ALPHA,
	]
	var ok := 0
	for t in types:
		var z = ZombieBaseScript.new() if t < GameEnums.ZombieType.BOSS_ZOMBIE_KING else ZombieBossScript.new()
		z.zombie_type = t
		var path = z._get_zombie_texture_path() if t < GameEnums.ZombieType.BOSS_ZOMBIE_KING else z._get_boss_texture_path()
		var tex = PixelLoader.load_texture(path)
		var status = "OK" if tex != null else "MISSING"
		if tex != null:
			ok += 1
		print("  %s -> %s [%s]" % [GameEnums.ZombieType.keys()[t], path.get_file(), status])
		z.free()
	print("CAST_TEST: %d/%d zombie textures resolved" % [ok, types.size()])

	# Player classes
	var PlayerScript = preload("res://scripts/entities/player/player.gd")
	var pok := 0
	for c in range(GameEnums.CharacterClass.size()):
		var p = PlayerScript.new()
		var ptex = PixelLoader.load_texture("res://assets/pixel/player_%d.png" % c)
		if ptex != null:
			pok += 1
		print("  player_%d.png [%s]" % [c, "OK" if ptex != null else "MISSING"])
		p.free()
	print("CAST_TEST: %d/%d player textures resolved" % [pok, GameEnums.CharacterClass.size()])
	quit()
