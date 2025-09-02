extends Area2D

var rotation_speed = 2.0

func _ready():
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Rotate the mine slowly
	rotation += rotation_speed * delta

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(1)
	
	# Create explosion effect
	var explosion_scene = preload("res://scenes/effects/Explosion.tscn")
	var explosion = explosion_scene.instantiate()
	explosion.position = position
	get_parent().add_child(explosion)
	
	# Remove the mine
	queue_free()
