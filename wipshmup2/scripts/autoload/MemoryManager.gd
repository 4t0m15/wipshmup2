extends Node

# MemoryManager - Advanced memory optimization and leak prevention
# Provides comprehensive memory management for the shmup game

signal memory_warning(usage_mb: float, threshold_mb: float)
signal memory_critical(usage_mb: float, threshold_mb: float)
signal memory_optimized(saved_mb: float)

# Memory thresholds
@export var warning_threshold_mb: float = 80.0
@export var critical_threshold_mb: float = 120.0
@export var target_memory_mb: float = 60.0

# Memory tracking
var memory_history: Array[float] = []
var max_history_size: int = 60  # 1 minute at 60fps
var last_cleanup_time: float = 0.0
var cleanup_interval: float = 10.0  # Clean every 10 seconds

# Object tracking for leak detection
var tracked_objects: Dictionary = {}
var object_creation_times: Dictionary = {}
var max_object_age: float = 30.0  # 30 seconds

# Memory optimization settings
var enable_aggressive_cleanup: bool = false
var enable_object_tracking: bool = true
var enable_memory_compression: bool = true

func _ready() -> void:
	print("[MemoryManager] Memory optimization system initialized")
	_initialize_memory_tracking()
	_connect_events()

func _process(delta: float) -> void:
	_update_memory_tracking()
	_check_memory_thresholds()
	_cleanup_old_objects()
	
	# Periodic cleanup
	last_cleanup_time += delta
	if last_cleanup_time >= cleanup_interval:
		_perform_memory_cleanup()
		last_cleanup_time = 0.0

func _initialize_memory_tracking() -> void:
	"""Initialize memory tracking systems"""
	memory_history.clear()
	tracked_objects.clear()
	object_creation_times.clear()

func _connect_events() -> void:
	"""Connect to game events for memory tracking"""
	if EventBus:
		EventBus.entity_spawned.connect(_on_entity_spawned)
		EventBus.entity_destroyed.connect(_on_entity_destroyed)
		EventBus.game_over.connect(_on_game_over)
		EventBus.stage_completed.connect(_on_stage_completed)

func _update_memory_tracking() -> void:
	"""Update memory usage tracking"""
	var current_memory = OS.get_static_memory_usage() / (1024.0 * 1024.0)  # Convert to MB
	memory_history.append(current_memory)
	
	if memory_history.size() > max_history_size:
		memory_history.pop_front()

func _check_memory_thresholds() -> void:
	"""Check if memory usage exceeds thresholds"""
	if memory_history.is_empty():
		return
	
	var current_memory = memory_history[-1]
	
	if current_memory >= critical_threshold_mb:
		memory_critical.emit(current_memory, critical_threshold_mb)
		_perform_aggressive_cleanup()
	elif current_memory >= warning_threshold_mb:
		memory_warning.emit(current_memory, warning_threshold_mb)
		_perform_memory_cleanup()

func _cleanup_old_objects() -> void:
	"""Clean up old objects to prevent memory leaks"""
	if not enable_object_tracking:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var objects_to_remove = []
	
	for obj_id in tracked_objects.keys():
		var creation_time = object_creation_times.get(obj_id, 0.0)
		if current_time - creation_time > max_object_age:
			objects_to_remove.append(obj_id)
	
	for obj_id in objects_to_remove:
		_remove_tracked_object(obj_id)

func _perform_memory_cleanup() -> void:
	"""Perform standard memory cleanup"""
	var initial_memory = _get_current_memory_mb()
	
	# Clean up bullet pools
	_cleanup_bullet_pools()
	
	# Clean up unused resources
	_cleanup_unused_resources()
	
	# Force garbage collection
	_force_garbage_collection()
	
	var final_memory = _get_current_memory_mb()
	var saved_memory = initial_memory - final_memory
	
	if saved_memory > 1.0:  # Only emit if we saved more than 1MB
		memory_optimized.emit(saved_memory)

func _perform_aggressive_cleanup() -> void:
	"""Perform aggressive memory cleanup for critical situations"""
	var initial_memory = _get_current_memory_mb()
	
	# Standard cleanup
	_perform_memory_cleanup()
	
	# Additional aggressive measures
	_cleanup_all_pools()
	_cleanup_ui_elements()
	_compress_memory()
	
	var final_memory = _get_current_memory_mb()
	var saved_memory = initial_memory - final_memory
	
	print("[MemoryManager] Aggressive cleanup saved ", saved_memory, " MB")

