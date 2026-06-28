## Procedural map generator — creates city block layouts for each floor.
class_name MapGenerator
extends Node

const AREA_TYPES := [
	GameEnums.AreaType.STREET,
	GameEnums.AreaType.SUPERMARKET,
	GameEnums.AreaType.HOTEL,
	GameEnums.AreaType.HOSPITAL,
	GameEnums.AreaType.PARKING_LOT,
]

const AREA_COLORS := {
	GameEnums.AreaType.STREET: Color(0.3, 0.3, 0.35),
	GameEnums.AreaType.SUPERMARKET: Color(0.4, 0.35, 0.3),
	GameEnums.AreaType.HOTEL: Color(0.35, 0.3, 0.4),
	GameEnums.AreaType.HOSPITAL: Color(0.3, 0.4, 0.35),
	GameEnums.AreaType.PARKING_LOT: Color(0.25, 0.25, 0.3),
	GameEnums.AreaType.BOSS_ROOM: Color(0.4, 0.1, 0.1),
}


func generate_floor(floor_number: int, is_boss_floor: bool = false) -> Node2D:
	var root = Node2D.new()
	root.name = "Floor_%d" % floor_number

	var area_size := Vector2(500.0, 400.0)
	var cols := 3
	var rows := 2

	if is_boss_floor:
		# Boss room is a single circular arena
		var arena = _create_boss_room(area_size * 2.0)
		arena.position = Vector2.ZERO
		root.add_child(arena)
		root.set_meta("player_spawn", Vector2.ZERO)
		root.set_meta("is_boss", true)
		return root

	# Randomly select area types for this floor
	var shuffled = AREA_TYPES.duplicate()
	shuffled.shuffle()

	for row in range(rows):
		for col in range(cols):
			var area_type = shuffled[(row * cols + col) % shuffled.size()]
			var pos = Vector2(col * area_size.x - cols * area_size.x / 2.0,
			                  row * area_size.y - rows * area_size.y / 2.0)
			var area = _create_area(area_type, pos, area_size, floor_number)
			root.add_child(area)

	var spawn = Vector2(0, 0)
	root.set_meta("player_spawn", spawn)
	root.set_meta("is_boss", false)
	return root


func _create_area(area_type: GameEnums.AreaType, position: Vector2, size: Vector2, _floor_num: int) -> Node2D:
	var area = Node2D.new()
	area.name = "Area_%s" % area_type
	area.position = position

	var floor_bg = ColorRect.new()
	floor_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	floor_bg.color = AREA_COLORS.get(area_type, Color.GRAY)
	area.add_child(floor_bg)

	# Buildings (indestructible)
	var building_count = 1 + randi() % 2
	for i in range(building_count):
		var building = _create_building(Vector2(randf_range(-size.x/3, size.x/3), randf_range(-size.y/3, size.y/3)))
		area.add_child(building)

	# Obstacles (some destructible)
	var rng = randi()
	var obstacle_count = 3 + rng % 5
	for i in range(obstacle_count):
		var is_destructible = randi() % 3 != 0
		var obstacle = _create_obstacle(Vector2(randf_range(-size.x/2, size.x/2), randf_range(-size.y/2, size.y/2)), is_destructible)
		area.add_child(obstacle)

	# Pickup items
	var item_count = 1 + randi() % 3
	for i in range(item_count):
		var item = _create_pickup_item(Vector2(randf_range(-size.x/2, size.x/2), randf_range(-size.y/2, size.y/2)))
		area.add_child(item)

	return area


func _create_boss_room(size: Vector2) -> Node2D:
	var room = ColorRect.new()
	room.set_anchors_preset(Control.PRESET_FULL_RECT)
	room.color = AREA_COLORS[GameEnums.AreaType.BOSS_ROOM]
	return room


func _create_building(offset: Vector2) -> Node2D:
	var building = StaticBody2D.new()
	building.name = "Building"
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(60, 60)
	shape.shape = rect
	building.add_child(shape)
	building.position = offset
	building.modulate = Color(0.6, 0.5, 0.4)
	return building


func _create_obstacle(offset: Vector2, destructible: bool) -> Node2D:
	var obstacle = StaticBody2D.new()
	obstacle.name = "Obstacle"
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(30, 30)
	shape.shape = rect
	obstacle.add_child(shape)
	obstacle.position = offset
	obstacle.modulate = Color(0.5, 0.4, 0.3)
	obstacle.set_meta("destructible", destructible)
	return obstacle


func _create_pickup_item(position: Vector2) -> Node2D:
	var item = Node2D.new()
	item.name = "PickupItem"
	item.position = position
	item.set_meta("item_type", GameEnums.ItemCategory.POTION)
	return item
