## Between-floor shop/upgrade panel.
extends CanvasLayer
class_name StorageBoxPanel

signal box_closed

const WeaponRegistry = preload("res://scripts/systems/weapon_registry.gd")
const AccessoryRegistry = preload("res://scripts/systems/accessory_registry.gd")
const StorageBox = preload("res://scripts/systems/storage_box.gd")
const WeaponInventory = preload("res://scripts/entities/player/weapon_inventory.gd")
const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

var _player: Player = null
var _scene_root: Node = null
var _soul_label: Label = null
var _leave_btn: Button = null


func setup(scene: Node2D, player: Player) -> void:
	_scene_root = scene
	_player = player


func show_box() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 0.9)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(900, 600)
	center.add_child(panel)

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
	title.text = "储物箱 — 选择要携带的装备"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	_soul_label = Label.new()
	_soul_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_soul_label.add_theme_font_size_override("font_size", 18)
	_soul_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0, 1.0))
	vbox.add_child(_soul_label)

	_add_section(vbox, "武器")
	_build_weapon_list(vbox)

	_add_section(vbox, "配件")
	_build_accessory_list(vbox)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	_leave_btn = Button.new()
	_leave_btn.text = "离开 / 进入下一层"
	_leave_btn.pressed.connect(_on_leave)
	btn_row.add_child(_leave_btn)

	_refresh_display()
	get_tree().paused = true


func _add_section(parent: Control, title: String) -> void:
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0, 1.0))
	parent.add_child(heading)


func _build_weapon_list(parent: Control) -> void:
	var container := ScrollContainer.new()
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.custom_minimum_size = Vector2(0, 120)
	parent.add_child(container)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(hbox)

	for entry in StorageBox.weapons:
		var data = entry["data"] as WeaponData
		if data == null:
			continue
		var card := _build_weapon_card(data, entry["level"] as int)
		hbox.add_child(card)

	if hbox.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "（暂无武器）"
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		hbox.add_child(empty)


func _build_weapon_card(data: WeaponData, level: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(160, 80)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.2, 0.95)
	sb.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var name_label := Label.new()
	name_label.text = "%s Lv.%d" % [data.name, level]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	var stats_label := Label.new()
	stats_label.text = "伤害 %d · 射速 %.1f" % [int(data.damage), data.fire_rate]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	vbox.add_child(stats_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 4)
	vbox.add_child(btn_row)

	var equip_btn := Button.new()
	equip_btn.text = "装备"
	equip_btn.custom_minimum_size = Vector2(50, 24)
	equip_btn.pressed.connect(_on_equip_weapon.bind(data.id))
	btn_row.add_child(equip_btn)

	var sell_btn := Button.new()
	sell_btn.text = "出售"
	sell_btn.custom_minimum_size = Vector2(50, 24)
	sell_btn.pressed.connect(_on_sell_weapon.bind(data.id))
	btn_row.add_child(sell_btn)

	var upgrade_btn := Button.new()
	upgrade_btn.text = "升级"
	upgrade_btn.custom_minimum_size = Vector2(50, 24)
	upgrade_btn.pressed.connect(_on_upgrade_weapon.bind(data.id, level))
	btn_row.add_child(upgrade_btn)

	return card


func _build_accessory_list(parent: Control) -> void:
	var container := ScrollContainer.new()
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.custom_minimum_size = Vector2(0, 80)
	parent.add_child(container)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(hbox)

	for entry in StorageBox.accessories:
		var data = entry["data"] as AccessoryData
		if data == null:
			continue
		var card := _build_accessory_card(data, entry["level"] as int)
		hbox.add_child(card)

	if hbox.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "（暂无配件）"
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		hbox.add_child(empty)


func _build_accessory_card(data: AccessoryData, level: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(140, 60)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.2, 0.95)
	sb.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	var name_label := Label.new()
	name_label.text = "%s Lv.%d" % [data.name, level]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(name_label)

	var stats_label := Label.new()
	var parts: Array[String] = []
	if data.health_bonus > 0: parts.append("HP+%d" % int(data.health_bonus))
	if data.ranged_damage_mult > 0: parts.append("远程+%d%%" % int(data.ranged_damage_mult * 100))
	if data.melee_damage_mult > 0: parts.append("近战+%d%%" % int(data.melee_damage_mult * 100))
	if data.speed_bonus > 0: parts.append("速度+%d" % int(data.speed_bonus))
	if parts.is_empty():
		parts.append("属性加成")
	stats_label.text = " · ".join(parts)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 9)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	vbox.add_child(stats_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 4)
	vbox.add_child(btn_row)

	var equip_btn := Button.new()
	equip_btn.text = "装备"
	equip_btn.custom_minimum_size = Vector2(45, 20)
	equip_btn.pressed.connect(_on_equip_accessory.bind(data.id))
	btn_row.add_child(equip_btn)

	var sell_btn := Button.new()
	sell_btn.text = "出售"
	sell_btn.custom_minimum_size = Vector2(45, 20)
	sell_btn.pressed.connect(_on_sell_accessory.bind(data.id))
	btn_row.add_child(sell_btn)

	return card


