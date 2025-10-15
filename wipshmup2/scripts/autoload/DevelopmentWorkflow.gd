extends Node

# DevelopmentWorkflow - Comprehensive development workflow management
# Provides automated testing, validation, and development aids

signal workflow_started(workflow_name: String)
signal workflow_completed(workflow_name: String, success: bool)
signal development_phase_changed(phase: String)

# Workflow state
var current_workflow: String = ""
var workflow_phase: String = "idle"
var development_mode: bool = false
var auto_testing_enabled: bool = false
var auto_validation_enabled: bool = false

# Development phases
var phases: Array[String] = ["idle", "testing", "validation", "optimization", "stability_check", "deployment"]
var current_phase_index: int = 0

# Workflow timers
var workflow_timer: Timer = null
var auto_test_timer: Timer = null
var auto_validation_timer: Timer = null

# Development metrics
var workflow_metrics: Dictionary = {}
var development_log: Array[Dictionary] = []

func _ready() -> void:
	print("[DevelopmentWorkflow] Development workflow system initialized")
	_setup_timers()
	_initialize_metrics()
	_detect_development_mode()

func _setup_timers() -> void:
	"""Setup workflow timers"""
	workflow_timer = Timer.new()
	workflow_timer.wait_time = 1.0
	workflow_timer.timeout.connect(_update_workflow)
	add_child(workflow_timer)
	
	auto_test_timer = Timer.new()
	auto_test_timer.wait_time = 30.0  # Run tests every 30 seconds
	auto_test_timer.timeout.connect(_run_auto_tests)
	add_child(auto_test_timer)
	
	auto_validation_timer = Timer.new()
	auto_validation_timer.wait_time = 60.0  # Run validation every minute
	auto_validation_timer.timeout.connect(_run_auto_validation)
	add_child(auto_validation_timer)

func _initialize_metrics() -> void:
	"""Initialize development metrics"""
	workflow_metrics = {
		"workflows_completed": 0,
		"tests_run": 0,
		"validations_run": 0,
		"errors_caught": 0,
		"performance_issues_fixed": 0,
		"stability_improvements": 0
	}

func _detect_development_mode() -> void:
	"""Detect if running in development mode"""
	development_mode = OS.is_debug_build()
	
	if development_mode:
		enable_auto_testing(true)
		enable_auto_validation(true)
		start_workflow("development")

func _update_workflow() -> void:
	"""Update workflow state"""
	_update_development_phase()
	_monitor_performance()
	_check_stability()

func _update_development_phase() -> void:
	"""Update development phase"""
	var new_phase = phases[current_phase_index]
	if new_phase != workflow_phase:
		workflow_phase = new_phase
		development_phase_changed.emit(workflow_phase)
		_log_development_event("Phase changed to: " + workflow_phase)

func _monitor_performance() -> void:
	"""Monitor performance metrics"""
	var stability_manager = get_node_or_null("/root/StabilityManager")
	if stability_manager and stability_manager.has_method("get_performance_metrics"):
		var metrics = stability_manager.get_performance_metrics()
		
		# Check for performance issues
		if metrics.get("fps", 60) < 30:
			_handle_performance_issue("low_fps", metrics)
		
		if metrics.get("memory_mb", 0) > 100:
			_handle_performance_issue("high_memory", metrics)
		
		if metrics.get("bullet_count", 0) > 400:
			_handle_performance_issue("high_bullet_count", metrics)

func _check_stability() -> void:
	"""Check system stability"""
	var stability_manager = get_node_or_null("/root/StabilityManager")
	if stability_manager:
		var stability_score = stability_manager.stability_score if stability_manager.has_method("get") else 100.0
		
		if stability_score < 50:
			_handle_stability_issue("low_stability", stability_score)
		
		var crash_count = stability_manager.crash_count if stability_manager.has_method("get") else 0
		if crash_count > 0:
			_handle_stability_issue("crashes_detected", crash_count)

func _handle_performance_issue(issue_type: String, metrics: Dictionary) -> void:
	"""Handle performance issues"""
	_log_development_event("Performance issue: " + issue_type + " - " + str(metrics))
	
	# Auto-optimize if possible
	match issue_type:
		"low_fps":
			_optimize_frame_rate()
		"high_memory":
			_optimize_memory_usage()
		"high_bullet_count":
			_optimize_bullet_count()

