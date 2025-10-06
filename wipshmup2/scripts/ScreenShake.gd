extends Node

class_name ScreenShake

var _target: Node2D
var _intensity: float = 0.0
var _duration: float = 0.0
var _time_left: float = 0.0
var _original_position: Vector2
var _noise := FastNoiseLite.new()
var _noise_time: float = 0.0

func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 4.0
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	set_process(true)

func set_target(target: Node2D) -> void:
	_target = target
	if is_instance_valid(_target):
		_original_position = _target.position

func shake(intensity: float, duration: float) -> void:
	_intensity = max(_intensity, intensity)
	_duration = max(_duration, duration)
	_time_left = _duration

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	if _time_left > 0.0:
		_noise_time += delta
		_time_left -= delta
		var t: float = 1.0 - clamp((_duration - _time_left) / max(_duration, 0.0001), 0.0, 1.0)
		var falloff: float = t * t
		var n1: float = _noise.get_noise_2d(_noise_time * 12.3, 0.0)
		var n2: float = _noise.get_noise_2d(0.0, _noise_time * 15.7)
		var offset: Vector2 = Vector2(n1, n2) * _intensity * falloff
		_target.position = _original_position + offset
	else:
		_target.position = _original_position

