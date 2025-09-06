extends Node

# Item drop system for power-ups, score items, and special pickups

signal item_collected(item_type: String, value: int)

enum ItemType {
	POWER_UP,   
	SCORE_SMALL,
	SCORE_LARGE,
	LIFE_EXTEND,
	BOMB,
	SHIELD
}

var drop_rates := {
	ItemType.POWER_UP: 0.15,
	ItemType.SCORE_SMALL: 0.3,
	ItemType.SCORE_LARGE: 0.05,
	ItemType.LIFE_EXTEND: 0.01,
	ItemType.BOMB: 0.08,
	ItemType.SHIELD: 0.02
}

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	# Add to group for autoloads to find
	add_to_group("item_drop_manager")

func try_drop_item(position: Vector2, enemy_points: int = 100) -> void:
	var drop_chance := _calculate_drop_chance(enemy_points)

	if _rng.randf() <= drop_chance:
		var item_type := _select_item_type()
		_spawn_item(item_type, position)

func _calculate_drop_chance(enemy_points: int) -> float:
	# Higher value enemies have better drop rates
	var base_chance := 0.2
	var point_multiplier: float = min(enemy_points / 1000.0, 2.0)
	return base_chance * point_multiplier

func _select_item_type() -> ItemType:
	var total_weight := 0.0
	for rate in drop_rates.values():
		total_weight += rate   

	var roll := _rng.randf() * total_weight
	var current_weight := 0.0

	for item_type: ItemType in drop_rates:
		current_weight += drop_rates[item_type]
		if roll <= current_weight:
			return item_type

	return ItemType.SCORE_SMALL  # Fallback

func _spawn_item(item_type: ItemType, position: Vector2) -> void:
	# Placeholder implementation since item scenes don't exist yet
	print("Would spawn item of type: ", item_type, " at position: ", position)
	# TODO: Implement actual item spawning when scenes are created

func get_drop_rate(item_type: ItemType) -> float:
	return drop_rates.get(item_type, 0.0)

func drop_item(_enemy_position: Vector2, _item_type: String = "powerup") -> void:
	# Legacy function for compatibility
	pass

func get_drop_chance(_enemy_type: String) -> float:
	# Legacy function for compatibility
	return 0.1  # 10% default chance

func force_drop_item(item_type: ItemType, position: Vector2) -> void:
	_spawn_item(item_type, position)

func set_drop_rate(item_type: ItemType, rate: float) -> void:
	drop_rates[item_type] = clamp(rate, 0.0, 1.0)
