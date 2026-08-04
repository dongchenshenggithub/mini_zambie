## Procedural map generator — one coherent background per floor.
##
## Previously each floor was a 3x2 grid of areas, each with a DIFFERENT themed
## floor texture, which read as "6 backgrounds stitched together" and never
## matched the map bounds. Now every floor gets a SINGLE themed background that
## is sized to cover the whole playable area, with buildings/obstacles/pickups
## scattered across that one space.
class_name MapGenerator
extends Node

const PixelLoader = preload("res://scripts/core/pixel_loader.gd")

# Normal floors are a single 1600x1000 arena; boss room is a 1200x1200 arena.
const FLOOR_SIZE := Vector2(1600.0, 1000.0)
const BOSS_SIZE := Vector2(1200.0, 1200.0)

# Deterministic, repeating theme order so each floor has its own look but the
# sequence is stable across runs.
const AREA_ORDER := [
	GameEnums.AreaType.STREET,
	GameEnums.AreaType.SUPERMARKET,
	GameEnums.AreaType.HOTEL,
	GameEnums.AreaType.HOSPITAL,
	GameEnums.AreaType.PARKING_LOT,
]

const AREA_NAMES := {
	GameEnums.AreaType.STREET: "街道",
	GameEnums.AreaType.SUPERMARKET: "超市",
	GameEnums.AreaType.HOTEL: "酒店",
	GameEnums.AreaType.HOSPITAL: "医院",
	GameEnums.AreaType.PARKING_LOT: "停车场",
	GameEnums.AreaType.BOSS_ROOM: "王座厅",
}

const AREA_FLOOR_TEXTURES := {
	GameEnums.AreaType.STREET: "res://assets/pixel/floor_street.png",
	GameEnums.AreaType.SUPERMARKET: "res://assets/pixel/floor_supermarket.png",
	GameEnums.AreaType.HOTEL: "res://assets/pixel/floor_hotel.png",
	GameEnums.AreaType.HOSPITAL: "res://assets/pixel/floor_hospital.png",
	GameEnums.AreaType.PARKING_LOT: "res://assets/pixel/floor_parking.png",
	GameEnums.AreaType.BOSS_ROOM: "res://assets/pixel/floor_boss.png",
}


## Picks the single theme for a floor. Boss floor always uses BOSS_ROOM.
static func theme_for_floor(floor_number: int, is_boss_floor: bool = false) -> GameEnums.AreaType:
	if is_boss_floor:
		return GameEnums.AreaType.BOSS_ROOM
	return AREA_ORDER[floor_number % AREA_ORDER.size()]


static func theme_name(theme: GameEnums.AreaType) -> String:
	return AREA_NAMES.get(theme, "区域")


## Adds a centered pixel Sprite2D child to `node`, scaled to fit `target_size`.
func _add_sprite(node: Node2D, path: String, target_size: float) -> void:
	var tex = PixelLoader.load_texture(path)
	if tex == null:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.name = "Visual"
	var s := float(maxi(1, tex.get_width()))
	spr.scale = Vector2(target_size / s, target_size / s)
	node.add_child(spr)


func generate_floor(floor_number: int, is_boss_floor: bool = false) -> Node2D:
	var root = Node2D.new()
	root.name = "Floor_%d" % floor_number

	var theme := theme_for_floor(floor_number, is_boss_floor)
	var size := FLOOR_SIZE
	if is_boss_floor:
		size = BOSS_SIZE

	_create_single_floor(root, theme, size, floor_number)

	root.set_meta("player_spawn", Vector2.ZERO)
	root.set_meta("is_boss", is_boss_floor)
	# World bounds (in the floor root's local space, which is centred on the
	# origin). The player clamps its position to this rect so it can never walk
	# off the background, and the camera limits its view to it.
	root.set_meta("bounds", Rect2(-size.x / 2.0, -size.y / 2.0, size.x, size.y))
	if is_boss_floor:
		root.set_meta("boss_spawn", Vector2(0, -size.y / 3.0))
	return root


