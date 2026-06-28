## Manages prosthetic limbs for Mech Monk and human characters.
class_name ProstheticManager
extends Node

signal limb_changed(slot_type: int, new_limb: LimbSlot)

var limbs: Dictionary = { 0: null, 1: null, 2: null, 3: null, 4: null, 5: null }
var is_mech_monk: bool = false
var owner_stats: PlayerStats = null

var _limb_slots: Dictionary = {
	0: "head", 1: "body", 2: "arm_l", 3: "arm_r", 4: "leg_l", 5: "leg_r"
}


func _init(is_mech: bool = false, stats: PlayerStats = null) -> void:
	is_mech_monk = is_mech
	owner_stats = stats


func can_equip(slot_type: int) -> bool:
	if is_mech_monk:
		return true
	return slot_type >= 2 and slot_type <= 5


func install_limb(slot_type: int, limb: LimbSlot) -> bool:
	if not can_equip(slot_type):
		return false
	limbs[slot_type] = limb
	_recalc_stats()
	limb_changed.emit(slot_type, limb)
	return true


func remove_limb(slot_type: int) -> bool:
	if limbs.has(slot_type) and limbs[slot_type] != null:
		limbs[slot_type] = null
		_recalc_stats()
		limb_changed.emit(slot_type, null)
		return true
	return false


func get_limb(slot_type: int) -> LimbSlot:
	return limbs.get(slot_type, null)


func _recalc_stats() -> void:
	if owner_stats == null:
		return
	var total_damage_bonus: float = 0.0
	var total_health_bonus: float = 0.0
	var total_speed_bonus: float = 0.0
	var total_armor_bonus: int = 0
	var total_crit_bonus: float = 0.0

	for slot_type in limbs:
		var limb = limbs[slot_type] as LimbSlot
		if limb:
			total_damage_bonus += limb.base_damage_bonus
			total_health_bonus += limb.base_health_bonus
			total_speed_bonus += limb.base_speed_bonus
			total_armor_bonus += limb.base_armor_bonus
			total_crit_bonus += limb.base_crit_bonus

	owner_stats.limb_damage_bonus = total_damage_bonus
	owner_stats.limb_health_bonus = total_health_bonus
	owner_stats.limb_speed_bonus = total_speed_bonus
	owner_stats.limb_armor_bonus = total_armor_bonus
	owner_stats.limb_crit_bonus = total_crit_bonus
