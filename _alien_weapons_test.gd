## Verifies the per-character max_weapons cap: Alien Shooter can hold 4
## weapons (4 tentacles), other classes stay at 2.
## Run: Godot ... -s res://_alien_weapons_test.gd
extends SceneTree

const WeaponInventoryScript = preload("res://scripts/entities/player/weapon_inventory.gd")
const WeaponRifleScript = preload("res://scripts/weapons/ranged/weapon_rifle.gd")
const WeaponChainsawScript = preload("res://scripts/weapons/melee/weapon_chainsaw.gd")
const WeaponSMGScript = preload("res://scripts/weapons/ranged/weapon_smg.gd")
const WeaponDualBladeScript = preload("res://scripts/weapons/melee/weapon_dualblade.gd")


func _initialize() -> void:
	# Alien Shooter: max_weapons = 4
	var inv: WeaponInventoryScript = WeaponInventoryScript.new()
	inv.max_weapons = 4
	root.add_child(inv)
	inv.equip_weapon(WeaponRifleScript.new())
	inv.equip_weapon(WeaponChainsawScript.new())
	inv.equip_weapon(WeaponSMGScript.new())
	inv.equip_weapon(WeaponDualBladeScript.new())
	print("alien weapons size (max=4): %d" % inv.weapons.size())
	var alien_ok: bool = (inv.weapons.size() == 4)
	inv.queue_free()

	# Veteran: max_weapons = 2 (3rd pickup drops one, stays 2)
	var inv2: WeaponInventoryScript = WeaponInventoryScript.new()
	inv2.max_weapons = 2
	root.add_child(inv2)
	inv2.equip_weapon(WeaponRifleScript.new())
	inv2.equip_weapon(WeaponChainsawScript.new())
	inv2.equip_weapon(WeaponSMGScript.new())
	print("veteran weapons size (max=2): %d" % inv2.weapons.size())
	var vet_ok: bool = (inv2.weapons.size() == 2)
	inv2.queue_free()

	var ok: bool = alien_ok and vet_ok
	print("ALIEN_WEAPONS %s" % ("PASS" if ok else "FAIL"))
	quit()
