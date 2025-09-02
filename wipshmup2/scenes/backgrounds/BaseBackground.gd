extends Node2D

var scroll_speed = 30.0

func _ready():
	# Connect the timer signal
	$ScrollTimer.timeout.connect(_on_scroll_timer_timeout)

func _on_scroll_timer_timeout():
	# Move the background down to create scrolling effect
	position.y += scroll_speed * 0.05
	
	# Reset position when it goes off screen
	if position.y > 200:
		position.y = -200
