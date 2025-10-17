extends Node
# Item drop system

signal item_collected(item_type: String, value: int)

enum ItemType {
	POWER_UP,
	SCORE_SMALL,
	SCORE_LARGE,
	LIFE_EXTEND,
	BOMB,
	SHIELD
}

# Drop rates
var drop_rates: Dictionary = {
	ItemType.POWER_UP: 0.15,
	ItemType.SCORE_SMALL: 0.3,
	ItemType.SCORE_LARGE: 0.05,
	ItemType.LIFE_EXTEND: 0.01,
	ItemType.BOMB: 0.08,
	ItemType.SHIELD: 0.02
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Config
@export var auto_emit_on_spawn: bool = true
@export var simulate_pickup_delay: float = 0.0  # If > 0, emit after a delay to simulate collection timing
@export var score_values := {
	ItemType.SCORE_SMALL: 100,
	ItemType.SCORE_LARGE: 500,
	ItemType.POWER_UP: 0,
	ItemType.LIFE_EXTEND: 0,
	ItemType.BOMB: 0,
	ItemType.SHIELD: 0
}

func _ready() -> void:
	_rng.randomize()
	add_to_group("item_drop_manager")

# Public API

func try_drop_item(position: Vector2, enemy_points: int = 100, enemy_type: String = "") -> void:
	# Cho Ren Sha 68K: triangle items
	var drop_chance: float = _calculate_drop_chance(enemy_points)
	print("[ItemDropManager] Trying to drop item at ", position, " with ", drop_chance * 100, "% chance")
	var roll = _rng.randf()
	print("[ItemDropManager] Roll: ", roll, " vs chance: ", drop_chance)
	if roll <= drop_chance:
		# Spawn triangle item instead of individual items
		print("[ItemDropManager] Drop successful! Spawning triangle item")
		spawn_triangle_item(position)
		return
	else:
		print("[ItemDropManager] Drop failed - no item spawned")
	
	# Legacy individual item spawning (kept for backward compatibility)
	# Only used if triangle spawning is disabled or for special cases
	if enemy_type == "legacy_individual":
		var item_type: ItemType = _select_item_type()
		_spawn_item(item_type, position)

func force_drop_item(_item_type: ItemType, position: Vector2) -> void:
	# Cho Ren Sha 68K: Force drop triangle items instead of individual items
	spawn_triangle_item(position)

func get_drop_rate(item_type: ItemType) -> float:
	return drop_rates.get(item_type, 0.0)

func set_drop_rate(item_type: ItemType, rate: float) -> void:
	drop_rates[item_type] = clamp(rate, 0.0, 1.0)

# Legacy / compatibility placeholders
func drop_item(_enemy_position: Vector2, _item_type: String = "powerup") -> void:
	# Intentionally left as a no-op for legacy calls
	pass

func get_drop_chance(_enemy_type: String) -> float:
	return 0.1

# Internal logic ---------------------------------------------------

func _calculate_drop_chance(enemy_points: int) -> float:
	var base_chance := 0.8  # Increased from 0.2 to 0.8 for testing
	var point_multiplier: float = min(enemy_points / 1000.0, 2.0)
	return base_chance * point_multiplier

func _select_item_type() -> ItemType:
	var total_weight: float = 0.0
	for rate in drop_rates.values():
		total_weight += rate
	if total_weight <= 0.0:
		return ItemType.SCORE_SMALL
	var roll := _rng.randf() * total_weight
	var current_weight: float = 0.0
	for item_type: ItemType in drop_rates:
		current_weight += drop_rates[item_type]
		if roll <= current_weight:
			return item_type
	return ItemType.SCORE_SMALL  # Fallback

func _spawn_item(item_type: ItemType, position: Vector2) -> void:
	# Integrate with actual scene instancing or object pooling in future
	print("Spawn item: ", item_type, " at ", position)
	if auto_emit_on_spawn and simulate_pickup_delay <= 0.0:
		_emit_collected(item_type)
	elif auto_emit_on_spawn and simulate_pickup_delay > 0.0:
		call_deferred("_deferred_emit_collected", item_type) # simple delayed pickup simulation

func _deferred_emit_collected(item_type: ItemType) -> void:
	await get_tree().create_timer(simulate_pickup_delay).timeout
	_emit_collected(item_type)

func _emit_collected(item_type: ItemType) -> void:
	var value: int = int(score_values.get(item_type, 0))
	emit_signal("item_collected", str(item_type), value)

# Triangle Item System (Cho Ren Sha 68K)
func spawn_triangle_item(position: Vector2) -> void:
	"""Spawn a triangle item with three pickups"""
	print("[ItemDropManager] spawn_triangle_item called at position: ", position)
	const TRIANGLE_SCENE = preload("res://scenes/items/TriangleItem.tscn")
	
	if not TRIANGLE_SCENE:
		push_error("TriangleItem scene not found")
		return
	
	var triangle = TRIANGLE_SCENE.instantiate()
	if not triangle:
		push_error("Failed to instantiate TriangleItem")
		return
	
	print("[ItemDropManager] Triangle item instantiated successfully")
	
	# Add to scene tree using deferred call to avoid query flushing issues
	var main_scene = get_tree().current_scene
	if main_scene:
		# Set position first, then add to scene using deferred call
		triangle.global_position = position
		call_deferred("_add_triangle_to_scene", triangle, main_scene)
		print("[ItemDropManager] Spawned triangle item at ", position)
	else:
		push_error("No current scene to add triangle item")
		triangle.queue_free()

func _add_triangle_to_scene(triangle: Node, parent: Node) -> void:
	"""Helper function to add triangle to scene using deferred call"""
	if is_instance_valid(triangle) and is_instance_valid(parent):
		parent.add_child(triangle)

# Test method for triangle items (can be called from debug)
func test_spawn_triangle() -> void:
	"""Test method to spawn a triangle item at center screen"""
	print("[ItemDropManager] TEST: Force spawning triangle item")
	spawn_triangle_item(Vector2(160, 100))

func force_spawn_triangle_at_player() -> void:
	"""Force spawn triangle item at player position for testing"""
	var player_pos = GameState.player_position
	print("[ItemDropManager] TEST: Force spawning triangle at player position: ", player_pos)
	spawn_triangle_item(player_pos)

# Test method for red carrier enemy (can be called from debug)
func test_spawn_red_carrier() -> void:
	"""Test method to spawn a red carrier enemy that drops triangle items"""
	# Create a simple test enemy with red_carrier type
	var test_enemy = preload("res://scenes/enemy/Enemy.tscn").instantiate()
	if test_enemy:
		test_enemy.enemy_type = "red_carrier"
		test_enemy.global_position = Vector2(160, 50)
		get_tree().current_scene.add_child(test_enemy)
		print("[ItemDropManager] Spawned test red carrier enemy")
