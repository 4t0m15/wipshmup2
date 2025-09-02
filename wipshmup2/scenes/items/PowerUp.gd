extends Area2D

var float_offset = 0.0
var float_speed = 3.0
var rotation_speed = 2.0

func _ready():
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)
	
	# Connect the float timer
	$FloatTimer.timeout.connect(_on_float_timer_timeout)

func _process(delta):
	# Rotate the power-up
	rotation += rotation_speed * delta

func _on_float_timer_timeout():
	# Create a floating up and down motion
	float_offset += float_speed * 0.016
	position.y = position.y + sin(float_offset) * 0.5

func _on_body_entered(body):
	if body.has_method("collect_powerup"):
		body.collect_powerup()
	
	# Remove the power-up when collected
	queue_free()
