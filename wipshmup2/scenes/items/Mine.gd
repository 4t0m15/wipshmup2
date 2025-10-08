extends Area2D

@export var speed: float = 50.0
@export var damage: int = 25

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)

func _process(delta: float) -> void:
	position.y += speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_screen_exited() -> void:
	queue_free()

