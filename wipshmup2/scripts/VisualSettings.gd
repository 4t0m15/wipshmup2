class_name VisualSettings
extends Node

# Visual clarity settings for accessibility and customization
# Centralized system for managing visual effects intensity

# Settings categories
enum SettingCategory {
	BULLET_VISIBILITY,
	BACKGROUND_CLARITY,
	EFFECT_INTENSITY,
	ACCESSIBILITY,
	PERFORMANCE
}

# Individual settings
var bullet_outline_intensity: float = 1.0  # 0.0 to 2.0
var bullet_glow_enabled: bool = true
var bullet_size_multiplier: float = 1.0  # 0.5 to 2.0

var background_dim_intensity: float = 0.5  # 0.0 to 1.0
var background_dynamic_dim: bool = true
var shader_intensity: float = 1.0  # 0.0 to 1.0

var screen_shake_intensity: float = 1.0  # 0.0 to 2.0
var hit_stop_enabled: bool = true
var flash_effects_enabled: bool = true
var particle_effects_enabled: bool = true

var colorblind_mode: String = "none"  # none, protanopia, deuteranopia, tritanopia
var high_contrast_mode: bool = false
var large_ui_mode: bool = false
var photosensitivity_mode: bool = false

var max_particles: int = 50
var dynamic_quality: bool = true
var effect_culling_distance: float = 200.0

# Color palettes for different modes
var _color_palettes = {
	"normal": {
		"player": Color(0.2, 1.0, 0.8, 1.0),
		"enemy": Color(1.0, 0.3, 0.3, 1.0),
		"bullet_low": Color(0.8, 0.8, 1.0, 1.0),
		"bullet_medium": Color(1.0, 0.8, 0.2, 1.0),
		"bullet_high": Color(1.0, 0.3, 0.3, 1.0)
	},
	"protanopia": {
		"player": Color(0.2, 1.0, 0.8, 1.0),
		"enemy": Color(1.0, 0.6, 0.0, 1.0),  # More orange
		"bullet_low": Color(0.8, 0.8, 1.0, 1.0),
		"bullet_medium": Color(1.0, 0.9, 0.0, 1.0),  # More yellow
		"bullet_high": Color(1.0, 0.0, 0.0, 1.0)  # Pure red
	},
	"deuteranopia": {
		"player": Color(0.2, 1.0, 0.8, 1.0),
		"enemy": Color(1.0, 0.4, 0.4, 1.0),
		"bullet_low": Color(0.8, 0.8, 1.0, 1.0),
		"bullet_medium": Color(1.0, 0.7, 0.0, 1.0),
		"bullet_high": Color(1.0, 0.2, 0.2, 1.0)
	},
	"tritanopia": {
		"player": Color(0.2, 1.0, 0.8, 1.0),
		"enemy": Color(1.0, 0.3, 0.3, 1.0),
		"bullet_low": Color(0.8, 0.8, 1.0, 1.0),
		"bullet_medium": Color(1.0, 0.8, 0.2, 1.0),
		"bullet_high": Color(1.0, 0.3, 0.3, 1.0)
	}
}

func _ready() -> void:
	# Load settings from file if available
	_load_settings()

func _load_settings() -> void:
	"""Load visual settings from config file"""
	var config = ConfigFile.new()
	var err = config.load("user://visual_settings.cfg")
	if err == OK:
		bullet_outline_intensity = config.get_value("bullet_visibility", "outline_intensity", 1.0)
		bullet_glow_enabled = config.get_value("bullet_visibility", "glow_enabled", true)
		bullet_size_multiplier = config.get_value("bullet_visibility", "size_multiplier", 1.0)
		
		background_dim_intensity = config.get_value("background", "dim_intensity", 0.5)
		background_dynamic_dim = config.get_value("background", "dynamic_dim", true)
		shader_intensity = config.get_value("background", "shader_intensity", 1.0)
		
		screen_shake_intensity = config.get_value("effects", "screen_shake", 1.0)
		hit_stop_enabled = config.get_value("effects", "hit_stop", true)
		flash_effects_enabled = config.get_value("effects", "flash", true)
		particle_effects_enabled = config.get_value("effects", "particles", true)
		
		colorblind_mode = config.get_value("accessibility", "colorblind_mode", "none")
		high_contrast_mode = config.get_value("accessibility", "high_contrast", false)
		large_ui_mode = config.get_value("accessibility", "large_ui", false)
		photosensitivity_mode = config.get_value("accessibility", "photosensitivity", false)
		
		max_particles = config.get_value("performance", "max_particles", 50)
		dynamic_quality = config.get_value("performance", "dynamic_quality", true)
		effect_culling_distance = config.get_value("performance", "culling_distance", 200.0)