func _refresh_display() -> void:
	if _soul_label != null:
		_soul_label.text = "灵魂: %d" % Game.souls


func _on_equip_weapon(weapon_id: String) -> void:
	if _player == null or _player.inventory == null:
		return
	var data = WeaponRegistry.get_data(weapon_id)
	if data == null:
		return
	var weapon = WeaponRegistry.spawn_instance(data)
	if weapon == null:
		return
	if _player.behavior:
		_player.behavior.on_weapon_pickup(weapon)
	if not is_instance_valid(weapon):
		return
	var ok = _player.inventory.equip_weapon(weapon)
	if ok:
		StorageBox.remove_weapon(weapon_id)
		_toast("装备: %s" % data.name)
		_refresh_display()
	else:
		weapon.queue_free()
		_toast("武器栏已满")
		_refresh_display()


func _on_sell_weapon(weapon_id: String) -> void:
	var data = WeaponRegistry.get_data(weapon_id)
	if data == null:
		return
	var sell_price = data.soul_cost
	Game.souls += sell_price
	StorageBox.remove_weapon(weapon_id)
	_toast("出售 %s 获得 %d 灵魂" % [data.name, sell_price])
	_refresh_display()


func _on_upgrade_weapon(weapon_id: String, current_level: int) -> void:
	var data = WeaponRegistry.get_data(weapon_id)
	if data == null:
		return
	var upgrade_cost = data.soul_cost * current_level
	if Game.souls < upgrade_cost:
		_toast("灵魂不足，需要 %d" % upgrade_cost)
		return
	var inv = _player.inventory
	var upgraded = false
	for i in range(inv.weapons.size()):
		var w = inv.weapons[i]
		if w != null and w.weapon_name == data.name:
			w.apply_upgrade("damage", 0.15)
			w.apply_upgrade("fire_rate", 0.1)
			w.apply_upgrade("crit_chance", 0.02)
			upgraded = true
			break
	if upgraded:
		Game.souls -= upgrade_cost
		_toast("升级 %s +15%%伤害" % data.name)
		_refresh_display()
	else:
		_toast("未装备该武器，无法升级")


func _on_equip_accessory(accessory_id: String) -> void:
	if _player == null:
		return
	var data = AccessoryRegistry.get_data(accessory_id)
	if data == null:
		return
	var cd = _player.character_data
	if cd == null:
		return
	cd.strength += data.strength_bonus
	cd.agility += data.agility_bonus
	cd.intelligence += data.intelligence_bonus
	cd.constitution += data.constitution_bonus
	cd.luck += data.luck_bonus
	cd.willpower += data.willpower_bonus
	var s = _player.stats
	s.max_health += data.health_bonus
	_player.heal(data.health_bonus)
	s.accessory_armor_bonus += data.armor_bonus
	s.accessory_speed_bonus += data.speed_bonus
	s.accessory_ranged_mult += data.ranged_damage_mult
	s.accessory_melee_mult += data.melee_damage_mult
	s.accessory_laser_mult += data.laser_damage_mult
	s.accessory_summon_mult += data.summon_damage_mult
	s.accessory_spray_mult += data.spray_damage_mult
	s.accessory_crit_bonus += data.crit_chance_bonus
	_player.recompute_combat_stats()
	StorageBox.remove_accessory(accessory_id)
	_toast("装备: %s" % data.name)
	_refresh_display()


func _on_sell_accessory(accessory_id: String) -> void:
	var data = AccessoryRegistry.get_data(accessory_id)
	if data == null:
		return
	var sell_price = data.sell_price
	if not data.has("sell_price"):
		sell_price = max(1, int(data.soul_cost / 2))
	Game.souls += sell_price
	StorageBox.remove_accessory(accessory_id)
	_toast("出售 %s 获得 %d 灵魂" % [data.name, sell_price])
	_refresh_display()


func _on_leave() -> void:
	get_tree().paused = false
	box_closed.emit()
	queue_free()


func _toast(text: String) -> void:
	var h = get_tree().get_first_node_in_group("hud") as HUD
	if h and h.has_method("show_toast"):
		h.show_toast(text)
