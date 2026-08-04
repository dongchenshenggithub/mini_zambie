## Upgrade picker — generates attribute-only upgrade options when the player levels up.
## Weapons and equipment are NOT offered here; they come from monster drops
## (see zombie_base._drop_loot + pickup_item.gd). Level-ups are pure stat growth.
class_name UpgradePicker
extends Node

signal upgrade_selected(upgrade_data: Dictionary)

enum UpgradeKind {
	HEALTH, STRENGTH, AGILITY, INTELLIGENCE, CONSTITUTION, LUCK, WILLPOWER,
}

# Attribute upgrade definitions. "attr" maps to a CharacterEntry exported field
# (so apply_upgrade can write the new value back); "label" is the display prefix.
const ATTR_UPGRADES: Array[Dictionary] = [
	{"kind": UpgradeKind.HEALTH, "label": "生命"},
	{"kind": UpgradeKind.STRENGTH, "label": "力量", "attr": "strength"},
	{"kind": UpgradeKind.AGILITY, "label": "敏捷", "attr": "agility"},
	{"kind": UpgradeKind.INTELLIGENCE, "label": "智力", "attr": "intelligence"},
	{"kind": UpgradeKind.CONSTITUTION, "label": "体质", "attr": "constitution"},
	{"kind": UpgradeKind.LUCK, "label": "幸运", "attr": "luck"},
	{"kind": UpgradeKind.WILLPOWER, "label": "意志", "attr": "willpower"},
]


func generate_options(player: Player, count: int = 6) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var attr_pool: Array[Dictionary] = ATTR_UPGRADES.duplicate()
	attr_pool.shuffle()

	for i in range(count):
		# Rotate through every attribute so a full level-up screen always shows
		# a balanced spread of stat boosts (no weapon/equipment options).
		var def: Dictionary = attr_pool[i % attr_pool.size()]
		var value: int = randi_range(2, 6)
		options.append({
			"kind": def["kind"],
			"label": "%s +%d" % [def["label"], value],
			"attr": def.get("attr", ""),
			"value": value,
		})
	return options


func apply_upgrade(upgrade: Dictionary, player: Player) -> void:
	var kind = upgrade["kind"] as int

	match kind:
		UpgradeKind.HEALTH:
			var value: int = int(upgrade.get("value", 2))
			player.stats.max_health += value
			player.heal(float(value))
		_:
			var attr: String = upgrade.get("attr", "")
			var value: int = int(upgrade.get("value", 1))
			if attr != "" and player.character_data:
				player.character_data.set(attr, int(player.character_data.get(attr)) + value)
			player.recompute_combat_stats()
