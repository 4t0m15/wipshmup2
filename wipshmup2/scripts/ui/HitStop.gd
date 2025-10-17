class_name HitStop
extends Node

# Hit-stop system

@export var hit_stop_duration: float = 0.05  # 50ms
@export var boss_hit_stop_duration: float = 0.1  # 100ms boss
@export var player_death_stop_duration: float = 0.15  # 150ms death

var _is_hit_stopping: bool = false
var _hit_stop_timer: float = 0.0
var _original_time_scale: float = 1.0
var _hit_stop_end_ms: int = 0

func _ready() -> void:
	# Setup
	set_process(true)

func _process(_delta: float) -> void:
	if _is_hit_stopping:
		# Wall-clock time
		if Time.get_ticks_msec() >= _hit_stop_end_ms:
			_end_hit_stop()

func trigger_hit_stop(duration: float = -1.0, intensity: float = 1.0) -> void:
	# Trigger hit-stop
	if _is_hit_stopping:
		return  # Don't interrupt
	
	var stop_duration = duration if duration > 0.0 else hit_stop_duration
	stop_duration *= intensity  # Scale
	
	_start_hit_stop(stop_duration)

func trigger_boss_hit_stop() -> void:
	# Boss hit-stop
	trigger_hit_stop(boss_hit_stop_duration, 1.0)

func trigger_player_death_stop() -> void:
	# Player death stop
	trigger_hit_stop(player_death_stop_duration, 1.0)

func _start_hit_stop(duration: float) -> void:
	# Start hit-stop
	_is_hit_stopping = true
	# Cap duration
	var capped_duration: float = min(duration, 0.5)
	_hit_stop_timer = capped_duration
	_hit_stop_end_ms = Time.get_ticks_msec() + int(capped_duration * 1000.0)
	_original_time_scale = Engine.time_scale
	# Use a near-zero time scale instead of a hard freeze to avoid stalling scaled timers in other systems
	Engine.time_scale = 0.0001

func _end_hit_stop() -> void:
	"""End the hit-stop effect"""
	_is_hit_stopping = false
	Engine.time_scale = _original_time_scale

func is_hit_stopping() -> bool:
	"""Check if currently in hit-stop"""
	return _is_hit_stopping

# Static functions for easy access
static func trigger_static(duration: float = -1.0, intensity: float = 1.0) -> void:
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var hit_stop = (main_loop as SceneTree).get_node_or_null("/root/HitStop")
		if hit_stop:
			hit_stop.trigger_hit_stop(duration, intensity)

static func trigger_boss_static() -> void:
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var hit_stop = (main_loop as SceneTree).get_node_or_null("/root/HitStop")
		if hit_stop:
			hit_stop.trigger_boss_hit_stop()

static func trigger_player_death_static() -> void:
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var hit_stop = (main_loop as SceneTree).get_node_or_null("/root/HitStop")
		if hit_stop:
			hit_stop.trigger_player_death_stop()
