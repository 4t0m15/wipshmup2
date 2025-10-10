extends MovementBehavior
class_name DiveBehavior

# Dive down and then level out movement

@export var dive_speed_multiplier: float = 2.0
@export var level_out_distance: float = 100.0

var has_dived: bool = false
var dive_start_y: float

func _ready() -> void:
	super._ready()
	dive_start_y = enemy.global_position.y

func _update_movement(delta: float) -> void:
	if not has_dived:
		# Dive down faster
		velocity = direction * speed * dive_speed_multiplier
		
		# Check if we've traveled far enough to level out
		if enemy.global_position.y - dive_start_y > level_out_distance:
			has_dived = true
	else:
		# Level out and continue at normal speed
		velocity = direction * speed
