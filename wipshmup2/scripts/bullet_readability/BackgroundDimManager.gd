extends ColorRect
class_name BackgroundDimManager

## Comprehensive Background Dimming System
## Dynamically adjusts background darkness based on bullet density and proximity

# Dimming state
var _current_dim_level: float = 0.0
var _target_dim_level: float = 0.0
var _transition_speed: float = 3.0  # Speed of dim transitions

# References
var _player: Node2D
var _readability_settings: Node

func _ready() -> void:
	# Setup as full-screen overlay
	set_anchors_preset(Control.PRESET_FULL_RECT)
	color = Color(0, 0, 0, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1  # Above background, below bullets
	
	# Get settings reference
	_readability_settings = get_node_or_null("/root/BulletReadability")
	
	print("[BackgroundDimManager] Initialized")

func _process(delta: float) -> void:
	# Get player reference if not cached
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if not _player:
			return
	
	# Calculate target dim level
	_target_dim_level = _calculate_dim_level()
	
	# Smoothly transition to target
	if abs(_current_dim_level - _target_dim_level) > 0.01:
		_current_dim_level = lerp(_current_dim_level, _target_dim_level, delta * _transition_speed)
	else:
		_current_dim_level = _target_dim_level
	
	# Apply to color
	color.a = _current_dim_level

func _calculate_dim_level() -> float:
	"""Calculate appropriate dim level based on game state"""
	if not _readability_settings:
		return 0.0
	
	if _readability_settings.auto_dim_multiplier == 0.0:
		return 0.0
	
	# Count bullets
	var all_bullets = get_tree().get_nodes_in_group("enemy_bullet")
	var bullet_count = all_bullets.size()
	
	# Count nearby bullets (within danger radius)
	var nearby_bullets = 0
	if _player:
		const DANGER_RADIUS = 120.0
		for bullet in all_bullets:
			if bullet and is_instance_valid(bullet):
				var distance = bullet.global_position.distance_to(_player.global_position)
				if distance < DANGER_RADIUS:
					nearby_bullets += 1
	
	# Check if boss is active
	var boss_nodes = get_tree().get_nodes_in_group("boss")
	var is_boss = boss_nodes.size() > 0
	
	# Use settings to calculate dim level
	return _readability_settings.get_background_dim_level(
		bullet_count,
		nearby_bullets,
		is_boss
	)

func set_manual_dim(level: float) -> void:
	"""Manually set dim level (bypasses automatic calculation)"""
	_target_dim_level = clamp(level, 0.0, 1.0)

func get_current_dim() -> float:
	"""Get current dim level"""
	return _current_dim_level

func enable_dimming(enabled: bool) -> void:
	"""Enable/disable dimming system"""
	visible = enabled
	if not enabled:
		_current_dim_level = 0.0
		_target_dim_level = 0.0
		color.a = 0.0

