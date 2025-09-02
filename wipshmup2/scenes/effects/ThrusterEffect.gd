extends Node2D

var flicker_intensity = 1.0
var flicker_direction = -1

func _ready():
	# Connect the timer signal
	$FlickerTimer.timeout.connect(_on_flicker_timer_timeout)

func _on_flicker_timer_timeout():
	# Create a flickering effect for the thrusters
	flicker_intensity += flicker_direction * 0.2
	
	if flicker_intensity <= 0.3:
		flicker_direction = 1
	elif flicker_intensity >= 1.0:
		flicker_direction = -1
	
	# Apply the flicker effect
	modulate = Color(flicker_intensity, flicker_intensity, flicker_intensity, 1.0)
