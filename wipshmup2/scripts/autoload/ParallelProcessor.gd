extends Node

# ParallelProcessor - Advanced parallel processing system
# Handles CPU-intensive tasks in parallel threads for better performance

signal task_completed(task_id: String, result: Variant)
signal task_failed(task_id: String, error: String)
# signal parallel_processing_started(task_count: int)  # Reserved for future use
# signal parallel_processing_completed(task_count: int)  # Reserved for future use

# Thread management
var worker_threads: Array[Thread] = []
var max_workers: int = 4
var task_queue: Array[Dictionary] = []
var active_tasks: Dictionary = {}
var completed_tasks: Dictionary = {}

# Thread safety
var _task_mutex: Mutex = Mutex.new()

# Task types and their processors
var task_processors: Dictionary = {}
var task_priorities: Dictionary = {}

# Performance tracking
var tasks_processed: int = 0
var total_processing_time: float = 0.0
var average_task_time: float = 0.0

func _ready() -> void:
	print("[ParallelProcessor] Parallel processing system initialized")
	_initialize_worker_threads()
	_register_task_processors()
	_setup_task_priorities()

func _initialize_worker_threads() -> void:
	"""Initialize worker threads"""
	for i in range(max_workers):
		var thread = Thread.new()
		worker_threads.append(thread)

func _register_task_processors() -> void:
	"""Register task processors for different task types"""
	task_processors["bullet_collision"] = _process_bullet_collision
	task_processors["enemy_ai"] = _process_enemy_ai
	task_processors["particle_system"] = _process_particle_system
	task_processors["audio_processing"] = _process_audio
	task_processors["pathfinding"] = _process_pathfinding
	task_processors["physics_calculation"] = _process_physics
	task_processors["rendering_optimization"] = _process_rendering

func _setup_task_priorities() -> void:
	"""Setup task priorities"""
	task_priorities["bullet_collision"] = 1  # High priority
	task_priorities["enemy_ai"] = 2
	task_priorities["particle_system"] = 3
	task_priorities["audio_processing"] = 4
	task_priorities["pathfinding"] = 2
	task_priorities["physics_calculation"] = 1
	task_priorities["rendering_optimization"] = 5  # Low priority

func _process(_delta: float) -> void:
	"""Process parallel tasks"""
	_process_task_queue()
	_check_completed_tasks()
	_update_performance_metrics()

func _process_task_queue() -> void:
	"""Process queued tasks"""
	_task_mutex.lock()
	# Sort tasks by priority
	task_queue.sort_custom(_compare_task_priority)
	_task_mutex.unlock()
	
	# Start new tasks if workers are available
	_task_mutex.lock()
	for i in range(task_queue.size() - 1, -1, -1):
		var task = task_queue[i]
		var worker = _get_available_worker()
		
		if worker:
			_start_task(task, worker)
			task_queue.remove_at(i)
	_task_mutex.unlock()

func _compare_task_priority(a: Dictionary, b: Dictionary) -> bool:
	"""Compare task priorities for sorting"""
	var priority_a = task_priorities.get(a.get("type", ""), 999)
	var priority_b = task_priorities.get(b.get("type", ""), 999)
	return priority_a < priority_b

func _get_available_worker() -> Thread:
	"""Get an available worker thread"""
	for thread in worker_threads:
		if not thread.is_started():
			return thread
	return null

func _start_task(task: Dictionary, worker: Thread) -> void:
	"""Start a task on a worker thread"""
	var task_id = task.get("id", "")
	var task_type = task.get("type", "")
	
	if task_id in active_tasks:
		print("[ParallelProcessor] Task already active: ", task_id)
		return
	
	# Store task info
	active_tasks[task_id] = {
		"task": task,
		"worker": worker,
		"start_time": Time.get_ticks_msec()
	}
	
	# Start the task
	worker.start(_execute_task.bind(task))
	
	print("[ParallelProcessor] Started task: ", task_id, " (", task_type, ")")

func _execute_task(task_data: Dictionary) -> void:
	"""Execute a task in a worker thread"""
	var task_id = task_data.get("id", "")
	var task_type = task_data.get("type", "")
	var start_time = Time.get_ticks_msec()
	
	var result = null
	var error = ""
	
	# Get the processor for this task type
	var processor = task_processors.get(task_type)
	if processor:
		# Execute processor safely
		result = processor.call(task_data)
		if result == null:
			error = "Task execution failed: " + task_type
	else:
		error = "No processor found for task type: " + task_type
	
	var end_time = Time.get_ticks_msec()
	var processing_time = (end_time - start_time) / 1000.0
	
	# Store result
	completed_tasks[task_id] = {
		"result": result,
		"error": error,
		"processing_time": processing_time,
		"task_type": task_type
	}

func _check_completed_tasks() -> void:
	"""Check for completed tasks"""
	var completed_task_ids = []
	
	for task_id in active_tasks:
		var task_info = active_tasks[task_id]
		var worker = task_info.worker
		
		if not worker.is_started() or not worker.is_alive():
			# Task completed
			completed_task_ids.append(task_id)
			
			# Get result from completed tasks
			if task_id in completed_tasks:
				var completed_task = completed_tasks[task_id]
				var result = completed_task.result
				var error = completed_task.error
				
				if error != "":
					task_failed.emit(task_id, error)
				else:
					task_completed.emit(task_id, result)
				
				# Update performance metrics
				tasks_processed += 1
				total_processing_time += completed_task.processing_time
				average_task_time = total_processing_time / tasks_processed
	
	# Clean up completed tasks
	for task_id in completed_task_ids:
		active_tasks.erase(task_id)
		completed_tasks.erase(task_id)

func _update_performance_metrics() -> void:
	"""Update performance metrics"""
	# This could be expanded with more detailed metrics
	pass

