## Headless test for drop item icons + rarity ring system.
##  - all 5 drop textures load (32x32)
##  - rarity_ring.png loads
##  - PickupItem._setup_visuals creates Visual + RarityRing children
##  - RarityRing modulate differs per rarity level
##  - SoulOrb visual loads
## Not part of the game.
extends SceneTree

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")
const SoulOrbScript = preload("res://scripts/gameplay/soul_orb.gd")
const PlayerScript = preload("res://scripts/entities/player/player.gd")
const PlayerStatsScript = preload("res://scripts/entities/player/player_stats.gd")
const CharacterEntryScript = preload("res://scripts/character_entry.gd")

var world: Node2D
var player
var _started := false
var _elapsed := 0.0
var _checks: Dictionary = {}

func _init() -> void:
	world = Node2D.new()
	world.name = "World"
	root.add_child(world)
	current_scene = world

	var cd = CharacterEntryScript.new()
	cd.strength = 5; cd.agility = 5; cd.intelligence = 5
	cd.constitution = 5; cd.luck = 5; cd.willpower = 5
	cd.starting_health = 100.0; cd.starting_speed = 200.0
	cd.character_class = 0
	player = PlayerScript.new()
	player.set("character_data", cd)
	player.stats = PlayerStatsScript.new()
	world.add_child(player)
	player.global_position = Vector2.ZERO
	player.add_to_group("player")


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		_run_checks()
		return false

	_elapsed += delta
	if _elapsed < 0.1:
		return false

	_final_checks()
	var all_ok := true
	for k in _checks.keys():
		if _checks[k] == false:
			all_ok = false
		print("DROPS check %s=%s" % [k, _checks[k]])
	print("DROPS_PASS" if all_ok else "DROPS_FAIL")
	quit()
	return false


func _run_checks() -> void:
	# --- Texture existence & size ---
	var tex_names := [
		"item_potion.png", "item_weapon.png", "item_accessory.png",
		"item_parts.png", "orb.png", "rarity_ring.png"
	]
	for tn in tex_names:
		var path = "res://assets/pixel/" + tn
		var img = PixelLoader.load_texture(path)
		if img != null:
			_checks[tn + "_exists"] = (img.get_width() == 32 and img.get_height() == 32)
		else:
			_checks[tn + "_exists"] = false

	# --- PickupItem visual structure per rarity ---
	for r in range(4):
		var pi = PickupItemScript.new()
		pi.item_type = PickupItemScript.ItemType.POTION
		pi.rarity = r
		world.add_child(pi)

		var vis = pi.get_node_or_null("Visual")
		var ring = pi.get_node_or_null("RarityRing")
		_checks["r%d_vis" % r] = (vis != null and vis.texture != null)
		_checks["r%d_ring" % r] = (ring != null and ring.texture != null)

		# Ring color should differ between rarities.
		if r > 0:
			var prev_pi = world.get_child(world.get_child_count() - 2) as PickupItemScript
			if prev_pi != null:
				var prev_ring = prev_pi.get_node_or_null("RarityRing")
				if prev_ring != null and ring != null:
					_checks["r%d_diff_r%d" % [r, r - 1]] = (ring.modulate != prev_ring.modulate)

	# --- SoulOrb visual ---
	var orb = SoulOrbScript.new()
	world.add_child(orb)
	var orb_vis = orb.get_node_or_null("Visual")
	_checks["orb_visual"] = (orb_vis != null and orb_vis.texture != null)


func _final_checks() -> void:
	# Verify icon shapes are distinct by checking a few pixels differ.
	var paths := {
		"potion": "res://assets/pixel/item_potion.png",
		"weapon": "res://assets/pixel/item_weapon.png",
		"accessory": "res://assets/pixel/item_accessory.png",
		"parts": "res://assets/pixel/item_parts.png",
		"orb": "res://assets/pixel/orb.png",
	}
	var imgs := {}
	for k in paths:
		imgs[k] = PixelLoader.load_texture(paths[k])

	# Every pair should have at least one differing pixel (at center or nearby).
	var pairs_ok := true
	var keys = imgs.keys()
	for i in range(keys.size()):
		for j in range(i + 1, keys.size()):
			var a = imgs[keys[i]]
			var b = imgs[keys[j]]
			if a == null or b == null:
				pairs_ok = false
				continue
			var diff := false
			for y in range(32):
				for x in range(32):
					if a.get_image().get_pixel(x, y) != b.get_image().get_pixel(x, y):
						diff = true
						break
				if diff:
					break
			if not diff:
				pairs_ok = false
	_checks["all_icons_distinct"] = pairs_ok
