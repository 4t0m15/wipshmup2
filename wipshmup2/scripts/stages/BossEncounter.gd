extends Resource
class_name BossEncounter

# BossEncounter - Defines a boss encounter in a stage
# Contains boss template, position, and special effects

@export var boss_template: String = "gliath"
@export var boss_position: Vector2 = Vector2(160, -50)
@export var boss_name: String = "Boss"
@export var intro_duration: float = 2.0
@export var outro_duration: float = 3.0

# Special effects
@export var intro_effects: Array[String] = []
@export var outro_effects: Array[String] = []
@export var background_tint: Color = Color.WHITE
@export var screen_shake_intensity: float = 0.0
@export var music_pitch: float = 1.0

# Boss behavior overrides
@export var behavior_overrides: Dictionary = {}

func _init() -> void:
	# Set default intro effects
	if intro_effects.is_empty():
		intro_effects = ["screen_shake", "flash"]
	
	# Set default outro effects
	if outro_effects.is_empty():
		outro_effects = ["explosion", "screen_shake"]

func apply_intro_effects() -> void:
	"""Apply boss introduction effects"""
	for effect in intro_effects:
		match effect:
			"screen_shake":
				EventBus.emit_visual_effect("screen_shake", {
					"intensity": screen_shake_intensity,
					"duration": intro_duration
				})
			"flash":
				EventBus.emit_visual_effect("flash", {
					"color": background_tint,
					"duration": intro_duration * 0.5
				})
			"explosion":
				EventBus.emit_visual_effect("explosion", {
					"position": boss_position,
					"size": 2.0
				})

func apply_outro_effects() -> void:
	"""Apply boss defeat effects"""
	for effect in outro_effects:
		match effect:
			"screen_shake":
				EventBus.emit_visual_effect("screen_shake", {
					"intensity": screen_shake_intensity * 1.5,
					"duration": outro_duration
				})
			"explosion":
				EventBus.emit_visual_effect("explosion", {
					"position": boss_position,
					"size": 3.0
				})
			"flash":
				EventBus.emit_visual_effect("flash", {
					"color": Color.WHITE,
					"duration": outro_duration * 0.3
				})

func get_boss_template_name() -> String:
	"""Get the boss template name"""
	return boss_template

func get_spawn_position() -> Vector2:
	"""Get the boss spawn position"""
	return boss_position

func get_intro_duration() -> float:
	"""Get the introduction duration"""
	return intro_duration

func get_outro_duration() -> float:
	"""Get the outro duration"""
	return outro_duration

func has_behavior_override(key: String) -> bool:
	"""Check if there's a behavior override for the given key"""
	return behavior_overrides.has(key)

func get_behavior_override(key: String, default_value = null):
	"""Get a behavior override value"""
	return behavior_overrides.get(key, default_value)
