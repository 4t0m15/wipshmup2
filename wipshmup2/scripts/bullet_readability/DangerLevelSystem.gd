extends Node
class_name DangerLevelSystem

## Comprehensive Danger Level Classification System
## Provides precise color coding and visual properties for bullet readability

enum DangerLevel {
    LOW = 1,      # Introductory patterns; highly predictable
	MEDIUM = 2,   # Aimed shots, moderate speed
	HIGH = 3      # Fast, homing, or dense patterns
}

## Exact color definitions (RGB values are pedantically specified)
const DANGER_COLORS = {
	DangerLevel.LOW: {
		"base": Color(1.0, 0.843, 0.0, 1.0),        # #FFD700 Gold
		"outline": Color(1.0, 1.0, 0.0, 1.0),       # #FFFF00 Yellow
		"glow": Color(1.0, 0.647, 0.0, 0.5),        # #FFA500 Orange, Alpha 0.5
		"pulse_rate": 0.5,                           # Hz
		"outline_thickness": 1.5                     # pixels
	},
	DangerLevel.MEDIUM: {
		"base": Color(1.0, 0.420, 0.0, 1.0),        # #FF6B00 Orange
		"outline": Color(1.0, 0.0, 0.0, 1.0),       # #FF0000 Red
		"glow": Color(1.0, 0.271, 0.0, 0.7),        # #FF4500 Orange-Red, Alpha 0.7
		"pulse_rate": 1.5,                           # Hz
		"outline_thickness": 2.0                     # pixels
	},
	DangerLevel.HIGH: {
		"base": Color(1.0, 0.0, 0.251, 1.0),        # #FF0040 Red
		"outline": Color(1.0, 1.0, 1.0, 1.0),       # #FFFFFF White
		"glow": Color(1.0, 0.0, 0.498, 0.8),        # #FF007F Bright Pink, Alpha 0.8
		"pulse_rate": 2.0,                           # Hz
		"outline_thickness": 2.5                     # pixels
	}
}

## Player bullet colors (always distinct from enemy)
const PLAYER_BULLET_COLORS = {
	"base": Color(0.290, 0.949, 1.0, 1.0),          # #4AF2FF Cyan
	"outline": Color(1.0, 1.0, 1.0, 1.0),           # #FFFFFF White
	"glow": Color(0.0, 0.831, 1.0, 0.6),            # #00D4FF Light Cyan, Alpha 0.6
	"shadow": Color(0.0, 0.122, 0.200, 0.3),        # #001F33 Dark Cyan, Alpha 0.3
	"outline_thickness": 2.0                         # pixels
}

## Glow layer specifications (pedantic multi-layer system)
const GLOW_LAYERS = {
	"inner": {
		"scale_multiplier": 1.10,
		"alpha": 0.8,
		"z_index": -1
	},
	"mid": {
		"scale_multiplier": 1.50,
		"alpha": 0.5,
		"z_index": -2
	},
	"outer": {
		"scale_multiplier": 2.00,
		"alpha": 0.3,
		"z_index": -3
	},
	"far": {  # High danger only
		"scale_multiplier": 3.00,
		"alpha": 0.15,
		"z_index": -4
	}
}

## Get complete visual properties for a bullet
static func get_visual_properties(danger_level: DangerLevel, is_player_bullet: bool = false) -> Dictionary:
	"""
	Returns a comprehensive dictionary of all visual properties for a bullet.
	
	Args:
		danger_level: The danger level (LOW, MEDIUM, HIGH)
		is_player_bullet: Whether this is a player's bullet
		
	Returns:
		Dictionary with keys: base_color, outline_color, glow_color, outline_thickness,
		pulse_rate, should_pulse, glow_layers, shadow (if player bullet)
	"""
	if is_player_bullet:
		return {
			"base_color": PLAYER_BULLET_COLORS["base"],
			"outline_color": PLAYER_BULLET_COLORS["outline"],
			"glow_color": PLAYER_BULLET_COLORS["glow"],
			"shadow_color": PLAYER_BULLET_COLORS["shadow"],
			"outline_thickness": PLAYER_BULLET_COLORS["outline_thickness"],
			"pulse_rate": 0.0,  # Player bullets don't pulse
			"should_pulse": false,
			"glow_layers": [
				GLOW_LAYERS["inner"],
				GLOW_LAYERS["mid"],
				GLOW_LAYERS["outer"]
			],
			"has_shadow": true
		}
	
	# Build normalized properties dictionary for enemy bullets
	var color_def: Dictionary = DANGER_COLORS[danger_level]
	
	# Add glow layer configuration based on danger level
	var layers: Array = [
		GLOW_LAYERS["inner"],
		GLOW_LAYERS["mid"],
		GLOW_LAYERS["outer"]
	]
	
	# High danger gets the extra far glow layer
	if danger_level == DangerLevel.HIGH:
		layers.append(GLOW_LAYERS["far"])
	
	return {
		"base_color": color_def["base"],
		"outline_color": color_def["outline"],
		"glow_color": color_def["glow"],
		"outline_thickness": color_def["outline_thickness"],
		"pulse_rate": color_def["pulse_rate"],
		"glow_layers": layers,
		"should_pulse": true,
		"has_shadow": false
	}

