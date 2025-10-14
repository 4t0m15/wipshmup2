extends Node

# ResourceValidator - Validates and safely loads resources
# Prevents crashes from missing or corrupted resources

var resource_cache: Dictionary = {}
var failed_resources: Array[String] = []

func _ready() -> void:
	print("[ResourceValidator] Resource validator initialized")

func safe_load(path: String, expected_type: String = "") -> Resource:
	"""Safely load a resource with validation"""
	if path.is_empty():
		push_error("[ResourceValidator] Empty path provided")
		return null
	
	# Check cache first
	if resource_cache.has(path):
		var cached_resource = resource_cache[path]
		if cached_resource and is_instance_valid(cached_resource):
			return cached_resource
		else:
			resource_cache.erase(path)
	
	# Check if resource failed before
	if path in failed_resources:
		return null
	
	# Try to load resource
	var resource = load(path)
	if not resource:
		push_error("[ResourceValidator] Failed to load resource: " + path)
		failed_resources.append(path)
		return null
	
	# Validate type if specified
	if not expected_type.is_empty():
		if not _is_valid_type(resource, expected_type):
			push_error("[ResourceValidator] Resource type mismatch: " + path + " (expected: " + expected_type + ")")
			failed_resources.append(path)
			return null
	
	# Cache successful load
	resource_cache[path] = resource
	return resource

func _is_valid_type(resource: Resource, expected_type: String) -> bool:
	"""Check if resource is of expected type"""
	if not resource:
		return false
	
	var resource_class = resource.get_class()
	return resource_class == expected_type or resource_class.begins_with(expected_type)

func safe_load_scene(path: String) -> PackedScene:
	"""Safely load a scene"""
	var scene = safe_load(path, "PackedScene")
	if scene and scene is PackedScene:
		return scene
	return null

func safe_load_texture(path: String) -> Texture2D:
	"""Safely load a texture"""
	var texture = safe_load(path, "Texture2D")
	if texture and texture is Texture2D:
		return texture
	return null

func safe_load_script(path: String) -> GDScript:
	"""Safely load a script"""
	var script = safe_load(path, "GDScript")
	if script and script is GDScript:
		return script
	return null

func preload_resources(resource_paths: Array[String]) -> Dictionary:
	"""Preload multiple resources"""
	var results = {}
	
	for path in resource_paths:
		var resource = safe_load(path)
		results[path] = resource
	
	return results

func clear_cache() -> void:
	"""Clear resource cache"""
	resource_cache.clear()

func clear_failed_resources() -> void:
	"""Clear failed resources list"""
	failed_resources.clear()

func get_cache_size() -> int:
	"""Get cache size"""
	return resource_cache.size()

func get_failed_count() -> int:
	"""Get failed resources count"""
	return failed_resources.size()

func is_resource_available(path: String) -> bool:
	"""Check if resource is available"""
	return not (path in failed_resources) and (resource_cache.has(path) or ResourceLoader.exists(path))