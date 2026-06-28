## Data resource defining a zombie type.
## Drop new .tres files into resources/zombies/ to add new zombies.
class_name ZombieData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var zombie_type: GameEnums.ZombieType = GameEnums.ZombieType.NORMAL
@export var zombie_path: String = "res://scripts/entities/zombie/zombie_base.gd"

@export_group("Stats")
@export var health: float = 50.0
@export var speed: float = 50.0
@export var damage: float = 10.0
@export var xp_reward: int = 10

@export_group("Spawn")
@export var min_wave: int = 1
@export var spawn_weight: float = 1.0

@export_group("Rarity")
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON
@export var soul_drop_chance: float = 0.2
@export var item_drop_chance: float = 0.05
