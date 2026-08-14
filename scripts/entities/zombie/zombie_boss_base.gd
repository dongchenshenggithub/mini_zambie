## Boss base — handles phase transitions and special attacks.
class_name ZombieBoss
extends ZombieBase

var current_phase: int = 1
var phase_thresholds: Array[float] = [0.7, 0.3]  # HP thresholds for phase changes
var _special_attack_timer: float = 0.0
var _special_attack_rate: float = 3.0

## Emitted when this boss dies, so the scene can trigger victory.
signal boss_defeated


func _ready() -> void:
	add_to_group("boss")
	_configure_type()
	current_health = base_health
	current_speed = base_speed
	current_damage = base_damage
	_setup_visuals()


func _setup_visuals() -> void:
	var spr = Sprite2D.new()
	spr.texture = PixelLoader.load_texture(_get_boss_texture_path())
	spr.name = "Visual"
	if spr.texture != null:
		spr.scale = Vector2(1.2, 1.2)
		spr.hframes = ANIM_HFRAMES
		spr.vframes = ANIM_VFRAMES
	_visual_ref = spr
	add_child(spr)
	# Add glow ring (kept as a translucent ColorRect — it's a glow effect, not a sprite)
	var ring = ColorRect.new()
	ring.position = Vector2(-24, -24)
	ring.size = Vector2(48, 48)
	ring.color = Color(1.0, 0.3, 0.0, 0.3)  # Orange glow
	ring.name = "Glow"
	add_child(ring)


func _get_boss_texture_path() -> String:
	match zombie_type:
		GameEnums.ZombieType.BOSS_ZOMBIE_KING: return "res://assets/pixel/boss_king.png"
		GameEnums.ZombieType.BOSS_BIO_TITAN: return "res://assets/pixel/boss_titan.png"
		GameEnums.ZombieType.BOSS_NANO_CORE: return "res://assets/pixel/boss_nano.png"
		GameEnums.ZombieType.BOSS_EXPERIMENT_ALPHA: return "res://assets/pixel/boss_alpha.png"
		_: return "res://assets/pixel/boss_king.png"


func _configure_type() -> void:
	match zombie_type:
		GameEnums.ZombieType.BOSS_ZOMBIE_KING:
			base_health = 2500.0; base_speed = 40.0; base_damage = 100.0; xp_reward = 500
		GameEnums.ZombieType.BOSS_BIO_TITAN:
			base_health = 4000.0; base_speed = 25.0; base_damage = 150.0; xp_reward = 800
		GameEnums.ZombieType.BOSS_NANO_CORE:
			base_health = 3000.0; base_speed = 30.0; base_damage = 120.0; xp_reward = 600
		GameEnums.ZombieType.BOSS_EXPERIMENT_ALPHA:
			base_health = 5000.0; base_speed = 35.0; base_damage = 200.0; xp_reward = 1000


func _physics_process(delta: float) -> void:
	# Check phase transitions
	var hp_ratio = float(current_health) / float(base_health)
	if hp_ratio <= phase_thresholds[current_phase - 1] and current_phase < 3:
		current_phase += 1
		_on_phase_change(current_phase)

	_special_attack_timer -= delta
	if _special_attack_timer <= 0:
		_special_attack()
		_special_attack_timer = _special_attack_rate

	super._physics_process(delta)


func _special_attack() -> void:
	pass


func _on_phase_change(phase: int) -> void:
	pass


func die() -> void:
	boss_defeated.emit()
	super.die()


## Spawns a short-lived, tinted sprite puff at the boss position for cheap
## special-attack feedback (no new art assets required).
func _spawn_puff(puff_color: Color, radius: float) -> void:
	var puff = Sprite2D.new()
	var tex = PixelLoader.load_texture("res://assets/pixel/orb.png")
	if tex != null:
		puff.texture = tex
		puff.scale = Vector2(radius / tex.get_width(), radius / tex.get_height())
	puff.modulate = puff_color
	puff.global_position = global_position
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(puff)
		var tw = create_tween()
		tw.tween_property(puff, "modulate:a", 0.0, 1.2)
		tw.tween_callback(puff.queue_free)
