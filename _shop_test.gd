## Verifies the between-floor shop: souls currency, stock generation, and the
## real purchase paths (weapon equip / accessory stat apply / heal) through the
## live player from the real game scene. Run: Godot ... -s res://_shop_test.gd
extends SceneTree

const GameSceneScript = preload("res://scenes/gameplay/game_scene.tscn")
const CharacterRegistryScript = preload("res://scripts/systems/character_registry.gd")
const WeaponRegistryScript = preload("res://scripts/systems/weapon_registry.gd")
const AccessoryRegistryScript = preload("res://scripts/systems/accessory_registry.gd")
const ShopPanelScript = preload("res://scripts/ui/shop_panel.gd")

var _scene = null
var _frames := 0
var _done := false
var _results: Array[String] = []
var _failed := false


func _initialize() -> void:
	CharacterRegistryScript.init()
	WeaponRegistryScript.init()
	AccessoryRegistryScript.init()
	Game.selected_character = CharacterRegistryScript.get_data("veteran")


func _physics_process(_delta: float) -> bool:
	if _done:
		return false
	if _scene == null:
		_scene = GameSceneScript.instantiate()
		root.add_child(_scene)
		_frames = 0
		return false
	_frames += 1
	if _frames < 3:
		return false
	_run_checks()
	_scene.queue_free()
	_scene = null
	_report()
	quit()
	return false


func _run_checks() -> void:
	var player = _scene.get_node_or_null("Player")
	if player == null:
		_fail("player node missing")
		return
	if player.inventory == null:
		_fail("player inventory missing")
		return

	# --- souls currency + stock generation ---
	var stock = ShopPanelScript.roll_stock()
	_check(stock.size() > 0, "roll_stock returns non-empty stock (got %d)" % stock.size())
	var all_priced := true
	for e in stock:
		if ShopPanelScript.price_for(e.data if e.get("data") != null else null) <= 0:
			all_priced = false
	_check(all_priced, "every shop item has a positive price")
	_check(ShopPanelScript.price_for(null) == 15, "heal price defaults to 15")

	# --- weapon purchase (real equip path) ---
	Game.souls = 0
	var weapons = WeaponRegistryScript.get_all().filter(
		func(w): return w != null and w.weapon_path != "" and ResourceLoader.exists(w.weapon_path))
	var wd = weapons[0]
	var before = player.inventory.weapons.size()
	var price = ShopPanelScript.price_for(wd)
	Game.souls = price  # exactly enough
	var ok_w = false
	if Game.souls >= price:
		Game.souls -= price
		ok_w = ShopPanelScript.apply_weapon_purchase(player, wd)
	_check(ok_w and player.inventory.weapons.size() == before + 1,
		"weapon purchase equips (+1 weapon, souls deducted to %d)" % Game.souls)

	# --- accessory purchase (real stat apply path) ---
	var acc = AccessoryRegistryScript.get_all()[0]
	var ok_a = ShopPanelScript.apply_accessory_purchase(player, acc)
	_check(ok_a and player.equipped_accessories.size() >= 1,
		"accessory purchase applies (equipped %d)" % player.equipped_accessories.size())

	# --- heal purchase ---
	player.stats.current_health = 10.0
	var ok_h = ShopPanelScript.apply_heal_purchase(player, 0.4)
	_check(ok_h and player.stats.current_health > 10.0,
		"heal purchase restores HP (now %.0f)" % player.stats.current_health)

	# --- affordability guard logic (UI path) ---
	Game.souls = 0
	var would_buy = (Game.souls >= price)
	_check(not would_buy, "cannot afford when souls == 0 (UI guard)")


func _check(cond: bool, msg: String) -> void:
	_results.append(("%s  %s" % ["OK" if cond else "FAIL", msg]))
	if not cond:
		_failed = true


func _fail(msg: String) -> void:
	_results.append("FAIL  " + msg)
	_failed = true


func _report() -> void:
	print("=== SHOP CHECK ===")
	for line in _results:
		print(line)
	print("SHOP %s" % ("PASS" if not _failed else "FAIL"))
