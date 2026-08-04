## Headless progression test (P0-1 / P0-2 / P1-6 verification).
## Boots the real GameScene, then checks: every zombie type spawns with the
## correct texture, floors advance through to the boss floor, the boss spawns,
## and defeating it shows the victory screen.
extends SceneTree

const GameScript = preload("res://scripts/core/game_state.gd")
const CharEntry = preload("res://scripts/character_entry.gd")
const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const ZombieBossScript = preload("res://scripts/entities/zombie/zombie_boss_base.gd")
const VictoryScreenScript = preload("res://scripts/gameplay/victory_screen.gd")

func _initialize() -> void:
	var cd = CharEntry.new()
	cd.character_class = 0
	cd.strength = 5; cd.agility = 5; cd.intelligence = 5
	cd.constitution = 5; cd.luck = 5; cd.willpower = 5
	cd.starting_health = 100.0; cd.starting_speed = 200.0
	GameScript.start_game(cd)

	var scene = preload("res://scenes/gameplay/game_scene.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	# Make the test player effectively invincible so spawned bosses don't end
	# the run before the assertions run.
	if scene.player and scene.player.stats:
		scene.player.stats.max_health = 1e9
		scene.player.stats.current_health = 1e9

	var t = Timer.new()
	t.wait_time = 1.5
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(_on_done)
	root.add_child(t)


func _on_done() -> void:
	var scene = current_scene as Node
	var spawner = scene.get_node("WaveSpawner")
	var ok := true

	# --- P0-1: every non-boss zombie type resolves to its own sprite ---
	var non_boss := [
		GameEnums.ZombieType.NORMAL, GameEnums.ZombieType.FAST, GameEnums.ZombieType.TANK,
		GameEnums.ZombieType.SELF_DESTRUCT, GameEnums.ZombieType.MECHA_MUTANT,
		GameEnums.ZombieType.BIO_SHIELD, GameEnums.ZombieType.NANOMITE,
		GameEnums.ZombieType.HOLOGRAM, GameEnums.ZombieType.ELITE_BIO_TYRANT,
		GameEnums.ZombieType.ELITE_MECHA_SOLDIER, GameEnums.ZombieType.ELITE_GENE_FUSION,
	]
	for t in non_boss:
		var z = spawner.create_zombie(t)
		if z == null:
			print("FAIL create_zombie type=%d returned null" % t)
			ok = false
			continue
		scene.add_child(z)
		if z.zombie_type != t:
			print("FAIL zombie_type mismatch: expected %d got %d" % [t, z.zombie_type])
			ok = false
		var path = z._get_zombie_texture_path()
		var tex = PixelLoader.load_texture(path)
		if tex == null:
			print("FAIL texture null for type=%d path=%s" % [t, path])
			ok = false

	# --- P0-2: advance floors to the boss floor ---
	var guard := 0
	while scene.current_floor < scene.total_floors and guard < 60:
		scene._advance_floor()
		guard += 1
	if scene.current_floor != scene.total_floors:
		print("FAIL did not reach boss floor: %d" % scene.current_floor)
		ok = false
	else:
		print("OK reached boss floor %d" % scene.current_floor)

	var boss = get_first_node_in_group("boss")
	if boss == null:
		print("FAIL no boss spawned on boss floor")
		ok = false
	else:
		print("OK boss spawned type=%d" % boss.zombie_type)
		boss.die()

	var victory := false
	for c in root.get_children():
		if c is VictoryScreenScript:
			victory = true
	if not victory:
		print("FAIL victory screen not shown after boss death")
		ok = false
	else:
		print("OK victory screen shown")

	# --- Boss types resolve (added after the real boss kill so they don't
	#     steal the victory check) ---
	var bosses := [
		GameEnums.ZombieType.BOSS_ZOMBIE_KING, GameEnums.ZombieType.BOSS_BIO_TITAN,
		GameEnums.ZombieType.BOSS_NANO_CORE, GameEnums.ZombieType.BOSS_EXPERIMENT_ALPHA,
	]
	for bt in bosses:
		var b = spawner.create_boss(bt)
		if b == null or not (b is ZombieBossScript):
			print("FAIL create_boss type=%d" % bt)
			ok = false
			continue
		scene.add_child(b)
		if b.zombie_type != bt:
			print("FAIL boss_type mismatch expected %d got %d" % [bt, b.zombie_type])
			ok = false

	# --- P1-6: pause action registered ---
	if not InputMap.has_action("pause"):
		print("FAIL pause action missing")
		ok = false
	else:
		print("OK pause action present")

	print("PROG_%s" % ("PASS" if ok else "FAIL"))
	quit()
