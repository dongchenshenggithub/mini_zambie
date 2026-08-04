## Central registry for all weapon data resources.
## New weapons are auto-discovered from resources/weapons/*.tres
class_name WeaponRegistry
extends RefCounted

static var _weapon_data: Dictionary = {}
static var _weapon_list: Array[WeaponData] = []


static func init() -> void:
	_load_weapons()


static func _load_weapons() -> void:
	var weapons_dir = "res://resources/weapons/"
	if not DirAccess.dir_exists_absolute(weapons_dir):
		return
	var dir = DirAccess.open(weapons_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = weapons_dir + file_name
			var data = load(path) as WeaponData
			if data and not data.id.is_empty():
				_weapon_data[data.id] = data
				_weapon_list.append(data)
		file_name = dir.get_next()


static func get_data(id: String) -> WeaponData:
	return _weapon_data.get(id, null)


static func get_all() -> Array[WeaponData]:
	return _weapon_list


static func get_by_rarity(rarity: GameEnums.Rarity) -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for data in _weapon_list:
		if data.rarity == rarity:
			result.append(data)
	return result


static func get_by_category(category: GameEnums.WeaponCategory) -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for data in _weapon_list:
		if data.category == category:
			result.append(data)
	return result


static func spawn_instance(data: WeaponData) -> WeaponBase:
	if data.weapon_path and not data.weapon_path.is_empty():
		var script = load(data.weapon_path) as Script
		if script:
			var instance = script.new()
			_copy_data_to_weapon(instance, data)
			return instance
	return null


static func _copy_data_to_weapon(weapon: WeaponBase, data: WeaponData) -> void:
	weapon.weapon_name = data.name
	weapon.attack_type = data.attack_type
	weapon.weapon_category = data.category
	weapon.weapon_weight = data.weapon_weight
	weapon.damage = data.damage
	weapon.fire_rate = data.fire_rate
	weapon.range = data.range
	weapon.crit_chance = data.crit_chance
	weapon.crit_multiplier = data.crit_multiplier
	weapon.pierce = data.pierce
	weapon.splash_radius = data.splash_radius
	weapon.effect = data.effect
	weapon.effect_duration = data.effect_duration
	weapon.fire_mode = data.fire_mode
	weapon.magazine_size = data.magazine_size
	weapon.reload_time = data.reload_time
	weapon.durability = data.max_durability
