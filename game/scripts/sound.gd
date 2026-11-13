class_name ArcadeSound
extends Node

const SAMPLE_RATE: int = 22050
# At half travel, effects are about 3.5 dB above the original mix.
const VOLUME_GAIN_DB: float = 9.5
const MUSIC_VOLUME_DB: float = -19.0
const Music = preload("res://scripts/music.gd")
var music: AudioStreamPlayer
var music_active: bool = false
var players: Dictionary[String, AudioStreamPlayer] = {}
var muted: bool = false
var volume_percent: float = 50.0
var hit_clock: float = 0.0

func _ready() -> void:
	# Original synthesized PCM effects; no external audio files or dependencies.
	create_effect("shot", [1250.0, 650.0], 0.065, 0.25, -22.0)
	create_effect("hit", [360.0, 180.0], 0.055, 0.45, -25.0)
	create_effect("break", [125.0, 55.0], 0.20, 0.70, -16.0)
	create_effect("reinforce", [523.25, 659.25, 783.99], 0.24, 0.0, -16.0)
	create_effect("loss", [260.0, 130.0], 0.18, 0.22, -18.0)
	create_effect("defeat", [220.0, 164.81, 110.0], 0.55, 0.0, -15.0)
	music = AudioStreamPlayer.new()
	music.stream = Music.build()
	add_child(music)
	update_music()

func set_music_playing(active: bool) -> void:
	music_active = active
	update_music()

func update_music() -> void:
	music.volume_db = MUSIC_VOLUME_DB + VOLUME_GAIN_DB + linear_to_db(maxf(volume_percent / 100.0, 0.0001))
	# Keep the musical position through pause, mute and zero volume.
	if music_active and not music.playing:
		music.play()
	music.stream_paused = not music_active or muted or volume_percent <= 0.0

func create_effect(id: String, notes: Array[float], duration: float, noise_mix: float, volume: float) -> void:
	var data := PackedByteArray()
	var count: int = int(duration * SAMPLE_RATE)
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8241
	var phase: float = 0.0
	for i: int in range(count):
		var progress: float = float(i) / float(count)
		var note_position: float = progress * notes.size()
		var index: int = mini(int(note_position), notes.size() - 1)
		var local: float = note_position - float(index)
		var frequency: float = notes[index]
		phase += TAU * frequency / SAMPLE_RATE
		# Short attack/release for each note avoids clicks at note boundaries.
		var envelope: float = minf(1.0, local * 20.0) * minf(1.0, (1.0 - local) * 10.0)
		envelope *= pow(1.0 - progress, 0.7)
		var sample: float = lerpf(sin(phase), rng.randf_range(-1.0, 1.0), noise_mix) * envelope * 0.65
		data.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.set_meta("base_volume_db", volume)
	player.volume_db = volume + VOLUME_GAIN_DB + linear_to_db(volume_percent / 100.0)
	player.max_polyphony = 3
	add_child(player)
	players[id] = player

func tick(delta: float) -> void:
	hit_clock = maxf(0.0, hit_clock - delta)

func play_effect(id: String) -> void:
	if muted or volume_percent <= 0.0:
		return
	if id == "hit":
		if hit_clock > 0.0:
			return
		hit_clock = 0.07
	players[id].play()

func stop_all() -> void:
	stop_effects()
	music_active = false
	music.stop()

func stop_effects() -> void:
	for player: AudioStreamPlayer in players.values():
		player.stop()
	hit_clock = 0.0

func toggle_mute() -> void:
	muted = not muted
	if muted:
		stop_effects()
	update_music()

func set_volume(percent: float) -> void:
	volume_percent = clampf(percent, 0.0, 100.0)
	for player: AudioStreamPlayer in players.values():
		player.volume_db = float(player.get_meta("base_volume_db")) + VOLUME_GAIN_DB + linear_to_db(maxf(volume_percent / 100.0, 0.0001))
	if volume_percent <= 0.0:
		stop_effects()
	update_music()
