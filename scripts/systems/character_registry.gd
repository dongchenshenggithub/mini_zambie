## Registry for all character data resources.
## Characters are loaded from both .tres files AND hardcoded defaults.
class_name CharacterRegistry
extends RefCounted

static var _character_data: Dictionary = {}
static var _character_list: Array[CharacterEntry] = []


static func init() -> void:
	_load_characters_from_tres()
	_load_default_characters()


static func _load_characters_from_tres() -> void:
	pass  # Disabled - using hardcoded defaults


static func _load_default_characters() -> void:
	# Only add if not already loaded from .tres
	var veterans = get_data("veteran")
	if veterans == null:
		var c = _create_veteran()
		_character_data[c.id] = c
		_character_list.append(c)

	var monks = get_data("mech_monk")
	if monks == null:
		var c = _create_mech_monk()
		_character_data[c.id] = c
		_character_list.append(c)

	var cyber = get_data("cyber_cultivator")
	if cyber == null:
		var c = _create_cyber()
		_character_data[c.id] = c
		_character_list.append(c)

	var cat = get_data("cat_cafe_worker")
	if cat == null:
		var c = _create_cat()
		_character_data[c.id] = c
		_character_list.append(c)

	var prof = get_data("professor")
	if prof == null:
		var c = _create_prof()
		_character_data[c.id] = c
		_character_list.append(c)

	var alien = get_data("alien_shooter")
	if alien == null:
		var c = _create_alien()
		_character_data[c.id] = c
		_character_list.append(c)


static func _create_veteran() -> CharacterEntry:
	var c := CharacterEntry.new()
	c.id = "veteran"
	c.name = "退伍老兵昊京"
	c.character_class = 0
	c.build_direction = 0
	c.initial_weapon_id = "rifle"
	c.description = "全能型选手，任何武器都能用。可带2个随从，人类，可缓慢自愈。"
	c.starting_health = 100.0
	c.starting_speed = 200.0
	c.strength = 5; c.agility = 5; c.intelligence = 5
	c.constitution = 5; c.luck = 5; c.willpower = 5
	c.base_followers = 0; c.max_followers = 2
	c.can_heal_self = true; c.heal_rate = 2.0
	c.laser_damage_multiplier = 1.0; c.melee_damage_multiplier = 1.0
	c.ranged_damage_multiplier = 1.0; c.summon_damage_multiplier = 1.0
	c.spray_damage_multiplier = 1.0
	c.limb_slots = [2, 3, 4, 5]
	return c


static func _create_mech_monk() -> CharacterEntry:
	var c := CharacterEntry.new()
	c.id = "mech_monk"
	c.name = "机械武僧"
	c.character_class = 1
	c.build_direction = 1
	c.initial_weapon_id = "chainsaw"
	c.description = "机械人类，无自愈。近战和激光加强，拆武回血。全身义肢可换。"
	c.starting_health = 120.0
	c.starting_speed = 180.0
	c.strength = 7; c.agility = 4; c.intelligence = 5
	c.constitution = 7; c.luck = 5; c.willpower = 5
	c.base_followers = 0; c.max_followers = 2
	c.can_heal_self = false; c.heal_rate = 0.0
	c.laser_damage_multiplier = 1.5; c.melee_damage_multiplier = 1.5
	c.ranged_damage_multiplier = 0.8; c.summon_damage_multiplier = 0.8
	c.spray_damage_multiplier = 0.8
	c.limb_slots = [0, 1, 2, 3, 4, 5]
	return c


static func _create_cyber() -> CharacterEntry:
	var c := CharacterEntry.new()
	c.id = "cyber_cultivator"
	c.name = "赛博修仙者"
	c.character_class = 2
	c.build_direction = 1
	c.initial_weapon_id = "sword"
	c.description = "近战武器可远程投掷并回收，无视障碍。远程武器减弱。"
	c.starting_health = 80.0
	c.starting_speed = 220.0
	c.strength = 6; c.agility = 4; c.intelligence = 6
	c.constitution = 5; c.luck = 5; c.willpower = 5
	c.base_followers = 0; c.max_followers = 2
	c.can_heal_self = true; c.heal_rate = 1.5
	c.laser_damage_multiplier = 1.3; c.melee_damage_multiplier = 1.5
	c.ranged_damage_multiplier = 0.5; c.summon_damage_multiplier = 1.2
	c.spray_damage_multiplier = 1.0
	c.limb_slots = [2, 3, 4, 5]
	return c


