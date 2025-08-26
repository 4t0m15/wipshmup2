extends Node

signal tick(delta_s: float)

@export var ticks_per_second: float = 20.0

var _fixed_dt: float
var _accumulator: float = 0.0

func _ready() -> void:
	_fixed_dt = 1.0 / max(1.0, ticks_per_second)
	set_process(true)

func _process(delta: float) -> void:
	_accumulator += delta
	while _accumulator >= _fixed_dt:
		_accumulator -= _fixed_dt
		emit_signal("tick", _fixed_dt)
