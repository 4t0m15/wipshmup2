extends MovementBehavior
class_name ZigzagBehavior

# Zigzag movement pattern

@export var zigzag_amplitude: float = 30.0
@export var zigzag_frequency: float = 2.0

var time: float = 0.0
var zigzag_direction: float = 1.0

func _update_movement(delta: float) -> void:
	time += delta * zigzag_frequency
	
	# Change direction periodically
	if int(time) % 2 == 0:
		zigzag_direction = 1.0
	else:
		zigzag_direction = -1.0
	
	var zigzag_offset = zigzag_direction * zigzag_amplitude
	velocity = direction * speed + Vector2(zigzag_offset, 0)
