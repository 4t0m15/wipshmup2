extends Node

# SafetyWrapper - Comprehensive safety checks and error prevention
# Reduces bugs by providing safe alternatives to common operations

func safe_array_access(array: Array, index: int, default_value = null) -> Variant:
	"""Safely access array element with bounds checking"""
	if not array or index < 0 or index >= array.size():
		return default_value
	return array[index]

func safe_array_set(array: Array, index: int, value: Variant) -> bool:
	"""Safely set array element with bounds checking"""
	if not array or index < 0:
		return false
	
	# Extend array if needed
	while array.size() <= index:
		array.append(null)
	
	array[index] = value
	return true

func safe_dictionary_get(dict: Dictionary, key: String, default_value = null) -> Variant:
	"""Safely get dictionary value"""
	if not dict or not dict.has(key):
		return default_value
	return dict[key]

func safe_dictionary_set(dict: Dictionary, key: String, value: Variant) -> bool:
	"""Safely set dictionary value"""
	if not dict:
		return false
	dict[key] = value
	return true

func safe_node_get_child(node: Node, child_name: String) -> Node:
	"""Safely get child node"""
	if not node or not is_instance_valid(node):
		return null
	
	var child = node.get_node_or_null(child_name)
	return child if child and is_instance_valid(child) else null

func safe_signal_connect(signal_obj: Object, signal_name: String, callable: Callable) -> bool:
	"""Safely connect signal with duplicate prevention"""
	if not signal_obj or not is_instance_valid(signal_obj):
		return false
	
	if not signal_obj.has_signal(signal_name):
		print("[SafetyWrapper] Signal not found: " + signal_name)
		return false
	
	# Check if already connected
	if signal_obj.is_connected(signal_name, callable):
		return true
	
	signal_obj.connect(signal_name, callable)
	return true

func safe_signal_disconnect(signal_obj: Object, signal_name: String, callable: Callable) -> bool:
	"""Safely disconnect signal"""
	if not signal_obj or not is_instance_valid(signal_obj):
		return false
	
	if signal_obj.is_connected(signal_name, callable):
		signal_obj.disconnect(signal_name, callable)
		return true
	return false

func safe_method_call(obj: Object, method_name: String, args: Array = []) -> Variant:
	"""Safely call method on object"""
	if not obj or not is_instance_valid(obj):
		return null
	
	if not obj.has_method(method_name):
		print("[SafetyWrapper] Method not found: " + method_name)
		return null
	
	# Use safe call pattern instead of try-catch
	if args.is_empty():
		return obj.call(method_name)
	else:
		return obj.callv(method_name, args)

func safe_property_get(obj: Object, property_name: String, default_value = null) -> Variant:
	"""Safely get object property"""
	if not obj or not is_instance_valid(obj):
		return default_value
	
	# Use safe get pattern instead of try-catch
	return obj.get(property_name)

func safe_property_set(obj: Object, property_name: String, value: Variant) -> bool:
	"""Safely set object property"""
	if not obj or not is_instance_valid(obj):
		return false
	
	# Use safe set pattern instead of try-catch
	obj.set(property_name, value)
	return true

func safe_scene_instantiate(scene: PackedScene) -> Node:
	"""Safely instantiate scene"""
	if not scene:
		print("[SafetyWrapper] Scene is null")
		return null
	
	# Use safe instantiate pattern instead of try-catch
	var instance = scene.instantiate()
	if instance and is_instance_valid(instance):
		return instance
	else:
		print("[SafetyWrapper] Failed to instantiate scene")
		return null

func safe_add_child(parent: Node, child: Node) -> bool:
	"""Safely add child node"""
	if not parent or not is_instance_valid(parent) or not child or not is_instance_valid(child):
		return false
	
	if child.get_parent():
		child.get_parent().remove_child(child)
	
	parent.add_child(child)
	return true

func safe_remove_child(parent: Node, child: Node) -> bool:
	"""Safely remove child node"""
	if not parent or not is_instance_valid(parent) or not child or not is_instance_valid(child):
		return false
	
	if child.get_parent() == parent:
		parent.remove_child(child)
		return true
	return false

func safe_queue_free(node: Node) -> bool:
	"""Safely queue free node"""
	if not node or not is_instance_valid(node):
		return false
	
	node.queue_free()
	return true

func safe_validate_node(node: Node) -> bool:
	"""Validate node is safe to use"""
	return node != null and is_instance_valid(node)

func safe_validate_array(array: Array) -> bool:
	"""Validate array is safe to use"""
	return array != null

func safe_validate_dictionary(dict: Dictionary) -> bool:
	"""Validate dictionary is safe to use"""
	return dict != null
