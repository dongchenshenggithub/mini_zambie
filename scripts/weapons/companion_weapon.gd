extends WeaponBase
## A "companion weapon" occupies ONE weapon slot and spawns a follower unit that
## fights alongside the player. For non-Cat-Cafe characters this is the ONLY way
## to gain a companion, so the companion count is implicitly capped by the number
## of free weapon slots (= max_weapons). Cat Cafe ignores the count limit and
## recruits companions directly through FollowerManager instead.
##
## Flow: picking up a COMPANION drop equips this weapon (via WeaponInventory).
## GameScene's `weapon_equipped` signal then calls spawn_companion(), which asks
## FollowerManager to spawn the unit and links weapon<->unit. When the weapon is
## dropped/dismissed it is freed, and _notification(PREDELETE) dismisses the
## linked unit so the companion slot and cap free up for future drops.

var _dismissed: bool = false


func _init() -> void:
	# Set identity immediately on .new() (before the weapon is added to the
	# tree). equip_weapon() emits `weapon_equipped` synchronously, and GameScene's
	# handler checks `weapon.is_companion` at that moment — if we only set it in
	# _ready (which runs deferred, after the signal), the follower would never
	# spawn. `is_companion` and `companion_unit` are inherited from WeaponBase.
	is_companion = true
	attack_type = GameEnums.AttackType.SUMMON
	auto_fire = false
	fire_mode = GameEnums.FireMode.AUTO


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_dismiss_linked_unit()


## Spawns the follower unit for this companion weapon. Called by GameScene once
## the weapon is equipped. NOTE: weapon_equipped is emitted by WeaponInventory
## BEFORE the weapon is added to the tree, so `get_tree()` is still null here —
## resolve the scene through `weapon_owner` (the player, which is in the tree).
func spawn_companion(character_class: int) -> void:
	var owner = weapon_owner
	var gs = null
	if owner != null and owner.get_tree() != null:
		gs = owner.get_tree().current_scene
	var fm = null
	if gs != null and gs.has_method("get"):
		fm = gs.get("follower_manager")
	if fm == null or not fm.has_method("spawn_unit_for_companion"):
		return
	var unit = fm.spawn_unit_for_companion(character_class)
	if unit != null:
		companion_unit = unit
		if unit.has_method("set"):
			unit.set("companion_weapon", self)


func _dismiss_linked_unit() -> void:
	if _dismissed:
		return
	_dismissed = true
	if companion_unit != null and is_instance_valid(companion_unit):
		var gs = null
		var owner = weapon_owner
		if owner != null and owner.get_tree() != null:
			gs = owner.get_tree().current_scene
		elif get_tree() != null:
			gs = get_tree().current_scene
		var fm = null
		if gs != null and gs.has_method("get"):
			fm = gs.get("follower_manager")
		if fm != null and fm.has_method("dismiss_unit"):
			fm.dismiss_unit(companion_unit)
	companion_unit = null
