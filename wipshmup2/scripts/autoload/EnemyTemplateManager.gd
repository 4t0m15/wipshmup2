extends Node

# EnemyTemplateManager - Manages enemy templates and creation
# Provides easy access to enemy templates by name

var templates: Dictionary = {}

func _ready() -> void:
	print("[EnemyTemplateManager] Initializing enemy templates")
	_register_default_templates()

func _register_default_templates() -> void:
	"""Register default enemy templates"""
	
	# Basic enemy types
	_register_template("basic_fighter", {
		"type_name": "basic_fighter",
		"hp": 1,
		"points": 100,
		"speed": 50.0,
		"movement_behavior": "StraightDown",
		"attack_behavior": "AimedShot",
		"movement_params": {"speed": 50.0},
		"attack_params": {"fire_rate": 1.0, "bullet_speed": 140.0}
	})
	
	_register_template("sine_fighter", {
		"type_name": "sine_fighter",
		"hp": 1,
		"points": 150,
		"speed": 40.0,
		"movement_behavior": "SineWave",
		"attack_behavior": "Fan",
		"movement_params": {"speed": 40.0, "amplitude": 30.0, "frequency": 1.0},
		"attack_params": {"fire_rate": 0.8, "fan_angle": 30.0, "bullet_count": 3}
	})
	
	_register_template("zigzag_fighter", {
		"type_name": "zigzag_fighter",
		"hp": 1,
		"points": 120,
		"speed": 45.0,
		"movement_behavior": "Zigzag",
		"attack_behavior": "AimedShot",
		"movement_params": {"speed": 45.0, "zigzag_amplitude": 25.0, "zigzag_frequency": 2.0},
		"attack_params": {"fire_rate": 1.2, "aim_lead": 0.3}
	})
	
	_register_template("dive_bomber", {
		"type_name": "dive_bomber",
		"hp": 2,
		"points": 200,
		"speed": 60.0,
		"movement_behavior": "Dive",
		"attack_behavior": "Ring",
		"movement_params": {"speed": 60.0, "dive_speed_multiplier": 1.5, "level_out_distance": 80.0},
		"attack_params": {"fire_rate": 0.6, "bullet_count": 6, "ring_rotation_speed": 45.0}
	})
	
	_register_template("heavy_bomber", {
		"type_name": "heavy_bomber",
		"hp": 3,
		"points": 300,
		"speed": 35.0,
		"movement_behavior": "StraightDown",
		"attack_behavior": "Fan",
		"movement_params": {"speed": 35.0},
		"attack_params": {"fire_rate": 0.4, "fan_angle": 60.0, "bullet_count": 5, "bullet_speed": 120.0}
	})
	
	print("[EnemyTemplateManager] Registered ", templates.size(), " enemy templates")

func _register_template(template_name: String, template_data: Dictionary) -> void:
	"""Register a new enemy template"""
	var template = EnemyTemplate.new()
	
	# Set basic properties
	template.type_name = template_data.get("type_name", template_name)
	template.hp = template_data.get("hp", 1)
	template.points = template_data.get("points", 100)
	template.speed = template_data.get("speed", 50.0)
	template.sprite_key = template_data.get("sprite_key", "enemy")
	
	# Set behaviors
	template.movement_behavior = template_data.get("movement_behavior", "StraightDown")
	template.attack_behavior = template_data.get("attack_behavior", "AimedShot")
	
	# Set parameters
	template.movement_params = template_data.get("movement_params", {})
	template.attack_params = template_data.get("attack_params", {})
	
	# Set visual properties
	template.sprite_scale = template_data.get("sprite_scale", 1.0)
	template.glow_color = template_data.get("glow_color", Color.WHITE)
	template.danger_level = template_data.get("danger_level", 1)
	
	# Set collision properties
	template.collision_radius = template_data.get("collision_radius", 8.0)
	template.collision_layer = template_data.get("collision_layer", 1)
	template.collision_mask = template_data.get("collision_mask", 1)
	
	# Set special properties
	template.ignore_shot_damage = template_data.get("ignore_shot_damage", false)
	template.ignore_bomb_damage = template_data.get("ignore_bomb_damage", false)
	template.bomb_points_override = template_data.get("bomb_points_override", -1)
	template.bomb_points_multiplier = template_data.get("bomb_points_multiplier", 10.0)
	
	templates[template_name] = template

func get_template(template_name: String) -> EnemyTemplate:
	"""Get an enemy template by name"""
	return templates.get(template_name, null)

func create_enemy(template_name: String, position: Vector2) -> Node:
	"""Create an enemy from a template"""
	var template = get_template(template_name)
	if not template:
		push_error("Enemy template not found: " + template_name)
		return null
	
	var enemy = template.create_enemy_instance()
	enemy.global_position = position
	
	return enemy

func get_all_template_names() -> Array[String]:
	"""Get all registered template names"""
	return templates.keys()

func has_template(template_name: String) -> bool:
	"""Check if a template exists"""
	return templates.has(template_name)

# Convenience methods for common enemy types
func create_basic_fighter(position: Vector2) -> Node:
	return create_enemy("basic_fighter", position)

func create_sine_fighter(position: Vector2) -> Node:
	return create_enemy("sine_fighter", position)

func create_zigzag_fighter(position: Vector2) -> Node:
	return create_enemy("zigzag_fighter", position)

func create_dive_bomber(position: Vector2) -> Node:
	return create_enemy("dive_bomber", position)

func create_heavy_bomber(position: Vector2) -> Node:
	return create_enemy("heavy_bomber", position)
