## Defines a single prosthetic limb slot on a character.
class_name LimbSlot
extends Resource

@export var slot_name: String = ""
@export var slot_type: int = 0  # 0=head, 1=body, 2=arm_l, 3=arm_r, 4=leg_l, 5=leg_r
@export var base_damage_bonus: float = 0.0
@export var base_health_bonus: float = 0.0
@export var base_speed_bonus: float = 0.0
@export var base_armor_bonus: int = 0
@export var base_crit_bonus: float = 0.0
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON
