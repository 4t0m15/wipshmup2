extends Node

# StabilityManager - Enhanced stability and development tools
# Provides comprehensive error handling, performance monitoring, and development aids

# signal stability_warning(message: String, severity: String)  # Reserved for future use
signal performance_warning(metric: String, value: float, threshold: float)
signal development_log(message: String, category: String)

# Stability tracking
var error_count: int = 0
var warning_count: int = 0
var crash_count: int = 0
var last_error_time: float = 0.0
var stability_score: float = 100.0

# Performance monitoring
var frame_times: Array[float] = []
var memory_usage: Array[int] = []
var bullet_count_history: Array[int] = []
var max_history_size: int = 60  # 1 second at 60fps

# Bullet tracking (event-driven with sampling fallback)
var bullet_count: int = 0
var bullet_sample_accum: float = 0.0
@export var bullet_sample_interval: float = 0.25
var last_bullet_count: int = 0

# Development tools
var debug_overlay_enabled: bool = false
var performance_overlay_enabled: bool = false
var hot_reload_enabled: bool = false
var development_mode: bool = false

# Parallel processing
var thread_pool: Array[Thread] = []
var max_threads: int = 4
var task_queue: Array[Dictionary] = []
var completed_tasks: Array[Dictionary] = []

func _ready() -> void:
	print("[StabilityManager] Enhanced stability system initialized")
	_initialize_thread_pool()
	_connect_events()
	
	# Enable development mode in debug builds
	if OS.is_debug_build():
		development_mode = true
		debug_overlay_enabled = true
		performance_overlay_enabled = true

func _process(delta: float) -> void:
	_update_performance_metrics(delta)
	_process_parallel_tasks()
	_update_stability_score()

func _initialize_thread_pool() -> void:
	"""Initialize thread pool for parallel processing"""
	for i in range(max_threads):
		var thread = Thread.new()
		thread_pool.append(thread)

func _connect_events() -> void:
	"""Connect to game events for monitoring"""
	# Connect to ErrorHandler signals
	var error_handler = get_node_or_null("/root/ErrorHandler")
	if error_handler:
		if error_handler.has_signal("error_occurred") and not error_handler.error_occurred.is_connected(_on_error_occurred):
			error_handler.error_occurred.connect(_on_error_occurred)
		if error_handler.has_signal("critical_error_occurred") and not error_handler.critical_error_occurred.is_connected(_on_critical_error):
			error_handler.critical_error_occurred.connect(_on_critical_error)
	
	# Connect to EventBus signals
	if EventBus:
		if EventBus.has_signal("bullet_hit_enemy"):
			EventBus.bullet_hit_enemy.connect(_on_bullet_hit)
		if EventBus.has_signal("enemy_killed"):
			EventBus.enemy_killed.connect(_on_enemy_killed)
		# Track bullets via entity events to avoid group scans
		if EventBus.has_signal("entity_spawned") and not EventBus.entity_spawned.is_connected(_on_entity_spawned):
			EventBus.entity_spawned.connect(_on_entity_spawned)
		if EventBus.has_signal("entity_destroyed") and not EventBus.entity_destroyed.is_connected(_on_entity_destroyed):
			EventBus.entity_destroyed.connect(_on_entity_destroyed)

func _update_performance_metrics(delta: float) -> void:
	"""Update performance metrics"""
	# Frame time tracking
	frame_times.append(delta)
	if frame_times.size() > max_history_size:
		frame_times.pop_front()
	
	# Memory usage tracking
	var memory = OS.get_static_memory_usage()
	memory_usage.append(memory)
	if memory_usage.size() > max_history_size:
		memory_usage.pop_front()
	
	# Bullet count tracking (sampled)
	bullet_sample_accum += delta
	if bullet_sample_accum >= bullet_sample_interval:
		last_bullet_count = _get_bullet_count()
		bullet_sample_accum = 0.0
	bullet_count_history.append(last_bullet_count)
	if bullet_count_history.size() > max_history_size:
		bullet_count_history.pop_front()
	
	# Check for performance issues
	_check_performance_thresholds()

func _get_bullet_count() -> int:
	"""Get current bullet count (event-driven)"""
	return bullet_count

func _on_entity_spawned(_entity: Node, entity_type: String) -> void:
	if entity_type == "player_bullet" or entity_type == "enemy_bullet":
		bullet_count += 1

func _on_entity_destroyed(_entity: Node, entity_type: String) -> void:
	if entity_type == "player_bullet" or entity_type == "enemy_bullet":
		bullet_count = max(0, bullet_count - 1)

