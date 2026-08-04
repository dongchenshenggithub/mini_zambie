## Character / inventory status panel — opened with I or C (the "status" action).
## Pauses the game while open (Brotato-style) and shows the equipped weapons,
## prosthetics (limbs), accessories, and the derived character stats.
class_name CharacterPanel
extends Control

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")
const AccessoryDataScript = preload("res://scripts/accessory_data.gd")

var _player: Player = null
var _opened_at: int = 0


func _init() -> void:
	# Keep processing while the tree is paused so we can catch the close key.
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(1280, 720)

	# IMPORTANT: never set `modulate` to black here. A black modulate multiplies
	# the WHOLE panel subtree (text, icons, the close button) by black, making
	# the entire UI invisible — the screen just goes dark and looks frozen.
	# Dim the background with a SEPARATE ColorRect behind the content instead.
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


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	_opened_at = Time.get_ticks_msec()
	_build()


func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 48.0
	root.offset_top = 28.0
	root.offset_right = -48.0
	root.offset_bottom = -28.0
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	_add_title(root)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 48)
	root.add_child(cols)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	cols.add_child(left)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	cols.add_child(right)

	_build_equipped(left)
	_build_stats(right)

	_add_footer(root)


func _add_title(root: VBoxContainer) -> void:
	var name_txt := "角色"
	if _player and _player.character_data:
		name_txt = _player.character_data.name
	var title := Label.new()
	title.text = "角色状态 · %s" % name_txt
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	root.add_child(title)

	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var lvl_txt := "等级 %d" % Game.current_level
	var floor_txt := "楼层 %d" % Game.current_floor
	var score_txt := "得分 %d" % Game.score
	sub.text = "%s    |    %s    |    %s" % [lvl_txt, floor_txt, score_txt]
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	root.add_child(sub)


## Left column: equipped weapons / prosthetics / accessories.
func _build_equipped(parent: VBoxContainer) -> void:
	_add_heading(parent, "已装备")

	_add_subheading(parent, "武器")
	if _player and _player.inventory:
		var weapons = _player.inventory.weapons
		if weapons.is_empty():
			_add_row(parent, "（无武器）", "")
		for i in range(weapons.size()):
			var w := weapons[i] as WeaponBase
			var icon := _weapon_icon(w.weapon_category)
			var mode := "自动" if w.fire_mode == GameEnums.FireMode.AUTO else "单发"
			var ammo := "无限弹" if w.magazine_size <= 0 else ("%d/%d" % [w.current_ammo, w.magazine_size])
			var txt := "%s   ·   %s   ·   %s   ·   耐久 %.0f%%" % [w.weapon_name, mode, ammo, w.durability]
			_add_row(parent, "槽 %d" % (i + 1), txt, icon)
	else:
		_add_row(parent, "（无）", "")

	_add_subheading(parent, "义肢")
	if _player and _player.prosthetic_manager:
		var pm = _player.prosthetic_manager
		var labels := ["头部", "身体", "左臂", "右臂", "左腿", "右腿"]
		for s in range(6):
			var limb = pm.get_limb(s)
			var val := "空"
			if limb != null:
				val = limb.slot_name
			_add_row(parent, labels[s], val)
	else:
		_add_row(parent, "（无可用槽位）", "")

	_add_subheading(parent, "装备（配件）")
	if _player and not _player.equipped_accessories.is_empty():
		for acc in _player.equipped_accessories:
			var a := acc as AccessoryDataScript
			if a == null:
				continue
			_add_row(parent, "· " + a.name, _rarity_tag(a.rarity), null, _rarity_color(a.rarity))
	else:
		_add_row(parent, "（暂无；拾取的配件会转化为属性加成）", "")


## Right column: derived combat stats + base attributes.
func _build_stats(parent: VBoxContainer) -> void:
	_add_heading(parent, "角色属性")
	if _player == null or _player.stats == null:
		return
	var s = _player.stats
	var max_hp: float = s.max_health + s.limb_health_bonus
	_add_row(parent, "生命", "%d / %d" % [int(ceil(s.current_health)), int(max_hp)])
	_add_row(parent, "移动速度", "%.0f" % s.get_movement_speed())
	_add_row(parent, "护甲", "%d" % (s.armor + s.limb_armor_bonus))
	_add_row(parent, "暴击率", "%.0f%%" % (s.get_crit_bonus() * 100.0))
	_add_row(parent, "远程伤害", "×%.2f" % s.damage_multiplier_ranged)
	_add_row(parent, "近战伤害", "×%.2f" % s.damage_multiplier_melee)
	_add_row(parent, "自愈 / 秒", "%.1f" % s.self_heal_rate)

	_add_subheading(parent, "基础属性")
	var cd = _player.character_data
	if cd != null:
		_add_row(parent, "力量 (STR)", "%d" % cd.strength)
		_add_row(parent, "敏捷 (AGI)", "%d" % cd.agility)
		_add_row(parent, "智力 (INT)", "%d" % cd.intelligence)
		_add_row(parent, "体质 (CON)", "%d" % cd.constitution)
		_add_row(parent, "幸运 (LUK)", "%d" % cd.luck)
		_add_row(parent, "意志 (WIL)", "%d" % cd.willpower)