## Classify bullet danger level based on properties
static func classify_danger_level(bullet_speed: float, is_homing: bool, is_accelerating: bool, pattern_type: String = "normal") -> DangerLevel:
	"""
	Automatically classify a bullet's danger level based on its properties.
	
	Args:
		bullet_speed: Bullet speed in pixels/second
		is_homing: Whether bullet homes toward player
		is_accelerating: Whether bullet accelerates over time
		pattern_type: Type of pattern ("normal", "dense", "random", "aimed")
		
	Returns:
		DangerLevel enum value
	"""
	# High danger conditions (any one triggers HIGH)
	if bullet_speed > 250.0:
		return DangerLevel.HIGH
	if is_homing:
		return DangerLevel.HIGH
	if pattern_type == "dense":
		return DangerLevel.HIGH
	
	# Medium danger conditions
	if bullet_speed > 150.0:
		return DangerLevel.MEDIUM
	if is_accelerating:
		return DangerLevel.MEDIUM
	if pattern_type == "aimed":
		return DangerLevel.MEDIUM
	
	# Default to low danger
	return DangerLevel.LOW

## Get pulse intensity at current time (for animated glow)
static func get_pulse_intensity(danger_level: DangerLevel, time: float) -> float:
	"""
	Calculate current pulse intensity for glow animation.
	
	Args:
		danger_level: Danger level of bullet
		time: Current time in seconds (use Time.get_ticks_msec() / 1000.0)
		
	Returns:
		Float between 0.7 and 1.0 (pulse amplitude)
	"""
	var props = DANGER_COLORS[danger_level]
	var pulse_rate = props["pulse_rate"]
	
	# Sine wave pulse with 70% to 100% range
	var pulse = 0.85 + 0.15 * sin(time * pulse_rate * TAU)
	return pulse

## Get proximity-adjusted glow intensity
static func get_proximity_glow_multiplier(distance_to_player: float) -> float:
	"""
	Calculate glow intensity multiplier based on distance to player.
	Closer bullets glow brighter for better awareness.
	
	Args:
		distance_to_player: Distance in pixels from bullet to player
		
	Returns:
		Float multiplier (1.0 to 1.5)
	"""
	if distance_to_player < 50.0:
		return 1.5  # +50% glow when very close
	elif distance_to_player < 100.0:
		return 1.25  # +25% glow when close
	else:
		return 1.0  # Normal glow when far

## Colorblind mode adjustments
static func apply_colorblind_filter(color: Color, mode: String) -> Color:
	"""
	Apply colorblind simulation filter to a color.
	
	Args:
		color: Original color
		mode: "protanopia", "deuteranopia", "tritanopia", or "none"
		
	Returns:
		Adjusted color for specified colorblind mode
	"""
	match mode:
		"protanopia":  # Red-blind
			if color.r > 0.8 and color.g < 0.3:  # Red colors
				return Color(0.0, 0.0, 1.0, color.a)  # Replace with blue
			if color.r > 0.8 and color.g > 0.4 and color.b < 0.3:  # Orange
				return Color(0.0, 1.0, 1.0, color.a)  # Replace with cyan
		
		"deuteranopia":  # Green-blind
			if color.g > 0.8 and color.r < 0.3:  # Green colors
				return Color(0.0, 0.0, 1.0, color.a)  # Replace with blue
		
		"tritanopia":  # Blue-blind
			if color.b > 0.8 and color.r < 0.3 and color.g < 0.3:  # Blue colors
				return Color(1.0, 1.0, 0.0, color.a)  # Replace with yellow
	
	return color  # No change for "none" or unrecognized modes

## High contrast mode adjustments
static func apply_high_contrast(is_player_bullet: bool) -> Dictionary:
	"""
	Get high contrast color scheme (accessibility feature).
	
	Args:
		is_player_bullet: Whether this is for a player bullet
		
	Returns:
		Dictionary with high-contrast colors
	"""
	if is_player_bullet:
		return {
			"base_color": Color(1.0, 1.0, 0.0, 1.0),    # Pure yellow
			"outline_color": Color(0.0, 0.0, 0.0, 1.0), # Pure black
			"outline_thickness": 3.0,                    # Extra thick
			"glow_layers": []  # No glow in high contrast (too soft)
		}
	else:
		return {
			"base_color": Color(1.0, 1.0, 1.0, 1.0),    # Pure white
			"outline_color": Color(0.0, 0.0, 0.0, 1.0), # Pure black
			"outline_thickness": 3.0,                    # Extra thick
			"glow_layers": []  # No glow in high contrast
		}

