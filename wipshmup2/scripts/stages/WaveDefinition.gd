extends Resource
class_name WaveDefinition

# WaveDefinition - Defines a wave of enemies
# Contains enemy spawns, timing, and patterns

@export var wave_name: String = "Wave"
@export var enemy_spawns: Array[Dictionary] = []
@export var wave_duration: float = -1.0  # -1 for infinite
@export var spawn_interval: float = 0.15  # Reduced from 0.5 - MUCH FASTER
@export var formation_type: String = "none"  # none, line, arc, circle, v_formation

# Formation parameters
@export var formation_params: Dictionary = {}

func _init() -> void:
	# Set default formation parameters
	if formation_params.is_empty():
		formation_params = {
			"spacing": 40.0,
			"radius": 50.0,
			"angle": 0.0
		}

func get_spawn_count() -> int:
	"""Get the total number of enemy spawns"""
	return enemy_spawns.size()

func get_spawn(index: int) -> Dictionary:
	"""Get a spawn definition by index"""
	if index >= 0 and index < enemy_spawns.size():
		return enemy_spawns[index]
	# Return safe default instead of empty dict
	return {
		"enemy_type": "unknown",
		"position": Vector2.ZERO,
		"delay": 0.0,
		"properties": {}
	}

func add_enemy_spawn(enemy_type: String, position: Vector2, delay: float = 0.0, properties: Dictionary = {}) -> void:
	"""Add an enemy spawn to the wave"""
	var spawn = {
		"enemy_type": enemy_type,
		"position": position,
		"delay": delay,
		"properties": properties
	}
	enemy_spawns.append(spawn)

func create_formation_spawns(formation_pattern: String, enemy_type: String, center_position: Vector2, count: int, properties: Dictionary = {}) -> void:
	"""Create spawns in a formation pattern"""
	match formation_pattern:
		"line":
			_create_line_formation(enemy_type, center_position, count, properties)
		"arc":
			_create_arc_formation(enemy_type, center_position, count, properties)
		"circle":
			_create_circle_formation(enemy_type, center_position, count, properties)
		"v_formation":
			_create_v_formation(enemy_type, center_position, count, properties)
		"spiral":
			_create_spiral_formation(enemy_type, center_position, count, properties)
		"diamond":
			_create_diamond_formation(enemy_type, center_position, count, properties)
		"cross":
			_create_cross_formation(enemy_type, center_position, count, properties)
		"wall":
			_create_wall_formation(enemy_type, center_position, count, properties)
		_:
			# Default to single spawn
			add_enemy_spawn(enemy_type, center_position, 0.0, properties)

func _create_line_formation(enemy_type: String, center: Vector2, count: int, properties: Dictionary) -> void:
	"""Create a horizontal line formation"""
	# Safety checks
	if count <= 0:
		return
	if enemy_type.is_empty():
		enemy_type = "unknown"
	
	var spacing = formation_params.get("spacing", 40.0)
	var start_x = center.x - (count - 1) * spacing * 0.5
	
	for i in range(count):
		var x = start_x + i * spacing
		var position = Vector2(x, center.y)
		add_enemy_spawn(enemy_type, position, 0.0, properties)

func _create_arc_formation(enemy_type: String, center: Vector2, count: int, properties: Dictionary) -> void:
	"""Create an arc formation"""
	# Safety checks
	if count <= 0:
		return
	if enemy_type.is_empty():
		enemy_type = "unknown"
	
	var radius = formation_params.get("radius", 50.0)
	var angle_start = formation_params.get("angle", 0.0)
	var angle_step = PI / float(max(count - 1, 1))
	
	for i in range(count):
		var angle = angle_start + angle_step * float(i)
		var x = center.x + cos(angle) * radius
		var y = center.y + sin(angle) * radius
		var position = Vector2(x, y)
		add_enemy_spawn(enemy_type, position, 0.0, properties)

func _create_circle_formation(enemy_type: String, center: Vector2, count: int, properties: Dictionary) -> void:
	"""Create a circle formation"""
	# Safety checks
	if count <= 0:
		return
	if enemy_type.is_empty():
		enemy_type = "unknown"
	
	var radius = formation_params.get("radius", 50.0)
	var angle_step = TAU / float(count)
	
	for i in range(count):
		var angle = angle_step * float(i)
		var x = center.x + cos(angle) * radius
		var y = center.y + sin(angle) * radius
		var position = Vector2(x, y)
		add_enemy_spawn(enemy_type, position, 0.0, properties)

