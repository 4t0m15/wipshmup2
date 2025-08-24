extends Area2D

@export var speed: float = 800.0
@export var sprite_target_height_px: float = 8.0

var direction: Vector2 = Vector2.UP

func _ready() -> void:
	monitoring = true
	add_to_group("player_bullet")
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	# Normalize sprite size to target height
	if has_node("Sprite2D"):
		var spr: Sprite2D = $Sprite2D
		if spr and spr.texture:
			var tex_size: Vector2i = spr.texture.get_size()
			if tex_size.y > 0:
				var s: float = sprite_target_height_px / float(tex_size.y)
				spr.scale = Vector2(s, s)

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
