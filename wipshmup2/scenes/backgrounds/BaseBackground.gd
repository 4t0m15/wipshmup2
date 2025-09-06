extends Node2D
# BaseBackground.gd
# Unified, delta-based background scrolling with optional horizontal movement
# and seamless looping support. Replaces older timer-based scrolling.

@export var scroll_speed: Vector2 = Vector2(0.0, 30.0)  # Base vertical (Y) / horizontal (X) scroll components
@export var enable_horizontal_scroll: bool = false
@export var horizontal_scroll_speed: float = 50.0       # Added to scroll_speed.x when horizontal scrolling enabled
@export var seamless_loop: bool = true
@export var loop_distance: float = 400.0  # Distance threshold before wrapping (per axis)

# Internal state
var _current_offset: Vector2 = Vector2.ZERO
var _base_position: Vector2

func _ready() -> void:
	_base_position = position
	# Clean up any legacy timer-based node if it still exists
	if has_node("ScrollTimer"):
		$ScrollTimer.queue_free()

func _process(delta: float) -> void:
	# Frame-rate independent scrolling
	var scroll_delta: Vector2 = scroll_speed * delta

	if enable_horizontal_scroll:
		scroll_delta.x += horizontal_scroll_speed * delta

	_current_offset += scroll_delta
	position = _base_position + _current_offset

	if seamless_loop:
		_handle_seamless_loop()

func _handle_seamless_loop() -> void:
	# Vertical looping
	if abs(_current_offset.y) > loop_distance:
		_current_offset.y = fmod(_current_offset.y, loop_distance)
		position.y = _base_position.y + _current_offset.y

	# Horizontal looping
	if abs(_current_offset.x) > loop_distance:
		_current_offset.x = fmod(_current_offset.x, loop_distance)
		position.x = _base_position.x + _current_offset.x

# Public control API ------------------------------------------------

func set_scroll_speed(speed: Vector2) -> void:
	scroll_speed = speed

func set_horizontal_scroll(enabled: bool, speed: float = 50.0) -> void:
	enable_horizontal_scroll = enabled
	horizontal_scroll_speed = speed

func reset_scroll() -> void:
	_current_offset = Vector2.ZERO
	position = _base_position

func get_scroll_offset() -> Vector2:
	return _current_offset
