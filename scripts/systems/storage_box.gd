## Storage box — holds weapons and accessories found during the run.
## Items go here instead of being auto-equipped.
## Player manages loadout at the between-floor shop screen.
class_name StorageBox
extends RefCounted

## List of owned weapons (WeaponData references)
static var weapons: Array[Dictionary] = []
## List of owned accessories (AccessoryData references)
static var accessories: Array[Dictionary] = []
## Dictionary of owned weapon instances (weapon_data_id -> instance)
static var weapon_instances: Dictionary = {}
## Dictionary of owned accessory instances (accessory_data_id -> instance)
static var accessory_instances: Dictionary = {}

static func init() -> void:
	weapons.clear()
	accessories.clear()
	weapon_instances.clear()
	accessory_instances.clear()


static func add_weapon(data: WeaponData) -> String:
	if data == null or data.id.is_empty():
		return ""
	weapons.append({"data": data, "level": 1})
	weapon_instances.erase(data.id)
	return data.id


static func add_accessory(data: AccessoryData) -> String:
	if data == null or data.id.is_empty():
		return ""
	accessories.append({"data": data, "level": 1})
	accessory_instances.erase(data.id)
	return data.id


static func remove_weapon(weapon_id: String) -> WeaponData:
	var idx = -1
	for i in range(weapons.size()):
		if weapons[i].get("data", null) != null and weapons[i]["data"].id == weapon_id:
			idx = i
			break
	if idx < 0:
		return null
	var data = weapons[idx]["data"]
	weapons.remove_at(idx)
	weapon_instances.erase(weapon_id)
	return data


static func remove_accessory(accessory_id: String) -> AccessoryData:
	var idx = -1
	for i in range(accessories.size()):
		if accessories[i].get("data", null) != null and accessories[i]["data"].id == accessory_id:
			idx = i
			break
	if idx < 0:
		return null
	var data = accessories[idx]["data"]
	accessories.remove_at(idx)
	accessory_instances.erase(accessory_id)
	return data


static func get_weapon_count() -> int:
	return weapons.size()


static func get_accessory_count() -> int:
	return accessories.size()


static func clear_all() -> void:
	weapons.clear()
	accessories.clear()
	weapon_instances.clear()
	accessory_instances.clear()