# Task processors
func _process_bullet_collision(task_data: Dictionary) -> Array:
	"""Process bullet collision detection"""
	var bullets = task_data.get("bullets", [])
	var enemies = task_data.get("enemies", [])
	var collisions = []
	
    # Minimal collision detection for coarse pruning
	for bullet in bullets:
		if not bullet or not is_instance_valid(bullet):
			continue
		
		for enemy in enemies:
			if not enemy or not is_instance_valid(enemy):
				continue
			
			if bullet.global_position.distance_to(enemy.global_position) < 16.0:
				collisions.append({
					"bullet": bullet,
					"enemy": enemy,
					"position": bullet.global_position
				})
	
	return collisions

func _process_enemy_ai(task_data: Dictionary) -> Array:
	"""Process enemy AI calculations"""
	var enemies = task_data.get("enemies", [])
	var player_pos = task_data.get("player_position", Vector2.ZERO)
	var delta = task_data.get("delta", 0.0)
	var ai_results = []
	
	for enemy in enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		# Calculate AI decisions
		var direction = (player_pos - enemy.global_position).normalized()
		var distance = enemy.global_position.distance_to(player_pos)
		var should_attack = distance < 100.0
		
		# Calculate movement
		var movement = direction * enemy.get("speed", 50.0) * delta
		
		ai_results.append({
			"enemy": enemy,
			"movement": movement,
			"should_attack": should_attack,
			"direction": direction
		})
	
	return ai_results

func _process_particle_system(task_data: Dictionary) -> Array:
	"""Process particle system updates"""
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

func _process_audio(task_data: Dictionary) -> Array:
	"""Process audio events"""
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

func _process_pathfinding(task_data: Dictionary) -> Array:
	"""Process pathfinding calculations"""
	var start_pos = task_data.get("start_position", Vector2.ZERO)
	var end_pos = task_data.get("end_position", Vector2.ZERO)
	var _obstacles = task_data.get("obstacles", [])
	
    # Basic pathfinding placeholder (replace with A* when needed)
	var path = [start_pos, end_pos]
	
	return path

func _process_physics(task_data: Dictionary) -> Array:
	"""Process physics calculations"""
	var objects = task_data.get("objects", [])
	var delta = task_data.get("delta", 0.0)
	var physics_results = []
	
	for obj in objects:
		if not obj or not is_instance_valid(obj):
			continue
		
		# Calculate physics
		var velocity = obj.get("velocity", Vector2.ZERO)
		var acceleration = obj.get("acceleration", Vector2.ZERO)
		
		velocity += acceleration * delta
		var new_position = obj.get("position", Vector2.ZERO) + velocity * delta
		
		physics_results.append({
			"object": obj,
			"new_position": new_position,
			"new_velocity": velocity
		})
	
	return physics_results

func _process_rendering(task_data: Dictionary) -> Array:
	"""Process rendering optimizations"""
	var render_objects = task_data.get("render_objects", [])
	var camera_pos = task_data.get("camera_position", Vector2.ZERO)
	var culled_objects = []
	
	for obj in render_objects:
		if not obj or not is_instance_valid(obj):
			continue
		
        # Coarse culling based on distance
		var distance = obj.global_position.distance_to(camera_pos)
		if distance > 500.0:  # Cull objects far from camera
			culled_objects.append(obj)
	
	return culled_objects

# Public API
func queue_task(task_type: String, data: Dictionary, priority: int = 0) -> String:
	"""Queue a task for parallel processing"""
	var task_id = _generate_task_id()
	
	var task = {
		"id": task_id,
		"type": task_type,
		"data": data,
		"priority": priority,
		"queued_time": Time.get_ticks_msec()
	}
	
	_task_mutex.lock()
	task_queue.append(task)
	_task_mutex.unlock()
	
	print("[ParallelProcessor] Queued task: ", task_id, " (", task_type, ")")
	return task_id

func _generate_task_id() -> String:
	"""Generate a unique task ID"""
	return "task_" + str(Time.get_ticks_msec()) + "_" + str(randi())

func get_task_status(task_id: String) -> String:
	"""Get the status of a task"""
	if task_id in active_tasks:
		return "active"
	elif task_id in completed_tasks:
		return "completed"
	else:
		return "not_found"

func get_task_result(task_id: String) -> Variant:
	"""Get the result of a completed task"""
	if task_id in completed_tasks:
		return completed_tasks[task_id].result
	return null

func cancel_task(task_id: String) -> bool:
	"""Cancel a queued or active task"""
	_task_mutex.lock()
	# Remove from queue
	for i in range(task_queue.size() - 1, -1, -1):
		if task_queue[i].id == task_id:
			task_queue.remove_at(i)
			_task_mutex.unlock()
			return true
	_task_mutex.unlock()
	
	# Cancel active task
	if task_id in active_tasks:
		var task_info = active_tasks[task_id]
		var worker = task_info.worker
		
		if worker.is_started():
			worker.wait_to_finish()
		
		active_tasks.erase(task_id)
		return true
	
	return false

func get_performance_metrics() -> Dictionary:
	"""Get performance metrics"""
	return {
		"tasks_processed": tasks_processed,
		"total_processing_time": total_processing_time,
		"average_task_time": average_task_time,
		"queued_tasks": task_queue.size(),
		"active_tasks": active_tasks.size(),
		"completed_tasks": completed_tasks.size()
	}

func clear_completed_tasks() -> void:
	"""Clear completed tasks"""
	completed_tasks.clear()

func _exit_tree() -> void:
	"""Cleanup on exit"""
	# Stop all worker threads
	for thread in worker_threads:
		if thread.is_started():
			thread.wait_to_finish()
	
	# Clear all data
	task_queue.clear()
	active_tasks.clear()
	completed_tasks.clear()