func _add_footer(parent: VBoxContainer) -> void:
	var f := Label.new()
	f.text = "按 I / C / Esc 关闭面板（游戏已暂停）"
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	parent.add_child(f)

	var btn := Button.new()
	btn.text = "关闭"
	btn.size = Vector2(140, 44)
	btn.pressed.connect(_close)
	parent.add_child(btn)


func _add_heading(parent: VBoxContainer, text: String) -> void:
	var h := Label.new()
	h.text = text
	h.add_theme_font_size_override("font_size", 22)
	h.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0, 1.0))
	parent.add_child(h)


func _add_subheading(parent: VBoxContainer, text: String) -> void:
	var h := Label.new()
	h.text = text
	h.add_theme_font_size_override("font_size", 16)
	h.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	parent.add_child(h)


func _add_row(parent: VBoxContainer, label: String, value: String, icon: Texture2D = null, color: Color = Color(1, 1, 1, 1)) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	if icon != null:
		var tr := TextureRect.new()
		tr.texture = icon
		tr.custom_minimum_size = Vector2(20, 20)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(tr)
	var lab := Label.new()
	lab.text = label
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.add_theme_color_override("font_color", color)
	row.add_child(lab)
	if value != "":
		var val := Label.new()
		val.text = value
		val.add_theme_color_override("font_color", color)
		row.add_child(val)
	parent.add_child(row)


func _weapon_icon(cat: int) -> Texture2D:
	return PixelLoader.load_texture(_weapon_icon_path(cat))


func _weapon_icon_path(cat: int) -> String:
	match cat:
		GameEnums.WeaponCategory.LIGHT_RANGED: return "res://assets/pixel/weapon_rifle.png"
		GameEnums.WeaponCategory.HEAVY_RANGED: return "res://assets/pixel/weapon_heavy_ranged.png"
		GameEnums.WeaponCategory.MELEE_SHARP: return "res://assets/pixel/weapon_blade.png"
		GameEnums.WeaponCategory.MELEE_BLUNT: return "res://assets/pixel/weapon_blunt.png"
		GameEnums.WeaponCategory.HEAVY_MELEE_BLUNT: return "res://assets/pixel/weapon_heavy_blunt.png"
		GameEnums.WeaponCategory.LIGHT_LASER: return "res://assets/pixel/weapon_laser.png"
		GameEnums.WeaponCategory.HEAVY_LASER: return "res://assets/pixel/weapon_heavy_laser.png"
		GameEnums.WeaponCategory.THROWABLE: return "res://assets/pixel/weapon_throw.png"
		GameEnums.WeaponCategory.EXPLOSIVE: return "res://assets/pixel/weapon_explosive.png"
		GameEnums.WeaponCategory.SUMMON: return "res://assets/pixel/weapon_summon.png"
		GameEnums.WeaponCategory.SPRAY_EFFECT: return "res://assets/pixel/weapon_spray.png"
		_: return "res://assets/pixel/weapon_icon.png"


func _rarity_tag(r: int) -> String:
	match r:
		1: return "（精良）"
		2: return "（稀有）"
		3: return "（史诗）"
		_: return "（普通）"


func _rarity_color(r: int) -> Color:
	match r:
		1: return Color(1.0, 0.9, 0.5, 1.0)
		2: return Color(0.6, 0.8, 1.0, 1.0)
		3: return Color(1.0, 0.6, 1.0, 1.0)
		_: return Color(1.0, 1.0, 1.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	# Ignore the exact keypress that just opened the panel (and any echo within
	# ~150 ms) so it can't immediately close itself and look like a no-op.
	if _opened_at > 0 and (Time.get_ticks_msec() - _opened_at) < 150:
		return
	if event.is_action_pressed("status") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if get_tree():
		get_tree().paused = false
	queue_free()
