class_name ZombieMechaMutant
extends ZombieBase

var _fire_cd: float = 0.0


func _ready() -> void:
	zombie_type = GameEnums.ZombieType.MECHA_MUTANT
	super._ready()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_fire_cd -= delta
	if _fire_cd <= 0.0:
		fire()
		_fire_cd = 2.5


func fire() -> void:
	"""Mecha mutants shoot at the player from range."""
	var target = get_tree().get_first_node_in_group("player") as Player
	if target == null:
		return
	var proj = preload("res://scripts/projectiles/projectile_base.gd").new()
	proj.direction = (target.global_position - global_position).normalized()
	proj.speed = 350.0
	proj.damage = current_damage * 0.5
	proj.range = 500.0
	proj.global_position = global_position
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(proj)
