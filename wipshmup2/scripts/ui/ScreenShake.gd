extends Node

class_name ScreenShake

# Screen shake system 

var _target: Node2D
var _original_position: Vector2
var _is_shaking: bool = false
var _shake_time_left: float = 0.0
var _shake_intensity: float = 0.0

func _ready() -> void:
	set_process(true)

func set_target(target: Node2D) -> void:
	_target = target
	if is_instance_valid(_target):
		_original_position = _target.position

func shake(intensity: float, duration: float) -> void:
	# Start or update a single shake session; no tween storm
	if not _target or not is_instance_valid(_target):
		return
	
	# Ensure we have a stable baseline
	if _original_position == Vector2.ZERO and _target:
		_original_position = _target.position
	
	# If already shaking, extend/strengthen; otherwise start
	_shake_time_left = max(_shake_time_left, max(0.0, duration))
	_shake_intensity = max(_shake_intensity, max(0.0, intensity))
	_is_shaking = true

func _process(delta: float) -> void:
	# Process a single, throttled shake; returns to origin when done
	if not _is_shaking:
		return
	if not _target or not is_instance_valid(_target):
		_is_shaking = false
		return
	
	_shake_time_left -= delta
	if _shake_time_left <= 0.0:
		# End shake and restore position
		_shake_time_left = 0.0
		_is_shaking = false
		_target.position = _original_position
		_shake_intensity = 0.0
		return
	
	# Apply random offset around original position; decay with remaining time
	var amount := _shake_intensity * 10.0
	var random_offset = Vector2(
		randf_range(-amount, amount),
		randf_range(-amount, amount)
	)
	_target.position = _original_position + random_offset

func stop() -> void:
	# Force stop and restore position
	_is_shaking = false
	_shake_time_left = 0.0
	_shake_intensity = 0.0
	if _target and is_instance_valid(_target):
		_target.position = _original_position

