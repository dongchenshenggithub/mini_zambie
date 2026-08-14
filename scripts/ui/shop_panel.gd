## Between-floor shop — Brotato-style overlay shown after a floor is cleared.
## Built entirely in code (mirrors UpgradePanel): a CanvasLayer at layer 100 that
## pauses the tree while open. Spends the run's `souls` currency (earned on kill)
## on weapons, accessories, and a heal.
##
## The purchase *effects* live in static funcs (apply_weapon_purchase / ...)
## so the headless regression test can exercise the real equip/apply paths
## without simulating button input.
extends CanvasLayer
class_name ShopPanel

signal shop_closed

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const WeaponRegistry = preload("res://scripts/systems/weapon_registry.gd")
const AccessoryRegistry = preload("res://scripts/systems/accessory_registry.gd")
const ZE = preload("res://scripts/core/game_enums.gd")

# Tunables (balance lives here).
const WEAPON_COUNT: int = 4
const ACCESSORY_COUNT: int = 3
const HEAL_PRICE: int = 15
const HEAL_PCT: float = 0.4
const REROLL_PRICE: int = 20

var _scene: Node2D = null
var _stock: Array = []
var _soul_label: Label = null
var _grid: GridContainer = null
var _reroll_btn: Button = null


# --------------------------------------------------------------------------- #
# Static purchase logic (also called by the headless test)
# --------------------------------------------------------------------------- #

## Price for a weapon/accessory, derived from its `soul_cost` field scaled by
## rarity (common = base, epic = base * 4). Returns HEAL_PRICE for heal entries.
static func price_for(item) -> int:
	if item == null:
		return HEAL_PRICE
	var base: int = item.soul_cost if (item.get("soul_cost") and item.soul_cost > 0) else 5
	var rarity: int = item.get("rarity") if item.get("rarity") != null else 0
	return base * (rarity + 1)


## Spawns a weapon instance and equips it through the same path as a floor drop
## (so class behaviors like the Mech Monk's "dismantle for HP" still apply).
## Returns true if the purchase took effect (equipped, or consumed for HP).
static func apply_weapon_purchase(player: Player, data: Variant) -> bool:
	if player == null or data == null:
		return false
	var weapon = WeaponRegistry.spawn_instance(data)
	if weapon == null:
		return false
	# Route through the class behavior so quirks stay consistent (Monk dismantles,
	# Cultivator may refuse non-melee, etc.).
	if player.behavior and player.behavior.has_method("on_weapon_pickup"):
		player.behavior.on_weapon_pickup(weapon)
	if not is_instance_valid(weapon):
		return true  # behavior consumed it (e.g. Monk +HP) — still a valid buy
	var ok = player.inventory.equip_weapon(weapon)
	if not ok:
		weapon.queue_free()
		return false
	return true


## Applies an accessory's stat bonuses the same way a floor pickup does: bonuses
## accumulate on the player's stats and character_data, and the piece is tracked
## so recompute_combat_stats re-applies them every level-up.
static func apply_accessory_purchase(player: Player, data: Variant) -> bool:
	if player == null or data == null:
		return false
	var cd = player.character_data
	if cd == null:
		return false
	cd.strength += data.strength_bonus
	cd.agility += data.agility_bonus
	cd.intelligence += data.intelligence_bonus
	cd.constitution += data.constitution_bonus
	cd.luck += data.luck_bonus
	cd.willpower += data.willpower_bonus
	var s = player.stats
	s.max_health += data.health_bonus
	player.heal(data.health_bonus)
	s.accessory_armor_bonus += data.armor_bonus
	s.accessory_speed_bonus += data.speed_bonus
	s.accessory_ranged_mult += data.ranged_damage_mult
	s.accessory_melee_mult += data.melee_damage_mult
	s.accessory_laser_mult += data.laser_damage_mult
	s.accessory_summon_mult += data.summon_damage_mult
	s.accessory_spray_mult += data.spray_damage_mult
	s.accessory_crit_bonus += data.crit_chance_bonus
	player.recompute_combat_stats()
	if player.equipped_accessories != null:
		player.equipped_accessories.append(data)
	return true


