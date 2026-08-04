extends SceneTree
const DeathScript = preload("res://scripts/gameplay/death_screen.gd")
const VictoryScript = preload("res://scripts/gameplay/victory_screen.gd")

## Both end screens previously blacked out their own text/buttons by setting
## `modulate` on the root Control, and failed to fill stats because the labels
## were nested inside a VBox (get_node_or_null only finds direct children).
## This test asserts each screen:
##  - root is NOT dimmed to black (modulate == white)
##  - has a separate dark overlay child
##  - stats text is filled, buttons exist with the expected labels.
func _initialize() -> void:
	var all_ok = true

	# --- Death screen ---
	var ds = DeathScript.create(1234, 7, 42, 125000, "老兵")
	var ds_mod = ds.modulate == Color(1, 1, 1, 1)
	var ds_overlay = ds._overlay != null
	var ds_stats_ok = (ds._stats_label != null and "最终得分" in ds._stats_label.text and "到达楼层" in ds._stats_label.text)
	var ds_char_ok = (ds._char_label != null and "角色" in ds._char_label.text)
	var ds_btn_ok = (ds._restart_btn != null and ds._restart_btn.text == "重新开始" and ds._quit_btn != null and ds._quit_btn.text == "返回主菜单")
	var ds_ok = ds_mod and ds_overlay and ds_stats_ok and ds_char_ok and ds_btn_ok
	print("VISUAL death: not_dimmed=%s overlay=%s stats_ok=%s char_ok=%s buttons_ok=%s -> %s" % [ds_mod, ds_overlay, ds_stats_ok, ds_char_ok, ds_btn_ok, ds_ok])
	all_ok = all_ok and ds_ok

	# --- Victory screen ---
	var vs = VictoryScript.new()
	vs.set_score(999, 15)
	var vs_mod = vs.modulate == Color(1, 1, 1, 1)
	var vs_overlay = vs._overlay != null
	var vs_score_ok = (vs._score_label != null and "得分" in vs._score_label.text and "到达楼层" in vs._score_label.text)
	var vs_btn_ok = (vs._restart_btn != null and vs._restart_btn.text == "再玩一次" and vs._quit_btn != null and vs._quit_btn.text == "返回主菜单")
	var vs_ok = vs_mod and vs_overlay and vs_score_ok and vs_btn_ok
	print("VISUAL victory: not_dimmed=%s overlay=%s score_ok=%s buttons_ok=%s -> %s" % [vs_mod, vs_overlay, vs_score_ok, vs_btn_ok, vs_ok])
	all_ok = all_ok and vs_ok

	print("SCREEN_VISUAL_TEST %s" % ("PASS" if all_ok else "FAIL"))
	quit()
