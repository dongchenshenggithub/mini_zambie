## Global music manager.
## Mirrors the Game/GameState pattern: the script has a `class_name` so it
## resolves as a global identifier in every build context (including headless
## `-s` regression), while the autoload is registered under a different name
## (`Music`) to avoid the "class hides autoload" conflict. Static methods
## delegate to the running instance; if the instance isn't up yet they no-op
## (keeps headless regression safe and silent).
class_name MusicManager
extends Node

const TRACKS := {
	"menu": "res://assets/music/menu.wav",
	"gameplay": "res://assets/music/gameplay.wav",
	"boss": "res://assets/music/boss.wav",
	"victory": "res://assets/music/victory.wav",
	"death": "res://assets/music/death.wav",
}

static var _instance: MusicManager = null

var _player: AudioStreamPlayer = null
var _cache: Dictionary = {}
var _current: String = ""


func _ready() -> void:
	_instance = self
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = "Master"
	# Autoload nodes pause with the tree, so music naturally stops while the
	# pause menu is up and resumes on unpause — no extra wiring needed.
	add_child(_player)


func _do_load(track: String) -> AudioStream:
	if _cache.has(track):
		return _cache[track]
	if not TRACKS.has(track):
		return null
	var res = load(TRACKS[track])
	if res == null or not (res is AudioStream):
		return null
	_cache[track] = res
	return res


## Switch to `track` (looping). Looping is baked into the imported WAV
## (edit/loop_mode=1 in the .import file), so no runtime loop assignment is
## needed. No-op if already playing it or it can't load.
func _do_play(track: String, _loop: bool) -> void:
	var stream = _do_load(track)
	if stream == null:
		return
	if _current == track and _player.playing:
		return
	_current = track
	_player.stream = stream
	_player.play()


static func play(track: String, loop: bool = true) -> void:
	if _instance != null:
		_instance._do_play(track, loop)


static func stop() -> void:
	if _instance != null:
		_instance._player.stop()
		_instance._current = ""


static func set_volume_linear(v: float) -> void:
	if _instance != null and _instance._player != null:
		_instance._player.volume_db = linear_to_db(clampf(v, 0.0, 1.0))