func _cleanup_bullet_pools() -> void:
	"""Clean up bullet pools to free memory"""
	var entity_factory = get_node_or_null("/root/EntityFactory")
	if entity_factory and entity_factory.has_method("_cleanup_pools"):
		entity_factory._cleanup_pools()

func _cleanup_unused_resources() -> void:
	"""Clean up unused resources"""
	# Clean up unused textures - placeholder for future implementation
	# RenderingServer doesn't have direct texture cleanup in Godot 4.5
	
	# Clean up unused audio resources
	var audio_server = AudioServer
	if audio_server:
        # Placeholder: actual cleanup depends on concrete audio system
		pass

func _cleanup_all_pools() -> void:
	"""Clean up all object pools"""
	_cleanup_bullet_pools()
	
	# Clean up any other pools
	var stability_manager = get_node_or_null("/root/StabilityManager")
	if stability_manager and stability_manager.has_method("cleanup_pools"):
		stability_manager.cleanup_pools()

func _cleanup_ui_elements() -> void:
	"""Clean up UI elements that might be consuming memory"""
	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("cleanup_popups"):
		hud.cleanup_popups()

func _compress_memory() -> void:
	"""Attempt to compress memory usage"""
	if enable_memory_compression:
		# Force garbage collection multiple times
		for i in range(3):
			_force_garbage_collection()
			await get_tree().process_frame

func _force_garbage_collection() -> void:
	"""Force garbage collection"""
    # Placeholder: Godot doesn't expose explicit GC control
	# But we can trigger cleanup by clearing arrays and freeing resources
	pass

func _get_current_memory_mb() -> float:
	"""Get current memory usage in MB"""
	return OS.get_static_memory_usage() / (1024.0 * 1024.0)

func _on_entity_spawned(entity: Node, _entity_type: String) -> void:
	"""Track entity creation for memory management"""
	if not enable_object_tracking:
		return
	
	var obj_id = str(entity.get_instance_id())
	tracked_objects[obj_id] = entity
	object_creation_times[obj_id] = Time.get_ticks_msec() / 1000.0

func _on_entity_destroyed(entity: Node, _entity_type: String) -> void:
	"""Track entity destruction for memory management"""
	if not enable_object_tracking:
		return
	
	var obj_id = str(entity.get_instance_id())
	_remove_tracked_object(obj_id)

func _remove_tracked_object(obj_id: String) -> void:
	"""Remove object from tracking"""
	tracked_objects.erase(obj_id)
	object_creation_times.erase(obj_id)

func _on_game_over() -> void:
	"""Handle game over - perform full memory cleanup"""
	_perform_aggressive_cleanup()
	_initialize_memory_tracking()

func _on_stage_completed(_stage_number: int) -> void:
	"""Handle stage completion - perform cleanup"""
	_perform_memory_cleanup()

# Public API for manual memory management
func force_cleanup() -> void:
	"""Force immediate memory cleanup"""
	_perform_aggressive_cleanup()

func get_memory_usage_mb() -> float:
	"""Get current memory usage in MB"""
	return _get_current_memory_mb()

func get_memory_trend() -> float:
	"""Get memory usage trend (positive = increasing, negative = decreasing)"""
	if memory_history.size() < 2:
		return 0.0
	
	var recent = memory_history[-1]
	var older_index = max(0, memory_history.size() - min(10, memory_history.size()))
	var older = memory_history[older_index]
	return recent - older

func _calculate_average(array: Array) -> float:
	"""Calculate average of array"""
	if array.is_empty():
		return 0.0
	
	var sum = 0.0
	for value in array:
		sum += value
	return sum / array.size()

# Configuration methods
func set_memory_thresholds(warning_mb: float, critical_mb: float) -> void:
	"""Set memory thresholds"""
	warning_threshold_mb = warning_mb
	critical_threshold_mb = critical_mb

func enable_optimizations(aggressive: bool, tracking: bool, compression: bool) -> void:
	"""Enable/disable optimization features"""
	enable_aggressive_cleanup = aggressive
	enable_object_tracking = tracking
	enable_memory_compression = compression