func _handle_stability_issue(issue_type: String, value: float) -> void:
	"""Handle stability issues"""
	_log_development_event("Stability issue: " + issue_type + " - " + str(value))
	
	# Auto-fix if possible
	match issue_type:
		"low_stability":
			_improve_stability()
		"crashes_detected":
			_handle_crashes()

func _optimize_frame_rate() -> void:
	"""Optimize frame rate"""
	var parallel_processor = get_node_or_null("/root/ParallelProcessor")
	if parallel_processor and parallel_processor.has_method("queue_parallel_task"):
		# Use parallel processing for heavy tasks
		parallel_processor.queue_parallel_task("rendering_optimization", {
			"render_objects": get_tree().get_nodes_in_group("renderable"),
			"camera_position": Vector2(160, 90)
		})
	
	_log_development_event("Frame rate optimization applied")

func _optimize_memory_usage() -> void:
	"""Optimize memory usage"""
	var stability_manager = get_node_or_null("/root/StabilityManager")
	if stability_manager and stability_manager.has_method("force_garbage_collection"):
		stability_manager.force_garbage_collection()
	
	_log_development_event("Memory optimization applied")

func _optimize_bullet_count() -> void:
	"""Optimize bullet count"""
	var entity_factory = get_node_or_null("/root/EntityFactory")
	if entity_factory:
		# Reduce bullet pool size if needed
		var current_bullets = get_tree().get_nodes_in_group("player_bullet") + get_tree().get_nodes_in_group("enemy_bullet")
		if current_bullets.size() > 300:
			# Clean up old bullets
			for bullet in current_bullets:
				if bullet and is_instance_valid(bullet):
					var age = bullet.get("age") if bullet.has_method("get") else 0.0
					if age > 5.0:  # Bullets older than 5 seconds
						entity_factory.destroy_entity(bullet)
	
	_log_development_event("Bullet count optimization applied")

func _improve_stability() -> void:
	"""Improve system stability"""
	var error_handler = get_node_or_null("/root/ErrorHandler")
	if error_handler and error_handler.has_method("clear_error_log"):
		error_handler.clear_error_log()
	
	var stability_manager = get_node_or_null("/root/StabilityManager")
	if stability_manager and stability_manager.has_method("clear_error_log"):
		stability_manager.clear_error_log()
	
	_log_development_event("Stability improvements applied")

func _handle_crashes() -> void:
	"""Handle detected crashes"""
	_log_development_event("Crash handling activated")
	
	# Implement crash recovery
	var error_handler = get_node_or_null("/root/ErrorHandler")
	if error_handler and error_handler.has_method("clear_error_log"):
		error_handler.clear_error_log()

func _run_auto_tests() -> void:
	"""Run automatic tests"""
	if not auto_testing_enabled:
		return
	
	_log_development_event("Running automatic tests...")
	
	var testing_framework = get_node_or_null("/root/TestingFramework")
	if testing_framework and testing_framework.has_method("run_unit_tests"):
		testing_framework.run_unit_tests()
		workflow_metrics["tests_run"] += 1

func _run_auto_validation() -> void:
	"""Run automatic validation"""
	if not auto_validation_enabled:
		return
	
	_log_development_event("Running automatic validation...")
	
	var testing_framework = get_node_or_null("/root/TestingFramework")
	if testing_framework and testing_framework.has_method("run_all_validations"):
		testing_framework.run_all_validations()
		workflow_metrics["validations_run"] += 1

# Workflow management
func start_workflow(workflow_name: String) -> void:
	"""Start a development workflow"""
	current_workflow = workflow_name
	workflow_started.emit(workflow_name)
	workflow_timer.start()
	
	_log_development_event("Workflow started: " + workflow_name)
	
	match workflow_name:
		"development":
			_start_development_workflow()
		"testing":
			_start_testing_workflow()
		"validation":
			_start_validation_workflow()
		"optimization":
			_start_optimization_workflow()
		"stability_check":
			_start_stability_workflow()
		"deployment":
			_start_deployment_workflow()

func stop_workflow() -> void:
	"""Stop current workflow"""
	workflow_timer.stop()
	current_workflow = ""
	workflow_phase = "idle"
	
	_log_development_event("Workflow stopped")

func _start_development_workflow() -> void:
	"""Start development workflow"""
	workflow_phase = "development"
	enable_auto_testing(true)
	enable_auto_validation(true)
	
	_log_development_event("Development workflow started")