static func _create_cat() -> CharacterEntry:
	var c := CharacterEntry.new()
	c.id = "cat_cafe_worker"
	c.name = "猫咖店员"
	c.character_class = 3
	c.build_direction = 2
	c.initial_weapon_ids = ["pistol", "drone"]
	c.initial_weapon_id = "drone"  # fallback if initial_weapon_ids is empty
	c.description = "输出靠随从，可给随从装备武器。随从数量与智力成正比。"
	c.starting_health = 70.0
	c.starting_speed = 190.0
	c.strength = 3; c.agility = 4; c.intelligence = 8
	c.constitution = 4; c.luck = 6; c.willpower = 5
	c.base_followers = 1; c.max_followers = 8
	c.can_heal_self = true; c.heal_rate = 1.0
	c.laser_damage_multiplier = 0.8; c.melee_damage_multiplier = 0.8
	c.ranged_damage_multiplier = 0.8; c.summon_damage_multiplier = 1.5
	c.spray_damage_multiplier = 0.9
	c.limb_slots = [2, 3, 4, 5]
	return c


static func _create_prof() -> CharacterEntry:
	var c := CharacterEntry.new()
	c.id = "professor"
	c.name = "大学教授"
	c.character_class = 4
	c.build_direction = 3
	c.initial_weapon_id = "laser_heal"
	c.description = "激光武器伤害翻倍。可放置固定炮台和治疗塔。"
	c.starting_health = 90.0
	c.starting_speed = 180.0
	c.strength = 4; c.agility = 5; c.intelligence = 8
	c.constitution = 5; c.luck = 5; c.willpower = 7
	c.base_followers = 0; c.max_followers = 2
	c.can_heal_self = true; c.heal_rate = 1.0
	c.laser_damage_multiplier = 2.0; c.melee_damage_multiplier = 0.8
	c.ranged_damage_multiplier = 1.0; c.summon_damage_multiplier = 1.0
	c.spray_damage_multiplier = 1.3
	c.limb_slots = [2, 3, 4, 5]
	return c


static func _create_alien() -> CharacterEntry:
	var c := CharacterEntry.new()
	c.id = "alien_shooter"
	c.name = "外星射手"
	c.character_class = 5
	c.build_direction = 0
	c.initial_weapon_id = "rifle"
	c.description = "章鱼状外星人，4条触手握持武器。远程伤害+50%，吞噬尸块回血。"
	c.starting_health = 60.0
	c.starting_speed = 210.0
	c.strength = 3; c.agility = 8; c.intelligence = 5
	c.constitution = 3; c.luck = 5; c.willpower = 5
	c.base_followers = 0; c.max_followers = 4; c.max_weapons = 4
	c.can_heal_self = false; c.heal_rate = 0.0
	c.laser_damage_multiplier = 1.0; c.melee_damage_multiplier = 0.7
	c.ranged_damage_multiplier = 1.5; c.summon_damage_multiplier = 1.0
	c.spray_damage_multiplier = 0.7
	c.limb_slots = [0]
	return c


static func get_data(id: String) -> CharacterEntry:
	return _character_data.get(id, null)


static func get_all() -> Array[CharacterEntry]:
	return _character_list


static func get_by_class(cls: int) -> CharacterEntry:
	for data in _character_list:
		if data.character_class == cls:
			return data
	return null


static func get_all_by_class(cls: int) -> Array[CharacterEntry]:
	var result: Array[CharacterEntry] = []
	for data in _character_list:
		if data.character_class == cls:
			result.append(data)
	return result
