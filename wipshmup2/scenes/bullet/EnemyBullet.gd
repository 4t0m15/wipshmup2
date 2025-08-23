extends Area2D

@export var speed: float = 320.0
@export var damage: int = 1

var direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	monitoring = true
	add_to_group("enemy_bullet")
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var speed_mult: float = 1.0
	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("get_bullet_speed_multiplier"):
		speed_mult = rm.get_bullet_speed_multiplier()
	position += direction * speed * speed_mult * delta
	position = position.round()
	var viewport_rect := get_viewport_rect()
	if position.y < -64 or position.y > viewport_rect.size.y + 64 or position.x < -64 or position.x > viewport_rect.size.x + 64:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		queue_free()

func _on_screen_exited() -> void:
	queue_free()


