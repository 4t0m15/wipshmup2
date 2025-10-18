extends MovementBehavior
class_name StraightDownBehavior

# Moves parent straight along its forward direction at current speed

func _update_movement(_delta: float) -> void:
	velocity = direction * speed
