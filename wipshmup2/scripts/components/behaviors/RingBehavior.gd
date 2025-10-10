extends AttackBehavior
class_name RingBehavior

# Ring shot behavior - fires bullets in a ring pattern

@export var bullet_count: int = 8
@export var ring_rotation_speed: float = 0.0  # Degrees per second

var ring_angle: float = 0.0

func _handle_attack(delta: float) -> void:
	# Update ring rotation
	ring_angle += ring_rotation_speed * delta
	
	if can_attack():
		_fire_ring_shot()

func _fire_ring_shot() -> void:
	var angle_step = 360.0 / float(bullet_count)
	
	for i in range(bullet_count):
		var angle = ring_angle + angle_step * float(i)
		var direction = Vector2.RIGHT.rotated(deg_to_rad(angle))
		fire_bullet(direction)
