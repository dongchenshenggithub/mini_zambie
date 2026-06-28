## Represents a single map area with its properties.
class_name MapArea
extends Node2D


@export var area_type: GameEnums.AreaType = GameEnums.AreaType.STREET
@export var area_size: Vector2 = Vector2(400.0, 300.0)
@export var min_zombie_level: int = 1
@export var max_zombie_level: int = 3
