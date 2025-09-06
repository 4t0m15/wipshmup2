extends Node

# SpriteManager - Centralized sprite scaling and management system
# This ensures all sprites are properly sized and visible

func _ready():
	print("SpriteManager autoload initialized")

# Target sizes for different entity types
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

# Sprite scaling presets for different entity types
const SCALE_PRESETS = {
	"player": Vector2(1.5, 1.5),
	"enemy_fighter": Vector2(1.2, 1.2),
	"enemy_bomber": Vector2(1.0, 1.0),
	"enemy_turret": Vector2(1.0, 1.0),
	"boss": Vector2(0.8, 0.8),
	"bullet": Vector2(3.0, 3.0),
	"explosion": Vector2(1.0, 1.0),
	"powerup": Vector2(1.0, 1.0)
}

# Color modulation presets for different enemy types
const COLOR_PRESETS = {
	"default": Color.WHITE,
	"fighter": Color.WHITE,
	"bomber": Color(0.7, 0.7, 1, 1),
	"turret": Color(0.8, 0.8, 1, 1),
	"escort": Color(0.8, 1, 0.8, 1),
	"kamikaze": Color(1, 0.4, 0.4, 1),
	"boss": Color.WHITE
}

static func setup_sprite(sprite: Sprite2D, entity_type: String, target_height: float = -1.0) -> void:
	"""Setup a sprite with proper scaling and color based on entity type"""
	if not sprite or not sprite.texture:
		push_warning("SpriteManager: Invalid sprite or missing texture")
		return
	
	# SPECIAL CASE: Don't aggressively auto-scale player; keep readable size.
	# The player texture can be large which made auto height-scaling shrink it to ~sub‑pixel size
	# after post-processing. Use the explicit preset scale for the player.
	if entity_type == "player":
		sprite.scale = SCALE_PRESETS.get("player", Vector2(1.5, 1.5))
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
	
	# Apply color modulation
	sprite.modulate = COLOR_PRESETS.get(entity_type, Color.WHITE)
	sprite.visible = true
	
	# Debug information
	print("SpriteManager: Setup ", entity_type, " sprite - scale: ", sprite.scale)

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
static func auto_setup_player_sprite(sprite: Sprite2D) -> void:
	setup_sprite(sprite, "player")

static func auto_setup_enemy_sprite(sprite: Sprite2D, enemy_type: String = "fighter") -> void:
	setup_sprite(sprite, "enemy_" + enemy_type)

static func auto_setup_boss_sprite(sprite: Sprite2D) -> void:
	setup_sprite(sprite, "boss")

static func auto_setup_bullet_sprite(sprite: Sprite2D) -> void:
	setup_sprite(sprite, "bullet")

static func auto_setup_explosion_sprite(sprite: Sprite2D) -> void:
	setup_sprite(sprite, "explosion")
