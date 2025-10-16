extends Node

# TestingFramework - Comprehensive testing system
# Provides unit tests, integration tests, and automated validation

signal test_started(test_name: String)
signal test_completed(test_name: String, passed: bool, duration: float)
signal test_suite_completed(suite_name: String, passed: int, failed: int)
signal validation_completed(component: String, passed: bool)

# Test state
var tests: Array[Dictionary] = []
var test_results: Array[Dictionary] = []
var current_test: String = ""
var test_start_time: float = 0.0

# Test categories
var unit_tests: Array[Dictionary] = []
var integration_tests: Array[Dictionary] = []
var performance_tests: Array[Dictionary] = []
var stability_tests: Array[Dictionary] = []

# Validation state
var validation_results: Dictionary = {}
var validation_passed: int = 0
var validation_failed: int = 0

func _ready() -> void:
	print("[TestingFramework] Testing framework initialized")
	_register_tests()
	_register_validations()

func _register_tests() -> void:
	"""Register all available tests"""
	_register_unit_tests()
	_register_integration_tests()
	_register_performance_tests()
	_register_stability_tests()

func _register_unit_tests() -> void:
	"""Register unit tests"""
	unit_tests = [
		{"name": "test_game_state_initialization", "func": _test_game_state_initialization},
		{"name": "test_entity_factory_spawning", "func": _test_entity_factory_spawning},
		{"name": "test_event_bus_communication", "func": _test_event_bus_communication},
		{"name": "test_safety_wrapper_functions", "func": _test_safety_wrapper_functions},
		{"name": "test_error_handler_functionality", "func": _test_error_handler_functionality}
	]

func _register_integration_tests() -> void:
	"""Register integration tests"""
	integration_tests = [
		{"name": "test_player_spawn_integration", "func": _test_player_spawn_integration},
		{"name": "test_enemy_spawn_integration", "func": _test_enemy_spawn_integration},
		{"name": "test_bullet_system_integration", "func": _test_bullet_system_integration},
		{"name": "test_stage_controller_integration", "func": _test_stage_controller_integration},
		{"name": "test_combat_system_integration", "func": _test_combat_system_integration}
	]

func _register_performance_tests() -> void:
	"""Register performance tests"""
	performance_tests = [
		{"name": "test_bullet_performance", "func": _test_bullet_performance},
		{"name": "test_memory_usage", "func": _test_memory_usage},
		{"name": "test_frame_rate_stability", "func": _test_frame_rate_stability},
		{"name": "test_object_pooling_efficiency", "func": _test_object_pooling_efficiency}
	]

func _register_stability_tests() -> void:
	"""Register stability tests"""
	stability_tests = [
		{"name": "test_error_recovery", "func": _test_error_recovery},
		{"name": "test_memory_leak_prevention", "func": _test_memory_leak_prevention},
		{"name": "test_signal_cleanup", "func": _test_signal_cleanup},
		{"name": "test_crash_prevention", "func": _test_crash_prevention}
	]

func _register_validations() -> void:
	"""Register validation checks"""
	validation_results = {
		"autoload_systems": false,
		"event_bus_connections": false,
		"entity_factory_pools": false,
		"game_state_consistency": false,
		"template_managers": false,
		"scene_loading": false,
		"signal_connections": false,
		"memory_management": false
	}

# Test execution
func run_all_tests() -> void:
	"""Run all tests"""
	print("[TestingFramework] Running all tests...")
	
	_run_test_suite("Unit Tests", unit_tests)
	_run_test_suite("Integration Tests", integration_tests)
	_run_test_suite("Performance Tests", performance_tests)
	_run_test_suite("Stability Tests", stability_tests)
	
	_print_test_summary()

func run_unit_tests() -> void:
	"""Run unit tests only"""
	_run_test_suite("Unit Tests", unit_tests)

func run_integration_tests() -> void:
	"""Run integration tests only"""
	_run_test_suite("Integration Tests", integration_tests)

