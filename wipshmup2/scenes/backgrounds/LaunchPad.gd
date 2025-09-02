extends Node2D

var glow_intensity = 1.0
var glow_direction = -1

func _ready():
	# Connect the timer signal
	$GlowTimer.timeout.connect(_on_glow_timer_timeout)

func _on_glow_timer_timeout():
	# Create a pulsing glow effect
	glow_intensity += glow_direction * 0.1
	
	if glow_intensity <= 0.5:
		glow_direction = 1
	elif glow_intensity >= 1.0:
		glow_direction = -1
	
	# Apply the glow effect
	modulate = Color(glow_intensity, glow_intensity, glow_intensity, 1.0)
