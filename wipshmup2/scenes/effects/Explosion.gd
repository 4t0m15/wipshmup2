extends Node2D

func _ready():
	# Connect the timer signal
	$LifetimeTimer.timeout.connect(_on_lifetime_timeout)
	
	# Add some random rotation for variety
	rotation = randf() * TAU

func _on_lifetime_timeout():
	# Remove the explosion when the timer expires
	queue_free()
