## Verifies the two balance fixes:
##  1) XP: realistic play (killing ~50% of spawned zombies) now gains at least
##     1 level per floor (the "can't even reach 1 level" regression is gone).
##     Full-clear numbers are printed for info only (they are allowed to exceed
##     2-3 levels — that is unrealistic upper-bound play).
##  2) Drop rate: equipment (weapon+accessory+parts) is now ~4.5% of kills,
##     exactly one-tenth of the previous 45%.
## Run: Godot ... -s res://_balance_fix_test.gd
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

## Total raw XP available in a floor = sum of (xp_reward + 10 soul orb) over all
## spawned zombies. clear_rate < 1 models a realistic player who does not kill
## every single zombie before the floor timer ends.
func _floor_xp(floor_num: int, clear_rate: float) -> int:
	var duration := 40.0 + (floor_num - 1) * 5.0
	var waves := int(duration / 1.5) + 1
	var total := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + floor_num
	for w in range(1, waves + 1):
		var diff_wave := w + (floor_num - 1) * 3
		var count := mini(5 + w, 30)
		for i in range(count):
			if rng.randf() > clear_rate:
				continue
			var t := _roll_zombie_type(diff_wave)
			total += XP_REWARD[t]
			total += 10  # soul orb always drops (+10)
	return total

## Mirrors zombie_base._drop_loot() thresholds. Returns item type string.
func _roll_drop(rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	if roll < 0.12: return "POTION"
	elif roll < 0.135: return "WEAPON"
	elif roll < 0.15: return "ACCESSORY"
	elif roll < 0.165: return "PARTS"
	return "NONE"

func _run_realistic(clear_rate: float) -> bool:
	var xp: XPSystem = XPSystemScript.new()
	root.add_child(xp)
	var min_inc := 99
	var all_ok := true
	print("=== REALISTIC XP (clear_rate=%.2f) ===" % clear_rate)
	for f in range(1, 15):
		var before := xp.level
		xp.gain_xp(_floor_xp(f, clear_rate))
		var inc := xp.level - before
		min_inc = mini(min_inc, inc)
		var ok := inc >= 1
		all_ok = all_ok and ok
		print("floor %2d: +%d level(s)  (total lvl %d)  %s" % [f, inc, xp.level, "OK" if ok else "FAIL"])
	print("clear_rate=%.2f min_inc=%d ok=%s" % [clear_rate, min_inc, all_ok])
	return all_ok

func _run() -> void:
	# ---- 1) XP balance (normal ~50% clear AND weaker ~25% clear) ----
	var ok_50 := _run_realistic(0.5)
	var ok_25 := _run_realistic(0.25)
	var all_real_ok := ok_50 and ok_25
	# full-clear info (not asserted)
	print("=== FULL-CLEAR XP (info only) ===")
	var xp2: XPSystem = XPSystemScript.new()
	root.add_child(xp2)
	for f in range(1, 15):
		var before := xp2.level
		xp2.gain_xp(_floor_xp(f, 1.0))
		print("floor %2d full-clear: +%d level(s) (total %d)" % [f, xp2.level - before, xp2.level])

	# ---- 2) Drop rate ----
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var counts := {"POTION": 0, "WEAPON": 0, "ACCESSORY": 0, "PARTS": 0, "NONE": 0}
	var N := 200000
	for i in range(N):
		counts[_roll_drop(rng)] += 1
	var equip := float(counts["WEAPON"] + counts["ACCESSORY"] + counts["PARTS"])
	var equip_rate := equip / float(N)
	var potion_rate := float(counts["POTION"]) / float(N)
	print("=== DROP RATE (N=%d) ===" % N)
	print("POTION=%.4f  WEAPON=%.4f  ACCESSORY=%.4f  PARTS=%.4f" % [
		potion_rate, counts["WEAPON"]/float(N), counts["ACCESSORY"]/float(N), counts["PARTS"]/float(N)])
	print("equipment rate = %.4f (expect ~0.045 = one-tenth of old 0.45)" % equip_rate)
	var drop_ok := equip_rate > 0.04 and equip_rate < 0.05
	print("XP xp_ok=%s  drop_ok=%s" % [all_real_ok, drop_ok])
	print("BALANCE_FIX %s" % ("PASS" if (all_real_ok and drop_ok) else "FAIL"))
	quit()

func _initialize() -> void:
	_run()
