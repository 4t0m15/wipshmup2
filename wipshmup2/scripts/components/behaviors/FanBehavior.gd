extends AttackBehavior
class_name FanBehavior

# Fan shot behavior - fires bullets in a fan pattern

@export var fan_angle: float = 45.0  # Total spread angle in degrees
@export var bullet_count: int = 3
@export var fan_center_angle: float = 90.0  # Center angle (90 = straight down)

func _handle_attack(_delta: float) -> void:
	if can_attack():
		_fire_fan_shot()

func _fire_fan_shot() -> void:
	if bullet_count <= 1:
		fire_bullet(Vector2.DOWN)
		return
	
	var angle_step = fan_angle / float(bullet_count - 1)
	var start_angle = fan_center_angle - fan_angle * 0.5
	
	for i in range(bullet_count):
		var angle = start_angle + angle_step * float(i)
		var direction = Vector2.RIGHT.rotated(deg_to_rad(angle))
		fire_bullet(direction)
