extends Node

# Test script for the new stability and development systems
# Run this to verify all systems are working correctly

func _ready() -> void:
	print("=== Testing Stability and Development Systems ===")
	
	# Test if all autoload systems are available
	_test_autoload_systems()
	
	# Test stability manager
	_test_stability_manager()
	
	# Test development tools
	_test_development_tools()
	
	# Test parallel processor
	_test_parallel_processor()
	
	# Test testing framework
	_test_testing_framework()
	
	# Test development workflow
	_test_development_workflow()
	
	print("=== All Tests Completed ===")

func _test_autoload_systems() -> void:
	print("\n--- Testing Autoload Systems ---")
	
	var systems = [
		"ErrorHandler",
		"StabilityManager", 
		"DevelopmentTools",
		"ParallelProcessor",
		"TestingFramework",
		"DevelopmentWorkflow"
	]
	
	for system_name in systems:
		var system = get_node_or_null("/root/" + system_name)
		if system and is_instance_valid(system):
			print("✓ " + system_name + " is available")
		else:
			print("✗ " + system_name + " is NOT available")

func _test_stability_manager() -> void:
	print("\n--- Testing Stability Manager ---")
	
	var stability_manager = get_node_or_null("/root/StabilityManager")
	if stability_manager:
		print("✓ StabilityManager found")
		
		# Test performance metrics
		if stability_manager.has_method("get_performance_metrics"):
			var metrics = stability_manager.get_performance_metrics()
			print("✓ Performance metrics: ", metrics)
		else:
			print("✗ get_performance_metrics method not found")
	else:
		print("✗ StabilityManager not found")

func _test_development_tools() -> void:
	print("\n--- Testing Development Tools ---")
	
	var dev_tools = get_node_or_null("/root/DevelopmentTools")
	if dev_tools:
		print("✓ DevelopmentTools found")
		
		# Test debug mode toggle
		if dev_tools.has_method("toggle_debug_mode"):
			dev_tools.toggle_debug_mode()
			print("✓ Debug mode toggled")
		else:
			print("✗ toggle_debug_mode method not found")
	else:
		print("✗ DevelopmentTools not found")

func _test_parallel_processor() -> void:
	print("\n--- Testing Parallel Processor ---")
	
	var parallel_processor = get_node_or_null("/root/ParallelProcessor")
	if parallel_processor:
		print("✓ ParallelProcessor found")
		
		# Test task queuing
		if parallel_processor.has_method("queue_parallel_task"):
			var task_id = parallel_processor.queue_parallel_task("test_task", {"data": "test"})
			print("✓ Task queued with ID: ", task_id)
		else:
			print("✗ queue_parallel_task method not found")
	else:
		print("✗ ParallelProcessor not found")

func _test_testing_framework() -> void:
	print("\n--- Testing Testing Framework ---")
	
	var testing_framework = get_node_or_null("/root/TestingFramework")
	if testing_framework:
		print("✓ TestingFramework found")
		
		# Test unit tests
		if testing_framework.has_method("run_unit_tests"):
			testing_framework.run_unit_tests()
			print("✓ Unit tests executed")
		else:
			print("✗ run_unit_tests method not found")
	else:
		print("✗ TestingFramework not found")

func _test_development_workflow() -> void:
	print("\n--- Testing Development Workflow ---")
	
	var workflow = get_node_or_null("/root/DevelopmentWorkflow")
	if workflow:
		print("✓ DevelopmentWorkflow found")
		
		# Test workflow status
		if workflow.has_method("get_current_status"):
			var status = workflow.get_current_status()
			print("✓ Current status: ", status)
		else:
			print("✗ get_current_status method not found")
	else:
		print("✗ DevelopmentWorkflow not found")

func _exit_tree() -> void:
	print("\n=== Test Script Cleanup ===")
	queue_free()
