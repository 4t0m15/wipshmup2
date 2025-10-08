extends Node2D

signal splash_complete

var timer: float = 0.0
var display_time: float = 3.0
var can_skip: bool = false

func _ready() -> void:
	# Allow skipping after 0.5 seconds to prevent accidental skips
	await get_tree().create_timer(0.5).timeout
	can_skip = true

func _process(delta: float) -> void:
	timer += delta
	
	# Auto-advance after display_time
	if timer >= display_time:
		_complete()

func _input(event: InputEvent) -> void:
	if can_skip and event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			_complete()

func _complete() -> void:
	splash_complete.emit()
	queue_free()

