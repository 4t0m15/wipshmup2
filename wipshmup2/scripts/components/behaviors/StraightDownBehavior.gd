extends MovementBehavior
class_name StraightDownBehavior

# Simple straight down movement

func _update_movement(_delta: float) -> void:
	velocity = direction * speed
