## Base projectile — moves forward and damages zombies on collision.
class_name ProjectileBase
extends Area2D

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 500.0
@export var damage: float = 10.0
@export var range: float = 300.0
@export var pierce: int = 0
@export var splash_radius: float = 0.0
@export var effect: GameEnums.StatusEffect = GameEnums.StatusEffect.NONE
@export var effect_duration: float = 0.0

var _distance_traveled: float = 0.0
var _hits: int = 0


func _ready() -> void:
	connect("body_entered", _on_body_entered)
	_setup_visuals()
	_setup_collision()


## A bullet must carry a collision shape or Area2D.body_entered never fires,
## so shots pass straight through zombies. Default layer/mask (1/1) already
## overlaps the zombie's, so no layer remap is needed — just the shape.
func _setup_collision() -> void:
	var hitbox := CollisionShape2D.new()
	hitbox.name = "Hitbox"
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	hitbox.shape = shape
	add_child(hitbox)


func _setup_visuals() -> void:
	var tex = PixelLoader.load_texture("res://assets/pixel/bullet.png")
	if tex == null:
		return
	# Bright glow halo so the projectile's flight path is easy to see.
	var glow = Sprite2D.new()
	glow.texture = tex
	glow.name = "Glow"
	glow.modulate = Color(1.0, 0.85, 0.3, 0.55)
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.name = "Visual"
	# Larger than the raw 10px sprite so it reads clearly while moving fast.
	var target := 18.0
	var s := Vector2(target / tex.get_width(), target / tex.get_height())
	spr.scale = s
	glow.scale = s * 2.2
	add_child(glow)
	add_child(spr)


func _process(delta: float) -> void:
	var move_amount = speed * delta
	_distance_traveled += move_amount
	if _distance_traveled > range:
		queue_free()
		return
	position += direction * move_amount


func _on_body_entered(body: Node2D) -> void:
	if body is ZombieBase:
		var zombie = body as ZombieBase
		zombie.take_damage(damage)
		zombie.flash_hit()
		_spawn_hit_effect(zombie.global_position)
		SfxManager.play("hit")
		if effect != GameEnums.StatusEffect.NONE:
			zombie.apply_status(effect, effect_duration)
		if splash_radius > 0:
			_apply_splash(zombie.global_position)
		_hits += 1
		if _hits > pierce:
			queue_free()


## Brief impact spark so the player can clearly see shots connecting.
## A small bright sprite that scales up and fades, then frees itself.
func _spawn_hit_effect(at: Vector2) -> void:
	var spark := Sprite2D.new()
	spark.texture = PixelLoader.load_texture("res://assets/pixel/bullet.png")
	spark.global_position = at
	spark.modulate = Color(1.0, 0.95, 0.6, 1.0)
	spark.scale = Vector2(0.4, 0.4)
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(spark)
	else:
		add_child(spark)
	var tw := create_tween()
	tw.tween_property(spark, "scale", Vector2(1.4, 1.4), 0.12)
	tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.14)
	tw.tween_callback(spark.queue_free)


func _apply_splash(center: Vector2) -> void:
	for zombie in get_tree().get_nodes_in_group("zombie"):
		var z = zombie as ZombieBase
		if z and z.global_position.distance_to(center) <= splash_radius:
			z.take_damage(damage * 0.5)
