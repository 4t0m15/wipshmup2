extends Node2D

# Optimized background scrolling using delta-time instead of timers
@export var scroll_speed: Vector2 = Vector2(0.0, 30.0)  # Vertical scrolling by default
@export var enable_horizontal_scroll: bool = false
@export var horizontal_scroll_speed: float = 50.0
@export var seamless_loop: bool = true
@export var loop_distance: float = 400.0  # Distance before resetting position

var _current_offset: Vector2 = Vector2.ZERO
var _base_position: Vector2

func _ready():
	_base_position = position
	# Remove old timer-based system
	if has_node("ScrollTimer"):
		$ScrollTimer.queue_free()

func _process(delta: float):
	# Frame-rate independent scrolling
	var scroll_delta = scroll_speed * delta
	
	# Add horizontal scroll if enabled
	if enable_horizontal_scroll:
		scroll_delta.x += horizontal_scroll_speed * delta
	
	# Update position
	_current_offset += scroll_delta
	position = _base_position + _current_offset
	
	# Handle seamless looping
	if seamless_loop:
		_handle_seamless_loop()

func _handle_seamless_loop():
	"""Handle seamless background looping"""
	# Vertical looping
	if abs(_current_offset.y) > loop_distance:
		_current_offset.y = fmod(_current_offset.y, loop_distance)
		position.y = _base_position.y + _current_offset.y
	
	# Horizontal looping
	if abs(_current_offset.x) > loop_distance:
		_current_offset.x = fmod(_current_offset.x, loop_distance)
		position.x = _base_position.x + _current_offset.x

func set_scroll_speed(speed: Vector2):
	"""Dynamically change scroll speed"""
	scroll_speed = speed

func set_horizontal_scroll(enabled: bool, speed: float = 50.0):
	"""Enable/disable horizontal scrolling"""
	enable_horizontal_scroll = enabled
	horizontal_scroll_speed = speed

func reset_scroll():
	"""Reset scroll position"""
	_current_offset = Vector2.ZERO
	position = _base_position

func get_scroll_offset() -> Vector2:
	"""Get current scroll offset"""
	return _current_offset
