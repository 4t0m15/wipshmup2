extends Resource
class_name BossPhase

# BossPhase - Data-driven boss phase definition
# Defines behavior, patterns, and transitions for boss phases

@export var phase_name: String = "Phase 1"
@export var hp_threshold: int = 0  # HP at which this phase starts
@export var movement_behavior: String = "StraightDown"
@export var attack_patterns: Array[String] = ["AimedShot"]
@export var phase_duration: float = -1.0  # -1 for infinite

# Movement parameters
@export var movement_params: Dictionary = {}

# Attack parameters
@export var attack_params: Dictionary = {}

# Visual changes
@export var sprite_scale: float = 1.0
@export var glow_color: Color = Color.WHITE
@export var danger_level: int = 1

# Special effects
@export var screen_shake_intensity: float = 0.0
@export var background_tint: Color = Color.WHITE
@export var music_pitch: float = 1.0

func _init() -> void:
	# Set default parameters
	if movement_params.is_empty():
		movement_params = {
			"speed": 30.0,
			"direction": Vector2.DOWN
		}
	
	if attack_params.is_empty():
		attack_params = {
			"fire_rate": 0.5,
			"bullet_speed": 120.0,
			"bullet_damage": 1
		}

func get_movement_behavior_scene() -> PackedScene:
	"""Get the movement behavior scene for this phase"""
	match movement_behavior:
		"StraightDown":
			return load("res://scripts/components/behaviors/StraightDownBehavior.gd")
		"SineWave":
			return load("res://scripts/components/behaviors/SineWaveBehavior.gd")
		"Zigzag":
			return load("res://scripts/components/behaviors/ZigzagBehavior.gd")
		"Dive":
			return load("res://scripts/components/behaviors/DiveBehavior.gd")
		_:
			return load("res://scripts/components/behaviors/StraightDownBehavior.gd")

func get_attack_behavior_scene() -> PackedScene:
	"""Get the attack behavior scene for this phase"""
	match attack_patterns[0] if attack_patterns.size() > 0 else "AimedShot":
		"AimedShot":
			return load("res://scripts/components/behaviors/AimedShotBehavior.gd")
		"Fan":
			return load("res://scripts/components/behaviors/FanBehavior.gd")
		"Ring":
			return load("res://scripts/components/behaviors/RingBehavior.gd")
		_:
			return load("res://scripts/components/behaviors/AimedShotBehavior.gd")

func apply_visual_effects(boss: Node) -> void:
	"""Apply visual effects for this phase"""
	# Apply sprite changes
	if boss.has_node("Sprite2D"):
		var sprite = boss.get_node("Sprite2D")
		sprite.scale = Vector2(sprite_scale, sprite_scale)
		if glow_color != Color.WHITE:
			sprite.modulate = glow_color
	
	# Apply screen shake
	if screen_shake_intensity > 0.0:
		EventBus.emit_visual_effect("screen_shake", {
			"intensity": screen_shake_intensity,
			"duration": 0.5
		})
	
	# Apply background tint
	if background_tint != Color.WHITE:
		EventBus.emit_visual_effect("flash", {
			"color": background_tint,
			"duration": 0.3
		})
	
	# Apply music pitch
	if music_pitch != 1.0:
		# Note: Audio manager access should be handled by the boss instance, not the phase definition
		# This is a data class, so we can't access the scene tree directly
		pass
