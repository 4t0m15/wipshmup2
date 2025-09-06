extends Node
class_name BackgroundPerformanceTest

# Performance testing for background scrolling system
@export var test_duration: float = 10.0
@export var log_interval: float = 1.0
@export var enable_stress_test: bool = false

var _start_time: float
var _frame_count: int = 0
var _last_log_time: float
var _fps_samples: Array[float] = []
var _memory_samples: Array[int] = []

# References to background systems
var _space_background: SpaceBackground
var _parallax_background: CustomParallaxBackground

func _ready():
	# Find background systems
	_space_background = get_node_or_null("/root/Main/GameViewport/SpaceBackground")
	if _space_background and _space_background.has_method("get") and _space_background.get("parallax_background"):
		_parallax_background = _space_background.parallax_background

	_start_time = Time.get_ticks_msec() / 1000.0
	_last_log_time = _start_time

	print("=== Background Performance Test Started ===")
	print("Test Duration: ", test_duration, " seconds")
	print("Log Interval: ", log_interval, " seconds")

	if enable_stress_test:
		_start_stress_test()

func _process(delta: float):
	_frame_count += 1

	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed = current_time - _start_time

	# Log performance metrics at intervals
	if current_time - _last_log_time >= log_interval:
		_log_performance_metrics(current_time)
		_last_log_time = current_time

	# End test after duration
	if elapsed >= test_duration:
		_end_test()
		return

	# Stress test modifications
	if enable_stress_test:
		_apply_stress_test(delta)

func _log_performance_metrics(current_time: float):
	"""Log current performance metrics"""
	var fps = _frame_count / (current_time - _start_time)
	var memory_usage = OS.get_static_memory_usage()

	_fps_samples.append(fps)
	_memory_samples.append(memory_usage)

	print("Time: %.1fs | FPS: %.1f | Memory: %d KB | Frames: %d" % [
		current_time - _start_time,
		fps,
		memory_usage / 1024,
		_frame_count
	])

	# Log background-specific metrics
	if _space_background:
		var scroll_offset = _space_background.get_scroll_offset() if _space_background.has_method("get_scroll_offset") else Vector2.ZERO
		print("  Background Scroll: ", scroll_offset)

	if _parallax_background:
		var layers_count = _parallax_background.layers.size() if _parallax_background.has_method("get") else 0
		print("  Parallax Layers: ", layers_count)

func _start_stress_test():
	"""Start stress testing by adding more background elements"""
	print("Starting stress test...")

	if _space_background:
		# Increase star count
		_space_background.star_count = 500
		_space_background.planet_count = 20

		# Reduce update frequency to stress test
		_space_background.update_frequency = 0.1

		# Recreate elements
		_space_background._create_star_field()
		_space_background._create_planets()

func _apply_stress_test(delta: float):
	"""Apply stress test modifications during runtime"""
	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed = current_time - _start_time

	# Gradually increase scroll speed
	if _space_background:
		var speed_multiplier = 1.0 + (elapsed * 0.5)  # Increase speed over time
		_space_background.set_scroll_speed(Vector2(50.0 * speed_multiplier, 0.0))

	# Add more parallax layers periodically
	if _parallax_background and int(elapsed) % 2 == 0 and elapsed > 2.0:
		# Add a new layer every 2 seconds
		var new_layer_count = _parallax_background.layers.size()
		if new_layer_count < 10:  # Limit to prevent memory issues
			_parallax_background.add_layer(
				preload("res://assets/Space/Asteroid.png"),
				Vector2(0.1 + new_layer_count * 0.1, 0.1 + new_layer_count * 0.1)
			)

func _end_test():
	"""End the performance test and print summary"""
	print("\n=== Background Performance Test Results ===")

	# Calculate average FPS
	var avg_fps = 0.0
	if _fps_samples.size() > 0:
		for fps in _fps_samples:
			avg_fps += fps
		avg_fps /= _fps_samples.size()

	# Calculate average memory usage
	var avg_memory = 0
	if _memory_samples.size() > 0:
		for memory in _memory_samples:
			avg_memory += memory
		avg_memory /= _memory_samples.size()

	# Calculate min/max FPS
	var min_fps = _fps_samples.min() if _fps_samples.size() > 0 else 0.0
	var max_fps = _fps_samples.max() if _fps_samples.size() > 0 else 0.0

	print("Test Duration: %.1f seconds" % test_duration)
	print("Total Frames: %d" % _frame_count)
	print("Average FPS: %.1f" % avg_fps)
	print("Min FPS: %.1f" % min_fps)
	print("Max FPS: %.1f" % max_fps)
	print("Average Memory: %d KB" % (avg_memory / 1024))
	print("Peak Memory: %d KB" % (_memory_samples.max() / 1024 if _memory_samples.size() > 0 else 0))

	# Performance assessment
	print("\n=== Performance Assessment ===")
	if avg_fps >= 55.0:
		print("✓ EXCELLENT: Smooth 60 FPS performance")
	elif avg_fps >= 45.0:
		print("✓ GOOD: Playable performance with minor drops")
	elif avg_fps >= 30.0:
		print("⚠ ACCEPTABLE: Playable but noticeable frame drops")
	else:
		print("✗ POOR: Significant performance issues detected")

	# Memory assessment
	var peak_memory_mb = (_memory_samples.max() / 1024 / 1024) if _memory_samples.size() > 0 else 0
	if peak_memory_mb < 100:
		print("✓ EXCELLENT: Low memory usage")
	elif peak_memory_mb < 200:
		print("✓ GOOD: Reasonable memory usage")
	elif peak_memory_mb < 500:
		print("⚠ ACCEPTABLE: High memory usage")
	else:
		print("✗ POOR: Excessive memory usage")

	print("=== Test Complete ===")

	# Stop the test
	set_process(false)

func get_performance_summary() -> Dictionary:
	"""Get a summary of performance metrics"""
	var avg_fps = 0.0
	if _fps_samples.size() > 0:
		for fps in _fps_samples:
			avg_fps += fps
		avg_fps /= _fps_samples.size()

	var avg_memory = 0
	if _memory_samples.size() > 0:
		for memory in _memory_samples:
			avg_memory += memory
		avg_memory /= _memory_samples.size()

	return {
		"duration": test_duration,
		"total_frames": _frame_count,
		"average_fps": avg_fps,
		"min_fps": _fps_samples.min() if _fps_samples.size() > 0 else 0.0,
		"max_fps": _fps_samples.max() if _fps_samples.size() > 0 else 0.0,
		"average_memory_kb": avg_memory / 1024,
		"peak_memory_kb": (_memory_samples.max() / 1024) if _memory_samples.size() > 0 else 0
	}