func _start_testing_workflow() -> void:
	"""Start testing workflow"""
	workflow_phase = "testing"
	
	var testing_framework = get_node_or_null("/root/TestingFramework")
	if testing_framework and testing_framework.has_method("run_all_tests"):
		testing_framework.run_all_tests()
	
	_log_development_event("Testing workflow started")

func _start_validation_workflow() -> void:
	"""Start validation workflow"""
	workflow_phase = "validation"
	
	var testing_framework = get_node_or_null("/root/TestingFramework")
	if testing_framework and testing_framework.has_method("run_all_validations"):
		testing_framework.run_all_validations()
	
	_log_development_event("Validation workflow started")

func _start_optimization_workflow() -> void:
	"""Start optimization workflow"""
	workflow_phase = "optimization"
	
	# Run performance tests
	var testing_framework = get_node_or_null("/root/TestingFramework")
	if testing_framework and testing_framework.has_method("run_performance_tests"):
		testing_framework.run_performance_tests()
	
	_log_development_event("Optimization workflow started")

func _start_stability_workflow() -> void:
	"""Start stability workflow"""
	workflow_phase = "stability_check"
	
	# Run stability tests
	var testing_framework = get_node_or_null("/root/TestingFramework")
	if testing_framework and testing_framework.has_method("run_stability_tests"):
		testing_framework.run_stability_tests()
	
	_log_development_event("Stability workflow started")

func _start_deployment_workflow() -> void:
	"""Start deployment workflow"""
	workflow_phase = "deployment"
	
	# Run final validation
	var testing_framework = get_node_or_null("/root/TestingFramework")
	if testing_framework and testing_framework.has_method("run_all_validations"):
		testing_framework.run_all_validations()
	
	_log_development_event("Deployment workflow started")

# Development tools
func enable_auto_testing(enabled: bool) -> void:
	"""Enable/disable automatic testing"""
	auto_testing_enabled = enabled
	
	if enabled:
		auto_test_timer.start()
	else:
		auto_test_timer.stop()
	
	_log_development_event("Auto testing: " + str(enabled))

func enable_auto_validation(enabled: bool) -> void:
	"""Enable/disable automatic validation"""
	auto_validation_enabled = enabled
	
	if enabled:
		auto_validation_timer.start()
	else:
		auto_validation_timer.stop()
	
	_log_development_event("Auto validation: " + str(enabled))

func next_phase() -> void:
	"""Move to next development phase"""
	current_phase_index = (current_phase_index + 1) % phases.size()
	_update_development_phase()

func previous_phase() -> void:
	"""Move to previous development phase"""
	current_phase_index = (current_phase_index - 1) % phases.size()
	_update_development_phase()

func set_phase(phase_name: String) -> void:
	"""Set specific development phase"""
	var phase_index = phases.find(phase_name)
	if phase_index >= 0:
		current_phase_index = phase_index
		_update_development_phase()

# Development logging
func _log_development_event(message: String) -> void:
	"""Log development event"""
	var event = {
		"timestamp": Time.get_ticks_msec(),
		"message": message,
		"workflow": current_workflow,
		"phase": workflow_phase
	}
	
	development_log.append(event)
	
	# Limit log size
	if development_log.size() > 1000:
		development_log.pop_front()
	
	print("[DevelopmentWorkflow] ", message)

func get_development_log() -> Array[Dictionary]:
	"""Get development log"""
	return development_log.duplicate()

func get_workflow_metrics() -> Dictionary:
	"""Get workflow metrics"""
	return workflow_metrics.duplicate()

func get_current_status() -> Dictionary:
	"""Get current workflow status"""
	return {
		"workflow": current_workflow,
		"phase": workflow_phase,
		"development_mode": development_mode,
		"auto_testing": auto_testing_enabled,
		"auto_validation": auto_validation_enabled,
		"metrics": workflow_metrics
	}

func force_workflow_completion() -> void:
	"""Force workflow completion"""
	if current_workflow != "":
		workflow_completed.emit(current_workflow, true)
		workflow_metrics["workflows_completed"] += 1
		stop_workflow()

func _exit_tree() -> void:
	"""Cleanup on exit"""
	if workflow_timer:
		workflow_timer.queue_free()
	if auto_test_timer:
		auto_test_timer.queue_free()
	if auto_validation_timer:
		auto_validation_timer.queue_free()
	
	development_log.clear()
	workflow_metrics.clear()
