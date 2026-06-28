## Character selection screen — loads characters from registry.
class_name CharacterSelect
extends Control

@onready var buttons_container: VBoxContainer = $VBoxContainer/ButtonContainer
@onready var char_name_label: Label = $VBoxContainer/CharNameLabel
@onready var char_desc_label: Label = $VBoxContainer/CharDescLabel
@onready var char_stats_label: Label = $VBoxContainer/CharStatsLabel
@onready var back_btn: Button = $VBoxContainer/BackButton

var selected_character: CharacterEntry = null


func _ready() -> void:
	CharacterRegistry.init()
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	_build_buttons()
	var all = CharacterRegistry.get_all()
	if not all.is_empty():
		_show_character_info(all[0])


func _build_buttons() -> void:
	for char_entry in CharacterRegistry.get_all():
		var btn = Button.new()
		btn.text = "%s - %s" % [char_entry.name, char_entry.description.left(30)]
		btn.pressed.connect(func(): _on_select(char_entry))
		buttons_container.add_child(btn)


func _on_select(char_entry: CharacterEntry) -> void:
	selected_character = char_entry
	_start_game(char_entry)


func _show_character_info(cd: CharacterEntry) -> void:
	char_name_label.text = cd.name
	char_desc_label.text = cd.description
	var limb_text = "无"
	if cd.character_class == 1:
		limb_text = "全部位"
	elif cd.character_class != 5:
		limb_text = "臂/腿"

	char_stats_label.text = "随从: %d/%d | 自愈: %s | 义肢: %s\n力量:%d 敏捷:%d 智力:%d 体质:%d 幸运:%d 意志:%d" % [
		cd.base_followers, cd.max_followers,
		"是" if cd.can_heal_self else "否", limb_text,
		cd.strength, cd.agility, cd.intelligence,
		cd.constitution, cd.luck, cd.willpower
	]


func _start_game(cd: CharacterEntry) -> void:
	Game.selected_character = cd
	Game.player_build_direction = cd.build_direction
	get_tree().change_scene_to_file("res://scenes/gameplay/game_scene.tscn")
