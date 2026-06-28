## Data resource defining a map area/floor type.
## Drop new .tres files into resources/maps/ to add new floor layouts.
class_name MapFloorData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var area_type: GameEnums.AreaType = GameEnums.AreaType.STREET
@export var floor_number: int = 1

@export_group("Layout")
@export var is_boss_floor: bool = false
@export var has_shop: bool = false
@export var has_rest_area: bool = false
@export var grid_cols: int = 3
@export var grid_rows: int = 2
@export var area_size: Vector2 = Vector2(500.0, 400.0)

@export_group("Zombies")
@export var min_zombie_wave: int = 1
@export var max_zombie_wave: int = 3
@export var zombie_density: float = 1.0

@export_group("Loot")
@export var loot_quality: float = 1.0
@export var has_treasure_chest: bool = false

@export_group("Visual")
@export var floor_color: Color = Color(0.3, 0.3, 0.35)
@export var bg_music: String = ""
@export var tileset_path: String = ""
