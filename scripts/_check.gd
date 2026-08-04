extends SceneTree
const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")
func _init() -> void:
	var scenes = [
		["res://scenes/gameplay/potion.tscn", PickupItemScript.ItemType.POTION],
		["res://scenes/gameplay/weapon_drop.tscn", PickupItemScript.ItemType.WEAPON],
		["res://scenes/gameplay/accessory_drop.tscn", PickupItemScript.ItemType.ACCESSORY],
		["res://scenes/gameplay/parts_drop.tscn", PickupItemScript.ItemType.PARTS],
	]
	var all_ok := true
	for s in scenes:
		var sc = load(s[0])
		if sc == null:
			print("LOAD FAIL %s" % s[0])
			all_ok = false
			continue
		var inst = sc.instantiate()
		var it = inst.get("item_type")
		var ok = (it == s[1])
		if not ok:
			all_ok = false
		print("SCENE %s item_type=%s expect=%s ok=%s" % [s[0].get_file(), it, s[1], ok])
		inst.queue_free()
	print("SCENE_SUMMARY %s" % ["OK" if all_ok else "FAIL"])
	quit()
