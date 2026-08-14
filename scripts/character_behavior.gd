## Abstract base class for character-specific behaviors.
class_name CharacterBehavior
extends RefCounted

var owner: Player = null
var character_entry: CharacterEntry = null


func _init(p_owner: Player, p_entry: CharacterEntry) -> void:
	owner = p_owner
	character_entry = p_entry


func on_player_take_damage(_amount: float) -> void:
	pass


func on_zombie_die(_zombie: ZombieBase) -> void:
	pass


func on_weapon_pickup(_weapon: WeaponBase) -> void:
	pass


func on_parts_pickup(_parts: Node2D) -> void:
	pass


func on_potion_pickup(_potion: Node2D) -> void:
	pass


func on_physics_process(_delta: float) -> void:
	pass


func on_level_up(_new_level: int) -> void:
	pass


func on_boss_enter() -> void:
	pass


func on_floor_clear(_floor: int) -> void:
	pass


## Optional active-ability hook. The GameScene routes the "place_tower" input
## action here so a character (e.g. Professor) can deploy structures. Default
## classes have no active ability, so this is a no-op.
func on_special_ability(_scene: Node2D) -> void:
	pass


func on_player_die() -> void:
	pass
