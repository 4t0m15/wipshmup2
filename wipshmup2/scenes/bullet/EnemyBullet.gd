extends Area2D

@export var speed: float = 320.0
@export var damage: int = 1
@export var sprite_target_height_px: float = 6.0

var direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	monitoring = true
	add_to_group("enemy_bullet")
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
	var speed_mult: float = 1.0
	var rm := get_node_or_null("/root/RankManager")
	if rm and rm.has_method("get_bullet_speed_multiplier"):
		speed_mult = rm.get_bullet_speed_multiplier()
	position += direction * speed * speed_mult * delta
	position = position.round()
	var viewport_rect := get_viewport_rect()
	var off_top: bool = position.y < -64
	var off_bottom: bool = position.y > viewport_rect.size.y + 64
	var off_left: bool = position.x < -64
	var off_right: bool = position.x > viewport_rect.size.x + 64
	if off_top or off_bottom or off_left or off_right:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		queue_free()

func _on_screen_exited() -> void:
	queue_free()


