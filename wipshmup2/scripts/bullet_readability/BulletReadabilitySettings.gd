extends Node
class_name BulletReadabilitySettings

## Comprehensive Bullet Readability Settings System
## Manages all visual clarity options with persistent save/load

signal settings_changed()

## === BULLET VISUAL SETTINGS ===

## Size multiplier for all bullets (visual only, hitbox unchanged)
@export_range(0.75, 1.5, 0.25) var bullet_size_multiplier: float = 1.0:
	set(value):
		bullet_size_multiplier = clamp(value, 0.75, 1.5)
		settings_changed.emit()

## Outline thickness level (1.0=Thin, 2.0=Normal, 3.0=Thick)
@export_range(1.0, 3.0, 1.0) var outline_thickness_preset: float = 2.0:
	set(value):
		outline_thickness_preset = value
		settings_changed.emit()

## Glow intensity level (0.0=Off, 0.5=Low, 1.0=Normal, 1.5=High)
@export_range(0.0, 1.5, 0.5) var glow_intensity: float = 1.0:
	set(value):
		glow_intensity = value
		settings_changed.emit()

## Show hitbox visualizations
@export_enum("Off:0", "Enemies:1", "Player:2", "Both:3") var hitbox_visibility: int = 0:
	set(value):
		hitbox_visibility = value
		settings_changed.emit()

## Bullet trail effect intensity (0.0=Off, 0.3=Low, 0.6=Normal, 1.0=High)
@export_range(0.0, 1.0, 0.3) var trail_intensity: float = 0.6:
	set(value):
		trail_intensity = value
		settings_changed.emit()

## === BACKGROUND SETTINGS ===

## Auto-dim background based on bullet density (0.0=Off, 0.3=Low, 0.6=Normal, 1.0=High)
@export_range(0.0, 1.0, 0.3) var auto_dim_multiplier: float = 0.6:
	set(value):
		auto_dim_multiplier = value
		settings_changed.emit()

## Background desaturation amount (0.0=Off, 0.25=25%, 0.5=50%, 0.75=75%)
@export_range(0.0, 0.75, 0.25) var desaturation_amount: float = 0.5:
	set(value):
		desaturation_amount = value
		settings_changed.emit()

## Background blur intensity (performance heavy) (0.0=Off, 1.0=Low, 2.0=Normal, 3.0=High)
@export_range(0.0, 3.0, 1.0) var blur_intensity: float = 0.0:
	set(value):
		blur_intensity = value
		settings_changed.emit()

## Use static background (disable animations)
@export var static_background: bool = false:
	set(value):
		static_background = value
		settings_changed.emit()

## === WARNING & INDICATOR SETTINGS ===

## Proximity warning system
@export_enum("Off:0", "Visual:1", "Audio:2", "Both:3") var proximity_warning_mode: int = 1:
	set(value):
		proximity_warning_mode = value
		settings_changed.emit()

## Show indicators for off-screen bullets
@export var offscreen_indicators: bool = true:
	set(value):
		offscreen_indicators = value
		settings_changed.emit()

## Danger pulse effect intensity (0.0=Off, 0.3=Subtle, 0.6=Normal, 1.0=Strong)
@export_range(0.0, 1.0, 0.3) var danger_pulse_intensity: float = 0.6:
	set(value):
		danger_pulse_intensity = value
		settings_changed.emit()

## Show trajectory lines (practice mode only)
@export var show_trajectory_lines: bool = false:
	set(value):
		show_trajectory_lines = value
		settings_changed.emit()

## === ACCESSIBILITY SETTINGS ===

## Colorblind mode
@export_enum("None:none", "Protanopia:protanopia", "Deuteranopia:deuteranopia", "Tritanopia:tritanopia") var colorblind_mode: String = "none":
	set(value):
		colorblind_mode = value
		settings_changed.emit()

## High contrast mode (maximum visibility)
@export var high_contrast_mode: bool = false:
	set(value):
		high_contrast_mode = value
		settings_changed.emit()

## Large UI elements
@export var large_ui_mode: bool = false:
	set(value):
		large_ui_mode = value
		settings_changed.emit()

## Simplified visuals (reduce effects for clarity/performance)
@export var simplified_visuals: bool = false:
	set(value):
		simplified_visuals = value
		settings_changed.emit()

## === ADVANCED SETTINGS ===

## Automatically adjust quality based on performance
@export var auto_adjust_quality: bool = true:
	set(value):
		auto_adjust_quality = value
		settings_changed.emit()

## Maximum particle count
@export_enum("50:50", "100:100", "200:200", "Unlimited:9999") var particle_limit: int = 100:
	set(value):
		particle_limit = value
		settings_changed.emit()

## Effect rendering distance (100.0=Near, 200.0=Normal, 400.0=Far)
@export_range(100.0, 400.0, 100.0) var effect_distance: float = 200.0:
	set(value):
		effect_distance = value
		settings_changed.emit()

