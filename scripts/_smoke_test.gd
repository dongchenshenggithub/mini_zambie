## Headless gameplay smoke test (Phase 4 stability).
## Boots the real GameScene, lets it run a few seconds with no input, and
## reports any runtime SCRIPT ERRORs from the live combat/wave/AI loop.
extends SceneTree

const GameScript = preload("res://scripts/core/game_state.gd")
const CharEntry = preload("res://scripts/character_entry.gd")

func _initialize() -> void:
	var cd = CharEntry.new()
	cd.character_class = 0
	cd.strength = 5; cd.agility = 5; cd.intelligence = 5
	cd.constitution = 5; cd.luck = 5; cd.willpower = 5
	cd.starting_health = 100.0; cd.starting_speed = 200.0
	cd.ranged_damage_multiplier = 1.0; cd.melee_damage_multiplier = 1.0
	cd.laser_damage_multiplier = 1.0; cd.summon_damage_multiplier = 1.0
	cd.spray_damage_multiplier = 1.0; cd.heal_rate = 0.0
	GameScript.start_game(cd)

	var scene = preload("res://scenes/gameplay/game_scene.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	print("SCENE_ADDED")

	var t = Timer.new()
	t.wait_time = 4.0
	t.one_shot = true
	t.autostart = true
	t.timeout.connect(_on_done)
	root.add_child(t)

func _on_done() -> void:
	print("SMOKE_DONE")
	quit()
