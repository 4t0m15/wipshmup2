extends Node

# Global error handling

signal error_occurred(error_message: String, error_type: String)
signal critical_error_occurred(error_message: String)

var error_log: Array[Dictionary] = []
var max_log_size: int = 100
var crash_count: int = 0
var max_crashes: int = 10

func _ready() -> void:
	# Initialize
	print("[ErrorHandler] Enhanced error handler initialized")
	
	# Connect to stability
	var stability_manager = get_node_or_null("/root/StabilityManager")
	if stability_manager and stability_manager.has_method("_on_error_occurred"):
		error_occurred.connect(stability_manager._on_error_occurred)
		critical_error_occurred.connect(stability_manager._on_critical_error)

func _on_error(error_message: String, error_type: String, error_file: String, error_line: int) -> void:
	# Handle errors
	var error_data = {
		"message": error_message,
		"type": error_type,
		"file": error_file,
		"line": error_line,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Add to log
	error_log.append(error_data)
	
	# Limit log size
	if error_log.size() > max_log_size:
		if error_log.size() > 0:
			error_log.pop_front()
	
	# Log
	print("[ErrorHandler] ", error_type, ": ", error_message, " at ", error_file, ":", error_line)
	
	# Emit
	error_occurred.emit(error_message, error_type)
	
	# Check critical
	if _is_critical_error(error_type):
		critical_error_occurred.emit(error_message)
		crash_count += 1
		
		# Prevent infinite crash loops
		if crash_count >= max_crashes:
			_handle_crash_limit_reached()

func _is_critical_error(error_type: String) -> bool:
	"""Check if error is critical"""
	var critical_types = ["SCRIPT_ERROR", "ASSERTION", "PUSH_ERROR", "PUSH_WARNING"]
	return error_type in critical_types

func _handle_crash_limit_reached() -> void:
	"""Handle when crash limit is reached - attempts recovery before graceful exit"""
	print("[ErrorHandler] CRITICAL: Too many crashes detected, attempting recovery")
	
	# Try to recover by restarting the game
	var tree = get_tree()
	if tree and is_instance_valid(tree):
		tree.reload_current_scene()
	else:
		# Last resort - quit gracefully
		print("[ErrorHandler] Unable to recover, exiting gracefully")
		if tree and is_instance_valid(tree):
			tree.quit()

func log_error(message: String, context: String = "") -> void:
	"""Log a custom error"""
	var error_data = {
		"message": message,
		"type": "CUSTOM_ERROR",
		"file": context,
		"line": 0,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	error_log.append(error_data)
	print("[ErrorHandler] Custom Error: ", message, " (", context, ")")
	error_occurred.emit(message, "CUSTOM_ERROR")

func safe_call(object: Object, method: String, args: Array = []) -> Variant:
	"""Safely call a method on an object with comprehensive error handling"""
	if not object or not is_instance_valid(object):
		log_error("Attempted to call method on invalid object: " + method)
		return null
	
	if not object.has_method(method):
		log_error("Object does not have method: " + method)
		return null
	
	# Use safe call pattern with error handling
	var result = null
	if args.is_empty():
		result = object.call(method)
	else:
		result = object.callv(method, args)
	
	# Log if result indicates failure (null for expected return types)
	if result == null and method != "void":
		log_error("Method call returned null: " + method)
	
	return result

func safe_get(object: Object, property: String, default_value = null) -> Variant:
	"""Safely get a property from an object"""
	if not object or not is_instance_valid(object):
		return default_value
	
	if not object.has_method("get"):
		return default_value
	
	# Use safe get pattern instead of try-catch
	return object.get(property)

func safe_set(object: Object, property: String, value: Variant) -> bool:
	"""Safely set a property on an object"""
	if not object or not is_instance_valid(object):
		log_error("Attempted to set property on invalid object: " + property)
		return false
	
	if not object.has_method("set"):
		log_error("Object does not have set method: " + property)
		return false
	
	# Use safe set pattern instead of try-catch
	object.set(property, value)
	return true

func get_error_count() -> int:
	"""Get total error count"""
	return error_log.size()

func get_crash_count() -> int:
	"""Get crash count"""
	return crash_count

func clear_error_log() -> void:
	"""Clear error log"""
	error_log.clear()
	crash_count = 0


#yo pierre you wanna come out here
func get_recent_errors(count: int = 10) -> Array[Dictionary]:
	"""Get recent errors"""
	var start_index = max(0, error_log.size() - count)#
	return error_log.slice(start_index)

func is_stable() -> bool:
	"""Check if system is stable (no recent crashes)"""
	return crash_count < max_crashes and error_log.size() < max_log_size
