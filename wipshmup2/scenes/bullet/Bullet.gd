extends Area2D

@export var speed: float = 1000.0
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
	var off_top := position.y < -64
	var off_bottom := position.y > rect.size.y + 64
	var off_left := position.x < -64
	var off_right := position.x > rect.size.x + 64
	if off_top or off_bottom or off_left or off_right:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		# Play hit sound
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager:
			if area.is_in_group("boss") and audio_manager.has_method("play_boss_hit"):
				audio_manager.play_boss_hit()
			elif audio_manager.has_method("play_bullet_hit"):
				audio_manager.play_bullet_hit()
		
		if area.has_method("take_damage"):
			# Mark source as shot for conditional scoring/behavior
			area.take_damage(2, "shot")  # Increased from 1 to 2 for easier gameplay
		var rm := get_node_or_null("/root/RankManager")
		if rm and rm.has_method("on_shot_fired"):
			rm.on_shot_fired(0.25)
		queue_free()

func _on_body_entered(_body: Node) -> void:
	pass

func _on_screen_exited() -> void:
	queue_free()