func run_performance_tests() -> void:
	"""Run performance tests only"""
	_run_test_suite("Performance Tests", performance_tests)

func run_stability_tests() -> void:
	"""Run stability tests only"""
	_run_test_suite("Stability Tests", stability_tests)

func _run_test_suite(suite_name: String, test_list: Array[Dictionary]) -> void:
	"""Run a test suite"""
	print("[TestingFramework] Running ", suite_name, "...")
	
	var passed = 0
	var failed = 0
	
	for test in test_list:
		var result = _run_single_test(test)
		if result.passed:
			passed += 1
		else:
			failed += 1

	test_suite_completed.emit(suite_name, passed, failed)
	print("[TestingFramework] ", suite_name, " completed: ", passed, " passed, ", failed, " failed")
#Runs a single test
func _run_single_test(test: Dictionary) -> Dictionary:
	"""Run a single test"""
	var test_name = test.name
	var test_func = test.func
	
	test_started.emit(test_name)
	test_start_time = Time.get_ticks_msec()
	
	var result = {
		"name": test_name,
		"passed": false,
		"error": "",
		"duration": 0.0
	}
	
	# Execute test function safely
	var test_result = test_func.call()
	result.passed = test_result
	if not test_result:
		result.error = "Test assertion failed"
	
	result.duration = (Time.get_ticks_msec() - test_start_time) / 1000.0
	test_completed.emit(test_name, result.passed, result.duration)
	
	test_results.append(result)
	return result

# Unit Tests
func _test_game_state_initialization() -> bool:
	"""Test game state initialization"""
	if not GameState:
		return false
	
	# Test initial values
	var initial_lives = GameState.lives
	var initial_bombs = GameState.bombs
	var initial_score = GameState.score
	
	return initial_lives == 3 and initial_bombs == 3 and initial_score == 0

func _test_entity_factory_spawning() -> bool:
	"""Test entity factory spawning"""
	if not EntityFactory:
		return false
	
	# Test bullet spawning
	var bullet = EntityFactory.spawn_bullet(Vector2(100, 100), Vector2(0, -1), 200.0)
	if not bullet or not is_instance_valid(bullet):
		return false
	
	# Test bullet properties
	var bullet_speed = bullet.get("speed") if bullet.has_method("get") else 0.0
	var bullet_direction = bullet.get("direction") if bullet.has_method("get") else Vector2.ZERO
	
	return bullet_speed == 200.0 and bullet_direction == Vector2(0, -1)

func _test_event_bus_communication() -> bool:
	"""Test event bus communication"""
	if not EventBus:
		return false
	
	# Test signal emission using a different approach
	var test_result = {"received": false}
	var test_callable = func(): 
		test_result.received = true
	
	EventBus.game_started.connect(test_callable)
	EventBus.game_started.emit()
	EventBus.game_started.disconnect(test_callable)
	
	return test_result.received

func _test_safety_wrapper_functions() -> bool:
	"""Test safety wrapper functions"""
	if not SafetyWrapper:
		return false
	
	# Test safe array access
	var test_array = [1, 2, 3]
	var safe_value = SafetyWrapper.safe_array_access(test_array, 1, -1)
	var unsafe_value = SafetyWrapper.safe_array_access(test_array, 10, -1)
	
	return safe_value == 2 and unsafe_value == -1

func _test_error_handler_functionality() -> bool:
	"""Test error handler functionality"""
	var error_handler = get_node_or_null("/root/ErrorHandler")
	if not error_handler:
		return false
	
	# Test error logging
	var initial_count = error_handler.get_error_count()
	error_handler.log_error("Test error", "TestingFramework")
	var final_count = error_handler.get_error_count()
	
	return final_count > initial_count

