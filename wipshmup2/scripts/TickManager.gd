extends Node

# Centralized time management for performance optimization
var _current_time: float = 0.0
var _delta_time: float = 0.0
var _time_scale: float = 0.5

# Cache management
var _cache_duration: float = 0.1  # Default cache duration
var _last_cache_update: float = 0.0

func _ready() -> void:
	# Set as singleton for global access
	if not get_tree().root.has_node("TickManager"):
		get_tree().root.add_child(self)
		name = "TickManager"

func _process(delta: float) -> void:
	_delta_time = delta * _time_scale
	_current_time += _delta_time
	
	# Update cache time
	if _current_time - _last_cache_update >= _cache_duration:
		_last_cache_update = _current_time

# Get current time in seconds
func get_current_time() -> float:
	return _current_time

# Get delta time
func get_delta_time() -> float:
	return _delta_time

# Check if cache should be refreshed
func should_refresh_cache(last_cache_time: float) -> bool:
	return (_current_time - last_cache_time) >= _cache_duration

# Set cache duration
func set_cache_duration(duration: float) -> void:
	_cache_duration = duration

# Get cache duration
func get_cache_duration() -> float:
	return _cache_duration

# Set time scale
func set_time_scale(scale: float) -> void:
	_time_scale = scale

# Get time scale
func get_time_scale() -> float:
	return _time_scale
