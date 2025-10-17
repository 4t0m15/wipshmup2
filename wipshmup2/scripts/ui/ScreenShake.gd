extends Node

class_name ScreenShake

# Screen shake system 

@export var hit_stop_duration: float = 0.05
@export var boss_hit_stop_duration: float = 0.1
@export var player_death_stop_duration: float = 0.15

var _target: Node2D
var _original_position: Vector2
var _is_shaking: bool = false
var _shake_time_left: float = 0.0
var _shake_intensity: float = 0.0

var _is_hit_stopping: bool = false
var _hit_stop_end_ms: int = 0
var _original_time_scale: float = 1.0

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
	# Handle hit-stop end using wall-clock time (unaffected by Engine.time_scale)
	if _is_hit_stopping and Time.get_ticks_msec() >= _hit_stop_end_ms:
		_end_hit_stop()

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

func trigger_hit_stop(duration: float = -1.0, intensity: float = 1.0) -> void:
	# Trigger a brief global slow-down effect (near-freeze)
	if _is_hit_stopping:
		return
	var stop_duration := duration if duration > 0.0 else hit_stop_duration
	stop_duration *= max(0.0, intensity)
	_start_hit_stop(stop_duration)

func trigger_boss_hit_stop() -> void:
	trigger_hit_stop(boss_hit_stop_duration, 1.0)

func trigger_player_death_stop() -> void:
	trigger_hit_stop(player_death_stop_duration, 1.0)

func _start_hit_stop(duration: float) -> void:
	_is_hit_stopping = true
	var capped_duration: float = min(duration, 0.5)
	_hit_stop_end_ms = Time.get_ticks_msec() + int(capped_duration * 1000.0)
	_original_time_scale = Engine.time_scale
	# Use a near-zero time scale instead of a hard freeze to avoid stalling scaled timers
	Engine.time_scale = 0.0001

func _end_hit_stop() -> void:
	_is_hit_stopping = false
	Engine.time_scale = _original_time_scale

func stop() -> void:
	# Force stop and restore position
	_is_shaking = false
	_shake_time_left = 0.0
	_shake_intensity = 0.0
	if _target and is_instance_valid(_target):
		_target.position = _original_position