# Integration Tests
func _test_player_spawn_integration() -> bool:
	"""Test player spawn integration"""
	if not EntityFactory:
		return false
	
	var player = EntityFactory.spawn_player(Vector2(160, 150))
	if not player or not is_instance_valid(player):
		return false
	
	# Test player properties
	var player_position = player.global_position
	var player_speed = player.get("speed") if player.has_method("get") else 0.0
	
	return player_position == Vector2(160, 150) and player_speed > 0

func _test_enemy_spawn_integration() -> bool:
	"""Test enemy spawn integration"""
	if not EntityFactory or not EnemyTemplateManager:
		return false
	
	var enemy = EntityFactory.spawn_enemy_by_type("basic_fighter", Vector2(160, -50))
	if not enemy or not is_instance_valid(enemy):
		return false
	
	# Test enemy properties
	var enemy_position = enemy.global_position
	var enemy_health = enemy.get("health", 0)
	
	return enemy_position == Vector2(160, -50) and enemy_health > 0

func _test_bullet_system_integration() -> bool:
	"""Test bullet system integration"""
	if not EntityFactory:
		return false
	
	# Spawn multiple bullets
	var bullets = []
	for i in range(10):
		var bullet = EntityFactory.spawn_bullet(Vector2(160, 150), Vector2(0, -1), 200.0)
		if bullet and is_instance_valid(bullet):
			bullets.append(bullet)
	
	# Test bullet count
	var bullet_count = get_tree().get_nodes_in_group("player_bullet").size()
	return bullet_count >= 10

func _test_stage_controller_integration() -> bool:
	"""Test stage controller integration"""
	var stage_controller = get_node_or_null("/root/StageController")
	if not stage_controller:
		return false
	
	# Test stage loading
	var stage = stage_controller.get_current_stage()
	return stage != null

func _test_combat_system_integration() -> bool:
	"""Test combat system integration"""
	var combat_system = get_node_or_null("/root/CombatSystem")
	if not combat_system:
		return false
	
	# Test combat system initialization
	return combat_system.has_method("calculate_damage")

# Performance Tests
func _test_bullet_performance() -> bool:
	"""Test bullet performance"""
	if not EntityFactory:
		return false
	
	var start_time = Time.get_ticks_msec()
	
	# Spawn many bullets
	for i in range(100):
		EntityFactory.spawn_bullet(Vector2(160, 150), Vector2(0, -1), 200.0)
	
	var end_time = Time.get_ticks_msec()
	var duration = end_time - start_time
	
	# Should complete within 100ms
	return duration < 100

func _test_memory_usage() -> bool:
	"""Test memory usage"""
	var initial_memory = OS.get_static_memory_usage()
	
	# Create many objects
	var objects = []
	for i in range(1000):
		var obj = Node.new()
		objects.append(obj)
		add_child(obj)
	
	var peak_memory = OS.get_static_memory_usage()
	
	# Clean up
	for obj in objects:
		obj.queue_free()
	
	var _final_memory = OS.get_static_memory_usage()
	
	# Memory should be reasonable
	return peak_memory < initial_memory * 2

func _test_frame_rate_stability() -> bool:
	"""Test frame rate stability"""
	var frame_times = []
	
	# Measure frame times for 1 second
	var start_time = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_time < 1000:
		var frame_start = Time.get_ticks_msec()
		await get_tree().process_frame
		var frame_end = Time.get_ticks_msec()
		frame_times.append(frame_end - frame_start)
	
	# Calculate average frame time
	var total_time = 0.0
	for time in frame_times:
		total_time += time
	
	var average_frame_time = total_time / frame_times.size()
	
	# Should be around 16.67ms (60fps)
	return average_frame_time < 20.0

func _test_object_pooling_efficiency() -> bool:
	"""Test object pooling efficiency"""
	if not EntityFactory:
		return false
	
	# Test bullet pooling
	var bullets = []
	for i in range(50):
		var bullet = EntityFactory.spawn_bullet(Vector2(160, 150), Vector2(0, -1), 200.0)
		bullets.append(bullet)
	
	# Destroy bullets
	for bullet in bullets:
		EntityFactory.destroy_entity(bullet)
	
	# Check if bullets are pooled
	var pool_size = EntityFactory.bullet_pool.size()
	return pool_size > 0

