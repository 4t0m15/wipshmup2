extends Node

class_name ScreenShake

# SCREENSHAKE deleted 

var _target: Node2D
var _original_position: Vector2

func _ready() -> void:
	set_process(false)  # Disabled - no processing needed

func set_target(target: Node2D) -> void:
	_target = target
	if is_instance_valid(_target):
		_original_position = _target.position

func shake(_intensity: float, _duration: float) -> void:
	# DISABLED - Screenshake does nothing
	pass

func _process(_delta: float) -> void:
	# DISABLED - No screenshake applied
	pass

