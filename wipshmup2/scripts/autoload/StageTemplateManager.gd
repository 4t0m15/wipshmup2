extends Node

# StageTemplateManager - Manages stage templates and creation
# Provides easy access to stage definitions by name

var templates: Dictionary = {}

func _ready() -> void:
	print("[StageTemplateManager] Initializing stage templates")
	_register_default_templates()

func _register_default_templates() -> void:
	"""Register default stage templates"""
	
	# Stage 1
	_register_template("stage_1", {
		"stage_name": "Stage 1",
		"stage_number": 1,
		"background_type": "space",
		"music_track": "default",
		"waves": [
			{
				"wave_name": "Opening Wave",
				"enemy_spawns": [
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.5},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 1.0}
				],
				"formation_type": "line"
			},
			{
				"wave_name": "Sine Wave",
				"enemy_spawns": [
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 0.0}
				],
				"formation_type": "none"
			}
		],
		"boss_encounter": {
			"boss_template": "gliath",
			"boss_position": Vector2(160, -50),
			"boss_name": "Gliath",
			"intro_effects": ["screen_shake", "flash"],
			"screen_shake_intensity": 1.0,
			"background_tint": Color(1.1, 0.9, 0.9)
		}
	})
	
	# Stage 2
	_register_template("stage_2", {
		"stage_name": "Stage 2",
		"stage_number": 2,
		"background_type": "space",
		"music_track": "default",
		"waves": [
			{
				"wave_name": "Zigzag Wave",
				"enemy_spawns": [
					{"enemy_type": "zigzag_fighter", "position": Vector2(160, -50), "delay": 0.0}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Formation Wave",
				"enemy_spawns": [
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.0}
				],
				"formation_type": "v_formation",
				"formation_params": {"spacing": 30.0}
			}
		],
		"boss_encounter": {
			"boss_template": "type0",
			"boss_position": Vector2(160, -50),
			"boss_name": "Type0",
			"intro_effects": ["screen_shake", "flash"],
			"screen_shake_intensity": 1.2,
			"background_tint": Color(1.2, 0.8, 0.8)
		}
	})
	
	# Stage 3
	_register_template("stage_3", {
		"stage_name": "Stage 3",
		"stage_number": 3,
		"background_type": "space",
		"music_track": "default",
		"waves": [
			{
				"wave_name": "Dive Wave",
				"enemy_spawns": [
					{"enemy_type": "dive_bomber", "position": Vector2(160, -50), "delay": 0.0}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Heavy Wave",
				"enemy_spawns": [
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.0}
				],
				"formation_type": "arc",
				"formation_params": {"radius": 60.0, "angle": 0.0}
			}
		],
		"boss_encounter": {
			"boss_template": "iron_casket",
			"boss_position": Vector2(160, -50),
			"boss_name": "Iron Casket",
			"intro_effects": ["screen_shake", "flash", "explosion"],
			"screen_shake_intensity": 1.5,
			"background_tint": Color(1.3, 0.7, 0.7),
			"music_pitch": 1.1
		}
	})
	
	print("[StageTemplateManager] Registered ", templates.size(), " stage templates")

func _register_template(template_name: String, template_data: Dictionary) -> void:
	"""Register a new stage template"""
	var template = StageDefinition.new()
	
	# Set basic properties
	template.stage_name = template_data.get("stage_name", template_name)
	template.stage_number = template_data.get("stage_number", 1)
	template.background_type = template_data.get("background_type", "space")
	template.music_track = template_data.get("music_track", "default")
	template.stage_duration = template_data.get("stage_duration", -1.0)
	template.wave_interval = template_data.get("wave_interval", 2.0)
	template.boss_delay = template_data.get("boss_delay", 1.0)
	
	# Set visual effects
	template.background_tint = template_data.get("background_tint", Color.WHITE)
	template.ambient_lighting = template_data.get("ambient_lighting", 1.0)
	# Properly construct typed array for particle_effects
	var effects = template_data.get("particle_effects", [])
	template.particle_effects.clear()
	for effect in effects:
		template.particle_effects.append(effect)
	
	# Create waves
	template.waves.clear()
	var waves_data = template_data.get("waves", [])
	for wave_data in waves_data:
		var wave = WaveDefinition.new()
		wave.wave_name = wave_data.get("wave_name", "Wave")
		wave.wave_duration = wave_data.get("wave_duration", -1.0)
		wave.spawn_interval = wave_data.get("spawn_interval", 0.5)
		wave.formation_type = wave_data.get("formation_type", "none")
		wave.formation_params = wave_data.get("formation_params", {})
		
		# Add enemy spawns
		wave.enemy_spawns.clear()
		var spawns_data = wave_data.get("enemy_spawns", [])
		for spawn_data in spawns_data:
			wave.add_enemy_spawn(
				spawn_data.get("enemy_type", "basic_fighter"),
				spawn_data.get("position", Vector2(160, -50)),
				spawn_data.get("delay", 0.0),
				spawn_data.get("properties", {})
			)
		
		template.waves.append(wave)
	
	# Create boss encounter
	var boss_data = template_data.get("boss_encounter", null)
	if boss_data:
		var boss_encounter = BossEncounter.new()
		boss_encounter.boss_template = boss_data.get("boss_template", "gliath")
		boss_encounter.boss_position = boss_data.get("boss_position", Vector2(160, -50))
		boss_encounter.boss_name = boss_data.get("boss_name", "Boss")
		boss_encounter.intro_duration = boss_data.get("intro_duration", 2.0)
		boss_encounter.outro_duration = boss_data.get("outro_duration", 3.0)
		# Properly construct typed arrays for effects
		var intro_effects_data = boss_data.get("intro_effects", ["screen_shake"])
		boss_encounter.intro_effects.clear()
		for effect in intro_effects_data:
			boss_encounter.intro_effects.append(effect)
		
		var outro_effects_data = boss_data.get("outro_effects", ["explosion"])
		boss_encounter.outro_effects.clear()
		for effect in outro_effects_data:
			boss_encounter.outro_effects.append(effect)
		boss_encounter.background_tint = boss_data.get("background_tint", Color.WHITE)
		boss_encounter.screen_shake_intensity = boss_data.get("screen_shake_intensity", 0.0)
		boss_encounter.music_pitch = boss_data.get("music_pitch", 1.0)
		boss_encounter.behavior_overrides = boss_data.get("behavior_overrides", {})
		template.boss_encounter = boss_encounter
	
	templates[template_name] = template

func get_template(template_name: String) -> StageDefinition:
	"""Get a stage template by name"""
	return templates.get(template_name, null)

func get_stage_by_number(stage_number: int) -> StageDefinition:
	"""Get a stage template by stage number"""
	for template in templates.values():
		if template.stage_number == stage_number:
			return template
	return null

func get_all_template_names() -> Array[String]:
	"""Get all registered template names"""
	return templates.keys()

func has_template(template_name: String) -> bool:
	"""Check if a template exists"""
	return templates.has(template_name)

# Convenience methods for common stages
func get_stage_1() -> StageDefinition:
	return get_template("stage_1")

func get_stage_2() -> StageDefinition:
	return get_template("stage_2")

func get_stage_3() -> StageDefinition:
	return get_template("stage_3")
