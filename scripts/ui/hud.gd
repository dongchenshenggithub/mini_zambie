## Main HUD — Brotato-style layout: HP/XP/info top-left, weapons bottom-center.
class_name HUD
extends CanvasLayer

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

@onready var health_bar: ProgressBar = $Control/TopLeft/HealthBar
@onready var health_text: Label = $Control/TopLeft/HealthBar/HealthText
@onready var xp_bar: ProgressBar = $Control/TopLeft/XPBar
@onready var score_label: Label = $Control/TopLeft/ScoreLabel
@onready var wave_label: Label = $Control/TopLeft/WaveLabel
@onready var level_label: Label = $Control/TopLeft/LevelLabel
@onready var bottom_bar: HBoxContainer = $Control/BottomBar
@onready var durability_label: Label = $Control/BottomBar/DurabilityLabel

var _toast_label: Label = null
var _toast_timer: float = 0.0
var _weapon_icons: HBoxContainer = null
var _last_weapon_sig: String = ""
var _floor_timer_label: Label = null


func _ready() -> void:
	add_to_group("hud")
	_apply_bar_style(health_bar, Color(0.78, 0.16, 0.16, 1.0), Color(0.12, 0.06, 0.06, 0.85))
	_apply_bar_style(xp_bar, Color(0.2, 0.7, 0.95, 1.0), Color(0.06, 0.12, 0.16, 0.85))

	_toast_label = Label.new()
	_toast_label.name = "ToastLabel"
	_toast_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.offset_top = 64.0  # sit just under the top edge
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6, 1.0))
	_toast_label.add_theme_font_size_override("font_size", 18)
	_toast_label.visible = false
	add_child(_toast_label)

	# Weapon icon chip, docked in the bottom-center bar.
	var panel := PanelContainer.new()
	panel.name = "WeaponPanel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.45)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	_weapon_icons = HBoxContainer.new()
	_weapon_icons.add_theme_constant_override("separation", 6)
	panel.add_child(_weapon_icons)
	if bottom_bar:
		bottom_bar.add_child(panel)

	# Top-center survive-timer (survive-mode floors) / BOSS banner.
	_floor_timer_label = Label.new()
	_floor_timer_label.name = "FloorTimerLabel"
	_floor_timer_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_floor_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_floor_timer_label.offset_top = 8.0
	_floor_timer_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	_floor_timer_label.add_theme_font_size_override("font_size", 20)
	add_child(_floor_timer_label)


## Briefly show a message near the top-center (used for pickups, etc.).
func show_toast(text: String) -> void:
	if _toast_label == null:
		return
	_toast_label.text = text
	_toast_label.visible = true
	_toast_timer = 2.5


func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player:
		var cur = player.stats.current_health
		var max_hp = player.stats.max_health + (player.stats.limb_health_bonus if player.stats else 0)
		if health_bar:
			health_bar.value = cur
			health_bar.max_value = max_hp
		if health_text:
			health_text.text = "%d / %d" % [int(ceil(cur)), int(max_hp)]

	var xp_sys = get_tree().get_first_node_in_group("xp_system") as XPSystem
	if xp_sys and xp_bar:
		xp_bar.value = xp_sys.get_xp_progress()
		xp_bar.max_value = 1.0

	if score_label:
		score_label.text = "得分: %d" % Game.score
	if wave_label:
		wave_label.text = "波次: %d" % Game.current_wave
	if level_label:
		level_label.text = "等级: %d" % Game.current_level

	if _floor_timer_label:
		if get_tree().get_nodes_in_group("boss").size() > 0:
			_floor_timer_label.text = "BOSS 战 — 击败它！"
		else:
			var ws = get_tree().get_first_node_in_group("wave_spawner") as WaveSpawner
			if ws:
				_floor_timer_label.text = "存活时间: %.0f s" % ws.get_time_remaining()

	if player and player.inventory:
		var dur_text := ""
		for w in player.inventory.weapons:
			dur_text += "%s " % w.weapon_name
			if w.magazine_size > 0:
				if w.is_reloading:
					dur_text += "[换弹中] "
				else:
					dur_text += "%d/%d " % [w.current_ammo, w.magazine_size]
			dur_text += "%.0f%%\n" % w.durability
		durability_label.text = dur_text.strip_edges()

	_refresh_weapon_icons(player)

	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _toast_label:
			_toast_label.visible = false


func _apply_bar_style(bar: ProgressBar, fill_color: Color, bg_color: Color) -> void:
	if bar == null:
		return
	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_color
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


## Rebuilds the weapon-icon row only when the equipped set changes.
func _refresh_weapon_icons(player: Player) -> void:
	if _weapon_icons == null or player == null or player.inventory == null:
		return
	var sig := ""
	for w in player.inventory.weapons:
		sig += str(w.weapon_category) + ","
	if sig == _last_weapon_sig:
		return
	_last_weapon_sig = sig
	for c in _weapon_icons.get_children():
		c.queue_free()
	for w in player.inventory.weapons:
		var tex = PixelLoader.load_texture(_weapon_icon_path(w.weapon_category))
		if tex == null:
			continue
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(28, 28)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		_weapon_icons.add_child(tr)


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
