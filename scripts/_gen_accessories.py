# Generate accessory .tres data files so equipment actually applies stat bonuses.
# Mirrors the working res://resources/weapons/rifle.tres format (path-based
# script ext_resource, which the loader resolves correctly).
import os

OUT = "resources/accessories"
SCRIPT = "res://scripts/accessory_data.gd"

# (id, name, category, rarity, fields...)
ACCESSORIES = [
    ("acc_iron_plate", "铁甲护板", "armor", 0,
     {"health_bonus": 10.0, "armor_bonus": 2, "constitution_bonus": 2}),
    ("acc_swift_boots", "疾行靴", "speed", 0,
     {"speed_bonus": 25.0, "agility_bonus": 2}),
    ("acc_vitality_charm", "生机护符", "health", 1,
     {"health_bonus": 45.0, "constitution_bonus": 3}),
    ("acc_power_core", "能量核心", "damage_ranged", 1,
     {"ranged_damage_mult": 0.15, "strength_bonus": 2}),
    ("acc_neural_chip", "神经芯片", "crit", 2,
     {"crit_chance_bonus": 0.12, "intelligence_bonus": 3}),
    ("acc_laser_lens", "激光透镜", "damage_laser", 2,
     {"laser_damage_mult": 0.22, "intelligence_bonus": 2}),
    ("acc_lucky_coin", "幸运币", "luck", 1,
     {"luck_bonus": 4, "crit_chance_bonus": 0.05}),
    ("acc_berserk_ring", "狂暴之戒", "damage_melee", 3,
     {"melee_damage_mult": 0.30, "strength_bonus": 5, "health_bonus": 20.0}),
]

# All numeric fields on AccessoryData, defaulted to 0 so generated files are complete.
ALL_FIELDS = [
    "health_bonus", "strength_bonus", "agility_bonus", "intelligence_bonus",
    "constitution_bonus", "luck_bonus", "willpower_bonus",
    "melee_damage_mult", "ranged_damage_mult", "laser_damage_mult",
    "summon_damage_mult", "spray_damage_mult", "crit_chance_bonus",
    "crit_multiplier_bonus", "armor_bonus", "speed_bonus", "attack_speed_bonus",
]


def fmt(key, val):
    if isinstance(val, bool):
        return "true" if val else "false"
    if isinstance(val, float):
        return ("%.1f" % val)
    if isinstance(val, int):
        return str(val)
    return '"%s"' % val


os.makedirs(OUT, exist_ok=True)
for (aid, name, cat, rarity, fields) in ACCESSORIES:
    full = {f: 0 for f in ALL_FIELDS}
    full.update(fields)
    lines = []
    lines.append('[gd_resource type="Resource" format=3]')
    lines.append("")
    lines.append('[ext_resource type="Script" path="%s" id="1_accessory_data"]' % SCRIPT)
    lines.append("")
    lines.append("[resource]")
    lines.append('script = ExtResource("1_accessory_data")')
    lines.append('id = "%s"' % aid)
    lines.append('name = "%s"' % name)
    lines.append('category = "%s"' % cat)
    lines.append("rarity = %d" % rarity)
    for f in ALL_FIELDS:
        lines.append("%s = %s" % (f, fmt(f, full[f])))
    text = "\n".join(lines) + "\n"
    with open(os.path.join(OUT, aid + ".tres"), "w", encoding="utf-8") as fh:
        fh.write(text)
    print("WROTE", aid + ".tres")

print("DONE")