func save_settings() -> void:
	"""Save current settings to config file"""
	var config = ConfigFile.new()
	
	config.set_value("bullet_visibility", "outline_intensity", bullet_outline_intensity)
	config.set_value("bullet_visibility", "glow_enabled", bullet_glow_enabled)
	config.set_value("bullet_visibility", "size_multiplier", bullet_size_multiplier)
	
	config.set_value("background", "dim_intensity", background_dim_intensity)
	config.set_value("background", "dynamic_dim", background_dynamic_dim)
	config.set_value("background", "shader_intensity", shader_intensity)
	
	config.set_value("effects", "screen_shake", screen_shake_intensity)
	config.set_value("effects", "hit_stop", hit_stop_enabled)
	config.set_value("effects", "flash", flash_effects_enabled)
	config.set_value("effects", "particles", particle_effects_enabled)
	
	config.set_value("accessibility", "colorblind_mode", colorblind_mode)
	config.set_value("accessibility", "high_contrast", high_contrast_mode)
	config.set_value("accessibility", "large_ui", large_ui_mode)
	config.set_value("accessibility", "photosensitivity", photosensitivity_mode)
	
	config.set_value("performance", "max_particles", max_particles)
	config.set_value("performance", "dynamic_quality", dynamic_quality)
	config.set_value("performance", "culling_distance", effect_culling_distance)
	
	config.save("user://visual_settings.cfg")

func get_color_for_type(type: String) -> Color:
	"""Get color for entity type based on current colorblind settings"""
	var palette = _color_palettes.get(colorblind_mode, _color_palettes["normal"])
	return palette.get(type, Color.WHITE)

func apply_photosensitivity_settings() -> void:
	"""Apply settings for photosensitivity"""
	if photosensitivity_mode:
		flash_effects_enabled = false
		screen_shake_intensity = 0.3
		bullet_glow_enabled = false
		particle_effects_enabled = false

func get_ui_scale() -> float:
	"""Get UI scale multiplier based on settings"""
	return 1.2 if large_ui_mode else 1.0

func get_contrast_multiplier() -> float:
	"""Get contrast multiplier for high contrast mode"""
	return 1.5 if high_contrast_mode else 1.0

func should_cull_effect(position: Vector2, player_pos: Vector2) -> bool:
	"""Check if effect should be culled based on distance"""
	if not dynamic_quality:
		return false
	
	var distance = position.distance_to(player_pos)
	return distance > effect_culling_distance

# Preset configurations
func apply_preset(preset_name: String) -> void:
	"""Apply a preset configuration"""
	match preset_name:
		"high_performance":
			bullet_outline_intensity = 0.5
			bullet_glow_enabled = false
			particle_effects_enabled = false
			max_particles = 20
			dynamic_quality = true
		"high_quality":
			bullet_outline_intensity = 1.5
			bullet_glow_enabled = true
			particle_effects_enabled = true
			max_particles = 100
			dynamic_quality = false
		"accessibility":
			high_contrast_mode = true
			large_ui_mode = true
			bullet_size_multiplier = 1.3
			background_dim_intensity = 0.8
		"photosensitivity":
			photosensitivity_mode = true
			apply_photosensitivity_settings()
