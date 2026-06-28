## Central registry for all zombie data resources.
class_name ZombieRegistry
extends RefCounted

static var _zombie_data: Dictionary = {}
static var _zombie_list: Array[ZombieData] = []


static func init() -> void:
	_load_zombies()


static func _load_zombies() -> void:
	var dir = "res://resources/zombies/"
	if not DirAccess.dir_exists_absolute(dir):
		return
	var d = DirAccess.open(dir)
	if not d:
		return
	d.list_dir_begin()
	var f = d.get_next()
	while f != "":
		if f.ends_with(".tres"):
			var data = load(dir + f) as ZombieData
			if data and not data.id.is_empty():
				_zombie_data[data.id] = data
				_zombie_list.append(data)
		f = d.get_next()


static func get_data(id: String) -> ZombieData:
	return _zombie_data.get(id, null)


static func get_all() -> Array[ZombieData]:
	return _zombie_list


static func get_by_min_wave(min_wave: int) -> Array[ZombieData]:
	var result: Array[ZombieData] = []
	for data in _zombie_list:
		if data.min_wave <= min_wave:
			result.append(data)
	return result


static func get_by_rarity(rarity: GameEnums.Rarity) -> Array[ZombieData]:
	var result: Array[ZombieData] = []
	for data in _zombie_list:
		if data.rarity == rarity:
			result.append(data)
	return result


static func spawn_instance(data: ZombieData) -> ZombieBase:
	if data.zombie_path:
		var instance = load(data.zombie_path).instantiate()
		_copy_data_to_zombie(instance, data)
		return instance
	return null


static func _copy_data_to_zombie(zombie: ZombieBase, data: ZombieData) -> void:
	zombie.base_health = data.health
	zombie.base_speed = data.speed
	zombie.base_damage = data.damage
	zombie.xp_reward = data.xp_reward
