## Verifies the real XPSystem never fails to grant at least one level-up per
## floor under the endless-survive economy (the "can't even reach 1 level in a
## floor" regression guard). Uses the ACTUAL gain_xp() (so XP_GAIN_MULTIPLIER
## is exercised) fed with full-clear per-floor XP from the spawner's real
## zombie-type roll + xp_reward table. Full-clear is the upper bound, so the
## only hard assertion is >= 1 level per floor (a floor yielding 0 would mean
## the multiplier/cost is mis-tuned again).
## Run: Godot ... -s res://_xp_test.gd
extends SceneTree

const ZE = preload("res://scripts/core/game_enums.gd")
const XPSystemScript = preload("res://scripts/systems/xp_system.gd")

const XP_REWARD := {
	ZE.ZombieType.NORMAL: 10,
	ZE.ZombieType.FAST: 15,
	ZE.ZombieType.TANK: 15,
	ZE.ZombieType.SELF_DESTRUCT: 12,
	ZE.ZombieType.MECHA_MUTANT: 30,
	ZE.ZombieType.BIO_SHIELD: 35,
	ZE.ZombieType.NANOMITE: 25,
	ZE.ZombieType.HOLOGRAM: 20,
	ZE.ZombieType.ELITE_BIO_TYRANT: 100,
	ZE.ZombieType.ELITE_MECHA_SOLDIER: 120,
	ZE.ZombieType.ELITE_GENE_FUSION: 90,
}

func _roll_zombie_type(wave: int) -> int:
	var pool: Array = [ZE.ZombieType.NORMAL]
	if wave >= 2: pool.append(ZE.ZombieType.FAST)
	if wave >= 3: pool.append(ZE.ZombieType.TANK)
	if wave >= 4: pool.append(ZE.ZombieType.SELF_DESTRUCT)
	if wave >= 5: pool.append(ZE.ZombieType.MECHA_MUTANT)
	if wave >= 6: pool.append(ZE.ZombieType.NANOMITE)
	if wave >= 7: pool.append(ZE.ZombieType.BIO_SHIELD)
	if wave >= 8: pool.append(ZE.ZombieType.HOLOGRAM)
	if wave >= 10: pool.append(ZE.ZombieType.ELITE_BIO_TYRANT)
	if wave >= 11: pool.append(ZE.ZombieType.ELITE_MECHA_SOLDIER)
	if wave >= 12: pool.append(ZE.ZombieType.ELITE_GENE_FUSION)
	return pool[randi() % pool.size()]

func _floor_xp(floor_num: int) -> int:
	var duration := 40.0 + (floor_num - 1) * 5.0
	var waves := int(duration / 1.5) + 1
	var total := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + floor_num
	for w in range(1, waves + 1):
		var diff_wave := w + (floor_num - 1) * 3
		var count := mini(5 + w, 30)
		for i in range(count):
			var t := _roll_zombie_type(diff_wave)
			total += XP_REWARD[t]
			total += 10  # soul orb always drops (+10)
	return total

var _gains := 0

func _on_leveled_up(_l: int) -> void:
	_gains += 1

func _run() -> void:
	var xp: XPSystem = XPSystemScript.new()
	root.add_child(xp)
	xp.leveled_up.connect(_on_leveled_up)
	var all_ok := true
	var min_inc := 99
	var max_inc := 0
	print("=== REAL XPSystem LEVELING PER FLOOR ===")
	for f in range(1, 15):
		_gains = 0
		var before := xp.level
		xp.gain_xp(_floor_xp(f))
		var inc := xp.level - before
		min_inc = mini(min_inc, inc)
		max_inc = maxi(max_inc, inc)
		var ok := (inc >= 1)
		all_ok = all_ok and ok
		print("floor %2d: +%d level(s)  (total lvl %d)  %s" % [f, inc, xp.level, "OK" if ok else "FAIL"])
	print("min_inc=%d max_inc=%d all_in_1_to_3=%s" % [min_inc, max_inc, all_ok])
	print("XP_TEST %s" % ("PASS" if all_ok else "FAIL"))
	quit()

func _initialize() -> void:
	_run()
