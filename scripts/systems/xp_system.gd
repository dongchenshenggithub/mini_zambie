## Manages XP, leveling, and upgrade generation.
class_name XPSystem
extends Node

signal leveled_up(new_level: int)
signal xp_gained(amount: int)

## Global multiplier on all XP intake. Realistic play clears ~250-500 kills
## per floor (each kill = xp_reward + a 10-xp soul orb), so a x1.0 intake with
## the base cost below lands leveling at ~1-2 levels per floor (weaker players
## get ~1, strong clears get a bit more). A previous 0.4 multiplier made it
## impossible to gain even one level in a floor, so this is the corrected value.
const XP_GAIN_MULTIPLIER: float = 1.0
## Per-level XP cost grows by this factor each level so later levels stay
## meaningful as per-floor XP income rises with floor duration/difficulty.
const XP_GROWTH: float = 1.08

var current_xp: float = 0.0
var total_xp: int = 0
var level: int = 1
var xp_to_next_level: float = 2500.0


func _ready() -> void:
	add_to_group("xp_system")


func gain_xp(amount: int) -> void:
	current_xp += float(amount) * XP_GAIN_MULTIPLIER
	total_xp += amount
	xp_gained.emit(amount)

	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level += 1
		xp_to_next_level = xp_to_next_level * XP_GROWTH
		leveled_up.emit(level)
		Game.current_level = level


func get_xp_progress() -> float:
	if xp_to_next_level <= 0:
		return 1.0
	return float(current_xp) / float(xp_to_next_level)


func is_max_level() -> bool:
	return level >= 50
