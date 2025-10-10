extends MovementBehavior
class_name SineWaveBehavior

# Sine wave movement pattern

@export var amplitude: float = 50.0
@export var frequency: float = 1.0

var time: float = 0.0

func _update_movement(delta: float) -> void:
	time += delta * frequency
	var sine_offset = sin(time) * amplitude
	velocity = direction * speed + Vector2(sine_offset, 0)
