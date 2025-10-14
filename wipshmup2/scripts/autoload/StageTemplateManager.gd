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
		"spawn_interval": 0.15,  # Much faster spawning - was 0.5
		"waves": [
			{
				"wave_name": "Side Pincer Attack",
				"spawn_interval": 0.15,
				"enemy_spawns": [
					# Left side wave
					{"enemy_type": "basic_fighter", "position": Vector2(20, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(20, -50), "delay": 0.15},
					{"enemy_type": "basic_fighter", "position": Vector2(20, -50), "delay": 0.3},
					# Right side wave
					{"enemy_type": "basic_fighter", "position": Vector2(300, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(300, -50), "delay": 0.15},
					{"enemy_type": "basic_fighter", "position": Vector2(300, -50), "delay": 0.3},
					# Center interrupt
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 0.5},
					# Second pincer
					{"enemy_type": "zigzag_fighter", "position": Vector2(40, -50), "delay": 0.8},
					{"enemy_type": "zigzag_fighter", "position": Vector2(280, -50), "delay": 0.8},
					{"enemy_type": "basic_fighter", "position": Vector2(60, -50), "delay": 1.0},
					{"enemy_type": "basic_fighter", "position": Vector2(260, -50), "delay": 1.0}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Weaving Serpent",
				"spawn_interval": 0.12,
				"enemy_spawns": [
					# Snake pattern from left to right
					{"enemy_type": "sine_fighter", "position": Vector2(40, -50), "delay": 0.0},
					{"enemy_type": "sine_fighter", "position": Vector2(80, -50), "delay": 0.15},
					{"enemy_type": "sine_fighter", "position": Vector2(120, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 0.45},
					{"enemy_type": "sine_fighter", "position": Vector2(200, -50), "delay": 0.6},
					{"enemy_type": "sine_fighter", "position": Vector2(240, -50), "delay": 0.75},
					{"enemy_type": "sine_fighter", "position": Vector2(280, -50), "delay": 0.9},
					# Counter-wave from opposite side
					{"enemy_type": "basic_fighter", "position": Vector2(280, -50), "delay": 1.2},
					{"enemy_type": "basic_fighter", "position": Vector2(200, -50), "delay": 1.3},
					{"enemy_type": "basic_fighter", "position": Vector2(120, -50), "delay": 1.4},
					{"enemy_type": "basic_fighter", "position": Vector2(40, -50), "delay": 1.5}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Diamond Formation Rush",
				"spawn_interval": 0.08,
				"enemy_spawns": [
					# Diamond 1 - Center
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(140, -50), "delay": 0.1},
					{"enemy_type": "basic_fighter", "position": Vector2(180, -50), "delay": 0.1},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.2},
					# Diamond 2 - Left offset
					{"enemy_type": "zigzag_fighter", "position": Vector2(80, -50), "delay": 0.5},
					{"enemy_type": "zigzag_fighter", "position": Vector2(60, -50), "delay": 0.6},
					{"enemy_type": "zigzag_fighter", "position": Vector2(100, -50), "delay": 0.6},
					# Diamond 3 - Right offset
					{"enemy_type": "zigzag_fighter", "position": Vector2(240, -50), "delay": 0.5},
					{"enemy_type": "zigzag_fighter", "position": Vector2(220, -50), "delay": 0.6},
					{"enemy_type": "zigzag_fighter", "position": Vector2(260, -50), "delay": 0.6},
					# Cleanup stragglers
					{"enemy_type": "basic_fighter", "position": Vector2(120, -50), "delay": 0.9},
					{"enemy_type": "basic_fighter", "position": Vector2(200, -50), "delay": 0.9}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Cascading Walls",
				"spawn_interval": 0.1,
				"enemy_spawns": [
					# Wall 1 - Left third
					{"enemy_type": "basic_fighter", "position": Vector2(40, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(70, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(100, -50), "delay": 0.0},
					# Wall 2 - Middle third
					{"enemy_type": "basic_fighter", "position": Vector2(130, -50), "delay": 0.3},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.3},
					{"enemy_type": "basic_fighter", "position": Vector2(190, -50), "delay": 0.3},
					# Wall 3 - Right third
					{"enemy_type": "basic_fighter", "position": Vector2(220, -50), "delay": 0.6},
					{"enemy_type": "basic_fighter", "position": Vector2(250, -50), "delay": 0.6},
					{"enemy_type": "basic_fighter", "position": Vector2(280, -50), "delay": 0.6},
					# Interrupters
					{"enemy_type": "sine_fighter", "position": Vector2(80, -50), "delay": 0.9},
					{"enemy_type": "sine_fighter", "position": Vector2(240, -50), "delay": 0.9}
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
		"spawn_interval": 0.12,
		"waves": [
			{
				"wave_name": "Crisscross Pattern",
				"spawn_interval": 0.1,
				"enemy_spawns": [
					# Left to right diagonal
					{"enemy_type": "zigzag_fighter", "position": Vector2(20, -50), "delay": 0.0},
					{"enemy_type": "zigzag_fighter", "position": Vector2(80, -50), "delay": 0.15},
					{"enemy_type": "zigzag_fighter", "position": Vector2(140, -50), "delay": 0.3},
					{"enemy_type": "zigzag_fighter", "position": Vector2(200, -50), "delay": 0.45},
					{"enemy_type": "zigzag_fighter", "position": Vector2(260, -50), "delay": 0.6},
					# Right to left diagonal (offset timing)
					{"enemy_type": "zigzag_fighter", "position": Vector2(300, -50), "delay": 0.3},
					{"enemy_type": "zigzag_fighter", "position": Vector2(240, -50), "delay": 0.45},
					{"enemy_type": "zigzag_fighter", "position": Vector2(180, -50), "delay": 0.6},
					{"enemy_type": "zigzag_fighter", "position": Vector2(120, -50), "delay": 0.75},
					{"enemy_type": "zigzag_fighter", "position": Vector2(60, -50), "delay": 0.9},
					# Fill the gaps
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 1.1},
					{"enemy_type": "basic_fighter", "position": Vector2(100, -50), "delay": 1.2},
					{"enemy_type": "basic_fighter", "position": Vector2(220, -50), "delay": 1.2}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Rotating Spokes",
				"spawn_interval": 0.09,
				"enemy_spawns": [
					# Spoke 1 - Top center
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.1},
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 0.2},
					# Spoke 2 - Upper left
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.3},
					{"enemy_type": "basic_fighter", "position": Vector2(60, -50), "delay": 0.4},
					# Spoke 3 - Upper right
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 0.3},
					{"enemy_type": "basic_fighter", "position": Vector2(260, -50), "delay": 0.4},
					# Spoke 4 - Left
					{"enemy_type": "sine_fighter", "position": Vector2(40, -50), "delay": 0.6},
					{"enemy_type": "basic_fighter", "position": Vector2(30, -50), "delay": 0.7},
					# Spoke 5 - Right
					{"enemy_type": "sine_fighter", "position": Vector2(280, -50), "delay": 0.6},
					{"enemy_type": "basic_fighter", "position": Vector2(290, -50), "delay": 0.7},
					# Center dive bombers
					{"enemy_type": "dive_bomber", "position": Vector2(140, -50), "delay": 0.9},
					{"enemy_type": "dive_bomber", "position": Vector2(180, -50), "delay": 0.9},
					# Heavy cleanup
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 1.2}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Alternating Columns",
				"spawn_interval": 0.07,
				"enemy_spawns": [
					# Column 1 - Far left
					{"enemy_type": "basic_fighter", "position": Vector2(40, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(40, -50), "delay": 0.2},
					{"enemy_type": "sine_fighter", "position": Vector2(40, -50), "delay": 0.4},
					# Column 2 - Left center
					{"enemy_type": "basic_fighter", "position": Vector2(110, -50), "delay": 0.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(110, -50), "delay": 0.3},
					{"enemy_type": "basic_fighter", "position": Vector2(110, -50), "delay": 0.5},
					# Column 3 - Right center
					{"enemy_type": "basic_fighter", "position": Vector2(210, -50), "delay": 0.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(210, -50), "delay": 0.3},
					{"enemy_type": "basic_fighter", "position": Vector2(210, -50), "delay": 0.5},
					# Column 4 - Far right
					{"enemy_type": "basic_fighter", "position": Vector2(280, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(280, -50), "delay": 0.2},
					{"enemy_type": "sine_fighter", "position": Vector2(280, -50), "delay": 0.4},
					# Dive bombers through the middle
					{"enemy_type": "dive_bomber", "position": Vector2(160, -50), "delay": 0.7},
					{"enemy_type": "dive_bomber", "position": Vector2(160, -50), "delay": 0.9}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Expanding Rings",
				"spawn_interval": 0.08,
				"enemy_spawns": [
					# Inner ring - 4 enemies
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 0.0},
					{"enemy_type": "sine_fighter", "position": Vector2(120, -50), "delay": 0.05},
					{"enemy_type": "sine_fighter", "position": Vector2(200, -50), "delay": 0.05},
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 0.1},
					# Middle ring - 6 enemies
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.4},
					{"enemy_type": "basic_fighter", "position": Vector2(120, -50), "delay": 0.45},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.5},
					{"enemy_type": "basic_fighter", "position": Vector2(200, -50), "delay": 0.45},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 0.4},
					# Outer ring - 8 enemies
					{"enemy_type": "zigzag_fighter", "position": Vector2(40, -50), "delay": 0.8},
					{"enemy_type": "zigzag_fighter", "position": Vector2(90, -50), "delay": 0.85},
					{"enemy_type": "zigzag_fighter", "position": Vector2(140, -50), "delay": 0.9},
					{"enemy_type": "zigzag_fighter", "position": Vector2(180, -50), "delay": 0.9},
					{"enemy_type": "zigzag_fighter", "position": Vector2(230, -50), "delay": 0.85},
					{"enemy_type": "zigzag_fighter", "position": Vector2(280, -50), "delay": 0.8}
				],
				"formation_type": "none"
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
		"spawn_interval": 0.1,
		"waves": [
			{
				"wave_name": "Bomber Wing Formation",
				"spawn_interval": 0.08,
				"enemy_spawns": [
					# Lead bomber with escort
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(140, -50), "delay": 0.1},
					{"enemy_type": "basic_fighter", "position": Vector2(180, -50), "delay": 0.1},
					# Dive bomber strike from sides
					{"enemy_type": "dive_bomber", "position": Vector2(40, -50), "delay": 0.3},
					{"enemy_type": "dive_bomber", "position": Vector2(280, -50), "delay": 0.3},
					{"enemy_type": "dive_bomber", "position": Vector2(80, -50), "delay": 0.5},
					{"enemy_type": "dive_bomber", "position": Vector2(240, -50), "delay": 0.5},
					# Second wave - heavier
					{"enemy_type": "heavy_bomber", "position": Vector2(100, -50), "delay": 0.8},
					{"enemy_type": "heavy_bomber", "position": Vector2(220, -50), "delay": 0.8},
					{"enemy_type": "sine_fighter", "position": Vector2(60, -50), "delay": 1.0},
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 1.0},
					{"enemy_type": "sine_fighter", "position": Vector2(260, -50), "delay": 1.0},
					# Cleanup strike
					{"enemy_type": "zigzag_fighter", "position": Vector2(120, -50), "delay": 1.3},
					{"enemy_type": "zigzag_fighter", "position": Vector2(200, -50), "delay": 1.3}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Pinwheel Assault",
				"spawn_interval": 0.06,
				"enemy_spawns": [
					# Center pivot
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.0},
					# First rotation - 4 arms
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.15},
					{"enemy_type": "sine_fighter", "position": Vector2(100, -50), "delay": 0.15},
					{"enemy_type": "sine_fighter", "position": Vector2(220, -50), "delay": 0.15},
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.25},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 0.25},
					# Second rotation - offset 45 degrees
					{"enemy_type": "zigzag_fighter", "position": Vector2(130, -50), "delay": 0.4},
					{"enemy_type": "zigzag_fighter", "position": Vector2(190, -50), "delay": 0.4},
					{"enemy_type": "zigzag_fighter", "position": Vector2(60, -50), "delay": 0.5},
					{"enemy_type": "zigzag_fighter", "position": Vector2(260, -50), "delay": 0.5},
					# Dive bomber burst
					{"enemy_type": "dive_bomber", "position": Vector2(40, -50), "delay": 0.7},
					{"enemy_type": "dive_bomber", "position": Vector2(120, -50), "delay": 0.75},
					{"enemy_type": "dive_bomber", "position": Vector2(200, -50), "delay": 0.75},
					{"enemy_type": "dive_bomber", "position": Vector2(280, -50), "delay": 0.7},
					# Final heavy wave
					{"enemy_type": "heavy_bomber", "position": Vector2(80, -50), "delay": 1.0},
					{"enemy_type": "heavy_bomber", "position": Vector2(240, -50), "delay": 1.0}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Interlocking Gears",
				"spawn_interval": 0.05,
				"enemy_spawns": [
					# Gear 1 - Left side rotating
					{"enemy_type": "sine_fighter", "position": Vector2(60, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.1},
					{"enemy_type": "sine_fighter", "position": Vector2(100, -50), "delay": 0.2},
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(60, -50), "delay": 0.4},
					# Gear 2 - Right side counter-rotating
					{"enemy_type": "sine_fighter", "position": Vector2(260, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 0.1},
					{"enemy_type": "sine_fighter", "position": Vector2(220, -50), "delay": 0.2},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(260, -50), "delay": 0.4},
					# Center teeth
					{"enemy_type": "zigzag_fighter", "position": Vector2(140, -50), "delay": 0.5},
					{"enemy_type": "zigzag_fighter", "position": Vector2(160, -50), "delay": 0.55},
					{"enemy_type": "zigzag_fighter", "position": Vector2(180, -50), "delay": 0.6},
					# Heavy assault through the gears
					{"enemy_type": "dive_bomber", "position": Vector2(120, -50), "delay": 0.8},
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.85},
					{"enemy_type": "dive_bomber", "position": Vector2(200, -50), "delay": 0.9},
					# Final chaos
					{"enemy_type": "basic_fighter", "position": Vector2(40, -50), "delay": 1.1},
					{"enemy_type": "basic_fighter", "position": Vector2(280, -50), "delay": 1.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(100, -50), "delay": 1.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(220, -50), "delay": 1.2}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Converging Storm",
				"spawn_interval": 0.05,
				"enemy_spawns": [
					# Top left converge
					{"enemy_type": "basic_fighter", "position": Vector2(20, -50), "delay": 0.0},
					{"enemy_type": "sine_fighter", "position": Vector2(40, -50), "delay": 0.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(60, -50), "delay": 0.2},
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.3},
					# Top right converge
					{"enemy_type": "basic_fighter", "position": Vector2(300, -50), "delay": 0.0},
					{"enemy_type": "sine_fighter", "position": Vector2(280, -50), "delay": 0.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(260, -50), "delay": 0.2},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 0.3},
					# Center collision point - heavy units
					{"enemy_type": "heavy_bomber", "position": Vector2(140, -50), "delay": 0.5},
					{"enemy_type": "heavy_bomber", "position": Vector2(180, -50), "delay": 0.5},
					{"enemy_type": "dive_bomber", "position": Vector2(160, -50), "delay": 0.6},
					# Outer spiral
					{"enemy_type": "sine_fighter", "position": Vector2(30, -50), "delay": 0.8},
					{"enemy_type": "sine_fighter", "position": Vector2(100, -50), "delay": 0.85},
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 0.9},
					{"enemy_type": "sine_fighter", "position": Vector2(220, -50), "delay": 0.85},
					{"enemy_type": "sine_fighter", "position": Vector2(290, -50), "delay": 0.8},
					# Final bombardment
					{"enemy_type": "dive_bomber", "position": Vector2(80, -50), "delay": 1.1},
					{"enemy_type": "dive_bomber", "position": Vector2(120, -50), "delay": 1.15},
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 1.2},
					{"enemy_type": "dive_bomber", "position": Vector2(200, -50), "delay": 1.15},
					{"enemy_type": "dive_bomber", "position": Vector2(240, -50), "delay": 1.1}
				],
				"formation_type": "none"
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
	
	# Stage 4 - Asteroid Field
	_register_template("stage_4", {
		"stage_name": "Stage 4 - Asteroid Field",
		"stage_number": 4,
		"background_type": "asteroid_field",
		"music_track": "tense",
		"spawn_interval": 0.08,
		"waves": [
			{
				"wave_name": "Asteroid Swarm",
				"spawn_interval": 0.06,
				"enemy_spawns": [
					# Large asteroid with escorts
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(140, -50), "delay": 0.1},
					{"enemy_type": "basic_fighter", "position": Vector2(180, -50), "delay": 0.1},
					{"enemy_type": "sine_fighter", "position": Vector2(120, -50), "delay": 0.2},
					{"enemy_type": "sine_fighter", "position": Vector2(200, -50), "delay": 0.2},
					# Side asteroids
					{"enemy_type": "zigzag_fighter", "position": Vector2(60, -50), "delay": 0.4},
					{"enemy_type": "zigzag_fighter", "position": Vector2(260, -50), "delay": 0.4},
					{"enemy_type": "dive_bomber", "position": Vector2(100, -50), "delay": 0.6},
					{"enemy_type": "dive_bomber", "position": Vector2(220, -50), "delay": 0.6},
					# Second wave
					{"enemy_type": "heavy_bomber", "position": Vector2(80, -50), "delay": 1.0},
					{"enemy_type": "heavy_bomber", "position": Vector2(240, -50), "delay": 1.0},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 1.2}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Meteor Shower",
				"spawn_interval": 0.05,
				"enemy_spawns": [
					# Rapid fire from multiple angles
					{"enemy_type": "basic_fighter", "position": Vector2(40, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.1},
					{"enemy_type": "basic_fighter", "position": Vector2(120, -50), "delay": 0.2},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.3},
					{"enemy_type": "basic_fighter", "position": Vector2(200, -50), "delay": 0.4},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 0.5},
					{"enemy_type": "basic_fighter", "position": Vector2(280, -50), "delay": 0.6},
					# Counter-wave
					{"enemy_type": "sine_fighter", "position": Vector2(280, -50), "delay": 0.8},
					{"enemy_type": "sine_fighter", "position": Vector2(240, -50), "delay": 0.9},
					{"enemy_type": "sine_fighter", "position": Vector2(200, -50), "delay": 1.0},
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 1.1},
					{"enemy_type": "sine_fighter", "position": Vector2(120, -50), "delay": 1.2},
					{"enemy_type": "sine_fighter", "position": Vector2(80, -50), "delay": 1.3},
					{"enemy_type": "sine_fighter", "position": Vector2(40, -50), "delay": 1.4},
					# Heavy finale
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 1.6},
					{"enemy_type": "dive_bomber", "position": Vector2(100, -50), "delay": 1.7},
					{"enemy_type": "dive_bomber", "position": Vector2(220, -50), "delay": 1.7}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Asteroid Belt",
				"spawn_interval": 0.04,
				"enemy_spawns": [
					# Dense formation
					{"enemy_type": "zigzag_fighter", "position": Vector2(50, -50), "delay": 0.0},
					{"enemy_type": "zigzag_fighter", "position": Vector2(70, -50), "delay": 0.05},
					{"enemy_type": "zigzag_fighter", "position": Vector2(90, -50), "delay": 0.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(110, -50), "delay": 0.15},
					{"enemy_type": "zigzag_fighter", "position": Vector2(130, -50), "delay": 0.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(150, -50), "delay": 0.25},
					{"enemy_type": "zigzag_fighter", "position": Vector2(170, -50), "delay": 0.3},
					{"enemy_type": "zigzag_fighter", "position": Vector2(190, -50), "delay": 0.35},
					{"enemy_type": "zigzag_fighter", "position": Vector2(210, -50), "delay": 0.4},
					{"enemy_type": "zigzag_fighter", "position": Vector2(230, -50), "delay": 0.45},
					{"enemy_type": "zigzag_fighter", "position": Vector2(250, -50), "delay": 0.5},
					{"enemy_type": "zigzag_fighter", "position": Vector2(270, -50), "delay": 0.55},
					# Heavy units mixed in
					{"enemy_type": "heavy_bomber", "position": Vector2(100, -50), "delay": 0.7},
					{"enemy_type": "heavy_bomber", "position": Vector2(220, -50), "delay": 0.7},
					{"enemy_type": "dive_bomber", "position": Vector2(160, -50), "delay": 0.8}
				],
				"formation_type": "none"
			}
		],
		"boss_encounter": {
			"boss_template": "fortress",
			"boss_position": Vector2(160, -50),
			"boss_name": "Fortress",
			"intro_effects": ["screen_shake", "flash", "explosion"],
			"screen_shake_intensity": 1.3,
			"background_tint": Color(0.8, 1.0, 0.8),
			"music_pitch": 0.9
		}
	})
	
	# Stage 5 - Nebula
	_register_template("stage_5", {
		"stage_name": "Stage 5 - Nebula",
		"stage_number": 5,
		"background_type": "nebula",
		"music_track": "mysterious",
		"spawn_interval": 0.07,
		"waves": [
			{
				"wave_name": "Phantom Squadron",
				"spawn_interval": 0.06,
				"enemy_spawns": [
					# Ghostly formation
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 0.0},
					{"enemy_type": "sine_fighter", "position": Vector2(120, -50), "delay": 0.1},
					{"enemy_type": "sine_fighter", "position": Vector2(200, -50), "delay": 0.1},
					{"enemy_type": "sine_fighter", "position": Vector2(80, -50), "delay": 0.2},
					{"enemy_type": "sine_fighter", "position": Vector2(240, -50), "delay": 0.2},
					{"enemy_type": "sine_fighter", "position": Vector2(40, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(280, -50), "delay": 0.3},
					# Dive bombers through the formation
					{"enemy_type": "dive_bomber", "position": Vector2(100, -50), "delay": 0.5},
					{"enemy_type": "dive_bomber", "position": Vector2(160, -50), "delay": 0.6},
					{"enemy_type": "dive_bomber", "position": Vector2(220, -50), "delay": 0.7},
					# Heavy phantom
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.9},
					{"enemy_type": "zigzag_fighter", "position": Vector2(140, -50), "delay": 1.0},
					{"enemy_type": "zigzag_fighter", "position": Vector2(180, -50), "delay": 1.0}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Nebula Storm",
				"spawn_interval": 0.05,
				"enemy_spawns": [
					# Chaotic storm pattern
					{"enemy_type": "zigzag_fighter", "position": Vector2(60, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(100, -50), "delay": 0.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(140, -50), "delay": 0.2},
					{"enemy_type": "basic_fighter", "position": Vector2(180, -50), "delay": 0.3},
					{"enemy_type": "zigzag_fighter", "position": Vector2(220, -50), "delay": 0.4},
					{"enemy_type": "basic_fighter", "position": Vector2(260, -50), "delay": 0.5},
					# Counter-chaos
					{"enemy_type": "sine_fighter", "position": Vector2(40, -50), "delay": 0.7},
					{"enemy_type": "sine_fighter", "position": Vector2(80, -50), "delay": 0.8},
					{"enemy_type": "sine_fighter", "position": Vector2(120, -50), "delay": 0.9},
					{"enemy_type": "sine_fighter", "position": Vector2(160, -50), "delay": 1.0},
					{"enemy_type": "sine_fighter", "position": Vector2(200, -50), "delay": 1.1},
					{"enemy_type": "sine_fighter", "position": Vector2(240, -50), "delay": 1.2},
					{"enemy_type": "sine_fighter", "position": Vector2(280, -50), "delay": 1.3},
					# Heavy storm
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 1.5},
					{"enemy_type": "dive_bomber", "position": Vector2(100, -50), "delay": 1.6},
					{"enemy_type": "dive_bomber", "position": Vector2(220, -50), "delay": 1.6}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Void Rift",
				"spawn_interval": 0.04,
				"enemy_spawns": [
					# Spiral from center
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(140, -50), "delay": 0.1},
					{"enemy_type": "basic_fighter", "position": Vector2(180, -50), "delay": 0.1},
					{"enemy_type": "basic_fighter", "position": Vector2(120, -50), "delay": 0.2},
					{"enemy_type": "basic_fighter", "position": Vector2(200, -50), "delay": 0.2},
					{"enemy_type": "basic_fighter", "position": Vector2(100, -50), "delay": 0.3},
					{"enemy_type": "basic_fighter", "position": Vector2(220, -50), "delay": 0.3},
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.4},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 0.4},
					{"enemy_type": "basic_fighter", "position": Vector2(60, -50), "delay": 0.5},
					{"enemy_type": "basic_fighter", "position": Vector2(260, -50), "delay": 0.5},
					{"enemy_type": "basic_fighter", "position": Vector2(40, -50), "delay": 0.6},
					{"enemy_type": "basic_fighter", "position": Vector2(280, -50), "delay": 0.6},
					# Heavy void entities
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.8},
					{"enemy_type": "heavy_bomber", "position": Vector2(120, -50), "delay": 0.9},
					{"enemy_type": "heavy_bomber", "position": Vector2(200, -50), "delay": 0.9},
					{"enemy_type": "dive_bomber", "position": Vector2(80, -50), "delay": 1.0},
					{"enemy_type": "dive_bomber", "position": Vector2(240, -50), "delay": 1.0}
				],
				"formation_type": "none"
			}
		],
		"boss_encounter": {
			"boss_template": "grafzeppelin",
			"boss_position": Vector2(160, -50),
			"boss_name": "Graf Zeppelin",
			"intro_effects": ["screen_shake", "flash", "explosion"],
			"screen_shake_intensity": 1.4,
			"background_tint": Color(0.7, 0.8, 1.2),
			"music_pitch": 1.1
		}
	})
	
	# Stage 6 - Space Station
	_register_template("stage_6", {
		"stage_name": "Stage 6 - Space Station",
		"stage_number": 6,
		"background_type": "space_station",
		"music_track": "industrial",
		"spawn_interval": 0.06,
		"waves": [
			{
				"wave_name": "Defense Grid",
				"spawn_interval": 0.05,
				"enemy_spawns": [
					# Grid pattern
					{"enemy_type": "basic_fighter", "position": Vector2(40, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(120, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(200, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(280, -50), "delay": 0.0},
					# Second row
					{"enemy_type": "sine_fighter", "position": Vector2(60, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(100, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(140, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(180, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(220, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(260, -50), "delay": 0.3},
					# Heavy units
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.6},
					{"enemy_type": "dive_bomber", "position": Vector2(120, -50), "delay": 0.7},
					{"enemy_type": "dive_bomber", "position": Vector2(200, -50), "delay": 0.7}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Turret Assault",
				"spawn_interval": 0.04,
				"enemy_spawns": [
					# Turret positions
					{"enemy_type": "zigzag_fighter", "position": Vector2(50, -50), "delay": 0.0},
					{"enemy_type": "zigzag_fighter", "position": Vector2(100, -50), "delay": 0.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(150, -50), "delay": 0.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(200, -50), "delay": 0.3},
					{"enemy_type": "zigzag_fighter", "position": Vector2(250, -50), "delay": 0.4},
					{"enemy_type": "zigzag_fighter", "position": Vector2(300, -50), "delay": 0.5},
					# Counter-attack
					{"enemy_type": "basic_fighter", "position": Vector2(40, -50), "delay": 0.7},
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.8},
					{"enemy_type": "basic_fighter", "position": Vector2(120, -50), "delay": 0.9},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 1.0},
					{"enemy_type": "basic_fighter", "position": Vector2(200, -50), "delay": 1.1},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 1.2},
					{"enemy_type": "basic_fighter", "position": Vector2(280, -50), "delay": 1.3},
					# Heavy turrets
					{"enemy_type": "heavy_bomber", "position": Vector2(100, -50), "delay": 1.5},
					{"enemy_type": "heavy_bomber", "position": Vector2(220, -50), "delay": 1.5},
					{"enemy_type": "dive_bomber", "position": Vector2(160, -50), "delay": 1.6}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Station Breach",
				"spawn_interval": 0.03,
				"enemy_spawns": [
					# Breach pattern
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(120, -50), "delay": 0.05},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.1},
					{"enemy_type": "basic_fighter", "position": Vector2(200, -50), "delay": 0.15},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 0.2},
					# Reinforcements
					{"enemy_type": "sine_fighter", "position": Vector2(60, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(100, -50), "delay": 0.35},
					{"enemy_type": "sine_fighter", "position": Vector2(140, -50), "delay": 0.4},
					{"enemy_type": "sine_fighter", "position": Vector2(180, -50), "delay": 0.45},
					{"enemy_type": "sine_fighter", "position": Vector2(220, -50), "delay": 0.5},
					{"enemy_type": "sine_fighter", "position": Vector2(260, -50), "delay": 0.55},
					# Heavy breach
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.7},
					{"enemy_type": "dive_bomber", "position": Vector2(120, -50), "delay": 0.8},
					{"enemy_type": "dive_bomber", "position": Vector2(200, -50), "delay": 0.8},
					{"enemy_type": "zigzag_fighter", "position": Vector2(80, -50), "delay": 0.9},
					{"enemy_type": "zigzag_fighter", "position": Vector2(240, -50), "delay": 0.9}
				],
				"formation_type": "none"
			}
		],
		"boss_encounter": {
			"boss_template": "blockade",
			"boss_position": Vector2(160, -50),
			"boss_name": "Blockade",
			"intro_effects": ["screen_shake", "flash", "explosion"],
			"screen_shake_intensity": 1.5,
			"background_tint": Color(1.1, 0.9, 0.9),
			"music_pitch": 1.2
		}
	})
	
	# Stage 7 - Deep Space
	_register_template("stage_7", {
		"stage_name": "Stage 7 - Deep Space",
		"stage_number": 7,
		"background_type": "deep_space",
		"music_track": "epic",
		"spawn_interval": 0.05,
		"waves": [
			{
				"wave_name": "Void Hunters",
				"spawn_interval": 0.04,
				"enemy_spawns": [
					# Elite formation
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.0},
					{"enemy_type": "heavy_bomber", "position": Vector2(120, -50), "delay": 0.1},
					{"enemy_type": "heavy_bomber", "position": Vector2(200, -50), "delay": 0.1},
					{"enemy_type": "dive_bomber", "position": Vector2(80, -50), "delay": 0.2},
					{"enemy_type": "dive_bomber", "position": Vector2(240, -50), "delay": 0.2},
					{"enemy_type": "sine_fighter", "position": Vector2(60, -50), "delay": 0.3},
					{"enemy_type": "sine_fighter", "position": Vector2(260, -50), "delay": 0.3},
					{"enemy_type": "zigzag_fighter", "position": Vector2(40, -50), "delay": 0.4},
					{"enemy_type": "zigzag_fighter", "position": Vector2(280, -50), "delay": 0.4},
					# Elite escorts
					{"enemy_type": "basic_fighter", "position": Vector2(100, -50), "delay": 0.5},
					{"enemy_type": "basic_fighter", "position": Vector2(140, -50), "delay": 0.5},
					{"enemy_type": "basic_fighter", "position": Vector2(180, -50), "delay": 0.5},
					{"enemy_type": "basic_fighter", "position": Vector2(220, -50), "delay": 0.5}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Cosmic Storm",
				"spawn_interval": 0.03,
				"enemy_spawns": [
					# Storm pattern
					{"enemy_type": "zigzag_fighter", "position": Vector2(40, -50), "delay": 0.0},
					{"enemy_type": "zigzag_fighter", "position": Vector2(80, -50), "delay": 0.05},
					{"enemy_type": "zigzag_fighter", "position": Vector2(120, -50), "delay": 0.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(160, -50), "delay": 0.15},
					{"enemy_type": "zigzag_fighter", "position": Vector2(200, -50), "delay": 0.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(240, -50), "delay": 0.25},
					{"enemy_type": "zigzag_fighter", "position": Vector2(280, -50), "delay": 0.3},
					# Counter-storm
					{"enemy_type": "sine_fighter", "position": Vector2(60, -50), "delay": 0.4},
					{"enemy_type": "sine_fighter", "position": Vector2(100, -50), "delay": 0.45},
					{"enemy_type": "sine_fighter", "position": Vector2(140, -50), "delay": 0.5},
					{"enemy_type": "sine_fighter", "position": Vector2(180, -50), "delay": 0.55},
					{"enemy_type": "sine_fighter", "position": Vector2(220, -50), "delay": 0.6},
					{"enemy_type": "sine_fighter", "position": Vector2(260, -50), "delay": 0.65},
					# Heavy storm
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.8},
					{"enemy_type": "dive_bomber", "position": Vector2(120, -50), "delay": 0.9},
					{"enemy_type": "dive_bomber", "position": Vector2(200, -50), "delay": 0.9}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Void Convergence",
				"spawn_interval": 0.02,
				"enemy_spawns": [
					# Converging pattern
					{"enemy_type": "basic_fighter", "position": Vector2(20, -50), "delay": 0.0},
					{"enemy_type": "basic_fighter", "position": Vector2(60, -50), "delay": 0.1},
					{"enemy_type": "basic_fighter", "position": Vector2(100, -50), "delay": 0.2},
					{"enemy_type": "basic_fighter", "position": Vector2(140, -50), "delay": 0.3},
					{"enemy_type": "basic_fighter", "position": Vector2(180, -50), "delay": 0.4},
					{"enemy_type": "basic_fighter", "position": Vector2(220, -50), "delay": 0.5},
					{"enemy_type": "basic_fighter", "position": Vector2(260, -50), "delay": 0.6},
					{"enemy_type": "basic_fighter", "position": Vector2(300, -50), "delay": 0.7},
					# Heavy convergence
					{"enemy_type": "heavy_bomber", "position": Vector2(80, -50), "delay": 0.8},
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.9},
					{"enemy_type": "heavy_bomber", "position": Vector2(240, -50), "delay": 1.0},
					{"enemy_type": "dive_bomber", "position": Vector2(120, -50), "delay": 1.1},
					{"enemy_type": "dive_bomber", "position": Vector2(200, -50), "delay": 1.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(100, -50), "delay": 1.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(220, -50), "delay": 1.2}
				],
				"formation_type": "none"
			}
		],
		"boss_encounter": {
			"boss_template": "crosssinker",
			"boss_position": Vector2(160, -50),
			"boss_name": "Cross Sinker",
			"intro_effects": ["screen_shake", "flash", "explosion"],
			"screen_shake_intensity": 1.6,
			"background_tint": Color(0.6, 0.8, 1.4),
			"music_pitch": 1.3
		}
	})
	
	# Stage 8 - Final Battle
	_register_template("stage_8", {
		"stage_name": "Stage 8 - Final Battle",
		"stage_number": 8,
		"background_type": "final_battle",
		"music_track": "final",
		"spawn_interval": 0.04,
		"waves": [
			{
				"wave_name": "Armada Assault",
				"spawn_interval": 0.03,
				"enemy_spawns": [
					# Massive formation
					{"enemy_type": "heavy_bomber", "position": Vector2(40, -50), "delay": 0.0},
					{"enemy_type": "heavy_bomber", "position": Vector2(80, -50), "delay": 0.05},
					{"enemy_type": "heavy_bomber", "position": Vector2(120, -50), "delay": 0.1},
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.15},
					{"enemy_type": "heavy_bomber", "position": Vector2(200, -50), "delay": 0.2},
					{"enemy_type": "heavy_bomber", "position": Vector2(240, -50), "delay": 0.25},
					{"enemy_type": "heavy_bomber", "position": Vector2(280, -50), "delay": 0.3},
					# Dive bomber escort
					{"enemy_type": "dive_bomber", "position": Vector2(60, -50), "delay": 0.4},
					{"enemy_type": "dive_bomber", "position": Vector2(100, -50), "delay": 0.45},
					{"enemy_type": "dive_bomber", "position": Vector2(140, -50), "delay": 0.5},
					{"enemy_type": "dive_bomber", "position": Vector2(180, -50), "delay": 0.55},
					{"enemy_type": "dive_bomber", "position": Vector2(220, -50), "delay": 0.6},
					{"enemy_type": "dive_bomber", "position": Vector2(260, -50), "delay": 0.65},
					# Elite fighters
					{"enemy_type": "sine_fighter", "position": Vector2(50, -50), "delay": 0.8},
					{"enemy_type": "sine_fighter", "position": Vector2(90, -50), "delay": 0.85},
					{"enemy_type": "sine_fighter", "position": Vector2(130, -50), "delay": 0.9},
					{"enemy_type": "sine_fighter", "position": Vector2(170, -50), "delay": 0.95},
					{"enemy_type": "sine_fighter", "position": Vector2(210, -50), "delay": 1.0},
					{"enemy_type": "sine_fighter", "position": Vector2(250, -50), "delay": 1.05},
					{"enemy_type": "sine_fighter", "position": Vector2(290, -50), "delay": 1.1}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Death Squadron",
				"spawn_interval": 0.02,
				"enemy_spawns": [
					# Elite death squadron
					{"enemy_type": "zigzag_fighter", "position": Vector2(30, -50), "delay": 0.0},
					{"enemy_type": "zigzag_fighter", "position": Vector2(70, -50), "delay": 0.05},
					{"enemy_type": "zigzag_fighter", "position": Vector2(110, -50), "delay": 0.1},
					{"enemy_type": "zigzag_fighter", "position": Vector2(150, -50), "delay": 0.15},
					{"enemy_type": "zigzag_fighter", "position": Vector2(190, -50), "delay": 0.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(230, -50), "delay": 0.25},
					{"enemy_type": "zigzag_fighter", "position": Vector2(270, -50), "delay": 0.3},
					{"enemy_type": "zigzag_fighter", "position": Vector2(310, -50), "delay": 0.35},
					# Heavy support
					{"enemy_type": "heavy_bomber", "position": Vector2(50, -50), "delay": 0.4},
					{"enemy_type": "heavy_bomber", "position": Vector2(130, -50), "delay": 0.45},
					{"enemy_type": "heavy_bomber", "position": Vector2(210, -50), "delay": 0.5},
					{"enemy_type": "heavy_bomber", "position": Vector2(290, -50), "delay": 0.55},
					# Dive bomber strike
					{"enemy_type": "dive_bomber", "position": Vector2(80, -50), "delay": 0.6},
					{"enemy_type": "dive_bomber", "position": Vector2(160, -50), "delay": 0.65},
					{"enemy_type": "dive_bomber", "position": Vector2(240, -50), "delay": 0.7},
					# Basic fighter swarm
					{"enemy_type": "basic_fighter", "position": Vector2(40, -50), "delay": 0.8},
					{"enemy_type": "basic_fighter", "position": Vector2(80, -50), "delay": 0.85},
					{"enemy_type": "basic_fighter", "position": Vector2(120, -50), "delay": 0.9},
					{"enemy_type": "basic_fighter", "position": Vector2(160, -50), "delay": 0.95},
					{"enemy_type": "basic_fighter", "position": Vector2(200, -50), "delay": 1.0},
					{"enemy_type": "basic_fighter", "position": Vector2(240, -50), "delay": 1.05},
					{"enemy_type": "basic_fighter", "position": Vector2(280, -50), "delay": 1.1}
				],
				"formation_type": "none"
			},
			{
				"wave_name": "Final Onslaught",
				"spawn_interval": 0.01,
				"enemy_spawns": [
					# Ultimate wave - all enemy types
					{"enemy_type": "heavy_bomber", "position": Vector2(160, -50), "delay": 0.0},
					{"enemy_type": "heavy_bomber", "position": Vector2(120, -50), "delay": 0.05},
					{"enemy_type": "heavy_bomber", "position": Vector2(200, -50), "delay": 0.05},
					{"enemy_type": "dive_bomber", "position": Vector2(80, -50), "delay": 0.1},
					{"enemy_type": "dive_bomber", "position": Vector2(240, -50), "delay": 0.1},
					{"enemy_type": "sine_fighter", "position": Vector2(60, -50), "delay": 0.15},
					{"enemy_type": "sine_fighter", "position": Vector2(100, -50), "delay": 0.15},
					{"enemy_type": "sine_fighter", "position": Vector2(140, -50), "delay": 0.15},
					{"enemy_type": "sine_fighter", "position": Vector2(180, -50), "delay": 0.15},
					{"enemy_type": "sine_fighter", "position": Vector2(220, -50), "delay": 0.15},
					{"enemy_type": "sine_fighter", "position": Vector2(260, -50), "delay": 0.15},
					{"enemy_type": "zigzag_fighter", "position": Vector2(40, -50), "delay": 0.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(80, -50), "delay": 0.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(120, -50), "delay": 0.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(160, -50), "delay": 0.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(200, -50), "delay": 0.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(240, -50), "delay": 0.2},
					{"enemy_type": "zigzag_fighter", "position": Vector2(280, -50), "delay": 0.2},
					{"enemy_type": "basic_fighter", "position": Vector2(50, -50), "delay": 0.25},
					{"enemy_type": "basic_fighter", "position": Vector2(90, -50), "delay": 0.25},
					{"enemy_type": "basic_fighter", "position": Vector2(130, -50), "delay": 0.25},
					{"enemy_type": "basic_fighter", "position": Vector2(170, -50), "delay": 0.25},
					{"enemy_type": "basic_fighter", "position": Vector2(210, -50), "delay": 0.25},
					{"enemy_type": "basic_fighter", "position": Vector2(250, -50), "delay": 0.25},
					{"enemy_type": "basic_fighter", "position": Vector2(290, -50), "delay": 0.25}
				],
				"formation_type": "none"
			}
		],
		"boss_encounter": {
			"boss_template": "bb",
			"boss_position": Vector2(160, -50),
			"boss_name": "BB",
			"intro_effects": ["screen_shake", "flash", "explosion"],
			"screen_shake_intensity": 2.0,
			"background_tint": Color(1.5, 0.5, 0.5),
			"music_pitch": 1.5
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

func get_stage_4() -> StageDefinition:
	return get_template("stage_4")

func get_stage_5() -> StageDefinition:
	return get_template("stage_5")

func get_stage_6() -> StageDefinition:
	return get_template("stage_6")

func get_stage_7() -> StageDefinition:
	return get_template("stage_7")

func get_stage_8() -> StageDefinition:
	return get_template("stage_8")
