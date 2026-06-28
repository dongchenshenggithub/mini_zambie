## Factory that creates the correct CharacterBehavior for a given character.
class_name BehaviorFactory
extends RefCounted


static func create_behavior(character_class: int, player: Player, entry: CharacterEntry) -> CharacterBehavior:
	match character_class:
		0:
			var beh = VeteranBehavior.new(player, entry)
			beh.owner = player
			beh.character_entry = entry
			return beh
		1:
			var beh = MechMonkBehavior.new(player, entry)
			beh.owner = player
			beh.character_entry = entry
			return beh
		2:
			var beh = CyberCultivatorBehavior.new(player, entry)
			beh.owner = player
			beh.character_entry = entry
			return beh
		3:
			var beh = CatCafeWorkerBehavior.new(player, entry)
			beh.owner = player
			beh.character_entry = entry
			return beh
		4:
			var beh = ProfessorBehavior.new(player, entry)
			beh.owner = player
			beh.character_entry = entry
			return beh
		5:
			var beh = AlienShooterBehavior.new(player, entry)
			beh.owner = player
			beh.character_entry = entry
			return beh
		_:
			var beh = HumanBehavior.new(player, entry)
			beh.owner = player
			beh.character_entry = entry
			return beh
