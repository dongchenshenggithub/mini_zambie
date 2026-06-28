## Registry for part data resources.
class_name PartRegistry
extends RefCounted

static var _part_data: Dictionary = {}
static var _part_list: Array[PartData] = []


static func init() -> void:
	_load_parts()


static func _load_parts() -> void:
	var dir = "res://resources/parts/"
	if not DirAccess.dir_exists_absolute(dir):
		return
	var d = DirAccess.open(dir)
	if not d:
		return
	d.list_dir_begin()
	var f = d.get_next()
	while f != "":
		if f.ends_with(".tres"):
			var data = load(dir + f) as PartData
			if data and not data.id.is_empty():
				_part_data[data.id] = data
				_part_list.append(data)
		f = d.get_next()


static func get_data(id: String) -> PartData:
	return _part_data.get(id, null)


static func get_all() -> Array[PartData]:
	return _part_list
