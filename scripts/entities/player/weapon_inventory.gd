## Manages the player's weapon slots, build bonuses, and follower count.
class_name WeaponInventory
extends Node

var max_weapons: int = 2

signal weapon_equipped(index: int, weapon: WeaponBase)
signal weapon_removed(index: int)
signal follower_count_changed(count: int)

var weapons: Array[WeaponBase] = []
var build_direction: int = 0
var max_followers: int = 1
var current_followers: int = 0


func equip_weapon(weapon: WeaponBase) -> bool:
	var replaced: WeaponBase = null
	if weapons.size() >= max_weapons:
		# Slots are full: swap out a weapon so a pickup ALWAYS changes the
		# loadout. We prefer dropping a NON-melee weapon so a melee weapon the
		# player picked up doesn't get silently replaced after a few kills
		# (it stays equipped as long as any ranged/other weapon can be dropped
		# instead). Falls back to the oldest weapon when everything is melee.
		var idx := _pick_replace_index()
		replaced = weapons[idx]
		weapons.remove_at(idx)
		if replaced != null:
			weapon_removed.emit(idx)
			replaced.queue_free()
	var slot_index = weapons.size()
	weapons.append(weapon)
	weapon.weapon_owner = get_tree().get_first_node_in_group("player") as Player
	weapon.equipped_weapon_index = slot_index
	if weapon.weapon_owner != null:
		weapon.weapon_owner.inventory = self
	weapon_equipped.emit(slot_index, weapon)
	# Put the weapon node into the scene tree and set its built-in `owner`.
	# Weapon subclasses reach `owner.global_position` and `get_tree()` inside
	# fire(); without a tree parent and a valid owner the projectile spawn
	# crashes and the weapon can never attack.
	var p = weapon.weapon_owner
	if p != null and weapon.get_parent() == null:
		p.add_child(weapon)
		weapon.owner = p
	return true


## When the weapon bar is full, pick which existing weapon to swap out on a
## pickup. Prefer a NON-melee weapon (keep melee equipped); otherwise drop the
## oldest weapon. Returns an index into `weapons`.
func _pick_replace_index() -> int:
	var oldest_non_melee := -1
	for i in range(weapons.size()):
		if weapons[i].attack_type != GameEnums.AttackType.MELEE:
			oldest_non_melee = i
			break
	if oldest_non_melee >= 0:
		return oldest_non_melee
	return 0


func remove_weapon(index: int) -> bool:
	if index < 0 or index >= weapons.size():
		return false
	var removed = weapons.pop_at(index)
	removed.queue_free()
	for i in range(weapons.size()):
		weapons[i].equipped_weapon_index = i
	weapon_removed.emit(index)
	return true


func get_weapons_by_type(atk_type: int) -> Array[WeaponBase]:
	var result: Array[WeaponBase] = []
	for w in weapons:
		if w.attack_type == atk_type:
			result.append(w)
	return result


func calculate_build_bonus() -> float:
	var counts: Dictionary = {}
	for w in weapons:
		counts[w.attack_type] = counts.get(w.attack_type, 0) + 1
	var max_count: int = 0
	for count in counts.values():
		if count > max_count:
			max_count = count
	return 1.0 + (max_count - 1) * 0.15


func get_dominant_attack_type() -> int:
	var counts: Dictionary = {}
	for w in weapons:
		counts[w.attack_type] = counts.get(w.attack_type, 0) + 1
	var dominant: int = 0  # 0 = RANGED
	var max_count: int = 0
	for type in counts:
		if (counts[type] as int) > max_count:
			max_count = counts[type] as int
			dominant = type as int
	return dominant


func add_follower_slot(count: int = 1) -> void:
	max_followers += count
	current_followers = min(current_followers, max_followers)
	follower_count_changed.emit(current_followers)


func can_add_follower() -> bool:
	return current_followers < max_followers
