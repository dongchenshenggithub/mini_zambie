extends SceneTree

## Repro for "选什么人形象都是老兵": after fixing the character_data timing,
## each character selection must yield a player whose visual class matches the
## selected CharacterEntry.character_class (not the default 0 = veteran).
func _process(_d: float) -> bool:
	CharacterRegistry.init()
	var all = CharacterRegistry.get_all()
	var all_ok = true
	for expect in all:
		Game.selected_character = expect
		var scene = load("res://scenes/gameplay/game_scene.tscn").instantiate()
		root.add_child(scene)
		var p = scene.get_node_or_null("Player")
		var got_data = -1
		if p != null and p.character_data != null:
			got_data = p.character_data.character_class
		var vis = -1
		if p != null:
			vis = p._visual_class
		var ok = (p != null and p.character_data != null
			and got_data == expect.character_class and vis == expect.character_class)
		print("CASE id=%s class=%d data=%d vis=%d OK=%s" % [expect.id, expect.character_class, got_data, vis, str(ok)])
		if not ok:
			all_ok = false
		scene.queue_free()
	print("SELECT_UNIFORM_OK=%s" % str(all_ok))
	quit()
	return false