## Debug overlays
@export_enum("Off:0", "Performance:1", "All:2") var debug_overlay: int = 0:
	set(value):
		debug_overlay = value
		settings_changed.emit()

## === INTERNAL STATE ===

const SAVE_PATH = "user://bullet_readability_settings.cfg"
var config_file: ConfigFile

func _ready() -> void:
	config_file = ConfigFile.new()
	load_settings()
	print("[BulletReadabilitySettings] Initialized with ", get_settings_summary())

## === SETTINGS MANAGEMENT ===

func get_settings_summary() -> String:
	"""Get a human-readable summary of current settings"""
	return "Size:%0.2fx Outline:%0.1fpx Glow:%0.1f Dim:%0.1f" % [
		bullet_size_multiplier,
		outline_thickness_preset,
		glow_intensity,
		auto_dim_multiplier
	]

func get_all_settings() -> Dictionary:
	"""Get complete settings dictionary"""
	return {
		# Bullet Visuals
		"bullet_size_multiplier": bullet_size_multiplier,
		"outline_thickness_preset": outline_thickness_preset,
		"glow_intensity": glow_intensity,
		"hitbox_visibility": hitbox_visibility,
		"trail_intensity": trail_intensity,
		
		# Background
		"auto_dim_multiplier": auto_dim_multiplier,
		"desaturation_amount": desaturation_amount,
		"blur_intensity": blur_intensity,
		"static_background": static_background,
		
		# Warnings & Indicators
		"proximity_warning_mode": proximity_warning_mode,
		"offscreen_indicators": offscreen_indicators,
		"danger_pulse_intensity": danger_pulse_intensity,
		"show_trajectory_lines": show_trajectory_lines,
		
		# Accessibility
		"colorblind_mode": colorblind_mode,
		"high_contrast_mode": high_contrast_mode,
		"large_ui_mode": large_ui_mode,
		"simplified_visuals": simplified_visuals,
		
		# Advanced
		"auto_adjust_quality": auto_adjust_quality,
		"particle_limit": particle_limit,
		"effect_distance": effect_distance,
		"debug_overlay": debug_overlay
	}

func apply_settings_dict(settings: Dictionary) -> void:
	"""Apply settings from dictionary"""
	for key in settings:
		if key in self:
			set(key, settings[key])

func reset_to_defaults() -> void:
	"""Reset all settings to defaults"""
	bullet_size_multiplier = 1.0
	outline_thickness_preset = 2.0
	glow_intensity = 1.0
	hitbox_visibility = 0
	trail_intensity = 0.6
	
	auto_dim_multiplier = 0.6
	desaturation_amount = 0.5
	blur_intensity = 0.0
	static_background = false
	
	proximity_warning_mode = 1
	offscreen_indicators = true
	danger_pulse_intensity = 0.6
	show_trajectory_lines = false
	
	colorblind_mode = "none"
	high_contrast_mode = false
	large_ui_mode = false
	simplified_visuals = false
	
	auto_adjust_quality = true
	particle_limit = 100
	effect_distance = 200.0
	debug_overlay = 0
	
	settings_changed.emit()
	print("[BulletReadabilitySettings] Reset to defaults")

## === PRESETS ===

func apply_preset(preset_name: String) -> void:
	"""Apply a named preset configuration"""
	match preset_name:
		"maximum_clarity":
			bullet_size_multiplier = 1.5
			outline_thickness_preset = 3.0
			glow_intensity = 1.5
			hitbox_visibility = 3  # Both
			auto_dim_multiplier = 1.0
			desaturation_amount = 0.75
			proximity_warning_mode = 3  # Both
			offscreen_indicators = true
			danger_pulse_intensity = 1.0
			
		"performance":
			bullet_size_multiplier = 1.0
			outline_thickness_preset = 1.0
			glow_intensity = 0.5
			hitbox_visibility = 0
			trail_intensity = 0.0
			auto_dim_multiplier = 0.3
			desaturation_amount = 0.0
			blur_intensity = 0.0
			proximity_warning_mode = 1  # Visual only
			particle_limit = 50
			simplified_visuals = true
			
		"accessibility":
			high_contrast_mode = true
			large_ui_mode = true
			bullet_size_multiplier = 1.5
			outline_thickness_preset = 3.0
			glow_intensity = 0.0  # Too soft for high contrast
			hitbox_visibility = 3  # Both
			auto_dim_multiplier = 1.0
			static_background = true
			
		"minimal":
			bullet_size_multiplier = 0.75
			outline_thickness_preset = 1.0
			glow_intensity = 0.5
			hitbox_visibility = 0
			trail_intensity = 0.0
			auto_dim_multiplier = 0.0
			desaturation_amount = 0.0
			blur_intensity = 0.0
			proximity_warning_mode = 0
			danger_pulse_intensity = 0.0
			simplified_visuals = true
			
		_:
			push_warning("Unknown preset: " + preset_name)
			return
	
	settings_changed.emit()
	print("[BulletReadabilitySettings] Applied preset: ", preset_name)

