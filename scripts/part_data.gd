## Data resource defining a repair part.
## Drop new .tres files into resources/parts/ to add new parts.
class_name PartData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON

@export_group("Effect")
@export var repair_amount: float = 20.0
@export var mech_monk_heal: float = 0.05

@export_group("Trade")
@export var soul_cost: int = 1
@export var sell_price: int = 1
