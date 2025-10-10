extends RefCounted

# Centralized utility functions for performance optimization

# Get cached player reference
static func get_cached_player() -> Node2D:
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop.get_root():
		var tree = main_loop.get_root().get_tree()
		if tree:
			return tree.get_first_node_in_group("player")
	return null

# Get cached viewport size
static func get_cached_viewport_size() -> Vector2:
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop.get_root():
		var tree = main_loop.get_root().get_tree()
		if tree and tree.get_root():
			return tree.get_root().get_viewport().get_visible_rect().size
	return Vector2.ZERO

# Check if position is on screen
static func is_on_screen(position: Vector2, margin: float = 32.0) -> bool:
	var viewport_size = get_cached_viewport_size()
	return position.x >= -margin and position.x <= viewport_size.x + margin and position.y >= -margin and position.y <= viewport_size.y + margin

# Get distance between two positions
static func get_distance(pos1: Vector2, pos2: Vector2) -> float:
	return pos1.distance_to(pos2)

# Get direction from one position to another
static func get_direction(from_pos: Vector2, to_pos: Vector2) -> Vector2:
	return (to_pos - from_pos).normalized()

# Check if object should be cleaned up based on position
static func should_cleanup(position: Vector2, is_turret: bool = false) -> bool:
	var viewport_size = get_cached_viewport_size()

	if not is_turret and position.y >= viewport_size.y - 2:
		return true
	if position.y > viewport_size.y + 64 or position.x < -64 or position.x > viewport_size.x + 64:
		return true

	return false

# Spawn bullet with optimized parameters
static func spawn_bullet(bullet_scene: PackedScene, position: Vector2, direction: Vector2, speed: float, parent: Node) -> void:
	if not bullet_scene or not parent:
		return

	var bullet: Area2D = bullet_scene.instantiate()
	if bullet:
		bullet.global_position = position
		if bullet.has_method("set"):
			bullet.set("direction", direction.normalized())
			bullet.set("speed", speed)

		var container = parent.get_node_or_null("GameViewport/Bullets")
		var target = container if container else parent
		if target and target.has_method("add_child"):
			target.add_child(bullet)
			# Ensure collision is properly enabled after adding to scene
			if bullet.has_method("set"):
				bullet.monitoring = true
				bullet.collision_layer = 0
				bullet.collision_mask = 1
