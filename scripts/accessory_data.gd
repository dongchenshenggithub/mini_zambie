## Data resource defining an accessory/equipment piece.
## Drop new .tres files into resources/accessories/ to add new accessories.
class_name AccessoryData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var category: String = ""
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON

@export_group("Stats")
@export var health_bonus: float = 0.0
@export var strength_bonus: int = 0
@export var agility_bonus: int = 0
@export var intelligence_bonus: int = 0
@export var constitution_bonus: int = 0
@export var luck_bonus: int = 0
@export var willpower_bonus: int = 0

@export_group("Combat")
@export var melee_damage_mult: float = 0.0
@export var ranged_damage_mult: float = 0.0
@export var laser_damage_mult: float = 0.0
@export var summon_damage_mult: float = 0.0
@export var spray_damage_mult: float = 0.0
@export var crit_chance_bonus: float = 0.0
@export var crit_multiplier_bonus: float = 0.0
@export var armor_bonus: int = 0
@export var speed_bonus: float = 0.0
@export var attack_speed_bonus: float = 0.0

@export_group("Special Effects")
@export var effect_name: String = ""
@export var effect_duration: float = 0.0
@export var effect_cooldown: float = 0.0

@export_group("Trade")
@export var soul_cost: int = 5
@export var sell_price: int = 2
@export var max_stack: int = 5
