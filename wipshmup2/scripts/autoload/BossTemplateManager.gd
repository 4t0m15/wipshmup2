extends Node

# BossTemplateManager - Manages boss templates and creation
# Provides easy access to boss templates by name

var templates: Dictionary = {}

func _ready() -> void:
	print("[BossTemplateManager] Initializing boss templates")
	_register_default_templates()

func _register_default_templates() -> void:
	"""Register default boss templates"""
	
	# Gliath Boss
	_register_template("gliath", {
		"boss_name": "Gliath",
		"max_hp": 60,
		"points_value": 5000,
		"phases": [
			{
				"phase_name": "Phase 1",
				"hp_threshold": 0,
				"movement_behavior": "StraightDown",
				"attack_patterns": ["AimedShot"],
				"movement_params": {"speed": 20.0},
				"attack_params": {"fire_rate": 0.8, "bullet_speed": 100.0}
			}
		]
	})
	
	# Type0 Boss
	_register_template("type0", {
		"boss_name": "Type0",
		"max_hp": 80,
		"points_value": 7500,
		"phases": [
			{
				"phase_name": "Phase 1",
				"hp_threshold": 0,
				"movement_behavior": "SineWave",
				"attack_patterns": ["Fan"],
				"movement_params": {"speed": 25.0, "amplitude": 40.0, "frequency": 0.8},
				"attack_params": {"fire_rate": 0.6, "fan_angle": 45.0, "bullet_count": 5}
			},
			{
				"phase_name": "Phase 2",
				"hp_threshold": 40,
				"movement_behavior": "Zigzag",
				"attack_patterns": ["Ring"],
				"movement_params": {"speed": 30.0, "zigzag_amplitude": 30.0, "zigzag_frequency": 1.5},
				"attack_params": {"fire_rate": 0.4, "bullet_count": 8, "ring_rotation_speed": 30.0},
				"screen_shake_intensity": 0.5,
				"background_tint": Color(1.2, 0.8, 0.8)
			}
		]
	})
	
	# Iron Casket Boss
	_register_template("iron_casket", {
		"boss_name": "Iron Casket",
		"max_hp": 100,
		"points_value": 10000,
		"phases": [
			{
				"phase_name": "Phase 1",
				"hp_threshold": 0,
				"movement_behavior": "StraightDown",
				"attack_patterns": ["Ring"],
				"movement_params": {"speed": 15.0},
				"attack_params": {"fire_rate": 0.3, "bullet_count": 6, "ring_rotation_speed": 20.0}
			},
			{
				"phase_name": "Phase 2",
				"hp_threshold": 50,
				"movement_behavior": "SineWave",
				"attack_patterns": ["Fan"],
				"movement_params": {"speed": 20.0, "amplitude": 50.0, "frequency": 0.6},
				"attack_params": {"fire_rate": 0.2, "fan_angle": 60.0, "bullet_count": 7},
				"screen_shake_intensity": 0.8,
				"background_tint": Color(1.3, 0.7, 0.7),
				"music_pitch": 1.1
			}
		]
	})
	
	print("[BossTemplateManager] Registered ", templates.size(), " boss templates")

func _register_template(template_name: String, template_data: Dictionary) -> void:
	"""Register a new boss template"""
	var template = BossTemplate.new()
	
	# Set basic properties
	template.boss_name = template_data.get("boss_name", template_name)
	template.max_hp = template_data.get("max_hp", 60)
	template.points_value = template_data.get("points_value", 5000)
	template.sprite_key = template_data.get("sprite_key", "boss")
	
	# Set visual properties
	template.sprite_scale = template_data.get("sprite_scale", 1.0)
	template.glow_color = template_data.get("glow_color", Color.RED)
	template.danger_level = template_data.get("danger_level", 3)
	
	# Set collision properties
	template.collision_radius = template_data.get("collision_radius", 16.0)
	template.collision_layer = template_data.get("collision_layer", 1)
	template.collision_mask = template_data.get("collision_mask", 0)
	
	# Set special properties
	template.immune_to_bombs = template_data.get("immune_to_bombs", false)
	template.immune_to_player_bullets = template_data.get("immune_to_player_bullets", false)
	
	# Create phases
	template.phases.clear()
	var phases_data = template_data.get("phases", [])
	for phase_data in phases_data:
		var phase = BossPhase.new()
		phase.phase_name = phase_data.get("phase_name", "Phase")
		phase.hp_threshold = phase_data.get("hp_threshold", 0)
		phase.movement_behavior = phase_data.get("movement_behavior", "StraightDown")
		phase.attack_patterns = phase_data.get("attack_patterns", ["AimedShot"])
		phase.movement_params = phase_data.get("movement_params", {})
		phase.attack_params = phase_data.get("attack_params", {})
		phase.sprite_scale = phase_data.get("sprite_scale", 1.0)
		phase.glow_color = phase_data.get("glow_color", Color.WHITE)
		phase.danger_level = phase_data.get("danger_level", 1)
		phase.screen_shake_intensity = phase_data.get("screen_shake_intensity", 0.0)
		phase.background_tint = phase_data.get("background_tint", Color.WHITE)
		phase.music_pitch = phase_data.get("music_pitch", 1.0)
		template.phases.append(phase)
	
	templates[template_name] = template

func get_template(template_name: String) -> BossTemplate:
	"""Get a boss template by name"""
	return templates.get(template_name, null)

func create_boss(template_name: String, position: Vector2) -> Node:
	"""Create a boss from a template"""
	var template = get_template(template_name)
	if not template:
		push_error("Boss template not found: " + template_name)
		return null
	
	var boss = template.create_boss_instance()
	boss.global_position = position
	
	return boss

func get_all_template_names() -> Array[String]:
	"""Get all registered template names"""
	return templates.keys()

func has_template(template_name: String) -> bool:
	"""Check if a template exists"""
	return templates.has(template_name)

# Convenience methods for common bosses
func create_gliath(position: Vector2) -> Node:
	return create_boss("gliath", position)

func create_type0(position: Vector2) -> Node:
	return create_boss("type0", position)

func create_iron_casket(position: Vector2) -> Node:
	return create_boss("iron_casket", position)
