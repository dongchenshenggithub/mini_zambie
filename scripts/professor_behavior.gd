## Behavior for Professor — laser specialization, turret placement.
## The Professor can deploy stationary structures (auto-turret + healing tower)
## via the "place_tower" active ability (Q). Stock is granted at start and
## topped up one structure per floor.
class_name ProfessorBehavior
extends HumanBehavior

const TurretScript = preload("res://scripts/entities/structures/turret.gd")
const HealingTowerScript = preload("res://scripts/entities/structures/healing_tower.gd")

## Placement stock (turret / heal) consumed by the place-tower ability.
var _tower_stock: Array[String] = ["turret", "heal"]
## Currently deployed structures (capped so the field doesn't flood).
var _placed: Array = []
const MAX_PLACED: int = 4


func on_weapon_pickup(weapon: WeaponBase) -> void:
	# Professor gets bonus damage on laser weapons
	if weapon and weapon.attack_type == GameEnums.AttackType.LASER:
		weapon.damage *= 1.5


func on_level_up(_new_level: int) -> void:
	# Research breakthroughs sharpen critical chance.
	if owner and owner.stats.is_alive():
		owner.stats.crit_bonus += 0.02


func on_floor_clear(_floor: int) -> void:
	# A modest patch-up between floors.
	if owner and owner.stats.is_alive():
		owner.heal(owner.stats.max_health * 0.1)
	# Grant a new structure each floor (alternating type), up to a stock cap.
	if _tower_stock.size() < 6:
		if _tower_stock.size() % 2 == 0:
			_tower_stock.append("turret")
		else:
			_tower_stock.append("heal")


## Active ability: place the next queued structure at the player's position.
## Bound to the "place_tower" action (Q). If the deployment cap is reached,
## the oldest structure is freed first so a fresh slot is always available.
func on_special_ability(scene: Node2D) -> void:
	if _tower_stock.is_empty() or owner == null or scene == null:
		return
	if _placed.size() >= MAX_PLACED:
		var oldest = _placed.pop_front()
		if oldest != null and is_instance_valid(oldest):
			oldest.queue_free()
	var kind: String = _tower_stock.pop_front()
	var node: Node2D = null
	if kind == "turret":
		node = TurretScript.new()
	else:
		node = HealingTowerScript.new()
	node.global_position = owner.global_position
	scene.add_child(node)
	_placed.append(node)
	print("Professor placed %s (stock left: %d, deployed: %d)" % [kind, _tower_stock.size(), _placed.size()])
