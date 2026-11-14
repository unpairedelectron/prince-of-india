extends Node
## Lightweight audio manager. Autoloaded as "Audio".
## Missing files are skipped with a single warning so placeholder gaps never crash.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL_SIZE := 10

var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _warned := {}
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_ambience = AudioStreamPlayer.new()
	add_child(_ambience)
	apply_volumes.call_deferred()


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	elif not _warned.has(path):
		_warned[path] = true
		push_warning("Audio missing: " + path)
	_cache[path] = s
	return s


func sfx(sound_name: String, pitch_jitter := 0.08, volume_db := 0.0) -> void:
	var s := _load(SFX_DIR + sound_name + ".wav")
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = s
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = volume_db + linear_to_db(maxf(Game.settings.sfx_volume, 0.001))
	p.play()


func play_music(track: String) -> void:
	_play_loop(_music, MUSIC_DIR + track + ".wav", Game.settings.music_volume, -6.0)


func play_ambience(track: String) -> void:
	_play_loop(_ambience, MUSIC_DIR + track + ".wav", Game.settings.sfx_volume, -10.0)


func stop_all_loops() -> void:
	_music.stop()
	_ambience.stop()


func _play_loop(player: AudioStreamPlayer, path: String, vol: float, base_db: float) -> void:
	var s := _load(path)
	if s == null:
		return
	if player.stream == s and player.playing:
		return
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = int(w.data.size() / 2.0)  # 16-bit mono samples
	player.stream = s
	player.volume_db = base_db + linear_to_db(maxf(vol, 0.001))
	player.play()


func apply_volumes() -> void:
	if _music:
		_music.volume_db = -6.0 + linear_to_db(maxf(Game.settings.music_volume, 0.001))
	if _ambience:
		_ambience.volume_db = -10.0 + linear_to_db(maxf(Game.settings.sfx_volume, 0.001))