func _create_v_formation(enemy_type: String, center: Vector2, count: int, properties: Dictionary) -> void:
	"""Create a V formation"""
	# Safety checks
	if count <= 0:
		return
	if enemy_type.is_empty():
		enemy_type = "unknown"
	
	var spacing = formation_params.get("spacing", 40.0)
	var rows = int(ceil(sqrt(float(count))))
	
	var spawn_index = 0
	for row in range(rows):
		var row_count = min(count - spawn_index, row + 1)
		var start_x = center.x - (row_count - 1) * spacing * 0.5
		
		for col in range(row_count):
			if spawn_index >= count:
				break
			
			var x = start_x + col * spacing
			var y = center.y + row * spacing * 0.8
			var position = Vector2(x, y)
			add_enemy_spawn(enemy_type, position, 0.0, properties)
			spawn_index += 1

func _create_spiral_formation(enemy_type: String, center: Vector2, count: int, properties: Dictionary) -> void:
	"""Create a spiral formation"""
	# Safety checks
	if count <= 0:
		return
	if enemy_type.is_empty():
		enemy_type = "unknown"
	
	var radius = formation_params.get("radius", 50.0)
	var angle_step = TAU / float(max(count, 1))
	
	for i in range(count):
		var angle = angle_step * float(i) * 2.0  # Double for tighter spiral
		var distance = radius * (float(i) / float(count))
		var x = center.x + cos(angle) * distance
		var y = center.y + sin(angle) * distance
		var position = Vector2(x, y)
		add_enemy_spawn(enemy_type, position, 0.0, properties)

func _create_diamond_formation(enemy_type: String, center: Vector2, count: int, properties: Dictionary) -> void:
	"""Create a diamond formation"""
	# Safety checks
	if count <= 0:
		return
	if enemy_type.is_empty():
		enemy_type = "unknown"
	
	var spacing = formation_params.get("spacing", 40.0)
	var rows = int(ceil(sqrt(float(count))))
	
	var spawn_index = 0
	for row in range(rows):
		var row_count = min(count - spawn_index, (row + 1) * 2 - 1)
		var start_x = center.x - (row_count - 1) * spacing * 0.5
		
		for col in range(row_count):
			if spawn_index >= count:
				break
			
			var x = start_x + col * spacing
			var y = center.y + row * spacing * 0.8
			var position = Vector2(x, y)
			add_enemy_spawn(enemy_type, position, 0.0, properties)
			spawn_index += 1

func _create_cross_formation(enemy_type: String, center: Vector2, count: int, properties: Dictionary) -> void:
	"""Create a cross formation"""
	# Safety checks
	if count <= 0:
		return
	if enemy_type.is_empty():
		enemy_type = "unknown"
	
	var spacing = formation_params.get("spacing", 40.0)
	var half_count: int = count >> 1  # Bit shift for integer division by 2
	
	for i in range(half_count):
		var y = center.y - (half_count - 1 - i) * spacing
		var position = Vector2(center.x, y)
		add_enemy_spawn(enemy_type, position, 0.0, properties)
	
	# Horizontal line
	for i in range(count - half_count):
		var x = center.x - (count - half_count - 1 - i) * spacing
		var position = Vector2(x, center.y)
		add_enemy_spawn(enemy_type, position, 0.0, properties)

func _create_wall_formation(enemy_type: String, center: Vector2, count: int, properties: Dictionary) -> void:
	"""Create a wall formation"""
	# Safety checks
	if count <= 0:
		return
	if enemy_type.is_empty():
		enemy_type = "unknown"
	
	var spacing = formation_params.get("spacing", 40.0)
	var width = formation_params.get("width", 3)
	var height = int(ceil(float(count) / float(width)))
	
	var spawn_index = 0
	for row in range(height):
		for col in range(width):
			if spawn_index >= count:
				break
			
			var x = center.x - (width - 1) * spacing * 0.5 + col * spacing
			var y = center.y - row * spacing
			var position = Vector2(x, y)
			add_enemy_spawn(enemy_type, position, 0.0, properties)
			spawn_index += 1
