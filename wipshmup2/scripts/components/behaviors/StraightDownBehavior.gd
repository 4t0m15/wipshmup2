extends MovementBehavior
class_name StraightDownBehavior

# Simple straight down movement

func _update_movement(delta: float) -> void:
	velocity = direction * speed
