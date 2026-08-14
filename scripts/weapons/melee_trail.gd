## Visual feedback for melee attacks, attached to the Player:
##  - a persistent faint ring showing the equipped melee weapon's reach (range)
##  - an animated slash trail on every swing. The trail sweeps a full 360°
##    arc starting from the aim direction, which matches the melee hit zone
##    (melee damages zombies within `range` in all directions around the player).
##
## Created lazily by WeaponBase._spawn_melee_trail() the first time a melee
## weapon fires; lives for the whole run after that.
class_name MeleeTrail
extends Node2D

const SWING_DURATION := 0.20

var _player: Player = null
var _range_active: float = 0.0
var _show_ring: bool = false
var _swings: Array = []   # each: {t, dur, radius, color, aim}

func _ready() -> void:
	_player = get_parent() as Player
	# Render above world entities (zombies/player are z-index 0) but below the
	# CanvasLayer HUD overlays, which live on a separate layer anyway.
	z_index = 5


## Begin a swing: bright 360° slash that sweeps out from `p_aim`, fading out.
func trigger(p_radius: float, p_color: Color, p_aim: Vector2) -> void:
	var ang := 0.0
	if p_aim != Vector2.ZERO:
		ang = p_aim.angle()
	_swings.append({ "t": 0.0, "dur": SWING_DURATION, "radius": p_radius, "color": p_color, "aim": ang })
	queue_redraw()


## Show / resize the persistent faint range ring (called when a melee weapon is equipped).
func set_range(p_radius: float) -> void:
	_range_active = p_radius
	_show_ring = p_radius > 0.0
	queue_redraw()


func clear_range() -> void:
	_show_ring = false
	queue_redraw()


func _physics_process(delta: float) -> void:
	var dirty := false
	if _swings.size() > 0:
		for s in _swings:
			s.t += delta
		_swings = _swings.filter(func(s): return s.t < s.dur)
		dirty = true

	# Auto show the range ring whenever a melee weapon is equipped, sizing it
	# to the largest melee reach currently in the player's inventory.
	if _player != null and _player.inventory != null:
		var mr := 0.0
		for w in _player.inventory.weapons:
			if w is WeaponBase and w.attack_type == GameEnums.AttackType.MELEE:
				mr = maxf(mr, w.range)
		if mr > 0.0 and (not _show_ring or abs(_range_active - mr) > 0.5):
			set_range(mr)
		elif mr <= 0.0 and _show_ring:
			clear_range()

	if dirty:
		queue_redraw()


func _draw() -> void:
	# Persistent faint range ring = the "attack range display".
	if _show_ring and _range_active > 0.0:
		draw_arc(Vector2.ZERO, _range_active, 0.0, TAU, 56, Color(1.0, 1.0, 1.0, 0.13), 1.5, true)

	# Active slash trails.
	for s in _swings:
		var p := clampf(s.t / s.dur, 0.0, 1.0)
		var alpha := 1.0 - p
		# Ease-out progress so the slash starts snappy then slows as it fades.
		var e := 1.0 - (1.0 - p) * (1.0 - p)
		var col: Color = s.color
		col.a = alpha
		var a0: float = s.aim
		var a1: float = s.aim + TAU * e
		# The main slash arc.
		draw_arc(Vector2.ZERO, s.radius, a0, a1, 40, col, 5.0, true)
		# Glowing leading tip.
		var tip: Vector2 = Vector2(cos(a1), sin(a1)) * s.radius
		draw_circle(tip, 7.0 * (1.0 - p) + 2.0, col)
		# Faint full ring at the start of the swing to mark the reach clearly.
		if p < 0.55:
			var rc: Color = s.color
			rc.a = alpha * 0.35
			draw_arc(Vector2.ZERO, s.radius, 0.0, TAU, 44, rc, 1.5, true)