func _check_performance_thresholds() -> void:
	"""Check for performance issues"""
	if frame_times.size() < 10:
		return
	
	# Check frame rate
	var avg_frame_time = _calculate_average(frame_times)
	if avg_frame_time > 1.0/30.0:  # Below 30fps
		performance_warning.emit("low_fps", avg_frame_time, 1.0/30.0)
	
	# Check memory usage
	if memory_usage.size() > 0:
		var current_memory = memory_usage[-1]
		if current_memory > 100 * 1024 * 1024:  # 100MB
			performance_warning.emit("high_memory", current_memory, 100 * 1024 * 1024)
	
	# Check bullet count
	if bullet_count_history.size() > 0:
		var current_bullets = bullet_count_history[-1]
		if current_bullets > 400:  # High bullet count
			performance_warning.emit("high_bullet_count", current_bullets, 400)

func _calculate_average(array: Array) -> float:
	"""Calculate average of array"""
	if array.is_empty():
		return 0.0
	
	var sum = 0.0
	for value in array:
		sum += value
	return sum / array.size()

func _process_parallel_tasks() -> void:
	"""Process parallel tasks"""
	# Check for completed tasks
	for i in range(task_queue.size() - 1, -1, -1):
		var task = task_queue[i]
		if task.has("thread") and task.thread.is_started() and not task.thread.is_alive():
			# Task completed
			completed_tasks.append(task)
			task_queue.remove_at(i)
	
	# Start new tasks if threads are available
	for i in range(task_queue.size()):
		var task = task_queue[i]
		if not task.has("thread") or not task.thread.is_started():
			_start_parallel_task(task)

func _start_parallel_task(task: Dictionary) -> void:
	"""Start a parallel task"""
	var available_thread = _get_available_thread()
	if not available_thread:
		return
	
	task.thread = available_thread
	task.start_time = Time.get_ticks_msec()
	
	# Start the task
	available_thread.start(_execute_parallel_task.bind(task))

func _get_available_thread() -> Thread:
	"""Get an available thread"""
	for thread in thread_pool:
		if not thread.is_started():
			return thread
	return null

func _execute_parallel_task(task_data: Dictionary) -> void:
	"""Execute a parallel task"""
	var task_type = task_data.get("type", "")
	var result = null
	
	match task_type:
		"bullet_collision_check":
			result = _parallel_bullet_collision_check(task_data)
		"enemy_ai_calculation":
			result = _parallel_enemy_ai_calculation(task_data)
		"particle_update":
			result = _parallel_particle_update(task_data)
		"audio_processing":
			result = _parallel_audio_processing(task_data)
		_:
			print("[StabilityManager] Unknown parallel task type: ", task_type)
	
	# Store result
	task_data.result = result
	task_data.completed = true

func _parallel_bullet_collision_check(task_data: Dictionary) -> Array:
	"""Parallel bullet collision checking"""
	var bullets = task_data.get("bullets", [])
	var enemies = task_data.get("enemies", [])
	var collisions = []
	
	# Simple collision checking (can be optimized further)
	for bullet in bullets:
		if not bullet or not is_instance_valid(bullet):
			continue
		
		for enemy in enemies:
			if not enemy or not is_instance_valid(enemy):
				continue
			
			if bullet.global_position.distance_to(enemy.global_position) < 16.0:
				collisions.append({"bullet": bullet, "enemy": enemy})
	
	return collisions

func _parallel_enemy_ai_calculation(task_data: Dictionary) -> Array:
	"""Parallel enemy AI calculations"""
	var enemies = task_data.get("enemies", [])
	var player_pos = task_data.get("player_position", Vector2.ZERO)
	var results = []
	
	for enemy in enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		# Calculate AI decisions
		var direction = (player_pos - enemy.global_position).normalized()
		var distance = enemy.global_position.distance_to(player_pos)
		
		results.append({
			"enemy": enemy,
			"direction": direction,
			"distance": distance,
			"should_attack": distance < 100.0
		})
	
	return results

func _parallel_particle_update(task_data: Dictionary) -> Array:
	"""Parallel particle system updates"""
	var particles = task_data.get("particles", [])
	var delta = task_data.get("delta", 0.0)
	var updated_particles = []
	
	for particle in particles:
		if not particle or not is_instance_valid(particle):
			continue
		
		# Update particle physics
		particle.position += particle.velocity * delta
		particle.velocity += particle.acceleration * delta
		particle.lifetime -= delta
		
		if particle.lifetime > 0.0:
			updated_particles.append(particle)
	
	return updated_particles

