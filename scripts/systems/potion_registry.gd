## Registry for potion data resources.
class_name PotionRegistry
extends RefCounted

static var _potion_data: Dictionary = {}
static var _potion_list: Array[PotionData] = []


static func init() -> void:
	_load_potions()


static func _load_potions() -> void:
	var dir = "res://resources/potions/"
	if not DirAccess.dir_exists_absolute(dir):
		return
	var d = DirAccess.open(dir)
	if not d:
		return
	d.list_dir_begin()
	var f = d.get_next()
	while f != "":
		if f.ends_with(".tres"):
			var data = load(dir + f) as PotionData
			if data and not data.id.is_empty():
				_potion_data[data.id] = data
				_potion_list.append(data)
		f = d.get_next()


static func get_data(id: String) -> PotionData:
	return _potion_data.get(id, null)


static func get_all() -> Array[PotionData]:
	return _potion_list


static func get_by_effect_type(effect_type: String) -> Array[PotionData]:
	var result: Array[PotionData] = []
	for data in _potion_list:
		if data.effect_type == effect_type:
			result.append(data)
	return result
