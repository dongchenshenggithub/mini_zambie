## Tests the follower attack chain directly (bypassing -s group quirks by
## manually registering the zombie in the "zombie" group and setting its HP).
## Run: Godot ... -s res://_follower_damage_test.gd
extends SceneTree

const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const SummonUnitScript = preload("res://scripts/entities/summon/summon_unit.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const ZE = preload("res://scripts/core/game_enums.gd")

func _initialize() -> void:
	var holder := Node.new()
	root.add_child(holder)

	var p := PlayerScript.new()
	holder.add_child(p)

	var z := ZombieBaseScript.new()
	z.zombie_type = ZE.ZombieType.NORMAL
	holder.add_child(z)
	# -s quirk: auto group/HP init from _ready is unreliable, so set manually.
	z.add_to_group("zombie")
	z.current_health = z.base_health
	z.global_position = p.global_position

	var f := SummonUnitScript.new()
	f.owner_node = p
	f.damage = 12.0
	f.range = 160.0
	f._attack_rate = 0.1
	holder.add_child(f)
	f.global_position = p.global_position

	print("prep: base_health=%.1f current_health=%.1f in_group=%s" % [
		z.base_health, z.current_health, z.is_in_group("zombie")])

	# 1) Direct take_damage works?
	var h0: float = z.current_health
	z.take_damage(12.0)
	var h1: float = z.current_health
	print("direct take_damage: %.1f -> %.1f (delta %.1f)" % [h0, h1, h0 - h1])
	var direct_ok: bool = (h0 - h1) > 0.0

	# reset
	z.current_health = z.base_health

	# 2) Follower _attack path?
	var g0: float = z.current_health
	f._attack()
	var g1: float = z.current_health
	print("follower _attack: %.1f -> %.1f (delta %.1f)" % [g0, g1, g0 - g1])
	var follow_ok: bool = (g0 - g1) > 0.0

	print("DIRECT_TAKEDAMAGE %s" % ("PASS" if direct_ok else "FAIL"))
	print("FOLLOWER_DAMAGE %s" % ("PASS" if follow_ok else "FAIL"))
	quit()
