extends SceneTree

## Headless verification for the rebuilt character select screen.
## - loads the scene
## - confirms 6 avatar cards were built
## - confirms every portrait_<id>.png exists & loads to a non-null texture
## - confirms back button is present

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const CHAR_SELECT = "res://scenes/menus/character_select.tscn"

func _init() -> void:
	var all_ok := true

	# 1. parse-check both scene and script
	var s1 := load("res://scenes/menus/character_select.tscn")
	if s1 == null:
		print("SELECT_FAIL: cannot load scene"); all_ok = false
	var s2 := load("res://scripts/menus/character_select.gd")
	if s2 == null:
		print("SELECT_FAIL: cannot load script"); all_ok = false

	# 2. load scene and grab the root
	change_scene_to_file(CHAR_SELECT)
	await create_timer(0.3).timeout
	var root := current_scene
	if root == null:
		print("SELECT_FAIL: no current scene"); quit(); return

	# 3. check CharacterRegistry has 6 entries
	CharacterRegistry.init()
	var chars := CharacterRegistry.get_all()
	if chars.size() != 6:
		print("SELECT_FAIL: expected 6 characters, got ", chars.size()); all_ok = false

	# 4. confirm GridContainer has 6 child cards
	var grid: GridContainer = root.get_node_or_null("Center/Grid")
	if grid == null:
		print("SELECT_FAIL: Grid node missing"); all_ok = false
	else:
		var card_count := 0
		for c in grid.get_children():
			if c is Button:
				card_count += 1
		if card_count != 6:
			print("SELECT_FAIL: expected 6 card buttons, got ", card_count); all_ok = false

	# 5. confirm every portrait PNG exists & loads to a non-null texture
	var expected_ids := ["veteran", "alien_shooter", "professor",
			"mech_monk", "cat_cafe_worker", "cyber_cultivator"]
	for cid in expected_ids:
		var tex = PixelLoader.load_texture("res://assets/pixel/portrait_%s.png" % cid)
		if tex == null:
			print("SELECT_FAIL: portrait missing for %s" % cid); all_ok = false

	# 6. confirm each card has a TextureRect child with a non-null texture
	if grid != null:
		for c in grid.get_children():
			if c is Button:
				var found_tex := false
				for sub in c.get_children():
					if sub is VBoxContainer:
						for leaf in sub.get_children():
							if leaf is TextureRect and leaf.texture != null:
								found_tex = true
				if not found_tex:
					print("SELECT_FAIL: card missing avatar texture"); all_ok = false

	# 7. confirm BackButton exists
	var back: Button = root.get_node_or_null("Center/BackButton")
	if back == null:
		print("SELECT_FAIL: BackButton missing"); all_ok = false

	print("SELECT ", "PASS" if all_ok else "FAIL")
	quit()