## Global sound-effects manager.
## Mirrors the MusicManager pattern: a `class_name` (SfxManager) so it resolves
## as a global identifier in every build context, plus an autoload registered
## under a different name (Sfx) to avoid the "class hides autoload" conflict.
## Plays short one-shot WAVs on a dedicated "SFX" audio bus (created at runtime
## so project.godot needs no fragile bus-layout edit). Safe in headless: if the
## instance isn't up yet, play() simply no-ops.
class_name SfxManager
extends Node

const SOUNDS := {
	"shoot": "res://assets/sfx/shoot.wav",
	"hit": "res://assets/sfx/hit.wav",
	"enemy_die": "res://assets/sfx/enemy_die.wav",
	"pickup": "res://assets/sfx/pickup.wav",
	"levelup": "res://assets/sfx/levelup.wav",
	"player_hurt": "res://assets/sfx/player_hurt.wav",
	"swing": "res://assets/sfx/swing.wav",
	"explosion": "res://assets/sfx/explosion.wav",
	"reload": "res://assets/sfx/reload.wav",
}

static var _instance: SfxManager = null

var _cache: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _max_pool: int = 24


func _ready() -> void:
	_instance = self
	# Create a dedicated SFX bus (separate volume from the Music bus) at runtime.
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")


func _do_load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		return null
	var res = load(path)
	if res == null or not (res is AudioStream):
		return null
	_cache[path] = res
	return res


## Reuse a free player from the pool, growing it up to _max_pool.
func _get_player() -> AudioStreamPlayer:
	for p in _pool:
		if not p.playing:
			return p
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	add_child(p)
	_pool.append(p)
	if _pool.size() > _max_pool:
		var old = _pool.pop_front()
		if old and is_instance_valid(old):
			old.queue_free()
	return p


func _do_play(name: String, pitch_variation: bool = true) -> void:
	if not SOUNDS.has(name):
		return
	var stream = _do_load(SOUNDS[name])
	if stream == null:
		return
	var p = _get_player()
	p.stream = stream
	p.pitch_scale = randf_range(0.9, 1.1) if pitch_variation else 1.0
	p.play()


## Play a one-shot SFX by name. No-op if the manager isn't initialized yet
## (e.g. before the tree is ready) or the sample can't load.
static func play(name: String, pitch_variation: bool = true) -> void:
	if _instance != null:
		_instance._do_play(name, pitch_variation)


static func set_volume_linear(v: float) -> void:
	if _instance == null:
		return
	var idx = AudioServer.get_bus_index("SFX")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(v, 0.0, 1.0)))
