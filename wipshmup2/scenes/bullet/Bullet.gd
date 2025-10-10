extends Area2D

@export var speed: float = 400.0  # Reduced from 1000.0 for playable speed
@export var sprite_target_height_px: float = 10.0  # Increased for better visibility

var direction: Vector2 = Vector2.UP
var _glow_sprite: Sprite2D

func _ready() -> void:
	monitoring = true
	collision_layer = 0
	collision_mask = 1
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
	
	# Setup visual clarity for player bullets
	_setup_player_bullet_effects()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	position = position.round()
	
	# Update glow effect
	if _glow_sprite:
		var pulse = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.01)
		_glow_sprite.modulate.a = pulse * 0.6
	
	var rect := get_viewport().get_visible_rect()
	var off_top := position.y < -64
	var off_bottom := position.y > rect.size.y + 64
	var off_left := position.x < -64
	var off_right := position.x > rect.size.x + 64
	if off_top or off_bottom or off_left or off_right:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		# Emit bullet hit event to EventBus
		EventBus.bullet_hit_enemy.emit(area.global_position, 2)
		
		# Play hit sound through EventBus
		if area.is_in_group("boss"):
			EventBus.emit_audio("boss_hit")
		else:
			EventBus.emit_audio("enemy_shot")
		
		# Update rank through EventBus
		EventBus.emit_audio("player_shot")  # This will trigger rank update
		
		queue_free()

func _on_body_entered(_body: Node) -> void:
	pass

func _on_screen_exited() -> void:
	queue_free()

func _setup_player_bullet_effects() -> void:
	"""Setup visual effects for player bullet clarity"""
	# Create bright glow for player bullets
	_glow_sprite = Sprite2D.new()
	_glow_sprite.texture = $Sprite2D.texture
	_glow_sprite.scale = $Sprite2D.scale * 1.3
	_glow_sprite.modulate = Color(0.2, 1.0, 0.8, 0.6)  # Bright cyan glow
	_glow_sprite.z_index = -1
	add_child(_glow_sprite)
