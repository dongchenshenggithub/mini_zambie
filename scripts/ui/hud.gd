## Main HUD — displays health, XP, score, wave, and inventory.
class_name HUD
extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/VBoxContainer/HealthBar
@onready var xp_bar: ProgressBar = $Control/VBoxContainer/XPBar
@onready var score_label: Label = $Control/VBoxContainer/ScoreLabel
@onready var wave_label: Label = $Control/VBoxContainer/WaveLabel
@onready var level_label: Label = $Control/VBoxContainer/LevelLabel
@onready var durability_label: Label = $Control/VBoxContainer/DurabilityLabel


func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if player:
		if health_bar:
			health_bar.value = player.stats.current_health
			health_bar.max_value = player.stats.max_health + (player.stats.limb_health_bonus if player.stats else 0)

	var xp_sys = get_tree().get_first_node_in_group("xp_system") as XPSystem
	if xp_sys and xp_bar:
		xp_bar.value = xp_sys.get_xp_progress()
		xp_bar.max_value = 1.0

	score_label.text = "得分: %d" % Game.score
	wave_label.text = "波次: %d" % Game.current_wave
	level_label.text = "等级: %d" % Game.current_level

	# Show weapon durability
	if player and player.inventory:
		var dur_text := ""
		for w in player.inventory.weapons:
			dur_text += "%s: %.0f%%  " % [w.weapon_name, w.durability]
		durability_label.text = dur_text
