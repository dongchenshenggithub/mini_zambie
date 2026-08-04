## Soul orb — dropped by zombies, flies toward player.
class_name SoulOrb
extends Area2D

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

var target_player: Player = null
var speed: float = 300.0
var value: int = 1


func _ready() -> void:
	connect("body_entered", _on_body_entered)
	_setup_visuals()
	target_player = get_tree().get_first_node_in_group("player") as Player


func _setup_visuals() -> void:
	var spr = Sprite2D.new()
	spr.texture = PixelLoader.load_texture("res://assets/pixel/orb.png")
	spr.name = "Visual"
	if spr.texture != null:
		var target := 14.0
		spr.scale = Vector2(target / spr.texture.get_width(), target / spr.texture.get_height())
	add_child(spr)


func _physics_process(delta: float) -> void:
	if target_player:
		var dir = (target_player.global_position - global_position).normalized()
		global_position += dir * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var xp_sys = get_tree().get_first_node_in_group("xp_system") as XPSystem
		if xp_sys:
			xp_sys.gain_xp(value * 10)
		queue_free()
