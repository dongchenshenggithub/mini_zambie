## Data resource defining a weapon's stats.
## Drop new .tres files into resources/weapons/ to add new weapons.
class_name WeaponData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var category: int = 0
@export var attack_type: int = 0
@export var weapon_path: String = ""

@export_group("Stats")
@export var damage: float = 10.0
@export var fire_rate: float = 1.0
@export var range: float = 200.0
@export var weapon_weight: int = 2

@export_group("Crit")
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0

@export_group("Effects")
@export var pierce: int = 0
@export var splash_radius: float = 0.0
@export var effect: int = 0
@export var effect_duration: float = 0.0

@export_group("Durability")
@export var max_durability: float = 100.0
@export var durability_decay_rate: float = 1.0

@export_group("Rarity")
@export var rarity: int = 0
@export var soul_cost: int = 5