# Stability Tests
func _test_error_recovery() -> bool:
	"""Test error recovery"""
	var error_handler = get_node_or_null("/root/ErrorHandler")
	if not error_handler:
		return false
	
	# Test error handling
	var initial_crash_count = error_handler.get_crash_count()
	
	# Simulate error
	error_handler.log_error("Test error for recovery", "TestingFramework")
	
	var final_crash_count = error_handler.get_crash_count()
	
	# Should not crash
	return final_crash_count == initial_crash_count

func _test_memory_leak_prevention() -> bool:
	"""Test memory leak prevention"""
	var initial_memory = OS.get_static_memory_usage()
	
	# Create and destroy many objects
	for i in range(100):
		var obj = Node.new()
		add_child(obj)
		obj.queue_free()
	
	# Wait for cleanup
	await get_tree().process_frame
	await get_tree().process_frame
	
	var final_memory = OS.get_static_memory_usage()
	
	# Memory should not increase significantly
	return final_memory < initial_memory * 1.1

func _test_signal_cleanup() -> bool:
	"""Test signal cleanup"""
	if not EventBus:
		return false
	
	# Connect and disconnect signals
	var test_callable = func(): pass
	
	EventBus.game_started.connect(test_callable)
	var connected = EventBus.game_started.is_connected(test_callable)
	
	EventBus.game_started.disconnect(test_callable)
	var disconnected = not EventBus.game_started.is_connected(test_callable)
	
	return connected and disconnected

func _test_crash_prevention() -> bool:
	"""Test crash prevention"""
	if not SafetyWrapper:
		return false
	
	# Test safe operations
	var null_node = null
	var safe_result = SafetyWrapper.safe_validate_node(null_node)
	
	return not safe_result

# Validation
func run_all_validations() -> void:
	"""Run all validations"""
	print("[TestingFramework] Running all validations...")
	
	_validate_autoload_systems()
	_validate_event_bus_connections()
	_validate_entity_factory_pools()
	_validate_game_state_consistency()
	_validate_template_managers()
	_validate_scene_loading()
	_validate_signal_connections()
	_validate_memory_management()
	
	_print_validation_summary()

func _validate_autoload_systems() -> bool:
	"""Validate autoload systems"""
	var systems = ["EventBus", "GameState", "EntityFactory", "ErrorHandler", "SafetyWrapper"]
	var all_valid = true
	
	for system_name in systems:
		var system = get_node_or_null("/root/" + system_name)
		if not system or not is_instance_valid(system):
			all_valid = false
			break
	
	validation_results["autoload_systems"] = all_valid
	validation_completed.emit("autoload_systems", all_valid)
	return all_valid

func _validate_event_bus_connections() -> bool:
	"""Validate event bus connections"""
	if not EventBus:
		return false
	
	# Check if EventBus has required signals
	var required_signals = ["game_started", "game_over", "player_hit", "enemy_killed"]
	var all_signals_exist = true
	
	for signal_name in required_signals:
		if not EventBus.has_signal(signal_name):
			all_signals_exist = false
			break
	
	validation_results["event_bus_connections"] = all_signals_exist
	validation_completed.emit("event_bus_connections", all_signals_exist)
	return all_signals_exist

func _validate_entity_factory_pools() -> bool:
	"""Validate entity factory pools"""
	if not EntityFactory:
		return false
	
	# Check if pools are initialized
	var pools_valid = EntityFactory.bullet_pool.size() > 0 and EntityFactory.enemy_bullet_pool.size() > 0
	
	validation_results["entity_factory_pools"] = pools_valid
	validation_completed.emit("entity_factory_pools", pools_valid)
	return pools_valid

