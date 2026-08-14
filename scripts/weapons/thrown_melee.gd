## Flying-sword projectile for the Cyber Cultivator's signature trait:
## melee weapons are THROWN as slow, piercing projectiles that ignore obstacles
## and boomerang back to the player (throw + recall). No magazine / no reload —
## the underlying melee weapon simply re-throws on its fire_rate cooldown.
## Run: (instantiated by WeaponBase._spawn_thrown_melee)
extends Area2D

const ZombieBaseScript = preload("res://scripts/entities/zombie/zombie_base.gd")

var _owner: Node2D = null
var _dir: Vector2 = Vector2.RIGHT
var _speed: float = 300.0          ## slow, deliberate throw
var _damage: float = 10.0
var _max_dist: float = 420.0
var _traveled: float = 0.0
var _returning: bool = false
var _life: float = 0.0
var _max_life: float = 3.5
var _hit: Dictionary = {}           ## instance_id -> true, so each zombie is hit once per pass

@onready var _blade: Polygon2D = $Blade


func setup(owner_node: Node2D, dir: Vector2, damage: float, reach: float) -> void:
	_owner = owner_node
	_dir = dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
	_damage = damage
	# Thrown reach is longer than a melee swing; scale the weapon's range up
	# so "remote throw" actually reaches across the screen a bit.
	_max_dist = maxf(reach * 2.5, 360.0)
	rotation = _dir.angle()
	global_position = owner_node.global_position + _dir * 18.0


func _ready() -> void:
	# Visible blade: an elongated cyan-white diamond drawn with a Polygon2D so
	# no extra art asset is needed (reliable under headless too).
	var blade := Polygon2D.new()
	blade.name = "Blade"
	blade.polygon = PackedVector2Array([
		Vector2(14, 0), Vector2(2, -4), Vector2(-14, 0), Vector2(2, 4)
	])
	blade.color = Color(0.75, 1.0, 1.0)
	add_child(blade)
	# Hitbox (small, centered on the blade).
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	var cshape := CollisionShape2D.new()
	cshape.shape = shape
	add_child(cshape)
	# Body-enter is how we damage zombies (pierce — we never free on hit).
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_life += delta
	if _life >= _max_life:
		queue_free()
		return
	# Boomerang: once we've flown far enough, steer back toward the owner.
	if not _returning and _traveled >= _max_dist:
		_returning = true
	if _returning and _owner != null:
		_dir = (_owner.global_position - global_position).normalized()
		rotation = _dir.angle()
	var step := _speed * delta
	position += _dir * step
	_traveled += step
	# Recall complete: reached the owner again -> vanish (weapon stays equipped).
	if _returning and _owner != null and global_position.distance_to(_owner.global_position) < 26.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	var z = body as ZombieBaseScript
	if z == null:
		return
	var id := z.get_instance_id()
	if _hit.has(id):
		return
	_hit[id] = true
	z.take_damage(_damage)
	# Brief red flash on the struck zombie so the throw reads as a hit.
	if z.has_method("flash_hit"):
		z.flash_hit()