## Heals the player by `pct` of max health. Returns false if already dead.
static func apply_heal_purchase(player: Player, pct: float) -> bool:
	if player == null or not player.stats.is_alive():
		return false
	player.heal(player.stats.max_health * pct)
	return true


## Builds a fresh random stock list. Each entry is a Dictionary understood by
## both the UI (`_build_card`) and the purchase funcs.
static func roll_stock() -> Array:
	var stock: Array = []
	var weapons = WeaponRegistry.get_all().filter(
		func(w): return w != null and w.weapon_path != "" and ResourceLoader.exists(w.weapon_path))
	var accessories = AccessoryRegistry.get_all().filter(func(a): return a != null)
	for w in _pick_random(weapons, WEAPON_COUNT):
		stock.append({
			"kind": "weapon",
			"data": w,
			"name": w.name,
			"price": price_for(w),
			"icon": _weapon_icon_path(w.category),
			"desc": _weapon_desc(w),
			"sold": false,
		})
	for a in _pick_random(accessories, ACCESSORY_COUNT):
		stock.append({
			"kind": "accessory",
			"data": a,
			"name": a.name,
			"price": price_for(a),
			"icon": "res://assets/pixel/item_accessory.png",
			"desc": _accessory_desc(a),
			"sold": false,
		})
	stock.append({
		"kind": "heal",
		"data": null,
		"name": "治疗",
		"price": HEAL_PRICE,
		"icon": "res://assets/pixel/item_potion.png",
		"desc": "恢复 %.0f%% 生命" % (HEAL_PCT * 100.0),
		"sold": false,
	})
	return stock


static func _pick_random(items: Array, n: int) -> Array:
	if items.is_empty():
		return []
	var pool: Array = items.duplicate()
	# Fisher-Yates shuffle
	for i in range(pool.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	return pool.slice(0, mini(n, pool.size()))


static func _weapon_desc(w: Variant) -> String:
	var cat_name: String = ZE.WeaponCategory.find_key(w.category) if ZE.WeaponCategory.has(w.category) else "武器"
	var txt := "伤害 %d · %s" % [int(w.damage), cat_name]
	if w.magazine_size > 0:
		txt += " · 弹匣 %d" % w.magazine_size
	else:
		txt += " · 无限弹"
	return txt


static func _accessory_desc(a: Variant) -> String:
	var parts: Array[String] = []
	if a.health_bonus != 0.0: parts.append("生命+%d" % int(a.health_bonus))
	if a.ranged_damage_mult != 0.0: parts.append("远程+%.0f%%" % (a.ranged_damage_mult * 100.0))
	if a.melee_damage_mult != 0.0: parts.append("近战+%.0f%%" % (a.melee_damage_mult * 100.0))
	if a.armor_bonus != 0: parts.append("护甲+%d" % a.armor_bonus)
	if a.speed_bonus != 0.0: parts.append("移速+%.0f" % a.speed_bonus)
	if a.crit_chance_bonus != 0.0: parts.append("暴击+%.0f%%" % (a.crit_chance_bonus * 100.0))
	if a.strength_bonus != 0: parts.append("力量+%d" % a.strength_bonus)
	if a.agility_bonus != 0: parts.append("敏捷+%d" % a.agility_bonus)
	if parts.is_empty():
		parts.append("属性加成")
	return " · ".join(parts)


static func _weapon_icon_path(cat: int) -> String:
	match cat:
		ZE.WeaponCategory.LIGHT_RANGED: return "res://assets/pixel/weapon_rifle.png"
		ZE.WeaponCategory.HEAVY_RANGED: return "res://assets/pixel/weapon_heavy_ranged.png"
		ZE.WeaponCategory.MELEE_SHARP: return "res://assets/pixel/weapon_blade.png"
		ZE.WeaponCategory.MELEE_BLUNT: return "res://assets/pixel/weapon_blunt.png"
		ZE.WeaponCategory.HEAVY_MELEE_BLUNT: return "res://assets/pixel/weapon_heavy_blunt.png"
		ZE.WeaponCategory.LIGHT_LASER: return "res://assets/pixel/weapon_laser.png"
		ZE.WeaponCategory.HEAVY_LASER: return "res://assets/pixel/weapon_heavy_laser.png"
		ZE.WeaponCategory.THROWABLE: return "res://assets/pixel/weapon_throw.png"
		ZE.WeaponCategory.EXPLOSIVE: return "res://assets/pixel/weapon_explosive.png"
		ZE.WeaponCategory.SUMMON: return "res://assets/pixel/weapon_summon.png"
		ZE.WeaponCategory.SPRAY_EFFECT: return "res://assets/pixel/weapon_spray.png"
		_: return "res://assets/pixel/weapon_icon.png"


# --------------------------------------------------------------------------- #
# UI
# --------------------------------------------------------------------------- #

func setup(scene: Node2D) -> void:
	_scene = scene


func show_shop() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(880, 560)
	center.add_child(panel)
	var panel_tw := create_tween()
	panel_tw.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.2)
	panel.modulate = Color(1, 1, 1, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "商店 — 花费灵魂强化你的构筑"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	_soul_label = Label.new()
	_soul_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_soul_label.add_theme_font_size_override("font_size", 18)
	_soul_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0, 1.0))
	vbox.add_child(_soul_label)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(_grid)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	_reroll_btn = Button.new()
	_reroll_btn.text = "刷新库存 (花费 %d 灵魂)" % REROLL_PRICE
	_reroll_btn.pressed.connect(_on_reroll)
	btn_row.add_child(_reroll_btn)

	var leave_btn := Button.new()
	leave_btn.text = "离开 / 进入下一层"
	leave_btn.pressed.connect(_close)
	btn_row.add_child(leave_btn)

	_refresh_stock()
	_update_souls()
	get_tree().paused = true
	# Fire the scaffolded signal so other systems can react to shop opens.
	if Game._instance != null and Game._instance.has_signal("shop_opened"):
		Game._instance.shop_opened.emit()


