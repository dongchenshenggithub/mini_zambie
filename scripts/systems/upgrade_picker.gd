## Upgrade picker — generates character-specific upgrade options when player levels up.
class_name UpgradePicker
extends Node

signal upgrade_selected(upgrade_data: Dictionary)

enum UpgradeKind {
	HEALTH, STRENGTH, AGILITY, INTELLIGENCE, CONSTITUTION, LUCK, WILLPOWER,
	WEAPON_DAMAGE, WEAPON_FIRE_RATE, WEAPON_RANGE, ITEM, SOUL_ORB_BONUS,
}

const UPGRADES: Array[Dictionary] = [
	{"kind": UpgradeKind.HEALTH, "label": "生命 +[2~6]", "stat": "max_health", "value": 0.15},
	{"kind": UpgradeKind.STRENGTH, "label": "力量 +[2~6]", "stat": "strength", "value": 1},
	{"kind": UpgradeKind.AGILITY, "label": "敏捷 +[2~6]", "stat": "agility", "value": 1},
	{"kind": UpgradeKind.INTELLIGENCE, "label": "智力 +[2~6]", "stat": "intelligence", "value": 1},
	{"kind": UpgradeKind.CONSTITUTION, "label": "体质 +[2~6]", "stat": "constitution", "value": 1},
	{"kind": UpgradeKind.LUCK, "label": "幸运 +[2~6]", "stat": "luck", "value": 1},
	{"kind": UpgradeKind.WILLPOWER, "label": "意志 +[2~6]", "stat": "willpower", "value": 1},
]


func generate_options(player: Player, count: int = 3) -> Array[Dictionary]:
	var options: Array[Dictionary] = UPGRADES.duplicate()
	var picked: Array[Dictionary] = []
	for i in range(minf(count, options.size())):
		var idx = randi() % options.size()
		picked.append(options[idx])
		options.remove_at(idx)
	return picked


func apply_upgrade(upgrade: Dictionary, player: Player) -> void:
	var kind = upgrade["kind"] as int
	var value = upgrade["value"] as float

	match kind:
		UpgradeKind.HEALTH:
			player.stats.max_health *= (1.0 + value)
			player.stats.current_health = player.stats.max_health
		UpgradeKind.STRENGTH:
			player.character_data.strength += int(value)
		UpgradeKind.AGILITY:
			player.character_data.agility += int(value)
		UpgradeKind.INTELLIGENCE:
			player.character_data.intelligence += int(value)
		UpgradeKind.CONSTITUTION:
			player.character_data.constitution += int(value)
		UpgradeKind.LUCK:
			player.character_data.luck += int(value)
		UpgradeKind.WILLPOWER:
			player.character_data.willpower += int(value)
