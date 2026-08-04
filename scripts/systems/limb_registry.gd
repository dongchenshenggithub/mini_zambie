## Registry for prosthetic limb (LimbSlot) resources.
## Drop new .tres files into resources/limbs/ to add new prosthetics.
class_name LimbRegistry
extends RefCounted

static var _limbs: Array[LimbSlot] = []


static func init() -> void:
	_load()


static func _load() -> void:
	var dir = "res://resources/limbs/"
	if not DirAccess.dir_exists_absolute(dir):
		return
	var d = DirAccess.open(dir)
	if not d:
		return
	d.list_dir_begin()
	var f = d.get_next()
	while f != "":
		if f.ends_with(".tres"):
			var data = load(dir + f) as LimbSlot
			if data:
				_limbs.append(data)
		f = d.get_next()


## Returns a random prosthetic limb, or null if none are registered.
static func get_random() -> LimbSlot:
	if _limbs.is_empty():
		return null
	return _limbs[randi() % _limbs.size()]


static func get_all() -> Array[LimbSlot]:
	return _limbs