func _parallel_audio_processing(task_data: Dictionary) -> Array:
	"""Parallel audio processing"""
	var audio_events = task_data.get("audio_events", [])
	var processed_events = []
	
	for event in audio_events:
		if not event:
			continue
		
		# Process audio event
		var processed_event = {
			"type": event.get("type", ""),
			"volume": event.get("volume", 1.0),
			"pitch": event.get("pitch", 1.0),
			"processed": true
		}
		processed_events.append(processed_event)
	
	return processed_events

func queue_parallel_task(task_type: String, data: Dictionary) -> void:
	"""Queue a parallel task"""
	var task = {
		"type": task_type,
		"data": data,
		"queued_time": Time.get_ticks_msec()
	}
	task_queue.append(task)

func get_completed_tasks() -> Array[Dictionary]:
	"""Get completed tasks"""
	var tasks = completed_tasks.duplicate()
	completed_tasks.clear()
	return tasks

func _update_stability_score() -> void:
	"""Update stability score based on recent performance"""
	var base_score = 100.0
	
	# Reduce score for errors
	base_score -= error_count * 5.0
	base_score -= warning_count * 2.0
	base_score -= crash_count * 20.0
	
	# Reduce score for performance issues
	if frame_times.size() > 0:
		var avg_frame_time = _calculate_average(frame_times)
		if avg_frame_time > 1.0/60.0:  # Below 60fps
			base_score -= (avg_frame_time - 1.0/60.0) * 1000.0
	
	# Reduce score for high memory usage
	if memory_usage.size() > 0:
		var current_memory = memory_usage[-1]
		if current_memory > 50 * 1024 * 1024:  # 50MB
			base_score -= float(current_memory - 50 * 1024 * 1024) / float(1024 * 1024) * 2.0
	
	stability_score = max(0.0, min(100.0, base_score))

func _on_error_occurred(message: String, _error_type: String) -> void:
	"""Handle error events"""
	error_count += 1
	last_error_time = Time.get_ticks_msec()
	
	if development_mode:
		development_log.emit("Error: " + message, "ERROR")

func _on_critical_error(message: String) -> void:
	"""Handle critical error events"""
	crash_count += 1
	
	if development_mode:
		development_log.emit("Critical Error: " + message, "CRITICAL")

func _on_bullet_hit(position: Vector2, _damage: int) -> void:
	"""Handle bullet hit events"""
	if development_mode:
		development_log.emit("Bullet hit at " + str(position), "COMBAT")

func _on_enemy_killed(_points: int, _position: Vector2, enemy_type: String) -> void:
	"""Handle enemy killed events"""
	if development_mode:
		development_log.emit("Enemy killed: " + enemy_type, "COMBAT")

# Development tools
func enable_debug_overlay(enabled: bool) -> void:
	"""Enable/disable debug overlay"""
	debug_overlay_enabled = enabled
	if development_mode:
		development_log.emit("Debug overlay " + ("enabled" if enabled else "disabled"), "DEBUG")

func enable_performance_overlay(enabled: bool) -> void:
	"""Enable/disable performance overlay"""
	performance_overlay_enabled = enabled
	if development_mode:
		development_log.emit("Performance overlay " + ("enabled" if enabled else "disabled"), "DEBUG")

func get_performance_metrics() -> Dictionary:
	"""Get current performance metrics"""
	return {
		"fps": 1.0 / _calculate_average(frame_times) if frame_times.size() > 0 else 0.0,
		"memory_mb": float(memory_usage[-1]) / float(1024 * 1024) if memory_usage.size() > 0 else 0.0,
		"bullet_count": bullet_count_history[-1] if bullet_count_history.size() > 0 else 0,
		"stability_score": stability_score,
		"error_count": error_count,
		"warning_count": warning_count,
		"crash_count": crash_count
	}

func get_development_log() -> Array[String]:
	"""Get development log"""
	# This would be implemented with a proper logging system
	return []

func force_garbage_collection() -> void:
	"""Force garbage collection"""
	# Godot doesn't have explicit GC, but we can help by clearing arrays
	frame_times.clear()
	memory_usage.clear()
	bullet_count_history.clear()
	
	if development_mode:
		development_log.emit("Forced garbage collection", "DEBUG")

func _exit_tree() -> void:
	"""Cleanup on exit"""
	# Stop all threads
	for thread in thread_pool:
		if thread.is_started():
			thread.wait_to_finish()
	
	# Clear arrays
	frame_times.clear()
	memory_usage.clear()
	bullet_count_history.clear()
	task_queue.clear()
	completed_tasks.clear()
