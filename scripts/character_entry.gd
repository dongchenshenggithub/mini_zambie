## Data resource defining a playable character.
## Drop new .tres files into resources/characters/ to add new characters.
class_name CharacterEntry
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var character_class: int = 0
@export var build_direction: int = 0
@export var initial_weapon_id: String = ""

@export_group("Description")
@export var description: String = ""
@export var portrait_path: String = ""

@export_group("Base Stats")
@export var starting_health: float = 100.0
@export var starting_speed: float = 200.0
@export var strength: int = 5
@export var agility: int = 5
@export var intelligence: int = 5
@export var constitution: int = 5
@export var luck: int = 5
@export var willpower: int = 5

@export_group("Combat")
@export var base_followers: int = 1
@export var max_followers: int = 1
@export var can_heal_self: bool = true
@export var heal_rate: float = 0.0
@export var laser_damage_multiplier: float = 1.0
@export var melee_damage_multiplier: float = 1.0
@export var ranged_damage_multiplier: float = 1.0
@export var summon_damage_multiplier: float = 1.0
@export var spray_damage_multiplier: float = 1.0
@export var limb_slots: Array[int] = [2, 3, 4, 5]

@export_group("Unlock Reward")
@export var unlock_reward_id: String = ""