func _refresh_stock() -> void:
	_stock = roll_stock()
	for c in _grid.get_children():
		c.queue_free()
	for entry in _stock:
		_grid.add_child(_build_card(entry))


func _build_card(entry: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.2, 0.95)
	sb.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var icon := TextureRect.new()
	var tex = PixelLoader.load_texture(entry.icon)
	if tex != null:
		icon.texture = tex
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon)

	var name_l := Label.new()
	name_l.text = entry.name
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 15)
	vbox.add_child(name_l)

	var desc_l := Label.new()
	desc_l.text = entry.desc
	desc_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_l.add_theme_font_size_override("font_size", 11)
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_l)

	var price_l := Label.new()
	price_l.text = "灵魂: %d" % entry.price
	price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_l.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0, 1.0))
	vbox.add_child(price_l)

	var buy_btn := Button.new()
	buy_btn.text = "购买"
	buy_btn.pressed.connect(_on_buy.bind(entry, buy_btn))
	vbox.add_child(buy_btn)
	entry["_btn"] = buy_btn
	return card


func _on_buy(entry: Dictionary, btn: Button) -> void:
	if entry.sold:
		return
	var player = get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	if Game.souls < entry.price:
		_toast("灵魂不足")
		return
	var ok := false
	match entry.kind:
		"weapon":
			ok = apply_weapon_purchase(player, entry.data)
		"accessory":
			ok = apply_accessory_purchase(player, entry.data)
		"heal":
			ok = apply_heal_purchase(player, HEAL_PCT)
	if not ok:
		_toast("无法购买")
		return
	Game.souls -= entry.price
	entry.sold = true
	btn.text = "已购买"
	btn.disabled = true
	_update_souls()
	_toast("已购买：%s" % entry.name)


func _on_reroll() -> void:
	if Game.souls < REROLL_PRICE:
		_toast("灵魂不足，无法刷新")
		return
	Game.souls -= REROLL_PRICE
	_refresh_stock()
	_update_souls()


func _update_souls() -> void:
	if _soul_label != null:
		_soul_label.text = "灵魂: %d" % Game.souls


func _close() -> void:
	get_tree().paused = false
	shop_closed.emit()
	queue_free()


func _toast(text: String) -> void:
	var h = get_tree().get_first_node_in_group("hud") as CanvasLayer
	if h and h.has_method("show_toast"):
		h.show_toast(text)
