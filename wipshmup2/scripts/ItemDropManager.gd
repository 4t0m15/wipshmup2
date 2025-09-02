extends Node

# ItemDropManager - Handles item drops from enemies
# Currently a placeholder for future item system implementation

func _ready() -> void:
	# Add to group for autoloads to find
	add_to_group("item_drop_manager")

func drop_item(_enemy_position: Vector2, _item_type: String = "powerup") -> void:
	# Placeholder for item drop functionality
	pass

func get_drop_chance(_enemy_type: String) -> float:
	# Placeholder for drop chance calculation
	return 0.1  # 10% default chance
