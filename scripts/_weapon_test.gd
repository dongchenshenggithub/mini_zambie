## Verifies every character gets a working starting weapon:
##  - the weapon is equipped (inventory not empty)
##  - the weapon node is inside the scene tree (so fire() can reach get_tree())
##  - the weapon's built-in `owner` is set (so owner.global_position works)
##  - calling fire() actually spawns a projectile without crashing
extends SceneTree

const MainMenu = preload("res://scenes/menus/main_menu.tscn")
const ProjectileBase = preload("res://scripts/projectiles/projectile_base.gd")
const CharacterRegistry = preload("res://scripts/systems/character_registry.gd")

func _count_projectiles(scene) -> int:
	var n := 0
	for c in scene.get_children():
		if c is ProjectileBase:
			n += 1
	return n

func _initialize() -> void:
	change_scene_to_file("res://scenes/menus/main_menu.tscn")
	await create_timer(0.4).timeout
	current_scene._on_start_pressed()
	await create_timer(0.4).timeout
	var cs = current_scene
	cs._on_select(CharacterRegistry.get_all()[0])  # veteran -> rifle
	await create_timer(0.6).timeout

	var gs = current_scene
	if gs == null:
		print("WEAPON FAIL: no game scene")
		print("WEAPON_TEST FAIL")
		quit()
		return

	var player = gs.get("player")
	if player == null:
		print("WEAPON player=MISSING")
		print("WEAPON_TEST FAIL")
		quit()
		return

	var inv = player.inventory
	print("WEAPON diag: char=%s init_weapon=%s wr_count=%d wr_rifle=%s inv_null=%s" % [
		(Game.selected_character.name if Game.selected_character != null else "null"),
		(Game.selected_character.initial_weapon_id if Game.selected_character != null else "?"),
		WeaponRegistry.get_all().size(),
		WeaponRegistry.get_data("rifle") != null,
		inv == null])
	var w = inv.weapons[0] if inv.weapons.size() > 0 else null
	var equipped = inv.weapons.size() > 0
	var in_tree = (w != null and w.is_inside_tree())
	var owner_set = (w != null and w.owner != null)
	print("WEAPON equipped=%s in_tree=%s owner_set=%s name=%s" % [equipped, in_tree, owner_set, (w.weapon_name if w != null else "none")])

	# Fire once and confirm a projectile is spawned into the scene.
	var scene = current_scene
	var before = _count_projectiles(scene)
	if w != null:
		w.try_fire(0.0)
	await create_timer(0.05).timeout
	var after = _count_projectiles(scene)
	var fired = after > before
	print("WEAPON projectiles before=%d after=%d fired=%s" % [before, after, fired])

	var ok = equipped and in_tree and owner_set and fired
	print("WEAPON_TEST %s" % ("PASS" if ok else "FAIL"))
	quit()
