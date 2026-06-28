## Registry for all accessory data resources.
class_name AccessoryRegistry
extends RefCounted

static var _accessory_data: Dictionary = {}
static var _accessory_list: Array[AccessoryData] = []


static func init() -> void:
	_load_accessories()


static func _load_accessories() -> void:
	var dir = "res://resources/accessories/"
	if not DirAccess.dir_exists_absolute(dir):
		return
	var d = DirAccess.open(dir)
	if not d:
		return
	d.list_dir_begin()
	var f = d.get_next()
	while f != "":
		if f.ends_with(".tres"):
			var data = load(dir + f) as AccessoryData
			if data and not data.id.is_empty():
				_accessory_data[data.id] = data
				_accessory_list.append(data)
		f = d.get_next()


static func get_data(id: String) -> AccessoryData:
	return _accessory_data.get(id, null)


static func get_all() -> Array[AccessoryData]:
	return _accessory_list


static func get_by_rarity(rarity: GameEnums.Rarity) -> Array[AccessoryData]:
	var result: Array[AccessoryData] = []
	for data in _accessory_list:
		if data.rarity == rarity:
			result.append(data)
	return result


static func get_by_category(category: String) -> Array[AccessoryData]:
	var result: Array[AccessoryData] = []
	for data in _accessory_list:
		if data.category == category:
			result.append(data)
	return result


static func get_by_rarity_and_category(rarity: GameEnums.Rarity, category: String) -> Array[AccessoryData]:
	var result: Array[AccessoryData] = []
	for data in _accessory_list:
		if data.rarity == rarity and data.category == category:
			result.append(data)
	return result
