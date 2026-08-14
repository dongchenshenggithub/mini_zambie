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
	# Same sweep group as PickupItem so floor transitions clear leftover orbs.
	add_to_group("drop")


func _setup_visuals() -> void:
	var spr = Sprite2D.new()
	spr.texture = PixelLoader.load_texture("res://assets/pixel/orb.png")
	spr.name = "Visual"
	if spr.texture != null:
		var target := 14.0
		spr.scale = Vector2(target / spr.texture.get_width(), target / spr.texture.get_height())
	add_child(spr)
	# The orb is an Area2D that grants XP on contact with the player, but it had
	# NO collision shape — so body_entered never fired and the +10 XP per kill
	# was silently lost. Add a small circle shape so collection actually works.
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	add_child(col)


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
