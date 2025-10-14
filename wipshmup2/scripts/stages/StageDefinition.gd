extends Resource
class_name StageDefinition

# StageDefinition - Data-driven stage definition
# Replaces hardcoded stage logic with configurable templates

@export var stage_name: String = "Stage"
@export var stage_number: int = 1
@export var background_type: String = "space"
@export var music_track: String = "default"
@export var waves: Array[WaveDefinition] = []
@export var boss_encounter: BossEncounter = null

# Stage timing
@export var stage_duration: float = -1.0  # -1 for infinite
@export var wave_interval: float = 2.0
@export var boss_delay: float = 1.0

# Visual effects
@export var background_tint: Color = Color.WHITE
@export var ambient_lighting: float = 1.0
@export var particle_effects: Array[String] = []

func _init() -> void:
	# Create default wave if none exist
	if waves.is_empty():
		_create_default_wave()

func _create_default_wave() -> void:
	"""Create a default wave for the stage"""
	var wave = WaveDefinition.new()
	wave.wave_name = "Default Wave"
	wave.enemy_spawns.clear()
	wave.enemy_spawns.append({
		"enemy_type": "basic_fighter",
		"position": Vector2(160, -50),
		"delay": 0.0
	})
	waves.append(wave)

func get_wave_count() -> int:
	"""Get the total number of waves"""
	if not waves:
		return 0
	return waves.size()

func get_wave(index: int) -> WaveDefinition:
	"""Get a wave by index"""
	if not waves or waves.is_empty():
		return null
	if index >= 0 and index < waves.size():
		return waves[index]
	return null

func has_boss() -> bool:
	"""Check if stage has a boss encounter"""
	return boss_encounter != null

func get_boss_template() -> String:
	"""Get the boss template name"""
	if boss_encounter:
		return boss_encounter.boss_template
	return ""

func get_boss_position() -> Vector2:
	"""Get the boss spawn position"""
	if boss_encounter:
		return boss_encounter.boss_position
	return Vector2(160, -50)

func apply_stage_effects() -> void:
	"""Apply stage-specific visual and audio effects"""
	# Apply background effects
	EventBus.emit_visual_effect("background_change", {
		"background_type": background_type,
		"tint": background_tint,
		"ambient_lighting": ambient_lighting
	})
	
	# Apply particle effects
	for effect in particle_effects:
		EventBus.emit_visual_effect("particle_effect", {
			"effect_name": effect,
			"duration": -1.0  # Continuous
		})
	
	# Apply music change
	EventBus.emit_audio("music_change", {
		"track": music_track,
		"fade_time": 1.0
	})
	
	print("[StageDefinition] Applied effects for stage: ", stage_name)
