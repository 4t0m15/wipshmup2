class_name DangerIndicator
extends Node2D

# Danger indicator system for off-screen threats
# Shows arrows pointing to enemies and bullets outside the screen

@export var arrow_distance: float = 20.0
@export var arrow_size: float = 8.0
@export var update_interval: float = 0.1  # Update every 100ms for performance

var _screen_rect: Rect2
var _player: Node2D
var _danger_arrows: Array[Node2D] = []
var _update_timer: float = 0.0

func _ready() -> void:
	# Get screen dimensions
	var viewport = get_viewport()
	_screen_rect = viewport.get_visible_rect()
	
	# Find player reference
	_player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= update_interval:
		_update_timer = 0.0
		_update_danger_indicators()

func _update_danger_indicators() -> void:
	"""Update danger indicators for off-screen threats"""
	if not _player or not is_instance_valid(_player):
		return
	
	# Clear existing arrows
	_clear_arrows()
	
	# Check for off-screen enemies
	_check_off_screen_enemies()
	
	# Check for off-screen bullets
	_check_off_screen_bullets()

func _check_off_screen_enemies() -> void:
	"""Check for enemies outside screen and create indicators"""
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var enemy_pos = enemy.global_position
		if not _screen_rect.has_point(enemy_pos):
			_create_danger_arrow(enemy_pos, Color(1.0, 0.3, 0.3, 0.8), "enemy")

func _check_off_screen_bullets() -> void:
	"""Check for enemy bullets outside screen and create indicators"""
	var bullets = get_tree().get_nodes_in_group("enemy_bullet")
	var bullet_count = 0
	var max_bullet_indicators = 5  # Limit to prevent spam
	
	for bullet in bullets:
		if not is_instance_valid(bullet):
			continue
		
		var bullet_pos = bullet.global_position
		if not _screen_rect.has_point(bullet_pos) and bullet_count < max_bullet_indicators:
			# Only show indicators for bullets that are moving toward the player
			var direction_to_player = (_player.global_position - bullet_pos).normalized()
			var bullet_direction = bullet.get("direction") if bullet.has_method("get") else Vector2.DOWN
			
			# Check if bullet is moving toward player (within 45 degrees)
			if direction_to_player.dot(bullet_direction) > 0.7:
				_create_danger_arrow(bullet_pos, Color(1.0, 0.8, 0.2, 0.6), "bullet")
				bullet_count += 1

func _create_danger_arrow(position: Vector2, color: Color, type: String) -> void:
	"""Create a danger arrow pointing to off-screen threat"""
	var arrow = Node2D.new()
	arrow.name = "DangerArrow_" + type
	add_child(arrow)
	
	# Calculate arrow position on screen edge
	var screen_center = _screen_rect.get_center()
	var direction_to_threat = (position - screen_center).normalized()
	var arrow_pos = screen_center + direction_to_threat * arrow_distance
	
	# Clamp to screen edges
	arrow_pos.x = clamp(arrow_pos.x, _screen_rect.position.x + 10, _screen_rect.position.x + _screen_rect.size.x - 10)
	arrow_pos.y = clamp(arrow_pos.y, _screen_rect.position.y + 10, _screen_rect.position.y + _screen_rect.size.y - 10)
	
	arrow.position = arrow_pos
	
	# Create arrow visual
	var arrow_sprite = Sprite2D.new()
	arrow_sprite.texture = _create_arrow_texture()
	arrow_sprite.scale = Vector2(arrow_size / 8.0, arrow_size / 8.0)
	arrow_sprite.modulate = color
	arrow.add_child(arrow_sprite)
	
	# Rotate arrow to point toward threat
	var angle = direction_to_threat.angle()
	arrow.rotation = angle
	
	# Add pulsing effect
	_add_pulsing_effect(arrow)
	
	_danger_arrows.append(arrow)

func _create_arrow_texture() -> ImageTexture:
	"""Create a simple arrow texture"""
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Draw simple arrow shape
	for i in range(8):
		for j in range(8):
			var x = i
			var y = j
			# Simple arrow pattern
			if (x == 4 and y >= 2) or (y == 4 and x >= 2) or (x + y == 6 and x >= 2 and y >= 2):
				image.set_pixel(x, y, Color.WHITE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _add_pulsing_effect(arrow: Node2D) -> void:
	"""Add pulsing effect to danger arrow"""
	var tween = create_tween()
	tween.tween_property(arrow, "modulate:a", 0.3, 0.5)
	tween.tween_property(arrow, "modulate:a", 1.0, 0.5)
	tween.set_loops(3)  # Set finite loops (3 times) instead of infinite

func _clear_arrows() -> void:
	"""Clear all danger arrows"""
	for arrow in _danger_arrows:
		if is_instance_valid(arrow):
			arrow.queue_free()
	_danger_arrows.clear()

func _on_screen_entered() -> void:
	"""Called when threats enter the screen - remove their indicators"""
	# This could be enhanced to track specific threats
	pass
