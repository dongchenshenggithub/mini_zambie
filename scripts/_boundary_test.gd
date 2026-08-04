## Verifies the player position is clamped to the floor bounds so it can't
## walk off the background, and that GameScene exposes/derives those bounds.
extends SceneTree

const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const ProstheticManagerScript = preload("res://scripts/core/prosthetic_manager.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")

var world
var player
var _started := false
var _results: Array[String] = []
var _ok := true


func _init() -> void:
	# Mock GameScene: provides get_world_bounds() duck-typed as the player reads it.
	var MockScript := GDScript.new()
	MockScript.source_code = "extends Node2D\nfunc get_world_bounds() -> Rect2:\n\treturn Rect2(-800.0, -500.0, 1600.0, 1000.0)"
	MockScript.reload()
	world = MockScript.new()
	world.name = "MockScene"
	root.add_child(world)
	current_scene = world

	var cd = CharacterEntryScript.new()
	cd.character_class = 0; cd.starting_health = 100.0; cd.starting_speed = 200.0
	player = PlayerScript.new(); player.set("character_data", cd)
	player.stats = PlayerStatsScript.new()
	player.prosthetic_manager = ProstheticManagerScript.new(false, player.stats)
	world.add_child(player)
	player.global_position = Vector2.ZERO
	player.add_to_group("player")


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		# Shove the player far outside the bounds and let physics clamp it back.
		player.global_position = Vector2(5000.0, -4000.0)
		# Nudge velocity so move_and_slide runs and the clamp applies.
		player.velocity = Vector2(1000.0, -1000.0)
		return false

	# After a few frames the position must be inside the bounds (minus margin).
	var b := Rect2(-800.0, -500.0, 1600.0, 1000.0)
	var m := 22.0
	var px = player.global_position.x
	var py = player.global_position.y
	var inside: bool = px <= b.position.x + b.size.x - m + 1.0 and px >= b.position.x + m - 1.0 and py <= b.position.y + b.size.y - m + 1.0 and py >= b.position.y + m - 1.0
	_results.append("BOUNDARY pos=%s inside=%s" % [player.global_position, inside])
	_ok = inside
	print(_results[0])
	print("BOUNDARY_TEST %s" % ("PASS" if _ok else "FAIL"))
	quit()
	return false
