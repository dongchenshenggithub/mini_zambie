## Weapon & companion inventory panel — opened with B (the "open_inventory"
## action). Pauses the game while open (Brotato-style) and lets the player
## DROP unwanted weapons to free a slot and DISMISS companions. This is the
## manual "swap weapons" surface: pickups still auto-equip (and prefer keeping
## a melee weapon), but here the player chooses exactly what to remove so a
## later drop can take its place.
extends Control

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

var _player: Player = null
var _fm = null
var _root: VBoxContainer = null
var _opened_at: int = 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(1280, 720)

	var tex = PixelLoader.load_texture("res://assets/pixel/menu_bg.png")
	if tex != null:
		var bg := TextureRect.new()
		bg.name = "BG"
		bg.texture = tex
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	move_child(dim, 1)

	_root = VBoxContainer.new()
	_root.name = "Content"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.offset_left = 48.0
	_root.offset_top = 28.0
	_root.offset_right = -48.0
	_root.offset_bottom = -28.0
	_root.add_theme_constant_override("separation", 14)
	add_child(_root)


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	var gs = get_tree().current_scene
	if gs != null and gs.has_method("get") and gs.get("follower_manager") != null:
		_fm = gs.get("follower_manager")
	_opened_at = Time.get_ticks_msec()
	_build()


func _build() -> void:
	for c in _root.get_children():
		c.queue_free()

	_add_title()
	_build_weapons()
	_build_companions()
	_add_footer()


func _rebuild() -> void:
	_build()


func _add_title() -> void:
	var name_txt := "角色"
	if _player and _player.character_data:
		name_txt = _player.character_data.name
	var title := Label.new()
	title.text = "武器背包 · %s" % name_txt
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	_root.add_child(title)

	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var slots := 0
	var maxw := 0
	if _player and _player.inventory:
		slots = _player.inventory.weapons.size()
		maxw = _player.inventory.max_weapons
	var foll := 0
	var maxf := 0
	if _fm != null:
		foll = _fm.get_current_count()
		maxf = _fm.get_max_count()
	sub.text = "武器槽 %d/%d    |    护卫 %d/%d    |    按 B 丢弃武器 / 解散护卫" % [slots, maxw, foll, maxf]
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	_root.add_child(sub)


func _build_weapons() -> void:
	_add_heading("武器（点击「丢弃」腾出武器槽）")
	if _player == null or _player.inventory == null or _player.inventory.weapons.is_empty():
		_add_row("（当前没有武器）", "")
		return
	var idx_local := 0
	for wobj in _player.inventory.weapons:
		var w = wobj
		if w == null:
			idx_local += 1
			continue
		var mode := "自动" if w.fire_mode == GameEnums.FireMode.AUTO else "单发"
		var atk := _attack_type_name(w.attack_type)
		var info := "%s  ·  %s  ·  %s  ·  伤害 %.0f" % [w.weapon_name, atk, mode, w.damage]
		if w.is_companion:
			info += "  ·  [护卫·占武器槽]"
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var lab := Label.new()
		lab.text = "槽 %d" % (idx_local + 1)
		lab.custom_minimum_size = Vector2(44, 0)
		lab.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7, 1.0))
		row.add_child(lab)
		var val := Label.new()
		val.text = info
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(val)
		var btn := Button.new()
		btn.text = "丢弃"
		btn.custom_minimum_size = Vector2(90, 34)
		btn.pressed.connect(_on_drop_weapon.bind(idx_local))
		row.add_child(btn)
		_root.add_child(row)
		idx_local += 1


func _build_companions() -> void:
	_add_heading("护卫（点击「解散」释放护卫栏）")
	if _fm == null:
		_add_row("（护卫系统不可用）", "")
		return
	var units: Array = _fm.get_current_units()
	if units.is_empty():
		_add_row("（暂无护卫；拾取绿色爪印掉落可获得）", "")
		return
	for idx in range(units.size()):
		var u = units[idx]
		var style: String = "近战护卫" if (u.has_method("get") and u.get("attack_style") == 1) else "远程护卫"
		var info := "护卫 #%d  ·  %s" % [idx + 1, style]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var lab := Label.new()
		lab.text = info
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lab)
		var btn := Button.new()
		btn.text = "解散"
		btn.custom_minimum_size = Vector2(90, 34)
		btn.pressed.connect(_on_dismiss.bind(u))
		row.add_child(btn)
		_root.add_child(row)


func _on_drop_weapon(index: int) -> void:
	if _player == null or _player.inventory == null:
		return
	_player.inventory.remove_weapon(index)
	_rebuild()


func _on_dismiss(unit: Node2D) -> void:
	if unit == null:
		return
	# Weapon-bound companions (non-Cat-Cafe) live inside a weapon slot: dismissing
	# the unit means dropping that weapon, which frees the slot and (via the
	# weapon's PREDELETE) dismisses the linked follower.
	var cw = null
	if unit.has_method("get"):
		cw = unit.get("companion_weapon")
	if cw != null and _player != null and _player.inventory != null:
		var idx = _player.inventory.weapons.find(cw)
		if idx >= 0:
			_player.inventory.remove_weapon(idx)
			_rebuild()
			return
	# Cat Cafe / no linked weapon: dismiss the unit directly.
	if _fm != null and _fm.has_method("dismiss_unit"):
		_fm.dismiss_unit(unit)
	_rebuild()


func _add_footer() -> void:
	var f := Label.new()
	f.text = "按 B / Esc 关闭面板（游戏已暂停）"
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	_root.add_child(f)

	var btn := Button.new()
	btn.text = "关闭"
	btn.size = Vector2(140, 44)
	btn.pressed.connect(_close)
	_root.add_child(btn)


func _add_heading(text: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_root.add_child(spacer)
	var h := Label.new()
	h.text = text
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0, 1.0))
	_root.add_child(h)


func _add_row(label: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var lab := Label.new()
	lab.text = label
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	if value != "":
		var val := Label.new()
		val.text = value
		row.add_child(val)
	_root.add_child(row)


func _attack_type_name(atk: int) -> String:
	match atk:
		GameEnums.AttackType.RANGED: return "远程"
		GameEnums.AttackType.MELEE: return "近战"
		GameEnums.AttackType.SUMMON: return "召唤"
		_: return "其他"


func _unhandled_input(event: InputEvent) -> void:
	if _opened_at > 0 and (Time.get_ticks_msec() - _opened_at) < 150:
		return
	if event.is_action_pressed("open_inventory") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if get_tree():
		get_tree().paused = false
	queue_free()
