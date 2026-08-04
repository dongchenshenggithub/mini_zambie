## Regenerate the four drop scenes with a proper uid in the ext_resource so
## the scene parser can resolve pickup_item.gd (hand-written scenes with a
## path-only ext_resource fail to attach the script under Godot 4.7's cache).
## Not part of the game.
extends SceneTree

const PickupItemScript = preload("res://scripts/gameplay/pickup_item.gd")

func _init() -> void:
	var defs := [
		["res://scenes/gameplay/potion.tscn", PickupItemScript.ItemType.POTION, "PotionDrop"],
		["res://scenes/gameplay/weapon_drop.tscn", PickupItemScript.ItemType.WEAPON, "WeaponDrop"],
		["res://scenes/gameplay/accessory_drop.tscn", PickupItemScript.ItemType.ACCESSORY, "AccessoryDrop"],
		["res://scenes/gameplay/parts_drop.tscn", PickupItemScript.ItemType.PARTS, "PartsDrop"],
	]
	for d in defs:
		var node = PickupItemScript.new()
		node.name = d[2]
		node.item_type = d[1]
		var scene := PackedScene.new()
		var pack_err := scene.pack(node)
		if pack_err != OK:
			printerr("PACK_FAIL %s -> %d" % [d[0], pack_err])
			node.queue_free()
			continue
		var save_err := ResourceSaver.save(scene, d[0])
		print("GEN_DROP %s item_type=%d save_err=%d" % [d[0], d[1], save_err])
		node.queue_free()
	quit()