## Builds ONE coherent floor: a single background that exactly covers `size`,
## plus scattered buildings/obstacles/pickups within that space.
func _create_single_floor(root: Node2D, theme: GameEnums.AreaType, size: Vector2, floor_number: int) -> void:
	var floor_path: String = AREA_FLOOR_TEXTURES.get(theme, "res://assets/pixel/floor_tile.png")

	# Solid themed backing so the floor always reads as this floor's colour even
	# where the (tiny) tile texture is sparse.
	var backing := ColorRect.new()
	backing.color = _theme_tint(theme)
	backing.position = Vector2(-size.x / 2.0, -size.y / 2.0)
	backing.size = size
	backing.name = "FloorTint"
	root.add_child(backing)

	# Single coherent background image stretched to cover the whole map.
	var tex = PixelLoader.load_texture(floor_path, true)
	var floor_bg := Sprite2D.new()
	floor_bg.texture = tex
	floor_bg.centered = false
	floor_bg.region_enabled = true
	floor_bg.region_rect = Rect2(0, 0, size.x, size.y)
	floor_bg.position = Vector2(-size.x / 2.0, -size.y / 2.0)
	floor_bg.name = "FloorBG"
	floor_bg.modulate = Color(1.0, 1.0, 1.0, 0.85)
	root.add_child(floor_bg)

	# Buildings (indestructible) — kept away from the very centre so the player
	# spawn point is clear.
	var building_count := 4 + floor_number % 3
	for i in range(building_count):
		var off := _scatter(size, 220.0)
		var building := _create_building(off)
		root.add_child(building)

	# Obstacles (some destructible).
	var obstacle_count := 8 + floor_number % 5
	for i in range(obstacle_count):
		var off := _scatter(size, 120.0)
		var is_destructible := randi() % 3 != 0
		var obstacle := _create_obstacle(off, is_destructible)
		root.add_child(obstacle)

	# Pickup items scattered in the world (separate from zombie drops).
	var item_count := 2 + floor_number % 3
	for i in range(item_count):
		var off := _scatter(size, 100.0)
		var item := _create_pickup_item(off)
		root.add_child(item)


## Returns a random position inside `size`, kept `margin` px from the edges.
func _scatter(size: Vector2, margin: float) -> Vector2:
	var hx := size.x / 2.0 - margin
	var hy := size.y / 2.0 - margin
	return Vector2(randf_range(-hx, hx), randf_range(-hy, hy))


## A muted tint derived from the floor theme so the backing reads as that biome.
func _theme_tint(theme: GameEnums.AreaType) -> Color:
	match theme:
		GameEnums.AreaType.SUPERMARKET:
			return Color(0.32, 0.28, 0.22)
		GameEnums.AreaType.HOTEL:
			return Color(0.28, 0.24, 0.34)
		GameEnums.AreaType.HOSPITAL:
			return Color(0.22, 0.32, 0.28)
		GameEnums.AreaType.PARKING_LOT:
			return Color(0.20, 0.20, 0.25)
		GameEnums.AreaType.BOSS_ROOM:
			return Color(0.30, 0.08, 0.08)
		_:
			return Color(0.24, 0.24, 0.28)


func _create_building(offset: Vector2) -> Node2D:
	var building = StaticBody2D.new()
	building.name = "Building"
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(60, 60)
	shape.shape = rect
	building.add_child(shape)
	building.position = offset
	_add_sprite(building, "res://assets/pixel/building.png", 60.0)
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
	# Destructible props (cars) look distinct from indestructible crates.
	var prop_path := "res://assets/pixel/obstacle_car.png" if destructible else "res://assets/pixel/obstacle_crate.png"
	_add_sprite(obstacle, prop_path, 30.0)
	obstacle.set_meta("destructible", destructible)
	return obstacle


func _create_pickup_item(position: Vector2) -> Node2D:
	var item = Node2D.new()
	item.name = "PickupItem"
	item.position = position
	item.set_meta("item_type", GameEnums.ItemCategory.POTION)
	return item
