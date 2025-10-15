extends CharacterBody2D

signal hit
signal damaged(amount: int)

var _alive: bool = true
var _invincible: bool = false
var _invincibility_timer: float = 0.0
const INVINCIBILITY_DURATION: float = 1.0  # 1 second of invincibility after hit

# Visual clarity enhancements
var _hitbox_indicator: Node2D
var _glow_sprite: Sprite2D
var _is_focused: bool = false

func _ready() -> void:
	add_to_group("player")
	print("[Player] Player initialized")
	
	if has_node("Hurtbox"):
		var hurtbox := $Hurtbox
		hurtbox.add_to_group("player_hurtbox")
		hurtbox.monitoring = true
		hurtbox.monitorable = true
		hurtbox.collision_layer = 1   # Player layer
		hurtbox.collision_mask = 2    # Enemy bullet layer
		# Ensure hurtbox tracks the player position
		hurtbox.position = Vector2.ZERO
		print("[Player] Hurtbox configured: layer=", hurtbox.collision_layer, " mask=", hurtbox.collision_mask)
	else:
		print("[Player] WARNING: No Hurtbox node found!")
	
	# Setup visual clarity enhancements
	_setup_visual_effects()

func _physics_process(delta: float) -> void:
	if not _alive: 
		return
	
	# Handle invincibility timer
	if _invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
			_invincibility_timer = 0.0
			print("[Player] Invincibility ended")
			# Make player fully visible again
			modulate = Color.WHITE
			# Hide hitbox indicator
			if _hitbox_indicator:
				_hitbox_indicator.visible = false
		else:
			# Enhanced blink effect during invincibility
			var blink_rate = 12.0  # Faster blinking
			var alpha = 0.2 + 0.8 * abs(sin(_invincibility_timer * blink_rate * PI))
			modulate = Color(1.0, 0.8, 0.8, alpha)  # Slight red tint during invincibility
			
			# Show hitbox indicator during invincibility
			if _hitbox_indicator:
				_hitbox_indicator.visible = true
				_hitbox_indicator.modulate = Color(1.0, 0.3, 0.3, alpha)
	
	# Simple movement - this will be overridden by Main.gd
	pass

func take_damage(amount: int = 1) -> void:
	if not _alive:
		print("[Player] take_damage called but player not alive")
		return
	
	if _invincible:
		print("[Player] take_damage called but player is invincible - ignoring")
		return
	
	# Check shield first (Cho Ren Sha 68K mechanic)
	if GameState.consume_shield():
		print("[Player] Shield absorbed damage")
		return
	
	print("[Player] Taking damage: amount=", amount, " position=", position)
	
	# Start invincibility period
	_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	print("[Player] Invincibility activated for ", INVINCIBILITY_DURATION, " seconds")
	
	damaged.emit(amount)

func die() -> void:
	if not _alive: 
		return
	print("[Player] Player died at position: ", position)
	_alive = false
	hit.emit()
	queue_free()

func is_invincible() -> bool:
	return _invincible

func _setup_visual_effects() -> void:
	"""Setup visual clarity enhancements for player"""
	# Create glow effect
	_glow_sprite = Sprite2D.new()
	_glow_sprite.texture = $Sprite2D.texture if has_node("Sprite2D") else null
	_glow_sprite.scale = Vector2(1.2, 1.2)
	_glow_sprite.modulate = Color(0.2, 1.0, 0.8, 0.4)  # Bright cyan glow
	_glow_sprite.z_index = -1
	add_child(_glow_sprite)
	
	# Create hitbox indicator
	_create_hitbox_indicator()

func _create_hitbox_indicator() -> void:
	"""Create visual indicator for player hitbox"""
	_hitbox_indicator = Node2D.new()
	_hitbox_indicator.name = "HitboxIndicator"
	add_child(_hitbox_indicator)
	
	# Create small circle to show hitbox
	var circle = Sprite2D.new()
	var circle_texture = _create_circle_texture(8, Color(0.2, 1.0, 0.2, 0.6))
	circle.texture = circle_texture
	circle.position = Vector2.ZERO
	_hitbox_indicator.add_child(circle)
	
	# Initially hidden
	_hitbox_indicator.visible = false

func _create_circle_texture(radius: int, color: Color) -> ImageTexture:
	"""Create a simple circle texture for hitbox indicator"""
	var size = radius * 2
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center = Vector2(radius, radius)
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			if distance <= radius and distance >= radius - 1:
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func set_focused(focused: bool) -> void:
	"""Set focus mode for enhanced hitbox visibility"""
	_is_focused = focused
	if _hitbox_indicator:
		_hitbox_indicator.visible = focused
		if focused:
			_hitbox_indicator.modulate = Color(0.2, 1.0, 0.2, 0.8)

func _update_visual_effects(_delta: float) -> void:
	"""Update visual effects for better clarity"""
	# Update glow pulsing
	if _glow_sprite:
		var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.008)
		_glow_sprite.modulate.a = pulse * 0.4