extends Node

# Centralized sprite scaling

func _ready():
	pass

# Target sizes
const TARGET_SIZES = {
	"player": 18.0,
	"enemy_fighter": 20.0,
	"enemy_bomber": 24.0,
	"enemy_turret": 22.0,
	"boss": 40.0,
	"bullet": 12.0,
	"explosion": 32.0,
	"powerup": 16.0
}

# Scale presets
const SCALE_PRESETS = {
	"player": Vector2(1.0, 1.0),  # Full size for better visibility
	"enemy_fighter": Vector2(1.2, 1.2),
	"enemy_bomber": Vector2(1.0, 1.0),
	"enemy_turret": Vector2(1.0, 1.0),
	"boss": Vector2(0.8, 0.8),
	"bullet": Vector2(3.0, 3.0),
	"explosion": Vector2(1.0, 1.0),
	"powerup": Vector2(1.0, 1.0)
}

# Color presets
const COLOR_PRESETS = {
	# Player: bright cyan
	"player": Color(0.2, 1.0, 0.8, 1.0),
	# Enemies by threat
	"enemy_fighter": Color(1.0, 0.3, 0.3, 1.0),  # Red - aggressive
	"enemy_bomber": Color(1.0, 0.6, 0.2, 1.0),   # Orange - medium threat
	"enemy_turret": Color(1.0, 0.8, 0.2, 1.0),   # Yellow - shooter
	"enemy_escort": Color(1.0, 0.5, 0.8, 1.0),   # Pink - support
	"enemy_kamikaze": Color(1.0, 0.2, 0.2, 1.0), # Dark red - high threat
	"enemy_boss": Color(0.8, 0.4, 1.0, 1.0),     # Purple - boss
	# Fallbacks
	"default": Color.WHITE,
	"fighter": Color(1.0, 0.3, 0.3, 1.0),
	"bomber": Color(1.0, 0.6, 0.2, 1.0),
	"turret": Color(1.0, 0.8, 0.2, 1.0),
	"escort": Color(1.0, 0.5, 0.8, 1.0),
	"kamikaze": Color(1.0, 0.2, 0.2, 1.0),
	"boss": Color(0.8, 0.4, 1.0, 1.0)
}

# Health-based color tinting for damaged enemies
const HEALTH_COLORS = {
	"healthy": Color(1.0, 1.0, 1.0, 1.0),      # White
	"damaged": Color(1.0, 0.8, 0.6, 1.0),      # Light orange
	"critical": Color(1.0, 0.4, 0.4, 1.0),     # Red
	"dying": Color(0.8, 0.2, 0.2, 1.0)         # Dark red
}

static func setup_sprite(sprite: Sprite2D, entity_type: String, target_height: float = -1.0) -> void:
	"""Setup sprite with enhanced visual clarity"""
	if not sprite:
		return
	
	# Apply size scaling
	if target_height > 0.0:
		var scale_preset = SCALE_PRESETS.get(entity_type, Vector2(1.0, 1.0))
		var base_scale = scale_preset
		if sprite.texture:
			var tex_size = sprite.texture.get_size()
			if tex_size.y > 0:
				var scale_factor = target_height / float(tex_size.y)
				sprite.scale = base_scale * scale_factor
	
	# Apply color modulation
	var color = COLOR_PRESETS.get(entity_type, COLOR_PRESETS["default"])
	sprite.modulate = color
	
	# Add subtle glow effect for better visibility
	_add_glow_effect(sprite, entity_type)

static func _add_glow_effect(sprite: Sprite2D, _entity_type: String) -> void:
	"""Add subtle glow effect for better visibility"""
	# This would be implemented with a glow shader or duplicate sprite
	# For now, we'll enhance the base color
	var base_color = sprite.modulate
	var glow_intensity = 0.1
	
	# Increase brightness slightly for better visibility
	sprite.modulate = Color(
		min(1.0, base_color.r + glow_intensity),
		min(1.0, base_color.g + glow_intensity),
		min(1.0, base_color.b + glow_intensity),
		base_color.a
	)

static func apply_health_tint(sprite: Sprite2D, health_ratio: float) -> void:
	"""Apply health-based color tinting to enemy sprites"""
	if not sprite:
		return
	
	var health_color: Color
	if health_ratio > 0.7:
		health_color = HEALTH_COLORS["healthy"]
	elif health_ratio > 0.3:
		health_color = HEALTH_COLORS["damaged"]
	elif health_ratio > 0.1:
		health_color = HEALTH_COLORS["critical"]
	else:
		health_color = HEALTH_COLORS["dying"]
	
	# Blend with original color
	var original_color = sprite.modulate
	sprite.modulate = Color(
		(original_color.r + health_color.r) * 0.5,
		(original_color.g + health_color.g) * 0.5,
		(original_color.b + health_color.b) * 0.5,
		original_color.a
	)

