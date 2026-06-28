## Registry for map floor data resources.
class_name MapFloorRegistry
extends RefCounted

static var _floor_data: Dictionary = {}
static var _floor_list: Array[MapFloorData] = []


static func init() -> void:
	_load_floors()


static func _load_floors() -> void:
	var dir = "res://resources/maps/"
	if not DirAccess.dir_exists_absolute(dir):
		return
	var d = DirAccess.open(dir)
	if not d:
		return
	d.list_dir_begin()
	var f = d.get_next()
	while f != "":
		if f.ends_with(".tres"):
			var data = load(dir + f) as MapFloorData
			if data and not data.id.is_empty():
				_floor_data[data.id] = data
				_floor_list.append(data)
		f = d.get_next()


static func get_data(id: String) -> MapFloorData:
	return _floor_data.get(id, null)


static func get_all() -> Array[MapFloorData]:
	return _floor_list


static func get_by_floor_number(floor_num: int) -> MapFloorData:
	for data in _floor_list:
		if data.floor_number == floor_num:
			return data
	return null


static func get_random_non_boss(count: int = 14) -> Array[MapFloorData]:
	var result: Array[MapFloorData] = []
	var candidates = get_all().filter(func(f): return not f.is_boss_floor)
	candidates.shuffle()
	for i in range(minf(count, candidates.size())):
		result.append(candidates[i])
	return result
