extends Node

# AudioManager - Centralized sound effects for the shmup game
# Handles all beep boop sound effects

var audio_players: Array[AudioStreamPlayer] = []
var max_concurrent_sounds: int = 32
var current_player_index: int = 0

# Sound effect parameters for procedural generation
const PLAYER_SHOT_FREQ: float = 800.0
const ENEMY_SHOT_FREQ: float = 400.0
const HIT_FREQ: float = 1200.0
const ENEMY_DEATH_FREQ: float = 300.0
const PLAYER_HIT_FREQ: float = 150.0
const BOMB_USE_FREQ: float = 100.0

const SOUND_DURATION: float = 0.1
const SAMPLE_RATE: int = 44100

func _ready() -> void:
	# Create a pool of AudioStreamPlayer nodes for concurrent sounds
	for i in range(max_concurrent_sounds):
		var player = AudioStreamPlayer.new()
		player.volume_db = -10.0  # Slightly quieter so they don't overpower music
		add_child(player)
		audio_players.append(player)

func _generate_beep_sound(frequency: float, duration: float = SOUND_DURATION, volume: float = 0.5) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2) # 2 bytes per sample for 16-bit
	
	# Generate a simple sine wave with envelope
	for i in range(sample_count):
		var time = float(i) / SAMPLE_RATE
		var envelope = 1.0 - (time / duration) # Fade out envelope
		var sample = sin(time * frequency * 2.0 * PI) * envelope * volume
		var sample_16bit = int(sample * 32767.0) # Convert to 16-bit signed integer
		
		# Store as little-endian 16-bit
		data[i * 2] = sample_16bit & 0xFF
		data[i * 2 + 1] = (sample_16bit >> 8) & 0xFF
	
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	stream.stereo = false
	
	return stream

func _get_available_player() -> AudioStreamPlayer:
	# Find an available player (not playing) or use round-robin
	for i in range(max_concurrent_sounds):
		var sound_player = audio_players[current_player_index]
		current_player_index = (current_player_index + 1) % max_concurrent_sounds
		if not sound_player.playing:
			return sound_player
	
	# If all are playing, use the current index anyway (will interrupt)
	current_player_index = (current_player_index + 1) % max_concurrent_sounds
	return audio_players[current_player_index - 1]

func play_sound(frequency: float, duration: float = SOUND_DURATION, volume: float = 0.5) -> void:
	var player = _get_available_player()
	if player:
		var sound = _generate_beep_sound(frequency, duration, volume)
		player.stream = sound
		player.play()

# Specific sound effect functions
func play_player_shot() -> void:
	play_sound(PLAYER_SHOT_FREQ, 0.05, 0.3)

func play_enemy_shot() -> void:
	play_sound(ENEMY_SHOT_FREQ, 0.08, 0.25)

func play_bullet_hit() -> void:
	play_sound(HIT_FREQ, 0.06, 0.4)

func play_enemy_death() -> void:
	# Multi-tone death sound
	play_sound(ENEMY_DEATH_FREQ, 0.15, 0.4)
	# Add a quick higher frequency component
	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func():
		play_sound(ENEMY_DEATH_FREQ * 2.0, 0.1, 0.3)
		timer.queue_free()
	)
	timer.start()

func play_player_hit() -> void:
	# Dramatic low-frequency hit sound
	play_sound(PLAYER_HIT_FREQ, 0.3, 0.6)

func play_bomb_use() -> void:
	# Deep bomb sound with multiple components
	play_sound(BOMB_USE_FREQ, 0.4, 0.5)
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func():
		play_sound(BOMB_USE_FREQ * 1.5, 0.3, 0.4)
		timer.queue_free()
	)
	timer.start()

func play_boss_hit() -> void:
	# Special heavier hit sound for bosses
	play_sound(HIT_FREQ * 0.7, 0.1, 0.5)



func play_extend() -> void:
	# Happy extend jingle
	var notes = [523.25, 659.25, 783.99, 1046.50]  # C5, E5, G5, C6
	for i in range(notes.size()):
		var timer = Timer.new()
		timer.wait_time = i * 0.1
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(func():
			play_sound(notes[i], 0.2, 0.4)
			timer.queue_free()
		)
		timer.start()