## === SAVE/LOAD ===

func save_settings() -> void:
	"""Save settings to disk"""
	var settings = get_all_settings()
	
	for key in settings:
		config_file.set_value("ReadabilitySettings", key, settings[key])
	
	var error = config_file.save(SAVE_PATH)
	if error != OK:
		push_error("Failed to save settings: " + str(error))
	else:
		print("[BulletReadabilitySettings] Settings saved")

func load_settings() -> void:
	"""Load settings from disk"""
	var error = config_file.load(SAVE_PATH)
	
	if error != OK:
		print("[BulletReadabilitySettings] No saved settings found, using defaults")
		return
	
	# Load each setting
	for key in get_all_settings().keys():
		if config_file.has_section_key("ReadabilitySettings", key):
			var value = config_file.get_value("ReadabilitySettings", key)
			set(key, value)
	
	print("[BulletReadabilitySettings] Settings loaded")

## === HELPER METHODS ===

func should_show_player_hitbox() -> bool:
	"""Check if player hitbox should be visible"""
	return hitbox_visibility == 2 or hitbox_visibility == 3

func should_show_enemy_hitboxes() -> bool:
	"""Check if enemy hitboxes should be visible"""
	return hitbox_visibility == 1 or hitbox_visibility == 3

func should_play_proximity_sound() -> bool:
	"""Check if proximity warning sound should play"""
	return proximity_warning_mode == 2 or proximity_warning_mode == 3

func should_show_proximity_visual() -> bool:
	"""Check if proximity warning visual should show"""
	return proximity_warning_mode == 1 or proximity_warning_mode == 3

func get_background_dim_level(bullet_count: int, nearby_bullets: int, is_boss: bool) -> float:
	"""Calculate current background dim level based on game state"""
	if auto_dim_multiplier == 0.0:
		return 0.0
	
	# Base calculation from bullet density
	var count_factor = clamp(float(bullet_count) / 100.0, 0.0, 0.7)
	var proximity_factor = clamp(float(nearby_bullets) / 30.0, 0.0, 0.3)
	var boss_factor = 0.2 if is_boss else 0.0
	
	var base_dim = min(count_factor + proximity_factor + boss_factor, 0.85)
	
	# Apply user multiplier
	return base_dim * auto_dim_multiplier

func get_effective_outline_thickness(danger_level: int) -> float:
	"""Get outline thickness adjusted for danger level and settings"""
	var base = outline_thickness_preset
	
	# High danger gets slightly thicker outline
	if danger_level == 3:
		base *= 1.25
	
	# High contrast mode gets extra thick
	if high_contrast_mode:
		base = 3.0
	
	return base

func is_effect_in_range(effect_position: Vector2, camera_position: Vector2) -> bool:
	"""Check if effect is within rendering distance"""
	var distance = effect_position.distance_to(camera_position)
	return distance <= effect_distance

## === AUTO-QUALITY ADJUSTMENT ===

var _performance_history: Array[float] = []
const HISTORY_SIZE = 60  # 1 second at 60fps

func update_performance_tracking(delta_time: float) -> void:
	"""Track performance and auto-adjust if enabled"""
	if not auto_adjust_quality:
		return
	
	_performance_history.append(delta_time)
	if _performance_history.size() > HISTORY_SIZE:
		_performance_history.pop_front()
	
	# Check every second
	if _performance_history.size() >= HISTORY_SIZE:
		var avg_fps = 1.0 / (_performance_history.reduce(func(acc, val): return acc + val) / float(HISTORY_SIZE))
		
		if avg_fps < 45.0:
			_reduce_quality()
		elif avg_fps > 55.0 and simplified_visuals:
			_increase_quality()

func _reduce_quality() -> void:
	"""Reduce quality settings for performance"""
	if glow_intensity > 0.5:
		glow_intensity -= 0.5
	elif trail_intensity > 0.0:
		trail_intensity = 0.0
	elif blur_intensity > 0.0:
		blur_intensity = 0.0
	elif particle_limit > 50:
		particle_limit = 50
	elif not simplified_visuals:
		simplified_visuals = true
	
	print("[BulletReadabilitySettings] Quality reduced for performance")

func _increase_quality() -> void:
	"""Increase quality settings when performance allows"""
	if simplified_visuals:
		simplified_visuals = false
	elif particle_limit < 100:
		particle_limit = 100
	elif glow_intensity < 1.0:
		glow_intensity += 0.5
	
	print("[BulletReadabilitySettings] Quality increased")

