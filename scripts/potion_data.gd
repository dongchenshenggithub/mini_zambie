## Data resource defining a potion.
## Drop new .tres files into resources/potions/ to add new potions.
class_name PotionData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON

@export_group("Effect")
@export var effect_type: String = "heal"
@export var value: float = 0.3
@export var duration: float = 0.0

@export_group("Trade")
@export var soul_cost: int = 3
@export var sell_price: int = 1