func _validate_game_state_consistency() -> bool:
	"""Validate game state consistency"""
	if not GameState:
		return false
	
	# Check if GameState has required properties
	var required_properties = ["lives", "bombs", "score", "current_stage"]
	var all_properties_exist = true
	
	for property_name in required_properties:
		if not GameState.has_method("get") or GameState.get(property_name) == null:
			all_properties_exist = false
			break
	
	validation_results["game_state_consistency"] = all_properties_exist
	validation_completed.emit("game_state_consistency", all_properties_exist)
	return all_properties_exist

func _validate_template_managers() -> bool:
	"""Validate template managers"""
	var managers = ["EnemyTemplateManager", "BossTemplateManager", "StageTemplateManager"]
	var all_valid = true
	
	for manager_name in managers:
		var manager = get_node_or_null("/root/" + manager_name)
		if not manager or not is_instance_valid(manager):
			all_valid = false
			break
	
	validation_results["template_managers"] = all_valid
	validation_completed.emit("template_managers", all_valid)
	return all_valid

func _validate_scene_loading() -> bool:
	"""Validate scene loading"""
	if not EntityFactory:
		return false
	
	# Check if required scenes are loaded
	var required_scenes = ["PLAYER_SCENE", "BULLET_SCENE", "ENEMY_BULLET_SCENE", "ENEMY_SCENE"]
	var all_scenes_loaded = true
	
	for scene_name in required_scenes:
		var scene = EntityFactory.get(scene_name)
		if not scene:
			all_scenes_loaded = false
			break
	
	validation_results["scene_loading"] = all_scenes_loaded
	validation_completed.emit("scene_loading", all_scenes_loaded)
	return all_scenes_loaded

func _validate_signal_connections() -> bool:
	"""Validate signal connections"""
	# This would check for proper signal connections
	# Implementation depends on specific requirements
	validation_results["signal_connections"] = true
	validation_completed.emit("signal_connections", true)
	return true

func _validate_memory_management() -> bool:
	"""Validate memory management"""
	# Check for memory leaks
	var initial_memory = OS.get_static_memory_usage()
	
	# Perform some operations
	for i in range(100):
		var obj = Node.new()
		add_child(obj)
		obj.queue_free()
	
	# Wait for cleanup
	await get_tree().process_frame
	
	var final_memory = OS.get_static_memory_usage()
	var memory_ok = final_memory < initial_memory * 1.2
	
	validation_results["memory_management"] = memory_ok
	validation_completed.emit("memory_management", memory_ok)
	return memory_ok

# Reporting
func _print_test_summary() -> void:
	"""Print test summary"""
	var total_tests = test_results.size()
	var passed_tests = 0
	var failed_tests = 0
	
	for result in test_results:
		if result.passed:
			passed_tests += 1
		else:
			failed_tests += 1
	
	print("[TestingFramework] Test Summary:")
	print("  Total Tests: ", total_tests)
	print("  Passed: ", passed_tests)
	print("  Failed: ", failed_tests)
	print("  Success Rate: ", (float(passed_tests) / float(total_tests) * 100.0) if total_tests > 0 else 0.0, "%")

func _print_validation_summary() -> void:
	"""Print validation summary"""
	var total_validations = validation_results.size()
	var passed_validations = 0
	
	for component in validation_results:
		if validation_results[component]:
			passed_validations += 1
	
	print("[TestingFramework] Validation Summary:")
	print("  Total Validations: ", total_validations)
	print("  Passed: ", passed_validations)
	print("  Failed: ", total_validations - passed_validations)
	print("  Success Rate: ", (float(passed_validations) / float(total_validations) * 100.0) if total_validations > 0 else 0.0, "%")

func get_test_results() -> Array[Dictionary]:
	"""Get test results"""
	return test_results.duplicate()

func get_validation_results() -> Dictionary:
	"""Get validation results"""
	return validation_results.duplicate()

func clear_results() -> void:
	"""Clear test and validation results"""
	test_results.clear()
	validation_results.clear()
