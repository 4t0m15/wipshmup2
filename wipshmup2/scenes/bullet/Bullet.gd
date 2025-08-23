extends Area2D

@export var speed: float = 800.0

var direction: Vector2 = Vector2.UP

func _ready() -> void:
	monitoring = true
	add_to_group("player_bullet")
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	position = position.round()
	var rect := get_viewport().get_visible_rect()
	if position.y < -64 or position.y > rect.size.y + 64 or position.x < -64 or position.x > rect.size.x + 64:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		if area.has_method("take_damage"):
			area.take_damage(1)
		queue_free()

func _on_body_entered(_body: Node) -> void:
	pass

func _on_screen_exited() -> void:
	queue_free()