static func setup_sprite_legacy(sprite: Sprite2D, entity_type: String, target_height: float = -1.0) -> void:
	"""Setup a sprite with proper scaling and color based on entity type"""
	if not sprite or not sprite.texture:
		push_warning("SpriteManager: Invalid sprite or missing texture")
		return
	
	# Check if sprite already has a reasonable scale set (from scene file)
	var current_scale = sprite.scale
	var is_already_scaled = current_scale.x > 0.5 and current_scale.y > 0.5
	
	# Only apply scaling if the sprite is at default scale (1,1) or very small
	if not is_already_scaled:
		# SPECIAL CASE: Don't aggressively auto-scale player; keep readable size.
		# The player texture can be large which made auto height-scaling shrink it to ~sub‑pixel size
		# after post-processing. Use the explicit preset scale for the player.
		if entity_type == "player":
			sprite.scale = SCALE_PRESETS.get("player", Vector2(1.0, 1.0))
		else:
			# Use provided target height or get from presets
			var height = target_height if target_height > 0 else TARGET_SIZES.get(entity_type, 20.0)
			# Calculate scale based on texture size
			var tex_size = sprite.texture.get_size()
			if tex_size.y > 0:
				var scale_factor = height / float(tex_size.y)
				# If computed scale would be too tiny, fall back to preset to keep visibility
				if scale_factor < 0.25:
					push_warning("SpriteManager: Computed scale (" + str(scale_factor) + ") too small for " + entity_type + ", using preset")
					sprite.scale = SCALE_PRESETS.get(entity_type, Vector2(1.0, 1.0))
				else:
					sprite.scale = Vector2(scale_factor, scale_factor)
			else:
				# Fallback to preset scale
				sprite.scale = SCALE_PRESETS.get(entity_type, Vector2(1.0, 1.0))
	else:
		# Sprite already has a good scale, just ensure it's not too small
		if current_scale.x < 0.1 or current_scale.y < 0.1:
			sprite.scale = SCALE_PRESETS.get(entity_type, Vector2(1.0, 1.0))
	
	# Apply color modulation (normalize keys like enemy_*)
	var key := entity_type
	if not COLOR_PRESETS.has(key):
		if key.begins_with("enemy_"):
			# try both specific enemy_* and generic role
			var role := key.replace("enemy_", "")
			key = ("enemy_" + role) if COLOR_PRESETS.has("enemy_" + role) else role
	sprite.modulate = COLOR_PRESETS.get(key, Color.WHITE)
	sprite.visible = true

static func get_optimal_scale(entity_type: String) -> Vector2:
	"""Get the optimal scale for an entity type"""
	return SCALE_PRESETS.get(entity_type, Vector2(1.0, 1.0))

static func get_optimal_color(entity_type: String) -> Color:
	"""Get the optimal color for an entity type"""
	return COLOR_PRESETS.get(entity_type, Color.WHITE)

static func validate_sprite_visibility(sprite: Sprite2D) -> bool:
	"""Check if a sprite is properly visible and sized"""
	if not sprite:
		return false
	
	if not sprite.texture:
		return false
	
	if sprite.scale.x < 0.1 or sprite.scale.y < 0.1:
		push_warning("SpriteManager: Sprite scale too small: ", sprite.scale)
		return false
	
	if not sprite.visible:
		push_warning("SpriteManager: Sprite not visible")
		return false
	
	return true

# Auto-setup function for common entity types
func auto_setup_player_sprite(sprite: Sprite2D) -> void:
	setup_sprite(sprite, "player")

func auto_setup_enemy_sprite(sprite: Sprite2D, enemy_type: String = "fighter") -> void:
	setup_sprite(sprite, "enemy_" + enemy_type)

func auto_setup_boss_sprite(sprite: Sprite2D) -> void:
	setup_sprite(sprite, "boss")

func auto_setup_bullet_sprite(sprite: Sprite2D) -> void:
	setup_sprite(sprite, "bullet")

func auto_setup_explosion_sprite(sprite: Sprite2D) -> void:
	setup_sprite(sprite, "explosion")
