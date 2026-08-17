## Shared enumerations across all systems.
## Uses @tool + class_name for type-safe access from other scripts.
class_name GameEnums
extends RefCounted

enum BuildDirection { RANGED, MELEE, SUMMON, SPRAY }
enum AttackType { RANGED, MELEE, SUMMON, SPRAY, LASER, SPRAY_EFFECT }
enum ZombieType { NORMAL, FAST, TANK, SELF_DESTRUCT, MECHA_MUTANT, BIO_SHIELD, NANOMITE, HOLOGRAM, ELITE_BIO_TYRANT, ELITE_MECHA_SOLDIER, ELITE_GENE_FUSION, BOSS_ZOMBIE_KING, BOSS_BIO_TITAN, BOSS_NANO_CORE, BOSS_EXPERIMENT_ALPHA }
enum StatusEffect { NONE, BURN, FREEZE, POISON, STUN, KNOCKBACK, ARMOR_DOWN, SLOW, BLEED }
enum AreaType { STREET, SUPERMARKET, HOTEL, HOSPITAL, PARKING_LOT, BOSS_ROOM }
enum ItemCategory { POTION, SHIELD, XP_CHIP, TELEPORTER, ACCESSORY }
enum WeaponCategory { LIGHT_RANGED, HEAVY_RANGED, MELEE_SHARP, MELEE_BLUNT, HEAVY_MELEE_BLUNT, LIGHT_LASER, HEAVY_LASER, THROWABLE, EXPLOSIVE, SUMMON, SPRAY_EFFECT }
enum FireMode { AUTO, SEMI }  # AUTO=长按连发; SEMI=单发(按的越快射的越快)
enum Rarity { COMMON, UNCOMMON, RARE, EPIC }  # 白、蓝、黄、紫

## Character classes (moved from CharacterData to be accessible globally).
enum CharacterClass {
	VETERAN,
	MECH_MONK,
	CYBER_CULTIVATOR,
	CAT_CAFE_WORKER,
	PROFESSOR,
	ALIEN_SHOOTER,
}
