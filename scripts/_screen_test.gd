## Verifies the death and victory overlays actually render (full-screen size,
## overlay fills, stats text filled, buttons present) — catches the "added to
## root Viewport so size stays (0,0) and shows nothing" regression.
extends SceneTree

const DeathScript = preload("res://scripts/gameplay/death_screen.gd")
const VictoryScript = preload("res://scripts/gameplay/victory_screen.gd")

func _initialize() -> void:
	# --- Death screen ---
	var ds = DeathScript.create(1234, 7, 42, 125000, "退伍老兵昊京")
	root.add_child(ds)
	await create_timer(0.1).timeout
	var ds_size_ok = ds.size.x > 0 and ds.size.y > 0
	var ds_overlay_ok = (ds._overlay != null and ds._overlay.size.x > 0 and ds._overlay.size.y > 0)
	var ds_text_ok = (ds._stats_label != null and "最终得分" in ds._stats_label.text and "到达楼层" in ds._stats_label.text)
	var ds_char_ok = (ds._char_label != null and ds._char_label.text != "")
	var ds_btn_ok = (ds._restart_btn != null and ds._quit_btn != null)
	print("SCREEN death size_ok=%s overlay_ok=%s text_ok=%s char_ok=%s btn_ok=%s" % [ds_size_ok, ds_overlay_ok, ds_text_ok, ds_char_ok, ds_btn_ok])

	# --- Victory screen ---
	var vs = VictoryScript.new()
	vs.set_score(999, 15)
	root.add_child(vs)
	await create_timer(0.1).timeout
	var vs_size_ok = vs.size.x > 0 and vs.size.y > 0
	var vs_overlay_ok = (vs._overlay != null and vs._overlay.size.x > 0 and vs._overlay.size.y > 0)
	var vs_text_ok = (vs._score_label != null and "得分" in vs._score_label.text and "到达楼层" in vs._score_label.text)
	var vs_btn_ok = (vs._restart_btn != null and vs._quit_btn != null)
	print("SCREEN victory size_ok=%s overlay_ok=%s text_ok=%s btn_ok=%s" % [vs_size_ok, vs_overlay_ok, vs_text_ok, vs_btn_ok])

	var ok = ds_size_ok and ds_overlay_ok and ds_text_ok and ds_char_ok and ds_btn_ok \
		and vs_size_ok and vs_overlay_ok and vs_text_ok and vs_btn_ok
	print("SCREEN_TEST %s" % ("PASS" if ok else "FAIL"))
	quit()
