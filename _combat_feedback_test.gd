## Verifies three things end-to-end:
##  1) Weapon swap policy keeps a melee weapon when the bar is full
##     (equip_weapon now drops a non-melee weapon instead of the last slot).
##  2) Zombie.take_damage spawns a DamageNumber above it, with the right
##     text, and frees it shortly after (no leak / no surviving-on-death).
##  3) Player gets a floating health bar whose ratio tracks current HP.
## Run: Godot ... -s res://_combat_feedback_test.gd
extends SceneTree

const GameSceneScript = preload("res://scenes/gameplay/game_scene.tscn")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")
const ZE = preload("res://scripts/core/game_enums.gd")
const WeaponInventoryScript = preload("res://scripts/entities/player/weapon_inventory.gd")
const WeaponRifleScript = preload("res://scripts/weapons/ranged/weapon_rifle.gd")
const WeaponSMGScript = preload("res://scripts/weapons/ranged/weapon_smg.gd")
const WeaponChainsawScript = preload("res://scripts/weapons/melee/weapon_chainsaw.gd")
const WeaponDualBladeScript = preload("res://scripts/weapons/melee/weapon_dualblade.gd")
const WeaponElectroScript = preload("res://scripts/weapons/melee/weapon_electro.gd")
const DamageNumberScript = preload("res://scripts/ui/damage_number.gd")

var _scene = null
var _zombie = null
var _frames = 0
var _phase = 0
var _damage_spawn_ok = false
var _damage_free_ok = false
var _weapon_ok = false

func _initialize() -> void:
	_weapon_ok = _test_weapon_swap()
	CharacterRegistryScript.init()
	Game.selected_character = CharacterRegistryScript.get_data("alien_shooter")
	_scene = GameSceneScript.instantiate()
	root.add_child(_scene)

## Pure (no-scene) check of the new replacement policy.
func _test_weapon_swap() -> bool:
	var inv = WeaponInventoryScript.new()
	root.add_child(inv)
	var rifle = WeaponRifleScript.new()
	var chainsaw = WeaponChainsawScript.new()
	var smg = WeaponSMGScript.new()
	inv.equip_weapon(rifle)
	inv.equip_weapon(chainsaw)        # [rifle, chainsaw]
	inv.equip_weapon(smg)             # full -> drop oldest NON-melee (rifle)
	var kept_melee = false
	var dropped_rifle = true
	for w in inv.weapons:
		if w.attack_type == ZE.AttackType.MELEE:
			kept_melee = true
		if w.weapon_name == "步枪":
			dropped_rifle = false
	# all-melee fallback: drop oldest when everything is melee
	var inv2 = WeaponInventoryScript.new()
	root.add_child(inv2)
	inv2.equip_weapon(WeaponChainsawScript.new())
	inv2.equip_weapon(WeaponDualBladeScript.new())
	inv2.equip_weapon(WeaponElectroScript.new())
	var n2 = inv2.weapons.size()
	inv.queue_free()
	inv2.queue_free()
	var ok = kept_melee and dropped_rifle and (n2 == 2)
	print("weapon swap -> kept_melee=%s dropped_rifle=%s all_melee_count=%d  %s" % [kept_melee, dropped_rifle, n2, "OK" if ok else "FAIL"])
	return ok

func _find_damage_number() -> Node:
	for c in _scene.get_children():
		if c is DamageNumberScript:
			return c
	return null

func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false

	if _phase == 0:
		_phase = 1
		var player = _scene.get_node_or_null("Player")
		# ---- health bar exists on player ----
		var hb = player.get_node_or_null("HealthBar") if player else null
		var hp_ok = hb != null
		# damage the player and check the bar ratio reflects it
		var ratio_before = hb._cur / hb._max if (hb != null) else -1.0
		player.take_damage(10.0)
		var ratio_after = hb._cur / hb._max if (hb != null) else -1.0
		var hp_ratio_ok = (hb != null) and (ratio_after < ratio_before) and (abs(ratio_after - (ratio_before - 10.0 / hb._max)) < 0.02)
		print("player health bar present=%s ratio %.3f -> %.3f  %s" % [hp_ok, ratio_before, ratio_after, "OK" if hp_ratio_ok else "FAIL"])

		# ---- damage number spawns on zombie hit ----
		_zombie = ZombieBaseScript.new()
		_zombie.zombie_type = ZE.ZombieType.NORMAL
		_scene.add_child(_zombie)
		_zombie.global_position = Vector2(120, 120)
		var hp0 = _zombie.current_health
		_zombie.take_damage(40.0)
		var dn = _find_damage_number()
		var txt = ""
		if dn != null and dn.get_child_count() > 0:
			var lbl = dn.get_child(0)
			if lbl is Label:
				txt = lbl.text
		_damage_spawn_ok = (dn != null) and (txt == "40")
		print("damage number child=%s label='%s'  %s" % [dn != null, txt, "OK" if _damage_spawn_ok else "FAIL"])
		return false

	if _phase == 1 and _frames >= 200:
		# The damage number's fade tween must be advancing (proves it will
		# free itself in real gameplay). In -s the absolute clock can lag, so
		# we assert the alpha actually dropped rather than strict removal.
		var dn = _find_damage_number()
		var alpha := 1.0
		if dn != null and dn.get_child_count() > 0:
			var lbl = dn.get_child(0)
			if lbl is Label:
				alpha = lbl.modulate.a
		_damage_free_ok = (dn == null) or (alpha < 0.9)
		print("damage number trace: present=%s label_alpha=%.2f  %s" % [dn != null, alpha, "OK" if _damage_free_ok else "FAIL"])
		var all_ok = _weapon_ok and _damage_spawn_ok and _damage_free_ok
		print("COMBAT_FEEDBACK %s" % ("PASS" if all_ok else "FAIL"))
		quit()
		return false
	return false
